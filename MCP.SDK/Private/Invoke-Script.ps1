function Invoke-Script {
    param (
        [string]$Path,
        [hashtable]$Parameters = @{}
    )

    if (-not (Test-Path -Path $Path)) {
        throw "Script file not found: $Path"
    }

    $ErrorActionPreference = 'Stop'
    & $Path @Parameters
}