"""
QuickDesk MCP HTTP Transport 真实测试脚本

测试内容:
  1. 启动 quickdesk-mcp --transport http，连接真实 QuickDesk (ws://127.0.0.1:9600)
  2. 测试 /health 端点
  3. 测试 MCP initialize
  4. 测试 tools/list (含事件工具)
  5. 测试 tool call (get_host_info, get_status, get_signaling_status, list_connections)
  6. 测试 resources/list, prompts/list
  7. 测试事件工具 (list_event_types, get_recent_events, wait_for_event 超时)
  8. 错误处理 (invalid session, DELETE)

前置条件: QuickDesk 已启动，WS API 在 ws://127.0.0.1:9600 监听
依赖: pip install requests
"""

import io
import json
import subprocess
import sys
import time
import os

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
            current["data"] = line[5:].lstrip()
        elif line == "":
            if current:
                events.append(current)
                current = {}
    if current:
        events.append(current)
    return events

def mcp_call(session, mcp_url, session_id, req_id, method, params=None):
    """发送 MCP JSON-RPC 请求，返回 (http_response, parsed_result_or_none)"""
    body = {
        "jsonrpc": "2.0",
        "id": req_id,
        "method": method,
        "params": params or {}
    }
    r = session.post(
        f"{mcp_url}/mcp",
        json=body,
        headers={
            "Content-Type": "application/json",
            "Accept": "application/json, text/event-stream",
            "mcp-session-id": session_id,
        },
        timeout=30,
    )
    result = None
    for ev in parse_sse_events(r.text):
        data = ev.get("data", "")
        if data:
            try:
                parsed = json.loads(data)
                if parsed.get("id") == req_id:
                    result = parsed.get("result", parsed)
                    break
            except json.JSONDecodeError:
                pass
    return r, result

def tool_call(session, mcp_url, session_id, req_id, tool_name, arguments=None):
    """调用 MCP tool，返回 (http_response, tool_result_dict, content_text)"""
    r, result = mcp_call(session, mcp_url, session_id, req_id, "tools/call", {
        "name": tool_name,
        "arguments": arguments or {}
    })
    content_text = ""
    if result:
        content = result.get("content", [])
        if content:
            content_text = content[0].get("text", "")
    return r, result, content_text


