function Get-Initialization {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$MCPRoot,
        [string]$ProtocolVersion = "2025-06-18",
        $Name = "LocalMCPServer",
        $Title = "Locally Managed MCP Server"
    )
    $response = [ordered]@{
        protocolVersion = $ProtocolVersion
        capabilities    = @{}
        serverInfo      = @{
            name    = $Name
            title   = $Title
            version = "1.0.0"
        }
    }
    if (Get-ChildItem "$MCPRoot/tools" -File -Filter '*.ps1' -ErrorAction SilentlyContinue) {
        $response.capabilities.tools = @{}
    }
    if (Get-ChildItem "$MCPRoot/prompts" -File -Filter '*.ps1' -ErrorAction SilentlyContinue) {
        $response.capabilities.prompts = @{}
    }
    if (Get-ChildItem "$MCPRoot/resources" -File -ErrorAction SilentlyContinue -Recurse) {
        $response.capabilities.resources = @{}
    }
    if (Test-Path "$MCPRoot/instructions.md") {
        $response.instructions = Get-Content "$MCPRoot/instructions.md" -Raw
    }
    return $response
}