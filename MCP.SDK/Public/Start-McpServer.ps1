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

function Start-McpServer {
    <#
    .SYNOPSIS
    Starts the MCP server.

    .DESCRIPTION
    This function starts the MCP server which listens for JSON-RPC requests and processes them.

    .NOTES
    Json-RPC messages are transmitted via standard input and output streams.
    Do not output any other information to these streams while the server is running.
    #>
    [CmdletBinding()]
    param(
        # The root directory of the MCP server
        [Parameter(Mandatory)]
        [string]$Path,
        # Forces the server to run until terminated
        [switch]$Wait
    )

    # Resolve the absolute path
    $mcpRoot = Resolve-Path -Path $Path
    $logPath = Join-Path -Path $mcpRoot -ChildPath "mcp-server.log"
    Add-Content -Path $logPath -Value "Starting MCP server at path $mcpRoot"

    try {
    while($Wait){
            # Read input from standard input
            $inputJson = Get-Console
            Add-Content -Path $logPath -Value "Received request|$inputJson"
            if ($null -ne $inputJson) {
                # Process the JSON-RPC request
                $responseJson = Invoke-JsonRpcRequest -RequestJson $inputJson -MCPRoot $mcpRoot

                if( $null -eq $responseJson ) {
                    continue
                }
                # Write the response to standard output
                Add-Content -Path $logPath -Value "Sending response|$responseJson"
                Out-Console -OutputString $responseJson
            }
        }
    }
    catch {
        Write-Warning "Error processing request: $_"
        Get-Error | Out-String | Add-Content -Path $logPath
        throw
    }
    finally {
        Add-Content -Path $logPath -Value "MCP server stopped."
    }
}