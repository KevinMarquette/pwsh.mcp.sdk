<#
.SYNOPSIS
    Starts the MCP server.
#>
[cmdletbinding()]
param(
    # The root directory of the MCP server
    [Parameter(Position=0)]
    [string]$Path,

    # Run as a Streamable HTTP listener on this port instead of stdio
    [int]$HttpPort
)
Import-Module $PSScriptRoot/MCP.SDK.psd1 -Force

if ($PSBoundParameters.ContainsKey('HttpPort')) {
    Start-McpServer -Path $Path -HttpPort $HttpPort
}
else {
    Start-McpServer -Path $Path -Wait
}
