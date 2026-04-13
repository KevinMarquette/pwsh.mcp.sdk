function Start-McpServer {
    <#
    .SYNOPSIS
    Starts the MCP server.

    .DESCRIPTION
    Starts the MCP server which listens for JSON-RPC requests and processes them.

    By default the server uses the stdio transport, reading requests from
    standard input and writing responses to standard output. This is the
    transport used when the server is launched as a child process by an MCP
    client.

    When -HttpPort is specified the server listens for HTTP requests on the
    given port instead, using the MCP Streamable HTTP transport. The endpoint
    is exposed at http://localhost:<port>/mcp/.

    .PARAMETER Path
    The root directory of the MCP server.

    .PARAMETER Wait
    In stdio mode, keeps the server running until the process is terminated.

    .PARAMETER HttpPort
    When supplied, runs the server as a Streamable HTTP listener on the given
    port instead of using stdio.

    .NOTES
    In stdio mode, JSON-RPC messages are transmitted via standard input and
    output streams. Do not output any other information to these streams
    while the server is running.
    #>
    [CmdletBinding(DefaultParameterSetName = 'Stdio')]
    param(
        # The root directory of the MCP server
        [Parameter(Mandatory)]
        [string]$Path,

        # Forces the server to run until terminated (stdio mode only)
        [Parameter(ParameterSetName = 'Stdio')]
        [switch]$Wait,

        # Run as a Streamable HTTP listener on this port instead of stdio
        [Parameter(Mandatory, ParameterSetName = 'Http')]
        [int]$HttpPort
    )

    $PSStyle.OutputRendering = 'PlainText'
    $ErrorActionPreference = 'Stop'
    $WarningPreference = 'Stop'

    # Resolve the absolute path
    $mcpRoot = Resolve-Path -Path $Path
    $logPath = Join-Path -Path $mcpRoot -ChildPath "mcp-server.log"
    Add-Content -Path $logPath -Value "Starting MCP server at path $mcpRoot"

    try {
        if ($PSCmdlet.ParameterSetName -eq 'Http') {
            Start-McpHttpListener -MCPRoot $mcpRoot -LogPath $logPath -Port $HttpPort
        }
        else {
            Start-McpStdioListener -MCPRoot $mcpRoot -LogPath $logPath -Wait:$Wait
        }
    }
    catch {
        Add-Content -Path $logPath -Value "Error processing request: $_"
        Get-Error | Out-String | Add-Content -Path $logPath
        throw
    }
    finally {
        Add-Content -Path $logPath -Value "MCP server stopped."
    }
}
