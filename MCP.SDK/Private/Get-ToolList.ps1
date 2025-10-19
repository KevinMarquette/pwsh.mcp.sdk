function Get-ToolList {
    <#
    .SYNOPSIS
        Retrieves a list of available tools with their signatures.
    #>
    [CmdletBinding()]
    param($MCPRoot)

    $tools = Get-ChildItem -Path "$MCPRoot/tools" -Filter '*.ps1' | Get-ToolSignature
    return @{tools=@($tools)}
}