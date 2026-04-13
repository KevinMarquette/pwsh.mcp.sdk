function Get-Console {
    # Helper function for easy mocking in tests
    return [Console]::In.ReadLine()
}

function Out-Console {
    # Helper function for easy mocking in tests
    param(
        [string]$OutputString
    )
    [Console]::Out.WriteLine($OutputString)
}

function Start-McpStdioListener {
    <#
    .SYNOPSIS
    Runs the MCP server loop using stdio transport.

    .DESCRIPTION
    Reads JSON-RPC requests from standard input, dispatches them to
    Invoke-JsonRpcRequest, and writes JSON-RPC responses to standard output.
    Intended to be called from Start-McpServer.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$MCPRoot,

        [Parameter(Mandatory)]
        [string]$LogPath,

        [switch]$Wait
    )

    while ($Wait) {
        # Read input from standard input
        $inputJson = Get-Console
        Add-Content -Path $LogPath -Value "Received request|$inputJson"
        if ($null -ne $inputJson) {
            # Process the JSON-RPC request
            $response = Invoke-JsonRpcRequest -RequestJson $inputJson -MCPRoot $MCPRoot

            if ($null -eq $response) {
                continue
            }
            # Serialize the response to JSON and write it to standard output
            $responseJson = $response | ConvertTo-Json -Depth 10 -Compress
            Add-Content -Path $LogPath -Value "Sending response|$responseJson"
            Out-Console -OutputString $responseJson
        }
    }
}
