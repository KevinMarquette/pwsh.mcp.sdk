function Start-McpHttpListener {
    <#
    .SYNOPSIS
    Runs the MCP server using the Streamable HTTP transport.

    .DESCRIPTION
    Opens an HttpListener on the supplied port and serves the MCP endpoint
    at /mcp/. Client-to-server JSON-RPC requests arrive as HTTP POST with a
    JSON body and the response is returned as application/json on the same
    POST, in accordance with the MCP Streamable HTTP transport spec.

    Notifications (requests without an id) receive HTTP 202 Accepted with
    an empty body. GET and DELETE are responded to with 405 Method Not Allowed
    because this implementation does not push server-initiated messages or
    track sessions.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$MCPRoot,

        [Parameter(Mandatory)]
        [string]$LogPath,

        [Parameter(Mandatory)]
        [int]$Port
    )

    $listener = [System.Net.HttpListener]::new()
    $prefix = "http://localhost:$Port/mcp/"
    $listener.Prefixes.Add($prefix)
    $listener.Start()
    Add-Content -Path $LogPath -Value "HTTP listener started on $prefix"

    try {
        while ($listener.IsListening) {
            $context = $listener.GetContext()
            $request = $context.Request
            $response = $context.Response

            try {
                switch ($request.HttpMethod) {
                    'POST' {
                        $reader = [System.IO.StreamReader]::new($request.InputStream, $request.ContentEncoding)
                        try {
                            $body = $reader.ReadToEnd()
                        }
                        finally {
                            $reader.Dispose()
                        }
                        Add-Content -Path $LogPath -Value "Received request|$body"

                        $rpcResponse = Invoke-JsonRpcRequest -RequestJson $body -MCPRoot $MCPRoot

                        if ($null -eq $rpcResponse) {
                            # Notification — acknowledge with 202 per Streamable HTTP spec
                            $response.StatusCode = 202
                            $response.ContentLength64 = 0
                        }
                        else {
                            $responseJson = $rpcResponse | ConvertTo-Json -Depth 10 -Compress
                            Add-Content -Path $LogPath -Value "Sending response|$responseJson"
                            $buffer = [System.Text.Encoding]::UTF8.GetBytes($responseJson)
                            $response.StatusCode = 200
                            $response.ContentType = 'application/json'
                            $response.ContentLength64 = $buffer.Length
                            $response.OutputStream.Write($buffer, 0, $buffer.Length)
                        }
                    }
                    'GET' {
                        # Server-initiated SSE streams are not supported by this server.
                        $response.StatusCode = 405
                        $response.AddHeader('Allow', 'POST')
                    }
                    'DELETE' {
                        # No session state to terminate.
                        $response.StatusCode = 405
                        $response.AddHeader('Allow', 'POST')
                    }
                    'OPTIONS' {
                        $response.StatusCode = 204
                        $response.AddHeader('Access-Control-Allow-Methods', 'POST, OPTIONS')
                        $response.AddHeader('Access-Control-Allow-Headers', 'Content-Type, Mcp-Session-Id')
                    }
                    default {
                        $response.StatusCode = 405
                    }
                }
            }
            catch {
                Add-Content -Path $LogPath -Value "Error handling HTTP request|$_"
                $response.StatusCode = 500
            }
            finally {
                $response.Close()
            }
        }
    }
    finally {
        if ($listener.IsListening) {
            $listener.Stop()
        }
        $listener.Close()
        Add-Content -Path $LogPath -Value "HTTP listener stopped on $prefix"
    }
}
