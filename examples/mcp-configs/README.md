# QuickDesk MCP Configuration Examples

Sample configuration files for connecting AI agents to QuickDesk via MCP.

QuickDesk supports two transport modes:
- **stdio** (default): AI client spawns `quickdesk-mcp` automatically. Zero configuration.
- **HTTP/SSE**: QuickDesk hosts the MCP HTTP server. Supports multiple AI clients simultaneously.

## Files

### stdio mode (AI client manages process)

| File | Description |
|------|-------------|
| `cursor-mcp.json` | Cursor IDE — place as `.cursor/mcp.json` in your project root |
| `claude-desktop-config.json` | Claude Desktop (Windows) — place at `%APPDATA%\Claude\claude_desktop_config.json` |
| `claude-desktop-config-mac.json` | Claude Desktop (macOS) — place at `~/Library/Application Support/Claude/claude_desktop_config.json` |
| `custom-ws-url.json` | Connect to QuickDesk running on a different machine |
| `with-auth-token.json` | Use authentication token via environment variable |

### HTTP/SSE mode (QuickDesk manages MCP server)

| File | Description |
|------|-------------|
| `cursor-sse.json` | Cursor IDE — HTTP/SSE transport (type: sse) |
| `claude-desktop-http.json` | Claude Desktop — HTTP/SSE transport (type: sse) |
| `vscode-http.json` | VS Code — HTTP transport (type: http) |
| `remote-http.json` | Connect to QuickDesk on a remote machine via HTTP |

## Usage

### stdio mode

1. Copy the appropriate file to the location required by your AI client
2. Update the `command` path to point to your `quickdesk-mcp` binary
3. Make sure QuickDesk is running
4. Restart your AI client to pick up the configuration

### HTTP/SSE mode

1. In QuickDesk, open MCP settings and switch to **HTTP/SSE** mode
2. Toggle the MCP HTTP Service **ON**
3. Copy the appropriate HTTP config from the buttons in QuickDesk, or use these example files
4. Update the `url` if QuickDesk runs on a different port or host
5. Restart your AI client to pick up the configuration

> **Note:** VS Code uses `"type": "http"` and the top-level key `"servers"`.
> Other clients (Cursor, Claude Desktop, Windsurf) use `"type": "sse"` and the key `"mcpServers"`.

See the full [MCP Integration Guide](../../docs/mcp-integration.md) for details.
