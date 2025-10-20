Push-Location $PSScriptRoot
$ProgressPreference = 'SilentlyContinue'
Invoke-Pester
Pop-Location