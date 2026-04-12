BeforeAll {
    # Import the module
    $ModuleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $ModulePath = Join-Path $ModuleRoot 'MCP.SDK\MCP.SDK.psd1'
    Import-Module $ModulePath -Force

    # Set up a test MCP server root with at least one tool so initialize/list work
    $script:TestMCPRoot = Join-Path $TestDrive 'test-mcp-server'
    New-Item -Path $script:TestMCPRoot -ItemType Directory -Force | Out-Null
    New-Item -Path "$script:TestMCPRoot/tools" -ItemType Directory -Force | Out-Null
    New-Item -Path "$script:TestMCPRoot/prompts" -ItemType Directory -Force | Out-Null
    New-Item -Path "$script:TestMCPRoot/resources" -ItemType Directory -Force | Out-Null

    $echoTool = @'
<#
.SYNOPSIS
Echoes a message back.
#>
[CmdletBinding()]
param(
    # Message to echo
    [Parameter(Mandatory)]
    [string]$Message
)
@{ echoed = $Message }
'@
    Set-Content -Path "$script:TestMCPRoot/tools/Echo.ps1" -Value $echoTool
}

Describe 'Start-McpServer' -Tag 'Unit' {

    Context 'Startup behavior without -Wait' {

        It 'should create a log file at the MCP root and write start/stop markers' {
            InModuleScope MCP.SDK -Parameters @{ MCPRoot = $script:TestMCPRoot } {
                param($MCPRoot)

                $logPath = Join-Path $MCPRoot 'mcp-server.log'
                if (Test-Path $logPath) { Remove-Item $logPath -Force }

                Start-McpServer -Path $MCPRoot

                Test-Path $logPath | Should -Be $true
                $log = Get-Content $logPath -Raw
                $log | Should -Match 'Starting MCP server'
                $log | Should -Match 'MCP server stopped'
            }
        }

        It 'should return immediately when -Wait is not supplied' {
            InModuleScope MCP.SDK -Parameters @{ MCPRoot = $script:TestMCPRoot } {
                param($MCPRoot)

                # Get-Console must NOT be called when -Wait is absent; mock it to fail loudly.
                Mock Get-Console { throw 'Get-Console should not be invoked without -Wait' }

                Start-McpServer -Path $MCPRoot
                Should -Invoke Get-Console -Times 0 -Exactly
            }
        }
    }

    Context 'Request/response loop with -Wait' {

        It 'should process a ping request and write the response via Out-Console' {
            InModuleScope MCP.SDK -Parameters @{ MCPRoot = $script:TestMCPRoot } {
                param($MCPRoot)

                $pingRequest = '{"jsonrpc":"2.0","id":7,"method":"ping"}'
                $script:callCount = 0
                Mock Get-Console {
                    $script:callCount++
                    if ($script:callCount -eq 1) { return $pingRequest }
                    # Second iteration: break out of the loop by throwing a sentinel.
                    throw 'TEST_LOOP_EXIT'
                }
                Mock Out-Console {}

                try { Start-McpServer -Path $MCPRoot -Wait }
                catch { $null = $_ } # sentinel throw from Get-Console mock breaks the loop

                Should -Invoke Out-Console -Times 1 -Exactly
                Should -Invoke Out-Console -ParameterFilter {
                    $OutputString -match '"id":7' -and $OutputString -match '"jsonrpc":"2.0"'
                }
            }
        }

        It 'should skip writing output when the handler returns null (notifications)' {
            InModuleScope MCP.SDK -Parameters @{ MCPRoot = $script:TestMCPRoot } {
                param($MCPRoot)

                # A notification method (no id, "notifications/*") produces a null response
                # in Invoke-JsonRpcRequest and must not be echoed back to the client.
                $notification = '{"jsonrpc":"2.0","method":"notifications/initialized"}'
                $script:callCount = 0
                Mock Get-Console {
                    $script:callCount++
                    if ($script:callCount -eq 1) { return $notification }
                    throw 'TEST_LOOP_EXIT'
                }
                Mock Out-Console {}

                try { Start-McpServer -Path $MCPRoot -Wait }
                catch { $null = $_ } # sentinel throw from Get-Console mock breaks the loop

                Should -Invoke Out-Console -Times 0 -Exactly
            }
        }

        It 'should log requests and responses to the log file' {
            InModuleScope MCP.SDK -Parameters @{ MCPRoot = $script:TestMCPRoot } {
                param($MCPRoot)

                $logPath = Join-Path $MCPRoot 'mcp-server.log'
                if (Test-Path $logPath) { Remove-Item $logPath -Force }

                $pingRequest = '{"jsonrpc":"2.0","id":9,"method":"ping"}'
                $script:callCount = 0
                Mock Get-Console {
                    $script:callCount++
                    if ($script:callCount -eq 1) { return $pingRequest }
                    throw 'TEST_LOOP_EXIT'
                }
                Mock Out-Console {}

                try { Start-McpServer -Path $MCPRoot -Wait }
                catch { $null = $_ } # sentinel throw from Get-Console mock breaks the loop

                $log = Get-Content $logPath -Raw
                $log | Should -Match 'Received request\|.*"id":9'
                $log | Should -Match 'Sending response\|.*"id":9'
            }
        }
    }

    Context 'Parameter validation' {

        It 'should declare Path as a mandatory parameter' {
            $cmd = Get-Command Start-McpServer
            $pathParam = $cmd.Parameters['Path']
            $pathParam | Should -Not -BeNullOrEmpty
            $mandatory = $pathParam.Attributes |
                Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] } |
                ForEach-Object { $_.Mandatory }
            $mandatory | Should -Contain $true
        }

        It 'should declare Wait as a switch parameter' {
            $cmd = Get-Command Start-McpServer
            $cmd.Parameters['Wait'].ParameterType | Should -Be ([switch])
        }
    }
}
