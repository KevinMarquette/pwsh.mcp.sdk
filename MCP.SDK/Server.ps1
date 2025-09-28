function Convert-ToJsonRpcResponse {
    param(
        $id,
        [parameter(ValueFromPipeline)]
        $result
    )
    process {
        [ordered]@{
            jsonrpc = "2.0"
            id      = $id
            result  = $result
        } | ConvertTo-Json -Depth 10 -Compress
    }
}

function ConvertTo-ToolResponse {
    param($InputObject)
    @{
        content           = @(@{
                type = 'text'
                text = $InputObject | ConvertTo-Json -Depth 10 -Compress
            })
        structuredContent = $InputObject
    }
}

function Invoke-Request {
    param(
        $jsonrpc
    )
    switch ($jsonrpc.method) {
        "ping" {
            @{}
        }
        "initialize" {
            Get-Initialize
        }
        "tools/list" {
            Get-Tools
        }
        "tools/call" {
            ConvertTo-ToolResponse $(switch ($jsonrpc.params.name) {
                    "get_weather" {
                        Get-Weather -Location $jsonrpc.params.arguments.location
                    }
                    "Resolve-DnsName" {
                 
                        Resolve-DnsName -Name $jsonrpc.params.arguments.Name
                 
                    }
                    default {
                        throw "Unknown tool: $($jsonrpc.params.tool)"
                    }
                })
        }
        default {
            throw "Unknown method: $($jsonrpc.method)"
        }
    }
}

function Get-Weather {
    param(
        [string]$Location
    )
    # Simulate getting weather information
    @{
        location    = $Location
        temperature = "72°F"
        condition   = "Sunny"
    }
}

function get-initialize {
    @{
        protocolVersion = "2024-11-05"
        capabilities    = @{
            tools = @{}
        }
        serverInfo      = @{
            name    = "PowerShell"
            title   = "Example PowerShell Server"
            version = "1.0.0"
        }
        #instructions = "Optional instructions for the client"
    }
}
function get-tools {
    @{
        tools = @(
            @{
                name        = "get_weather"
                title       = "Weather Information Provider"
                description = "Get current weather information for a location"
                inputSchema = @{
                    type       = "object"
                    properties = @{
                        location = @{
                            type        = "string"
                            description = "City name or zip code to get the weather for."
                        }                     
                    }
                    required   = @("location")
                }
            },
            (Get-ToolSignature Resolve-DnsName)
        )
    }
}




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
            $output | Write-Host         
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
            $jsonrpc | ConvertTo-Json -Depth 10 -Compress | Write-Host
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