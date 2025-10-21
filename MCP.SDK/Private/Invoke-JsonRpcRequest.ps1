function Invoke-JsonRpcRequest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$RequestJson,

        [Parameter(Mandatory)]
        [string]$MCPRoot
    )
    process {

        # ConvertFrom-Json -AsHashtable is only available in PowerShell 7+
        if ($PSVersionTable.PSVersion.Major -ge 7) {
            $request = $RequestJson | ConvertFrom-Json -Depth 10 -AsHashtable
        }
        else {
            throw "Requires PowerShell 7 or higher."
        }
        # Handle MCP requests based on the "method" field
        $result = @()
        try {
            $result += switch ($request.method) {
                "initialize" {
                    Get-Initialization -MCPRoot $MCPRoot -ProtocolVersion $request.params.protocolVersion
                }
                "ping" {
                    @{}
                }
                "tools/list" {
                    Get-ToolList -MCPRoot $MCPRoot
                }
                "prompts/list" {
                    Get-PromptList -MCPRoot $MCPRoot
                }
                "resources/templates/list" {
                    @{resourceTemplates=@()}
                }
                "resources/list" {
                    Get-ResourceList -MCPRoot $MCPRoot
                }
                "resources/read" {
                    Get-Resource -MCPRoot $MCPRoot -Uri $request.params.uri
                }
                "tools/call" {
                    Invoke-Tool -MCPRoot $MCPRoot -Name $request.params.name -Parameters $request.params.arguments
                }
                default {
                    if($PSItem -match 'notifications') {
                        # Ignore notification messages
                        return
                    }
                    throw [System.NotImplementedException]::new("Method '$($request.method)' is not implemented.")
                }
            }
        }
        catch {
            # Capture any errors that occur during processing
            $result += $_
        }
        # Output the result as a JSON-RPC response
        $result | ConvertTo-JsonRpcResponse -ID $request.id |
            ConvertTo-Json -Depth 10 -Compress
    }
}