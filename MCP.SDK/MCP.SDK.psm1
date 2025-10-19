#Requires -Version 5.1

<#
.SYNOPSIS
PowerShell MCP Server SDK

.DESCRIPTION
This module provides a complete SDK for creating Model Context Protocol (MCP) servers
using PowerShell. It enables PowerShell scripts to be exposed as MCP resources, tools,
and prompts through simple folder organization.
#>

# Import all classes first
$classPath = Join-Path $PSScriptRoot 'Classes'
if (Test-Path $classPath -ErrorAction SilentlyContinue) {
    Get-ChildItem -Path $classPath -Filter '*.ps1' -Recurse | ForEach-Object {
        Write-Verbose "Loading class: $($_.Name)"
        . $_.FullName
    }
}

# Import all private functions
$privatePath = Join-Path $PSScriptRoot 'Private'
if (Test-Path $privatePath -ErrorAction SilentlyContinue) {
    $PrivateFunctions = Get-ChildItem -Path $privatePath -Filter '*.ps1' -Recurse
    $PrivateFunctions | ForEach-Object {
        Write-Verbose "Loading private function: $($_.Name)"
        . $_.FullName
    }
    # Export private functions (for development/testing purposes)
    Export-ModuleMember -Function $PrivateFunctions.BaseName
}

# Import all public functions
$publicPath = Join-Path $PSScriptRoot 'Public'
if (Test-Path $publicPath -ErrorAction SilentlyContinue) {
    $PublicFunctions = Get-ChildItem -Path $publicPath -Filter '*.ps1' -Recurse
    $PublicFunctions | ForEach-Object {
        Write-Verbose "Loading public function: $($_.Name)"
        . $_.FullName
    }
    # Export public functions (these should match the manifest)
    Export-ModuleMember -Function $PublicFunctions.BaseName
}


# Module cleanup when removed
$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
    Write-Verbose "Cleaning up MCP.SDK module"
    # Add any necessary cleanup code here

    Write-Verbose "MCP.SDK module cleanup completed"
}

Write-Verbose "MCP.SDK module loaded successfully"
