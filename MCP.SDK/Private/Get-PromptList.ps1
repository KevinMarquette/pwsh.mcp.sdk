function Get-PromptList {
    <#
    .SYNOPSIS
        Retrieves a list of available prompts with their signatures.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $MCPRoot
    )

    $prompts = @(Get-ChildItem -Path "$MCPRoot/prompts" -Filter '*.ps1' -ErrorAction SilentlyContinue | Get-PromptSignature)
    return @{prompts=$prompts}
}