# MCP.SDK

A PowerShell SDK for building [Model Context Protocol](https://modelcontextprotocol.io) servers. Drop PowerShell scripts into a folder, and the SDK discovers and exposes them as MCP tools, prompts, and resources — no boilerplate, no protocol plumbing.

## How it works

The SDK uses a convention-based folder layout. Anything you put in these directories is auto-discovered:

```text
my-server/
├── tools/          # .ps1 scripts exposed as MCP tools
├── prompts/        # .ps1 scripts exposed as MCP prompts
├── resources/      # files (or .ps1 scripts) exposed as MCP resources
└── instructions.md # optional: server usage instructions for the client
```

Parameter metadata, types, `ValidateSet`, and help text from your scripts are translated into the MCP tool/prompt schemas automatically.

See [CLAUDE.md](CLAUDE.md) for architectural detail and [Examples/reference-server](Examples/reference-server) for a working example.

## Installation

Clone the repo and import the module:

```powershell
Import-Module ./MCP.SDK/MCP.SDK.psd1 -Force
```

Requires PowerShell 7.1+.

## Running a server

The SDK ships with `Start-McpServer` and a convenience launcher at [MCP.SDK/Start.ps1](MCP.SDK/Start.ps1).

### Stdio (default)

Stdio is the transport used when an MCP client launches the server as a child process:

```powershell
./MCP.SDK/Start.ps1 ./Examples/reference-server
```

### Streamable HTTP

Pass `-HttpPort` to run as an HTTP listener at `http://localhost:<port>/mcp/` using the MCP Streamable HTTP transport:

```powershell
./MCP.SDK/Start.ps1 ./Examples/reference-server -HttpPort 8080
```

## `mcp.json` examples

The following examples wire the bundled [Examples/reference-server](Examples/reference-server) into an MCP client. Adjust the absolute paths to match where you cloned the repo.

### Stdio client config

The client launches `pwsh` and speaks JSON-RPC over stdin/stdout:

```json
{
  "mcpServers": {
    "reference-server": {
      "command": "pwsh",
      "args": [
        "-NoProfile",
        "-File",
        "<path-to-repo>/MCP.SDK/Start.ps1",
        "<path-to-repo>/Examples/reference-server"
      ]
    }
  }
}
```

### Streamable HTTP client config

Start the server yourself in a terminal:

```powershell
./MCP.SDK/Start.ps1 ./Examples/reference-server -HttpPort 8080
```

Then point the client at the running endpoint:

```json
{
  "mcpServers": {
    "reference-server": {
      "type": "http",
      "url": "http://localhost:8080/mcp/"
    }
  }
}
```

## Building your own server

1. Create a folder with `tools/`, `prompts/`, and/or `resources/` subdirectories.
2. Write PowerShell scripts with proper comment-based help and typed parameters — the SDK turns these into MCP schemas.
3. Launch with `Start-McpServer -Path ./your-server` (or `-HttpPort` for HTTP).

See [Examples/reference-server](Examples/reference-server) for a complete incident-management server demonstrating tools, prompts, and dynamic/static resources.

## Testing

```powershell
./Run-Tests.ps1
```

See [TESTING.md](TESTING.md) for detail.
