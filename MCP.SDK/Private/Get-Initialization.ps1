function Get-Initialization {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $MCPRoot,
        $Name = "LocalMCPServer",
        $Title = "Locally Managed MCP Server"
    )
    $response = [ordered]@{
        protocolVersion = "2024-11-05"
        capabilities = @{}
        serverInfo = @{
            name = "PowerShell"
            title = "Example PowerShell Server"
            version = "1.0.0"
        }
    }
    if(Get-ChildItem "$MCPRoot/tools" -File -Filter '*.ps1' -ErrorAction SilentlyContinue) {
        $response.capabilities.tools = @{}
    }
    if(Get-ChildItem "$MCPRoot/prompts" -File -Filter '*.ps1' -ErrorAction SilentlyContinue) {
        $response.capabilities.prompts = @{}
    }
    if(Get-ChildItem "$MCPRoot/resources" -File -ErrorAction SilentlyContinue -Recurse) {
        $response.capabilities.resources = @{}
    }
    if(Test-Path "$MCPRoot/instructions.md") {
        $response.instructions = Get-Content "$MCPRoot/instructions.md" -Raw
    }
    return $response
}