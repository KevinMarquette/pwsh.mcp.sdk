



# MCP server
function Start-MCPServer {
    for ("ever") {
        $jsonRequest = Read-Host
        Add-Content $PSScriptRoot\log.log -Value "stdin: $jsonRequest"
        $jsonrpc = $jsonRequest | ConvertFrom-Json -AsHashtable
        try {
            if ($jsonrpc.jsonrpc -ne "2.0") {
                throw "Invalid JSON RPC request"
            }
            $result = Invoke-Request -jsonrpc $jsonrpc
            $output = $result | Convert-ToJsonRpcResponse -id $jsonrpc.id
            $output | Add-Content $PSScriptRoot\log.log
            # $output | Write-Host
        }
        catch {
            [ordered]@{
                jsonrpc = "2.0"
                id      = $id
                error   = @{
                    code    = -1
                    message = "Internal error $($_.Exception.Message)"
                    data    = $jsonrpc
                }
            }
            #$jsonrpc | ConvertTo-Json -Depth 10 -Compress | Write-Host
        }
    }
}

# {"jsonrpc": "2.0",  "id": 1,  "method": "tools/list"}
# {"jsonrpc": "2.0",  "id": 1,  "method": "tools/call"}
# {"jsonrpc": "2.0",  "id": 1,  "method": "tools/call", "params": {    "name": "get_weather",    "arguments": {      "location": "New York"    }  }}
# {"jsonrpc": "2.0",  "id": 1,  "method": "tools/call", "params": {    "name": "Resolve-DnsName",    "arguments": {      "name": "www.google.com"    }  }}
# {"method":"tools/call","params":{"name":"Resolve-DnsName","arguments":{"Name":"www.google.com"}},"jsonrpc":"2.0","id":5}
# {"jsonrpc": "2.0",  "id": 1,  "method": "other"}
Start-MCPServer