# -------------------------------------------------------------------
# Main test
# -------------------------------------------------------------------
def main():
    global passed, failed
    import requests

    QUICKDESK_WS_PORT = 9600
    MCP_HTTP_PORT = 18080
    MCP_URL = f"http://127.0.0.1:{MCP_HTTP_PORT}"

    # Paths
    script_dir = os.path.dirname(os.path.abspath(__file__))
    mcp_dir = os.path.join(script_dir, "quickdesk-mcp")
    exe = os.path.join(mcp_dir, "target", "debug", "quickdesk-mcp.exe")
    if not os.path.exists(exe):
        exe = os.path.join(mcp_dir, "target", "release", "quickdesk-mcp.exe")
    if not os.path.exists(exe):
        print(red(f"找不到 quickdesk-mcp.exe，请先 cargo build"))
        sys.exit(1)

    # 0) 检测真实 QuickDesk 是否在运行
    print(cyan(f"\n=== 检测 QuickDesk (ws://127.0.0.1:{QUICKDESK_WS_PORT}) ==="))
    try:
        import socket
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.settimeout(2)
        s.connect(("127.0.0.1", QUICKDESK_WS_PORT))
        s.close()
        print(f"  {green('OK')} QuickDesk WS API 端口 {QUICKDESK_WS_PORT} 可达")
    except Exception as e:
        print(red(f"  QuickDesk 未运行或 WS API 端口 {QUICKDESK_WS_PORT} 不可达: {e}"))
        print(f"  请先启动 QuickDesk 再运行此测试")
        sys.exit(1)

    # 1) 启动 quickdesk-mcp in HTTP mode，连接真实 QuickDesk
    print(cyan(f"\n=== 启动 quickdesk-mcp --transport http (port {MCP_HTTP_PORT}) ==="))
    print(f"  连接真实 QuickDesk ws://127.0.0.1:{QUICKDESK_WS_PORT}")
    env = os.environ.copy()
    env["RUST_LOG"] = "info"
    mcp_proc = subprocess.Popen(
        [exe,
         "--transport", "http",
         "--port", str(MCP_HTTP_PORT),
         "--ws-url", f"ws://127.0.0.1:{QUICKDESK_WS_PORT}"],
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

    print(f"  {green('OK')} MCP HTTP 服务已就绪 {MCP_URL}")

    session = requests.Session()

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
                "clientInfo": {"name": "test-client-real", "version": "1.0"}
            }
        }
        r = session.post(
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

        events = parse_sse_events(r.text)
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

        check("收到 mcp-session-id header", session_id is not None)
        check("收到 initialize 响应", init_result is not None)

        if init_result:
            result = init_result.get("result", {})
            server_info = result.get("serverInfo", {})
            check("serverInfo.name == 'quickdesk-mcp'",
                  server_info.get("name") == "quickdesk-mcp")
            caps = result.get("capabilities", {})
            check("capabilities 含 tools", "tools" in caps)
            check("capabilities 含 resources", "resources" in caps)
            check("capabilities 含 prompts", "prompts" in caps)
            proto_ver = result.get("protocolVersion", "")
            check("protocolVersion 非空", len(proto_ver) > 0)
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
        r_notif = session.post(
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
        r, tools_result = mcp_call(session, MCP_URL, session_id, 2, "tools/list")
        check("状态码 200", r.status_code == 200, f"got {r.status_code}")
        check("收到 tools/list 响应", tools_result is not None)

        if tools_result:
            tools = tools_result.get("tools", [])
            tool_names = [t["name"] for t in tools]
            check(f"工具数量 > 0 (实际 {len(tools)})", len(tools) > 0)
            for expected in ["get_host_info", "screenshot", "mouse_click", "keyboard_type", "connect_device"]:
                check(f"包含工具 '{expected}'", expected in tool_names)
            for expected in ["wait_for_event", "wait_for_connection_state", "wait_for_clipboard_change", "get_recent_events", "list_event_types"]:
                check(f"包含事件工具 '{expected}'", expected in tool_names)
            print(f"  {yellow('全部工具')} ({len(tools)}): {', '.join(sorted(tool_names))}")

        # ---------------------------------------------------------------
        # Test 4: get_host_info (真实数据)
        # ---------------------------------------------------------------
        print(cyan("\n=== Test 4: tools/call get_host_info (真实 QuickDesk) ==="))
        r, result, text = tool_call(session, MCP_URL, session_id, 3, "get_host_info")
        check("状态码 200", r.status_code == 200, f"got {r.status_code}")
        check("收到响应", result is not None)

        host_info = {}
        if text:
            try:
                host_info = json.loads(text)
                check("返回有效 JSON", True)
                check("返回包含 deviceId", "deviceId" in host_info, f"keys={list(host_info.keys())}")
                check("返回包含 accessCode", "accessCode" in host_info, f"keys={list(host_info.keys())}")
                print(f"  {yellow('设备ID')}: {host_info.get('deviceId', 'N/A')}")
                print(f"  {yellow('访问码')}: {host_info.get('accessCode', 'N/A')}")
                print(f"  {yellow('信令状态')}: {host_info.get('signalingState', 'N/A')}")
                print(f"  {yellow('连接客户端数')}: {host_info.get('clientCount', 'N/A')}")
            except json.JSONDecodeError:
                check("返回有效 JSON", False, f"text={text[:200]}")

        # ---------------------------------------------------------------
        # Test 5: get_status (真实数据)
        # ---------------------------------------------------------------
        print(cyan("\n=== Test 5: tools/call get_status (真实 QuickDesk) ==="))
        r, result, text = tool_call(session, MCP_URL, session_id, 4, "get_status")
        check("状态码 200", r.status_code == 200, f"got {r.status_code}")
        check("收到响应", result is not None)

        if text:
            try:
                status_data = json.loads(text)
                check("返回有效 JSON", True)
                print(f"  {yellow('get_status 返回')}: {json.dumps(status_data, indent=2, ensure_ascii=False)}")
            except json.JSONDecodeError:
                check("返回有效 JSON", False, f"text={text[:200]}")

        # ---------------------------------------------------------------
        # Test 6: get_signaling_status (真实数据)
        # ---------------------------------------------------------------
        print(cyan("\n=== Test 6: tools/call get_signaling_status ==="))
        r, result, text = tool_call(session, MCP_URL, session_id, 5, "get_signaling_status")
        check("状态码 200", r.status_code == 200, f"got {r.status_code}")
        check("收到响应", result is not None)

        if text:
            try:
                sig_data = json.loads(text)
                check("返回有效 JSON", True)
                print(f"  {yellow('信令状态')}: {json.dumps(sig_data, indent=2, ensure_ascii=False)}")
            except json.JSONDecodeError:
                check("返回有效 JSON", False, f"text={text[:200]}")

        # ---------------------------------------------------------------
        # Test 7: list_connections (真实数据)
        # ---------------------------------------------------------------
        print(cyan("\n=== Test 7: tools/call list_connections ==="))
        r, result, text = tool_call(session, MCP_URL, session_id, 6, "list_connections")
        check("状态码 200", r.status_code == 200, f"got {r.status_code}")
        check("收到响应", result is not None)

        if text:
            try:
                conn_data = json.loads(text)
                check("返回有效 JSON", True)
                if isinstance(conn_data, dict):
                    conns = conn_data.get("connections", [])
                    print(f"  {yellow('当前连接数')}: {len(conns)}")
                    for c in conns:
                        print(f"    - {c.get('connectionId', '?')}: {c.get('deviceId', '?')} ({c.get('state', '?')})")
                else:
                    print(f"  {yellow('list_connections 返回')}: {text[:200]}")
            except json.JSONDecodeError:
                check("返回有效 JSON", False, f"text={text[:200]}")

        # ---------------------------------------------------------------
        # Test 8: resources/list
        # ---------------------------------------------------------------
        print(cyan("\n=== Test 8: POST /mcp — resources/list ==="))
        r, res_result = mcp_call(session, MCP_URL, session_id, 7, "resources/list")
        check("状态码 200", r.status_code == 200, f"got {r.status_code}")
        check("收到 resources/list 响应", res_result is not None)

        if res_result:
            resources = res_result.get("resources", [])
            check(f"资源数量 >= 2 (实际 {len(resources)})", len(resources) >= 2)
            res_names = [r.get("name", "") for r in resources]
            print(f"  {yellow('资源列表')}: {', '.join(res_names)}")

        # ---------------------------------------------------------------
        # Test 9: prompts/list
        # ---------------------------------------------------------------
        print(cyan("\n=== Test 9: POST /mcp — prompts/list ==="))
        r, prompts_result = mcp_call(session, MCP_URL, session_id, 8, "prompts/list")
        check("状态码 200", r.status_code == 200, f"got {r.status_code}")
        check("收到 prompts/list 响应", prompts_result is not None)

        if prompts_result:
            prompts = prompts_result.get("prompts", [])
            check(f"Prompts 数量 > 0 (实际 {len(prompts)})", len(prompts) > 0)
            prompt_names = [p.get("name", "") for p in prompts]
            print(f"  {yellow('Prompts 列表')}: {', '.join(prompt_names)}")

        # ---------------------------------------------------------------
        # Test 10: list_event_types
        # ---------------------------------------------------------------
        print(cyan("\n=== Test 10: tools/call list_event_types ==="))
        r, result, text = tool_call(session, MCP_URL, session_id, 10, "list_event_types")
        check("状态码 200", r.status_code == 200, f"got {r.status_code}")
        check("收到响应", result is not None)

        if text:
            event_types = json.loads(text)
            type_names = [e["event"] for e in event_types]
            check("包含 connectionStateChanged", "connectionStateChanged" in type_names)
            check("包含 clipboardChanged", "clipboardChanged" in type_names)
            check("包含 sessionTimeout", "sessionTimeout" in type_names)
            check("包含 screenChanged", "screenChanged" in type_names)
            print(f"  {yellow('事件类型')}: {', '.join(type_names)}")

        # ---------------------------------------------------------------
        # Test 11: get_recent_events (真实环境，可能为空)
        # ---------------------------------------------------------------
        print(cyan("\n=== Test 11: tools/call get_recent_events ==="))
        r, result, text = tool_call(session, MCP_URL, session_id, 11, "get_recent_events")
        check("状态码 200", r.status_code == 200, f"got {r.status_code}")
        check("收到响应", result is not None)

        if text:
            recent = json.loads(text)
            check("返回数组", isinstance(recent, list))
            if recent:
                print(f"  {yellow('最近事件数')}: {len(recent)}")
                for evt in recent[:5]:
                    print(f"    - [{evt.get('event')}] ts={evt.get('timestamp')} data={json.dumps(evt.get('data', {}), ensure_ascii=False)[:80]}")
                if recent:
                    check("事件有 timestamp", recent[0].get("timestamp", 0) > 0)
                    check("事件有 event 字段", "event" in recent[0])
            else:
                print(f"  {yellow('暂无事件')} (真实环境启动后可能尚未产生事件，这是正常的)")

        # ---------------------------------------------------------------
        # Test 12: get_recent_events 按类型过滤
        # ---------------------------------------------------------------
        print(cyan("\n=== Test 12: tools/call get_recent_events (过滤) ==="))
        r, result, text = tool_call(session, MCP_URL, session_id, 12,
                                     "get_recent_events",
                                     {"event_type": "connectionStateChanged", "limit": 5})
        check("状态码 200", r.status_code == 200, f"got {r.status_code}")
        check("收到响应", result is not None)

        if text:
            filtered = json.loads(text)
            check("返回数组", isinstance(filtered, list))
            if filtered:
                all_match = all(e["event"] == "connectionStateChanged" for e in filtered)
                check(f"过滤结果全部是 connectionStateChanged ({len(filtered)})", all_match)
            else:
                print(f"  {yellow('无匹配事件')} (正常，真实环境可能尚未有连接状态变化)")

        # ---------------------------------------------------------------
        # Test 13: wait_for_event 超时测试
        # ---------------------------------------------------------------
        print(cyan("\n=== Test 13: tools/call wait_for_event (超时验证) ==="))
        print(f"  等待一个不存在的事件类型，验证 500ms 后正确超时...")
        r, result, text = tool_call(session, MCP_URL, session_id, 13,
                                     "wait_for_event",
                                     {"event": "nonExistentEventType_12345", "timeout_ms": 500})
        check("状态码 200", r.status_code == 200, f"got {r.status_code}")
        check("收到响应", result is not None)
        if text:
            check("包含 Timeout 错误", "Timeout" in text, f"text={text[:100]}")

        # ---------------------------------------------------------------
        # Test 14: wait_for_clipboard_change 超时测试
        # ---------------------------------------------------------------
        print(cyan("\n=== Test 14: tools/call wait_for_clipboard_change (超时验证) ==="))
        r, result, text = tool_call(session, MCP_URL, session_id, 14,
                                     "wait_for_clipboard_change",
                                     {"connection_id": "nonexistent_conn", "timeout_ms": 500})
        check("状态码 200", r.status_code == 200, f"got {r.status_code}")
        check("收到响应", result is not None)
        if text:
            check("包含 Timeout 错误", "Timeout" in text, f"text={text[:100]}")

        # ---------------------------------------------------------------
        # Test 15: get_host_clients
        # ---------------------------------------------------------------
        print(cyan("\n=== Test 15: tools/call get_host_clients ==="))
        r, result, text = tool_call(session, MCP_URL, session_id, 15, "get_host_clients")
        check("状态码 200", r.status_code == 200, f"got {r.status_code}")
        check("收到响应", result is not None)
        if text:
            try:
                clients_data = json.loads(text)
                check("返回有效 JSON", True)
                print(f"  {yellow('get_host_clients 返回')}: {json.dumps(clients_data, indent=2, ensure_ascii=False)[:300]}")
            except json.JSONDecodeError:
                check("返回有效 JSON", False, f"text={text[:200]}")

        # ---------------------------------------------------------------
        # Test 16: 错误 session_id → 404
        # ---------------------------------------------------------------
        print(cyan("\n=== Test 16: 错误 session_id → 404 ==="))
        r = session.post(
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
        # Test 17: DELETE session
        # ---------------------------------------------------------------
        print(cyan("\n=== Test 17: DELETE /mcp — 终止会话 ==="))
        r = session.delete(
            f"{MCP_URL}/mcp",
            headers={"mcp-session-id": session_id},
            timeout=5,
        )
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
    if failed:
        print(f"  测试结果: {green(f'{passed} passed')} / {red(f'{failed} failed')} / {total} total")
    else:
        print(f"  测试结果: {green(f'{passed} passed')} / {total} total")
    print(cyan(f"{'='*50}\n"))

    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
