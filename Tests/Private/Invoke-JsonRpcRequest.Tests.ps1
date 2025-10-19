BeforeAll {
    # Import the module
    $ModuleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $ModulePath = Join-Path $ModuleRoot 'MCP.SDK\MCP.SDK.psd1'
    Import-Module $ModulePath -Force

    # Set up a test MCP server root
    $script:TestMCPRoot = Join-Path $TestDrive 'test-mcp-server'
    New-Item -Path $script:TestMCPRoot -ItemType Directory -Force | Out-Null
    New-Item -Path "$script:TestMCPRoot/tools" -ItemType Directory -Force | Out-Null
    New-Item -Path "$script:TestMCPRoot/prompts" -ItemType Directory -Force | Out-Null
    New-Item -Path "$script:TestMCPRoot/resources" -ItemType Directory -Force | Out-Null
}

Describe 'Invoke-JsonRpcRequest' -Tag 'Unit' {

    Context 'Request Parsing' {

        It 'should parse valid JSON-RPC request' {
            InModuleScope MCP.SDK -Parameters @{ MCPRoot = $script:TestMCPRoot } {
                param($MCPRoot)
                # Arrange
                $requestJson = @{
                    jsonrpc = "2.0"
                    id      = 1
                    method  = "ping"
                } | ConvertTo-Json

                # Act
                $result = Invoke-JsonRpcRequest -RequestJson $requestJson -MCPRoot $MCPRoot

                # Assert
                $result | Should -Not -BeNullOrEmpty
                $result.jsonrpc | Should -Be "2.0"
            }
        }

        It 'should handle complex nested JSON' {
            InModuleScope MCP.SDK -Parameters @{ MCPRoot = $script:TestMCPRoot } {
                param($MCPRoot)
                # Arrange
                $requestJson = @{
                    jsonrpc = "2.0"
                    id      = 1
                    method  = "ping"
                    params  = @{
                        nested = @{
                            data = "value"
                        }
                    }
                } | ConvertTo-Json -Depth 10

                # Act
                $result = Invoke-JsonRpcRequest -RequestJson $requestJson -MCPRoot $MCPRoot

                # Assert
                $result.jsonrpc | Should -Be "2.0"
            }
        }

        It 'should preserve request ID in response' {
            InModuleScope MCP.SDK -Parameters @{ MCPRoot = $script:TestMCPRoot } {
                param($MCPRoot)
                # Arrange
                $requestJson = @{
                    jsonrpc = "2.0"
                    id      = 42
                    method  = "ping"
                } | ConvertTo-Json

                # Act
                $result = Invoke-JsonRpcRequest -RequestJson $requestJson -MCPRoot $MCPRoot

                # Assert
                $result.id | Should -Be 42
            }
        }

        It 'should handle string IDs' {
            InModuleScope MCP.SDK -Parameters @{ MCPRoot = $script:TestMCPRoot } {
                param($MCPRoot)
                # Arrange
                $requestJson = @{
                    jsonrpc = "2.0"
                    id      = "request-123"
                    method  = "ping"
                } | ConvertTo-Json

                # Act
                $result = Invoke-JsonRpcRequest -RequestJson $requestJson -MCPRoot $MCPRoot

                # Assert
                $result.id | Should -Be "request-123"
            }
        }
    }

    Context 'Method Routing - initialize' {

        It 'should handle initialize method' {
            InModuleScope MCP.SDK -Parameters @{ MCPRoot = $script:TestMCPRoot } {
                param($MCPRoot)
                # Arrange
                $requestJson = @{
                    jsonrpc = "2.0"
                    id      = 1
                    method  = "initialize"
                } | ConvertTo-Json

                # Act
                $result = Invoke-JsonRpcRequest -RequestJson $requestJson -MCPRoot $MCPRoot

                # Assert
                $result.result | Should -Not -BeNullOrEmpty
                $result.result.protocolVersion | Should -Be "2024-11-05"
                $result.result.serverInfo | Should -Not -BeNullOrEmpty
            }
        }

        It 'should return capabilities in initialize response' {
            InModuleScope MCP.SDK -Parameters @{ MCPRoot = $script:TestMCPRoot } {
                param($MCPRoot)
                # Arrange
                $requestJson = @{
                    jsonrpc = "2.0"
                    id      = 1
                    method  = "initialize"
                } | ConvertTo-Json

                # Act
                $result = Invoke-JsonRpcRequest -RequestJson $requestJson -MCPRoot $MCPRoot

                # Assert
                $result.result.Keys | Should -Contain 'capabilities'
            }
        }
    }

    Context 'Method Routing - ping' {

        It 'should handle ping method' {
            InModuleScope MCP.SDK -Parameters @{ MCPRoot = $script:TestMCPRoot } {
                param($MCPRoot)
                # Arrange
                $requestJson = @{
                    jsonrpc = "2.0"
                    id      = 1
                    method  = "ping"
                } | ConvertTo-Json

                # Act
                $result = Invoke-JsonRpcRequest -RequestJson $requestJson -MCPRoot $MCPRoot

                # Assert
                $result.Keys | Should -Contain 'result'
                $result.result | Should -BeOfType [hashtable]
            }
        }

        It 'should return empty object for ping' {
            InModuleScope MCP.SDK -Parameters @{ MCPRoot = $script:TestMCPRoot } {
                param($MCPRoot)
                # Arrange
                $requestJson = @{
                    jsonrpc = "2.0"
                    id      = 1
                    method  = "ping"
                } | ConvertTo-Json

                # Act
                $result = Invoke-JsonRpcRequest -RequestJson $requestJson -MCPRoot $MCPRoot

                # Assert
                $result.result.Keys.Count | Should -Be 0
            }
        }
    }

    Context 'Method Routing - tools/list' {

        It 'should handle tools/list method' {
            InModuleScope MCP.SDK -Parameters @{ MCPRoot = $script:TestMCPRoot } {
                param($MCPRoot)
                # Arrange
                $requestJson = @{
                    jsonrpc = "2.0"
                    id      = 1
                    method  = "tools/list"
                } | ConvertTo-Json

                # Act
                $result = Invoke-JsonRpcRequest -RequestJson $requestJson -MCPRoot $MCPRoot

                # Assert
                $result.result | Should -Not -BeNullOrEmpty
                $result.result.Keys | Should -Contain 'tools'
            }
        }

        It 'should return tools array' {
            InModuleScope MCP.SDK -Parameters @{ MCPRoot = $script:TestMCPRoot } {
                param($MCPRoot)
                # Arrange
                $requestJson = @{
                    jsonrpc = "2.0"
                    id      = 1
                    method  = "tools/list"
                } | ConvertTo-Json

                # Act
                $result = Invoke-JsonRpcRequest -RequestJson $requestJson -MCPRoot $MCPRoot

                # Assert
                $result.result.tools.GetType().Name | Should -Match 'Object\[\]|Array'
            }
        }
    }

    Context 'Method Routing - prompts/list' {

        It 'should handle prompts/list method' {
            InModuleScope MCP.SDK -Parameters @{ MCPRoot = $script:TestMCPRoot } {
                param($MCPRoot)
                # Arrange
                $requestJson = @{
                    jsonrpc = "2.0"
                    id      = 1
                    method  = "prompts/list"
                } | ConvertTo-Json

                # Act
                $result = Invoke-JsonRpcRequest -RequestJson $requestJson -MCPRoot $MCPRoot

                # Assert
                $result.result | Should -Not -BeNullOrEmpty
                $result.result.Keys | Should -Contain 'prompts'
            }
        }

        It 'should return prompts array' {
            InModuleScope MCP.SDK -Parameters @{ MCPRoot = $script:TestMCPRoot } {
                param($MCPRoot)
                # Arrange
                $requestJson = @{
                    jsonrpc = "2.0"
                    id      = 1
                    method  = "prompts/list"
                } | ConvertTo-Json

                # Act
                $result = Invoke-JsonRpcRequest -RequestJson $requestJson -MCPRoot $MCPRoot

                # Assert
                $result.result.prompts.GetType().Name | Should -Match 'Object\[\]|Array'
            }
        }
    }

    Context 'Method Routing - resources/list' {

        It 'should handle resources/list method' {
            InModuleScope MCP.SDK -Parameters @{ MCPRoot = $script:TestMCPRoot } {
                param($MCPRoot)
                # Arrange
                $requestJson = @{
                    jsonrpc = "2.0"
                    id      = 1
                    method  = "resources/list"
                } | ConvertTo-Json

                # Act
                $result = Invoke-JsonRpcRequest -RequestJson $requestJson -MCPRoot $MCPRoot

                # Assert
                $result.result | Should -Not -BeNullOrEmpty
                $result.result.Keys | Should -Contain 'resources'
            }
        }

        It 'should return resources array' {
            InModuleScope MCP.SDK -Parameters @{ MCPRoot = $script:TestMCPRoot } {
                param($MCPRoot)
                # Arrange
                $requestJson = @{
                    jsonrpc = "2.0"
                    id      = 1
                    method  = "resources/list"
                } | ConvertTo-Json

                # Act
                $result = Invoke-JsonRpcRequest -RequestJson $requestJson -MCPRoot $MCPRoot

                # Assert
                $result.result.resources.GetType().Name | Should -Match 'Object\[\]|Array'
            }
        }
    }

    Context 'Error Handling' {

        It 'should return error for unimplemented method' {
            InModuleScope MCP.SDK -Parameters @{ MCPRoot = $script:TestMCPRoot } {
                param($MCPRoot)
                # Arrange
                $requestJson = @{
                    jsonrpc = "2.0"
                    id      = 1
                    method  = "unknown/method"
                } | ConvertTo-Json

                # Act
                $result = Invoke-JsonRpcRequest -RequestJson $requestJson -MCPRoot $MCPRoot

                # Assert
                $result.Keys | Should -Contain 'error'
                $result.error.code | Should -Be -32603
                $result.error.message | Should -Match "not implemented"
            }
        }

        It 'should not include result property when error occurs' {
            InModuleScope MCP.SDK -Parameters @{ MCPRoot = $script:TestMCPRoot } {
                param($MCPRoot)
                # Arrange
                $requestJson = @{
                    jsonrpc = "2.0"
                    id      = 1
                    method  = "invalid/method"
                } | ConvertTo-Json

                # Act
                $result = Invoke-JsonRpcRequest -RequestJson $requestJson -MCPRoot $MCPRoot

                # Assert
                $result.Keys | Should -Not -Contain 'result'
            }
        }

        It 'should include method name in error message' {
            InModuleScope MCP.SDK -Parameters @{ MCPRoot = $script:TestMCPRoot } {
                param($MCPRoot)
                # Arrange
                $requestJson = @{
                    jsonrpc = "2.0"
                    id      = 1
                    method  = "custom/unknown"
                } | ConvertTo-Json

                # Act
                $result = Invoke-JsonRpcRequest -RequestJson $requestJson -MCPRoot $MCPRoot

                # Assert
                $result.error.message | Should -Match "custom/unknown"
            }
        }

        It 'should handle invalid JSON gracefully' {
            InModuleScope MCP.SDK -Parameters @{ MCPRoot = $script:TestMCPRoot } {
                param($MCPRoot)
                # Arrange
                $invalidJson = "{invalid json"

                # Act & Assert
                { Invoke-JsonRpcRequest -RequestJson $invalidJson -MCPRoot $MCPRoot } | Should -Throw
            }
        }
    }

    Context 'Pipeline Support' {

        It 'should accept input from pipeline' {
            InModuleScope MCP.SDK -Parameters @{ MCPRoot = $script:TestMCPRoot } {
                param($MCPRoot)
                # Arrange
                $requestJson = @{
                    jsonrpc = "2.0"
                    id      = 1
                    method  = "ping"
                } | ConvertTo-Json

                # Act
                $result = $requestJson | Invoke-JsonRpcRequest -MCPRoot $MCPRoot

                # Assert
                $result.jsonrpc | Should -Be "2.0"
            }
        }

        It 'should process multiple requests from pipeline' {
            InModuleScope MCP.SDK -Parameters @{ MCPRoot = $script:TestMCPRoot } {
                param($MCPRoot)
                # Arrange
                $request1 = @{
                    jsonrpc = "2.0"
                    id      = 1
                    method  = "ping"
                } | ConvertTo-Json

                $request2 = @{
                    jsonrpc = "2.0"
                    id      = 2
                    method  = "ping"
                } | ConvertTo-Json

                # Act
                $results = $request1, $request2 | Invoke-JsonRpcRequest -MCPRoot $MCPRoot

                # Assert
                $results.Count | Should -Be 2
                $results[0].id | Should -Be 1
                $results[1].id | Should -Be 2
            }
        }
    }

    Context 'Parameter Validation' {

        It 'should accept valid RequestJson string' {
            InModuleScope MCP.SDK -Parameters @{ MCPRoot = $script:TestMCPRoot } {
                param($MCPRoot)
                # Arrange
                $requestJson = '{"jsonrpc":"2.0","id":1,"method":"ping"}'

                # Act & Assert
                { Invoke-JsonRpcRequest -RequestJson $requestJson -MCPRoot $MCPRoot } | Should -Not -Throw
            }
        }
    }

    Context 'Response Format' {

        It 'should return JSON-RPC 2.0 response' {
            InModuleScope MCP.SDK -Parameters @{ MCPRoot = $script:TestMCPRoot } {
                param($MCPRoot)
                # Arrange
                $requestJson = @{
                    jsonrpc = "2.0"
                    id      = 1
                    method  = "ping"
                } | ConvertTo-Json

                # Act
                $result = Invoke-JsonRpcRequest -RequestJson $requestJson -MCPRoot $MCPRoot

                # Assert
                $result.jsonrpc | Should -Be "2.0"
            }
        }

        It 'should include id in response' {
            InModuleScope MCP.SDK -Parameters @{ MCPRoot = $script:TestMCPRoot } {
                param($MCPRoot)
                # Arrange
                $requestJson = @{
                    jsonrpc = "2.0"
                    id      = 99
                    method  = "ping"
                } | ConvertTo-Json

                # Act
                $result = Invoke-JsonRpcRequest -RequestJson $requestJson -MCPRoot $MCPRoot

                # Assert
                $result.Keys | Should -Contain 'id'
                $result.id | Should -Be 99
            }
        }

        It 'should return ordered hashtable' {
            InModuleScope MCP.SDK -Parameters @{ MCPRoot = $script:TestMCPRoot } {
                param($MCPRoot)
                # Arrange
                $requestJson = @{
                    jsonrpc = "2.0"
                    id      = 1
                    method  = "ping"
                } | ConvertTo-Json

                # Act
                $result = Invoke-JsonRpcRequest -RequestJson $requestJson -MCPRoot $MCPRoot

                # Assert
                $result | Should -BeOfType [System.Collections.Specialized.OrderedDictionary]
            }
        }

        It 'should have either result or error key' {
            InModuleScope MCP.SDK -Parameters @{ MCPRoot = $script:TestMCPRoot } {
                param($MCPRoot)
                # Arrange
                $requestJson = @{
                    jsonrpc = "2.0"
                    id      = 1
                    method  = "ping"
                } | ConvertTo-Json

                # Act
                $result = Invoke-JsonRpcRequest -RequestJson $requestJson -MCPRoot $MCPRoot

                # Assert
                ($result.Keys -contains 'result' -or $result.Keys -contains 'error') | Should -Be $true
            }
        }
    }

    Context 'Integration with Reference Server' {

        It 'should work with reference-server initialize request' {
            InModuleScope MCP.SDK {
                # Arrange
                $refServerPath = Join-Path $PSScriptRoot '..\..\Examples\reference-server'

                if (Test-Path $refServerPath) {
                    $requestJson = @{
                        jsonrpc = "2.0"
                        id      = 1
                        method  = "initialize"
                    } | ConvertTo-Json

                    # Act
                    $result = Invoke-JsonRpcRequest -RequestJson $requestJson -MCPRoot $refServerPath

                    # Assert
                    $result.result.capabilities | Should -Not -BeNullOrEmpty
                    $result.result.capabilities.Keys | Should -Contain 'tools'
                }
            }
        }

        It 'should work with reference-server tools/list request' {
            InModuleScope MCP.SDK {
                # Arrange
                $refServerPath = Join-Path $PSScriptRoot '..\..\Examples\reference-server'

                if (Test-Path $refServerPath) {
                    $requestJson = @{
                        jsonrpc = "2.0"
                        id      = 1
                        method  = "tools/list"
                    } | ConvertTo-Json

                    # Act
                    $result = Invoke-JsonRpcRequest -RequestJson $requestJson -MCPRoot $refServerPath

                    # Assert
                    @($result.result.tools).Count | Should -BeGreaterThan 0
                }
            }
        }
    }
}
