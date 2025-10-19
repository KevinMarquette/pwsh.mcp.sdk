function Invoke-JsonRpcRequest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$RequestJson,

        [Parameter(Mandatory)]
        [string]$MCPRoot
    )
    process{

        $request = $RequestJson | ConvertFrom-Json -Depth 10
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
            }
        } catch {
            # Capture any errors that occur during processing
            $result += $_
        }
        # Output the result as a JSON-RPC response
        $result | ConvertTo-JsonRpcResponse -ID $request.id
    }
}