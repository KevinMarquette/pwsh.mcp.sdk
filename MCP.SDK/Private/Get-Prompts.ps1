function Get-Prompts {
    <#
    .SYNOPSIS
        Retrieves a list of available prompts with their signatures.
    #>
    [CmdletBinding()]
    param($MCPRoot)

    $prompts = Get-ChildItem -Path "$MCPRoot/prompts" -Filter '*.ps1' | Get-PromptSignature
    return @{prompts=$prompts}
}