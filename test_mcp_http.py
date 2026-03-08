"""
QuickDesk MCP HTTP Transport 测试脚本

测试内容:
  1. 启动 mock WebSocket 后端 (模拟 QuickDesk API + 事件推送)
  2. 启动 quickdesk-mcp --transport http
  3. 测试 /health 端点
  4. 测试 MCP initialize (POST /mcp)
  5. 测试 tools/list (含新增事件工具)
  6. 测试 tool call (get_status)
  7. 测试事件工具 (list_event_types, get_recent_events, wait_for_event, wait_for_connection_state)
  8. 清理进程

依赖: pip install websockets requests
"""

import asyncio
import io
import json
import subprocess
import sys
import time
import threading
import os
import signal

# Force UTF-8 stdout on Windows
if sys.platform == "win32":
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding="utf-8", errors="replace")

# --- 颜色输出 ---
def green(s):  return f"\033[92m{s}\033[0m"
def red(s):    return f"\033[91m{s}\033[0m"
def yellow(s): return f"\033[93m{s}\033[0m"
def cyan(s):   return f"\033[96m{s}\033[0m"

passed = 0
failed = 0

def check(name, condition, detail=""):
    global passed, failed
    if condition:
        passed += 1
        print(f"  {green('PASS')} {name}")
    else:
        failed += 1
        msg = f"  {red('FAIL')} {name}"
        if detail:
            msg += f"  -- {detail}"
        print(msg)

# -------------------------------------------------------------------
# Mock WebSocket server: simulates QuickDesk's internal WS API on 9601
# -------------------------------------------------------------------
MOCK_WS_PORT = 9601

# Store connected websocket clients for event pushing
mock_ws_clients = []
mock_ws_clients_lock = threading.Lock()

async def mock_ws_handler(websocket):
    """Handle one WebSocket connection from quickdesk-mcp."""
    with mock_ws_clients_lock:
        mock_ws_clients.append(websocket)
    try:
        async for raw in websocket:
            try:
                msg = json.loads(raw)
            except json.JSONDecodeError:
                continue

            req_id = msg.get("id")
            method = msg.get("method", "")

            # Build mock responses for each API method
            if method == "auth":
                resp = {"id": req_id, "result": {"authenticated": True}}
            elif method == "getHostInfo":
                resp = {"id": req_id, "result": {
                    "deviceId": "123456789",
                    "accessCode": "000000",
                    "signalingState": "connected",
                    "clientCount": 0
                }}
            elif method == "getStatus":
                resp = {"id": req_id, "result": {
                    "hostProcess": "running",
                    "clientProcess": "running",
                    "signalingServer": "connected"
                }}
            elif method == "getSignalingStatus":
                resp = {"id": req_id, "result": {
                    "host": "connected",
                    "client": "connected"
                }}
            elif method == "listConnections":
                resp = {"id": req_id, "result": {"connections": []}}
            elif method == "getHostClients":
                resp = {"id": req_id, "result": {"clients": []}}
            else:
                resp = {"id": req_id, "result": {"ok": True, "method": method}}

            await websocket.send(json.dumps(resp))
    finally:
        with mock_ws_clients_lock:
            if websocket in mock_ws_clients:
                mock_ws_clients.remove(websocket)


# Global event loop reference for pushing events from main thread
mock_ws_loop = None

async def push_event_to_clients(event_name, data):
    """Push an event to all connected WS clients (simulates Qt broadcastEvent)."""
    msg = json.dumps({"event": event_name, "data": data})
    with mock_ws_clients_lock:
        clients = list(mock_ws_clients)
    for ws in clients:
        try:
            await ws.send(msg)
        except Exception:
            pass

def push_event_sync(event_name, data):
    """Push an event from the main test thread into the mock WS event loop."""
    global mock_ws_loop
    if mock_ws_loop is None:
        return
    asyncio.run_coroutine_threadsafe(
        push_event_to_clients(event_name, data),
        mock_ws_loop
    )

async def run_mock_ws():
    import websockets
    server = await websockets.serve(mock_ws_handler, "127.0.0.1", MOCK_WS_PORT)
    await server.serve_forever()

def start_mock_ws():
    """Run mock WS in a daemon thread."""
    global mock_ws_loop
    loop = asyncio.new_event_loop()
    mock_ws_loop = loop
    asyncio.set_event_loop(loop)
    loop.run_until_complete(run_mock_ws())

