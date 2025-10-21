<#
.SYNOPSIS
    Starts the MCP server.
#>
[cmdletbinding()]
param(
    # The root directory of the MCP server
    [Parameter(Position=0)]
    [string]$Path
)
Import-Module $PSScriptRoot/MCP.SDK.psd1 -Force
Start-McpServer -Path $Path -Wait