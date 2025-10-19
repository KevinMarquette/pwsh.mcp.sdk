function Invoke-JsonRpcRequest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$RequestJson,

        [Parameter(Mandatory)]
        [string]$MCPRoot
    )
    process{

        # ConvertFrom-Json -Depth is only available in PowerShell 6+
        # PowerShell 5.1 uses default depth of 2 which may not be sufficient
        if ($PSVersionTable.PSVersion.Major -ge 6) {
            $request = $RequestJson | ConvertFrom-Json -Depth 10
        } else {
            $request = $RequestJson | ConvertFrom-Json
        }
        # Handle MCP requests based on the "method" field
        $result = @()
        try{
            $result += switch ($request.method) {
                "initialize" {
                    Get-Initialization -MCPRoot $MCPRoot
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
                "resources/list" {
                    Get-ResourceList -MCPRoot $MCPRoot
                }
                default {
                    throw [System.NotImplementedException]::new("Method '$($request.method)' is not implemented.")
                }
            }
        } catch {
            # Capture any errors that occur during processing
            $result += $_
        }
        # Output the result as a JSON-RPC response
        $result | ConvertTo-JsonRpcResponse -ID $request.id
    }
}