# -------------------------------------------------------------------
# SSE response parser
# -------------------------------------------------------------------
def parse_sse_events(text):
    """Parse SSE text into list of dicts with 'event_id', 'data', 'retry'."""
    events = []
    current = {}
    for line in text.split("\n"):
        if line.startswith("id: "):
            current["event_id"] = line[4:]
        elif line.startswith("data: "):
            current["data"] = line[6:]
        elif line.startswith("retry: "):
            current["retry"] = line[7:]
        elif line.startswith("data:"):
            # data with no space after colon (empty or immediate value)
            current["data"] = line[5:].lstrip()
        elif line == "":
            if current:
                events.append(current)
                current = {}
    if current:
        events.append(current)
    return events

# -------------------------------------------------------------------
# Main test
# -------------------------------------------------------------------
def main():
    global passed, failed
    import requests

    # Paths
    script_dir = os.path.dirname(os.path.abspath(__file__))
    mcp_dir = os.path.join(script_dir, "quickdesk-mcp")
    exe = os.path.join(mcp_dir, "target", "debug", "quickdesk-mcp.exe")
    if not os.path.exists(exe):
        # Try release
        exe = os.path.join(mcp_dir, "target", "release", "quickdesk-mcp.exe")
    if not os.path.exists(exe):
        print(red(f"找不到 quickdesk-mcp.exe，请先 cargo build"))
        print(f"  尝试路径: {exe}")
        sys.exit(1)

    MCP_HTTP_PORT = 18080
    MCP_URL = f"http://127.0.0.1:{MCP_HTTP_PORT}"

    # 1) Start mock WebSocket server
    print(cyan("\n=== 启动 Mock WebSocket 后端 (port {}) ===".format(MOCK_WS_PORT)))
    ws_thread = threading.Thread(target=start_mock_ws, daemon=True)
    ws_thread.start()
    time.sleep(0.5)
    print(f"  Mock WS 已启动 ws://127.0.0.1:{MOCK_WS_PORT}")

    # 2) Start quickdesk-mcp in HTTP mode
    print(cyan(f"\n=== 启动 quickdesk-mcp --transport http (port {MCP_HTTP_PORT}) ==="))
    env = os.environ.copy()
    env["RUST_LOG"] = "info"
    mcp_proc = subprocess.Popen(
        [exe,
         "--transport", "http",
         "--port", str(MCP_HTTP_PORT),
         "--ws-url", f"ws://127.0.0.1:{MOCK_WS_PORT}"],
        stderr=subprocess.PIPE,
        stdout=subprocess.PIPE,
        env=env,
        creationflags=subprocess.CREATE_NEW_PROCESS_GROUP if sys.platform == "win32" else 0,
    )

    # Wait for server to be ready
    ready = False
    for _ in range(30):
        time.sleep(0.3)
        try:
            r = requests.get(f"{MCP_URL}/health", timeout=1)
            if r.status_code == 200:
                ready = True
                break
        except requests.ConnectionError:
            continue

    if not ready:
        print(red("  quickdesk-mcp 启动超时!"))
        stderr_out = mcp_proc.stderr.read(4096).decode(errors="replace") if mcp_proc.stderr else ""
        if stderr_out:
            print(f"  stderr: {stderr_out[:500]}")
        mcp_proc.kill()
        sys.exit(1)

    print(f"  MCP HTTP 服务已就绪 {MCP_URL}")

    try:
        # ---------------------------------------------------------------
        # Test 1: Health check
        # ---------------------------------------------------------------
        print(cyan("\n=== Test 1: GET /health ==="))
        r = requests.get(f"{MCP_URL}/health", timeout=5)
        check("状态码 200", r.status_code == 200, f"got {r.status_code}")
        check("响应体 'ok'", r.text == "ok", f"got '{r.text}'")

        # ---------------------------------------------------------------
        # Test 2: MCP Initialize
        # ---------------------------------------------------------------
        print(cyan("\n=== Test 2: POST /mcp — initialize ==="))
        init_body = {
            "jsonrpc": "2.0",
            "id": 1,
            "method": "initialize",
            "params": {
                "protocolVersion": "2025-11-25",
                "capabilities": {},
                "clientInfo": {"name": "test-client", "version": "1.0"}
            }
        }
        r = requests.post(
            f"{MCP_URL}/mcp",
            json=init_body,
            headers={
                "Content-Type": "application/json",
                "Accept": "application/json, text/event-stream",
            },
            timeout=10,
        )
        check("状态码 200", r.status_code == 200, f"got {r.status_code}")

        content_type = r.headers.get("Content-Type", "")
        check("Content-Type 含 text/event-stream", "text/event-stream" in content_type, content_type)

        # Parse SSE
        events = parse_sse_events(r.text)
        # Find the event with JSON-RPC response
        init_result = None
        session_id = r.headers.get("mcp-session-id")
        for ev in events:
            data = ev.get("data", "")
            if data:
                try:
                    parsed = json.loads(data)
                    if parsed.get("id") == 1:
                        init_result = parsed
                        break
                except json.JSONDecodeError:
                    pass

        check("收到 mcp-session-id header", session_id is not None, f"headers={dict(r.headers)}")
        check("收到 initialize 响应", init_result is not None, f"events={events}")

        if init_result:
            result = init_result.get("result", {})
            server_info = result.get("serverInfo", {})
            check("serverInfo.name == 'quickdesk-mcp'",
                  server_info.get("name") == "quickdesk-mcp",
                  f"got {server_info.get('name')}")
            caps = result.get("capabilities", {})
            check("capabilities 含 tools", "tools" in caps, f"caps={caps}")
            check("capabilities 含 resources", "resources" in caps, f"caps={caps}")
            check("capabilities 含 prompts", "prompts" in caps, f"caps={caps}")
            proto_ver = result.get("protocolVersion", "")
            check("protocolVersion 非空", len(proto_ver) > 0, f"got '{proto_ver}'")
            print(f"  {yellow('协议版本')}: {proto_ver}")
            print(f"  {yellow('服务器')}: {server_info.get('name')} v{server_info.get('version')}")

        if not session_id:
            print(red("\n  无法继续后续测试（缺少 session_id）"))
            return

        # Send initialized notification
        notif_body = {
            "jsonrpc": "2.0",
            "method": "notifications/initialized",
        }
        r_notif = requests.post(
            f"{MCP_URL}/mcp",
            json=notif_body,
            headers={
                "Content-Type": "application/json",
                "Accept": "application/json, text/event-stream",
                "mcp-session-id": session_id,
            },
            timeout=5,
        )
        check("initialized 通知 → 202 Accepted", r_notif.status_code == 202, f"got {r_notif.status_code}")

        # ---------------------------------------------------------------
        # Test 3: tools/list
        # ---------------------------------------------------------------
        print(cyan("\n=== Test 3: POST /mcp — tools/list ==="))
        tools_body = {
            "jsonrpc": "2.0",
            "id": 2,
            "method": "tools/list",
            "params": {}
        }
        r = requests.post(
            f"{MCP_URL}/mcp",
            json=tools_body,
            headers={
                "Content-Type": "application/json",
                "Accept": "application/json, text/event-stream",
                "mcp-session-id": session_id,
            },
            timeout=10,
        )
        check("状态码 200", r.status_code == 200, f"got {r.status_code}")

        tools_result = None
        for ev in parse_sse_events(r.text):
            data = ev.get("data", "")
            if data:
                try:
                    parsed = json.loads(data)
                    if parsed.get("id") == 2:
                        tools_result = parsed.get("result", {})
                        break
                except json.JSONDecodeError:
                    pass

        check("收到 tools/list 响应", tools_result is not None, f"raw={r.text[:300]}")
        if tools_result:
            tools = tools_result.get("tools", [])
            tool_names = [t["name"] for t in tools]
            check(f"工具数量 > 0 (实际 {len(tools)})", len(tools) > 0)
            # Check some known tools
            for expected in ["get_host_info", "screenshot", "mouse_click", "keyboard_type", "connect_device"]:
                check(f"包含工具 '{expected}'", expected in tool_names,
                      f"available: {tool_names[:10]}...")
            # Check new event tools
            for expected in ["wait_for_event", "wait_for_connection_state", "wait_for_clipboard_change", "get_recent_events", "list_event_types"]:
                check(f"包含事件工具 '{expected}'", expected in tool_names,
                      f"available: {tool_names}")
            print(f"  {yellow('全部工具')}: {', '.join(tool_names)}")

        # ---------------------------------------------------------------
        # Test 4: Call a tool (get_status)
        # ---------------------------------------------------------------
        print(cyan("\n=== Test 4: POST /mcp — tools/call get_status ==="))
        call_body = {
            "jsonrpc": "2.0",
            "id": 3,
            "method": "tools/call",
            "params": {
                "name": "get_status",
                "arguments": {}
            }
        }
        r = requests.post(
            f"{MCP_URL}/mcp",
            json=call_body,
            headers={
                "Content-Type": "application/json",
                "Accept": "application/json, text/event-stream",
                "mcp-session-id": session_id,
            },
            timeout=10,
        )
        check("状态码 200", r.status_code == 200, f"got {r.status_code}")

        call_result = None
        for ev in parse_sse_events(r.text):
            data = ev.get("data", "")
            if data:
                try:
                    parsed = json.loads(data)
                    if parsed.get("id") == 3:
                        call_result = parsed.get("result", {})
                        break
                except json.JSONDecodeError:
                    pass

        check("收到 tools/call 响应", call_result is not None, f"raw={r.text[:300]}")
        if call_result:
            content = call_result.get("content", [])
            check("响应 content 非空", len(content) > 0, f"result={call_result}")
            if content:
                text = content[0].get("text", "")
                check("content[0].type == 'text'", content[0].get("type") == "text")
                # The mock returns a JSON with hostProcess etc.
                try:
                    status_data = json.loads(text)
                    check("返回包含 hostProcess", "hostProcess" in status_data, f"data={status_data}")
                    print(f"  {yellow('get_status 返回')}: {json.dumps(status_data, indent=2)}")
                except json.JSONDecodeError:
                    check("返回可解析为 JSON", False, f"text={text[:200]}")

        # ---------------------------------------------------------------
        # Test 5: resources/list
        # ---------------------------------------------------------------
        print(cyan("\n=== Test 5: POST /mcp — resources/list ==="))
        res_body = {
            "jsonrpc": "2.0",
            "id": 4,
            "method": "resources/list",
            "params": {}
        }
        r = requests.post(
            f"{MCP_URL}/mcp",
            json=res_body,
            headers={
                "Content-Type": "application/json",
                "Accept": "application/json, text/event-stream",
                "mcp-session-id": session_id,
            },
            timeout=10,
        )
        check("状态码 200", r.status_code == 200, f"got {r.status_code}")

        res_result = None
        for ev in parse_sse_events(r.text):
            data = ev.get("data", "")
            if data:
                try:
                    parsed = json.loads(data)
                    if parsed.get("id") == 4:
                        res_result = parsed.get("result", {})
                        break
                except json.JSONDecodeError:
                    pass

        check("收到 resources/list 响应", res_result is not None, f"raw={r.text[:300]}")
        if res_result:
            resources = res_result.get("resources", [])
            check(f"资源数量 >= 2 (实际 {len(resources)})", len(resources) >= 2)
            res_names = [r.get("name", "") for r in resources]
            print(f"  {yellow('资源列表')}: {', '.join(res_names)}")

        # ---------------------------------------------------------------
        # Test 6: prompts/list
        # ---------------------------------------------------------------
        print(cyan("\n=== Test 6: POST /mcp — prompts/list ==="))
        prompts_body = {
            "jsonrpc": "2.0",
            "id": 5,
            "method": "prompts/list",
            "params": {}
        }
        r = requests.post(
            f"{MCP_URL}/mcp",
            json=prompts_body,
            headers={
                "Content-Type": "application/json",
                "Accept": "application/json, text/event-stream",
                "mcp-session-id": session_id,
            },
            timeout=10,
        )
        check("状态码 200", r.status_code == 200, f"got {r.status_code}")

        prompts_result = None
        for ev in parse_sse_events(r.text):
            data = ev.get("data", "")
            if data:
                try:
                    parsed = json.loads(data)
                    if parsed.get("id") == 5:
                        prompts_result = parsed.get("result", {})
                        break
                except json.JSONDecodeError:
                    pass

        check("收到 prompts/list 响应", prompts_result is not None)
        if prompts_result:
            prompts = prompts_result.get("prompts", [])
            check(f"Prompts 数量 > 0 (实际 {len(prompts)})", len(prompts) > 0)
            prompt_names = [p.get("name", "") for p in prompts]
            print(f"  {yellow('Prompts 列表')}: {', '.join(prompt_names)}")

        # ---------------------------------------------------------------
        # Test 7: list_event_types tool
        # ---------------------------------------------------------------
        print(cyan("\n=== Test 7: tools/call list_event_types ==="))
        call_body = {
            "jsonrpc": "2.0",
            "id": 10,
            "method": "tools/call",
            "params": {
                "name": "list_event_types",
                "arguments": {}
            }
        }
        r = requests.post(
            f"{MCP_URL}/mcp",
            json=call_body,
            headers={
                "Content-Type": "application/json",
                "Accept": "application/json, text/event-stream",
                "mcp-session-id": session_id,
            },
            timeout=10,
        )
        check("状态码 200", r.status_code == 200, f"got {r.status_code}")

        call_result = None
        for ev in parse_sse_events(r.text):
            data = ev.get("data", "")
            if data:
                try:
                    parsed = json.loads(data)
                    if parsed.get("id") == 10:
                        call_result = parsed.get("result", {})
                        break
                except json.JSONDecodeError:
                    pass

        check("收到 list_event_types 响应", call_result is not None)
        if call_result:
            content = call_result.get("content", [])
            check("content 非空", len(content) > 0)
            if content:
                text = content[0].get("text", "")
                event_types = json.loads(text)
                type_names = [e["event"] for e in event_types]
                check("包含 connectionStateChanged", "connectionStateChanged" in type_names)
                check("包含 clipboardChanged", "clipboardChanged" in type_names)
                check("包含 sessionTimeout", "sessionTimeout" in type_names)
                check("包含 screenChanged", "screenChanged" in type_names)
                print(f"  {yellow('事件类型')}: {', '.join(type_names)}")

        # ---------------------------------------------------------------
        # Test 8: Push events from mock WS and test get_recent_events
        # ---------------------------------------------------------------
        print(cyan("\n=== Test 8: 事件推送 + get_recent_events ==="))

        # Push several events from mock WS backend
        push_event_sync("connectionStateChanged", {
            "connectionId": "conn_test_1",
            "state": "connected",
            "previousState": "connecting"
        })
        time.sleep(0.1)
        push_event_sync("clipboardChanged", {
            "connectionId": "conn_test_1",
            "text": "Hello from clipboard"
        })
        time.sleep(0.1)
        push_event_sync("connectionStateChanged", {
            "connectionId": "conn_test_2",
            "state": "failed",
            "previousState": "connecting"
        })
        # Give time for events to propagate through the bridge
        time.sleep(0.5)

        # Now call get_recent_events
        call_body = {
            "jsonrpc": "2.0",
            "id": 11,
            "method": "tools/call",
            "params": {
                "name": "get_recent_events",
                "arguments": {}
            }
        }
        r = requests.post(
            f"{MCP_URL}/mcp",
            json=call_body,
            headers={
                "Content-Type": "application/json",
                "Accept": "application/json, text/event-stream",
                "mcp-session-id": session_id,
            },
            timeout=10,
        )
        check("状态码 200", r.status_code == 200, f"got {r.status_code}")

        call_result = None
        for ev in parse_sse_events(r.text):
            data = ev.get("data", "")
            if data:
                try:
                    parsed = json.loads(data)
                    if parsed.get("id") == 11:
                        call_result = parsed.get("result", {})
                        break
                except json.JSONDecodeError:
                    pass

        check("收到 get_recent_events 响应", call_result is not None)
        if call_result:
            content = call_result.get("content", [])
            check("content 非空", len(content) > 0)
            if content:
                text = content[0].get("text", "")
                recent = json.loads(text)
                check(f"收到 >= 3 个事件 (实际 {len(recent)})", len(recent) >= 3)
                event_names = [e["event"] for e in recent]
                check("包含 connectionStateChanged 事件", "connectionStateChanged" in event_names)
                check("包含 clipboardChanged 事件", "clipboardChanged" in event_names)
                # Check timestamp is set
                if recent:
                    check("事件有 timestamp", recent[0].get("timestamp", 0) > 0)
                print(f"  {yellow('最近事件')}: {event_names}")

        # ---------------------------------------------------------------
        # Test 9: get_recent_events with filter
        # ---------------------------------------------------------------
        print(cyan("\n=== Test 9: get_recent_events 按类型过滤 ==="))
        call_body = {
            "jsonrpc": "2.0",
            "id": 12,
            "method": "tools/call",
            "params": {
                "name": "get_recent_events",
                "arguments": {"event_type": "clipboardChanged", "limit": 5}
            }
        }
        r = requests.post(
            f"{MCP_URL}/mcp",
            json=call_body,
            headers={
                "Content-Type": "application/json",
                "Accept": "application/json, text/event-stream",
                "mcp-session-id": session_id,
            },
            timeout=10,
        )
        check("状态码 200", r.status_code == 200, f"got {r.status_code}")

        call_result = None
        for ev in parse_sse_events(r.text):
            data = ev.get("data", "")
            if data:
                try:
                    parsed = json.loads(data)
                    if parsed.get("id") == 12:
                        call_result = parsed.get("result", {})
                        break
                except json.JSONDecodeError:
                    pass

        check("收到过滤结果", call_result is not None)
        if call_result:
            content = call_result.get("content", [])
            if content:
                text = content[0].get("text", "")
                filtered = json.loads(text)
                check(f"只有 clipboardChanged 事件 (实际 {len(filtered)})", len(filtered) >= 1)
                all_clipboard = all(e["event"] == "clipboardChanged" for e in filtered)
                check("全部是 clipboardChanged", all_clipboard)
                if filtered:
                    check("data 含 text 字段", "text" in filtered[0].get("data", {}))

        # ---------------------------------------------------------------
        # Test 10: wait_for_event with delayed push
        # ---------------------------------------------------------------
        print(cyan("\n=== Test 10: wait_for_event (延迟事件推送) ==="))

        # Schedule event push after 0.5s in background
        def delayed_push():
            time.sleep(0.5)
            push_event_sync("screenChanged", {
                "connectionId": "conn_test_1",
                "changePercent": 42.5
            })
        push_thread = threading.Thread(target=delayed_push, daemon=True)
        push_thread.start()

        call_body = {
            "jsonrpc": "2.0",
            "id": 13,
            "method": "tools/call",
            "params": {
                "name": "wait_for_event",
                "arguments": {
                    "event": "screenChanged",
                    "timeout_ms": 5000
                }
            }
        }
        r = requests.post(
            f"{MCP_URL}/mcp",
            json=call_body,
            headers={
                "Content-Type": "application/json",
                "Accept": "application/json, text/event-stream",
                "mcp-session-id": session_id,
            },
            timeout=10,
        )
        check("状态码 200", r.status_code == 200, f"got {r.status_code}")

        call_result = None
        for ev in parse_sse_events(r.text):
            data = ev.get("data", "")
            if data:
                try:
                    parsed = json.loads(data)
                    if parsed.get("id") == 13:
                        call_result = parsed.get("result", {})
                        break
                except json.JSONDecodeError:
                    pass

        check("收到 wait_for_event 响应", call_result is not None)
        if call_result:
            content = call_result.get("content", [])
            check("content 非空", len(content) > 0)
            if content:
                text = content[0].get("text", "")
                event_data = json.loads(text)
                check("事件类型 == screenChanged", event_data.get("event") == "screenChanged")
                check("data 含 changePercent", "changePercent" in event_data.get("data", {}))
                print(f"  {yellow('等到的事件')}: {event_data.get('event')} data={event_data.get('data')}")

        # ---------------------------------------------------------------
        # Test 11: wait_for_connection_state with filter
        # ---------------------------------------------------------------
        print(cyan("\n=== Test 11: wait_for_connection_state ==="))

        # Schedule connection state event
        def delayed_connection_push():
            time.sleep(0.5)
            push_event_sync("connectionStateChanged", {
                "connectionId": "conn_42",
                "state": "connected",
                "previousState": "connecting"
            })
        push_thread2 = threading.Thread(target=delayed_connection_push, daemon=True)
        push_thread2.start()

        call_body = {
            "jsonrpc": "2.0",
            "id": 14,
            "method": "tools/call",
            "params": {
                "name": "wait_for_connection_state",
                "arguments": {
                    "connection_id": "conn_42",
                    "state": "connected",
                    "timeout_ms": 5000
                }
            }
        }
        r = requests.post(
            f"{MCP_URL}/mcp",
            json=call_body,
            headers={
                "Content-Type": "application/json",
                "Accept": "application/json, text/event-stream",
                "mcp-session-id": session_id,
            },
            timeout=10,
        )
        check("状态码 200", r.status_code == 200, f"got {r.status_code}")

        call_result = None
        for ev in parse_sse_events(r.text):
            data = ev.get("data", "")
            if data:
                try:
                    parsed = json.loads(data)
                    if parsed.get("id") == 14:
                        call_result = parsed.get("result", {})
                        break
                except json.JSONDecodeError:
                    pass

        check("收到 wait_for_connection_state 响应", call_result is not None)
        if call_result:
            content = call_result.get("content", [])
            check("content 非空", len(content) > 0)
            if content:
                text = content[0].get("text", "")
                event_data = json.loads(text)
                check("事件类型 == connectionStateChanged",
                      event_data.get("event") == "connectionStateChanged")
                check("connectionId == conn_42",
                      event_data.get("data", {}).get("connectionId") == "conn_42")
                check("state == connected",
                      event_data.get("data", {}).get("state") == "connected")

        # ---------------------------------------------------------------
        # Test 12: wait_for_event timeout
        # ---------------------------------------------------------------
        print(cyan("\n=== Test 12: wait_for_event 超时 ==="))
        call_body = {
            "jsonrpc": "2.0",
            "id": 15,
            "method": "tools/call",
            "params": {
                "name": "wait_for_event",
                "arguments": {
                    "event": "nonExistentEvent",
                    "timeout_ms": 500
                }
            }
        }
        r = requests.post(
            f"{MCP_URL}/mcp",
            json=call_body,
            headers={
                "Content-Type": "application/json",
                "Accept": "application/json, text/event-stream",
                "mcp-session-id": session_id,
            },
            timeout=10,
        )
        check("状态码 200", r.status_code == 200, f"got {r.status_code}")

        call_result = None
        for ev in parse_sse_events(r.text):
            data = ev.get("data", "")
            if data:
                try:
                    parsed = json.loads(data)
                    if parsed.get("id") == 15:
                        call_result = parsed.get("result", {})
                        break
                except json.JSONDecodeError:
                    pass

        check("收到超时响应", call_result is not None)
        if call_result:
            content = call_result.get("content", [])
            if content:
                text = content[0].get("text", "")
                check("包含 Timeout 错误", "Timeout" in text, f"text={text[:100]}")

        # ---------------------------------------------------------------
        # Test 13: Invalid session → 404
        # ---------------------------------------------------------------
        print(cyan("\n=== Test 13: 错误 session_id → 404 ==="))
        r = requests.post(
            f"{MCP_URL}/mcp",
            json={"jsonrpc": "2.0", "id": 99, "method": "tools/list", "params": {}},
            headers={
                "Content-Type": "application/json",
                "Accept": "application/json, text/event-stream",
                "mcp-session-id": "invalid-session-id-12345",
            },
            timeout=5,
        )
        check("伪造 session_id → 404", r.status_code == 404, f"got {r.status_code}")

        # ---------------------------------------------------------------
        # Test 14: DELETE session
        # ---------------------------------------------------------------
        print(cyan("\n=== Test 14: DELETE /mcp — 终止会话 ==="))
        r = requests.delete(
            f"{MCP_URL}/mcp",
            headers={"mcp-session-id": session_id},
            timeout=5,
        )
        # 405 or 200 depending on implementation; rmcp returns 200 or 202
        check("DELETE 返回 2xx", 200 <= r.status_code < 300, f"got {r.status_code}")

    finally:
        # Cleanup
        print(cyan("\n=== 清理 ==="))
        try:
            mcp_proc.terminate()
            mcp_proc.wait(timeout=5)
        except Exception:
            mcp_proc.kill()
        print("  quickdesk-mcp 已停止")

    # Summary
    total = passed + failed
    print(cyan(f"\n{'='*50}"))
    print(f"  测试结果: {green(f'{passed} passed')} / {red(f'{failed} failed') if failed else f'{total} total'}")
    print(cyan(f"{'='*50}\n"))

    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
