BeforeAll {
    # Import the module
    $ModuleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $ModulePath = Join-Path $ModuleRoot 'MCP.SDK\MCP.SDK.psd1'
    Import-Module $ModulePath -Force
}

Describe 'ConvertTo-JsonRpcResponse' -Tag 'Unit' {

    Context 'Basic Structure' {

        It 'should include jsonrpc version 2.0' {
            InModuleScope MCP.SDK {
                # Act
                $result = ConvertTo-JsonRpcResponse -InputObject @{result = "test"} -ID 1

                # Assert
                $result.jsonrpc | Should -Be "2.0"
            }
        }

        It 'should include the provided ID' {
            InModuleScope MCP.SDK {
                # Act
                $result = ConvertTo-JsonRpcResponse -InputObject @{result = "test"} -ID 42

                # Assert
                $result.id | Should -Be 42
            }
        }

        It 'should return an ordered hashtable' {
            InModuleScope MCP.SDK {
                # Act
                $result = ConvertTo-JsonRpcResponse -InputObject @{result = "test"} -ID 1

                # Assert
                $result | Should -BeOfType [System.Collections.Specialized.OrderedDictionary]
            }
        }

        It 'should have jsonrpc and id as first keys' {
            InModuleScope MCP.SDK {
                # Act
                $result = ConvertTo-JsonRpcResponse -InputObject @{result = "test"} -ID 1

                # Assert
                $keys = @($result.Keys)
                $keys[0] | Should -Be 'jsonrpc'
                $keys[1] | Should -Be 'id'
            }
        }
    }

    Context 'Result Handling' {

        It 'should use existing result property when present' {
            InModuleScope MCP.SDK {
                # Arrange
                $input = @{result = @{data = "test data"}}

                # Act
                $result = ConvertTo-JsonRpcResponse -InputObject $input -ID 1

                # Assert
                $result.Keys | Should -Contain 'result'
                $result.result.data | Should -Be "test data"
            }
        }

        It 'should wrap <InputType> as result' -TestCases @(
            @{ InputType = 'string'; InputValue = "test string" }
            @{ InputType = 'integer'; InputValue = 42 }
            @{ InputType = 'boolean'; InputValue = $true }
            @{ InputType = 'hashtable'; InputValue = @{key = "value"} }
            @{ InputType = 'array'; InputValue = @(1, 2, 3) }
        ) {
            InModuleScope MCP.SDK -Parameters @{ InputValue = $InputValue } {
                param($InputValue)
                # Act
                $result = ConvertTo-JsonRpcResponse -InputObject $InputValue -ID 1

                # Assert
                $result.Keys | Should -Contain 'result'
                $result.result | Should -Be $InputValue
            }
        }

        It 'should not include error property for normal results' {
            InModuleScope MCP.SDK {
                # Act
                $result = ConvertTo-JsonRpcResponse -InputObject @{result = "test"} -ID 1

                # Assert
                $result.Keys | Should -Not -Contain 'error'
                $result.Keys | Should -Not -Contain 'code'
            }
        }
    }

    Context 'Error Handling with Existing Error Property' {

        It 'should use existing error property when present' {
            InModuleScope MCP.SDK {
                # Arrange
                $input = @{
                    error = @{
                        code = -32600
                        message = "Invalid Request"
                    }
                    code = -32600
                }

                # Act
                $result = ConvertTo-JsonRpcResponse -InputObject $input -ID 1

                # Assert
                $result.Keys | Should -Contain 'error'
                $result.error.code | Should -Be -32600
                $result.error.message | Should -Be "Invalid Request"
            }
        }

        It 'should include code property when error is present' {
            InModuleScope MCP.SDK {
                # Arrange
                $input = @{
                    error = @{code = -32601; message = "Method not found"}
                }

                # Act
                $result = ConvertTo-JsonRpcResponse -InputObject $input -ID 1

                # Assert
                $result.Keys | Should -Contain 'error'
                $result.error.code | Should -Be -32601
            }
        }

        It 'should not include result property when error is present' {
            InModuleScope MCP.SDK {
                # Arrange
                $input = @{
                    error = @{code = -32600; message = "Invalid"}
                    code = -32600
                }

                # Act
                $result = ConvertTo-JsonRpcResponse -InputObject $input -ID 1

                # Assert
                $result.Keys | Should -Not -Contain 'result'
            }
        }
    }

    Context 'ErrorRecord and Exception Handling' {

        It 'should convert ErrorRecord to JSON-RPC error' {
            InModuleScope MCP.SDK {
                # Arrange
                try {
                    Get-Item "NonExistentPath" -ErrorAction Stop
                } catch {
                    $errorRecord = $_
                }

                # Act
                $result = ConvertTo-JsonRpcResponse -InputObject $errorRecord -ID 1

                # Assert
                $result.Keys | Should -Contain 'error'
                $result.error | Should -BeOfType [hashtable]
                $result.error.code | Should -Be -32603
                $result.error.message | Should -Not -BeNullOrEmpty
            }
        }

        It 'should convert Exception to JSON-RPC error' {
            InModuleScope MCP.SDK {
                # Arrange
                $exception = [System.Exception]::new("Test exception message")

                # Act
                $result = ConvertTo-JsonRpcResponse -InputObject $exception -ID 1

                # Assert
                $result.Keys | Should -Contain 'error'
                $result.error.code | Should -Be -32603
                $result.error.message | Should -Be "System.Exception: Test exception message"
            }
        }

        It 'should use error code -32603 for ErrorRecord and Exception' {
            InModuleScope MCP.SDK {
                # Arrange
                $exception = [System.InvalidOperationException]::new("Invalid operation")

                # Act
                $result = ConvertTo-JsonRpcResponse -InputObject $exception -ID 1

                # Assert
                $result.error.code | Should -Be -32603
            }
        }

        It 'should not include result property when handling exceptions' {
            InModuleScope MCP.SDK {
                # Arrange
                $exception = [System.Exception]::new("Error")

                # Act
                $result = ConvertTo-JsonRpcResponse -InputObject $exception -ID 1

                # Assert
                $result.Keys | Should -Not -Contain 'result'
            }
        }
    }

    Context 'Pipeline Support' {

        It 'should accept input from pipeline' {
            InModuleScope MCP.SDK {
                # Act
                $result = @{result = "test"} | ConvertTo-JsonRpcResponse -ID 1

                # Assert
                $result.result | Should -Be "test"
            }
        }

        It 'should process multiple items from pipeline' {
            InModuleScope MCP.SDK {
                # Act
                $results = "item1", "item2", "item3" | ConvertTo-JsonRpcResponse -ID 1

                # Assert
                $results.Count | Should -Be 3
                $results[0].result | Should -Be "item1"
                $results[1].result | Should -Be "item2"
                $results[2].result | Should -Be "item3"
            }
        }

        It 'should maintain same ID across multiple pipeline items' {
            InModuleScope MCP.SDK {
                # Act
                $results = "item1", "item2" | ConvertTo-JsonRpcResponse -ID 99

                # Assert
                $results[0].id | Should -Be 99
                $results[1].id | Should -Be 99
            }
        }
    }

    Context 'ID Parameter Handling' {

        It 'should accept string ID' {
            InModuleScope MCP.SDK {
                # Act
                $result = ConvertTo-JsonRpcResponse -InputObject @{result = "test"} -ID "string-id"

                # Assert
                $result.id | Should -Be "string-id"
            }
        }

        It 'should accept integer ID' {
            InModuleScope MCP.SDK {
                # Act
                $result = ConvertTo-JsonRpcResponse -InputObject @{result = "test"} -ID 12345

                # Assert
                $result.id | Should -Be 12345
            }
        }

        It 'should accept null ID' {
            InModuleScope MCP.SDK {
                # Act
                $result = ConvertTo-JsonRpcResponse -InputObject @{result = "test"} -ID $null

                # Assert
                $result.Keys | Should -Contain 'id'
                $result.id | Should -BeNullOrEmpty
            }
        }

        It 'should work without ID parameter' {
            InModuleScope MCP.SDK {
                # Act
                $result = ConvertTo-JsonRpcResponse -InputObject @{result = "test"}

                # Assert
                $result.Keys | Should -Contain 'id'
            }
        }
    }

    Context 'Edge Cases' {

        It 'should handle null InputObject' {
            InModuleScope MCP.SDK {
                # Act
                $result = ConvertTo-JsonRpcResponse -InputObject $null -ID 1

                # Assert
                $result.Keys | Should -Contain 'result'
                $result.result | Should -BeNullOrEmpty
            }
        }

        It 'should handle empty hashtable' {
            InModuleScope MCP.SDK {
                # Act
                $result = ConvertTo-JsonRpcResponse -InputObject @{} -ID 1

                # Assert
                $result.Keys | Should -Contain 'result'
                $result.result | Should -BeOfType [hashtable]
            }
        }

        It 'should handle objects with both result and error properties' {
            InModuleScope MCP.SDK {
                # Arrange - result property should take precedence
                $input = [PSCustomObject]@{
                    result = "success data"
                    error = @{code = -32000; message = "Error"}
                }

                # Act
                $result = ConvertTo-JsonRpcResponse -InputObject $input -ID 1

                # Assert
                $result.Keys | Should -Contain 'result'
                $result.result | Should -Be "success data"
                $result.Keys | Should -Not -Contain 'error'
            }
        }

        It 'should handle complex nested objects' {
            InModuleScope MCP.SDK {
                # Arrange
                $complex = @{
                    result = @{
                        nested = @{
                            level1 = @{
                                level2 = "deep value"
                            }
                        }
                        array = @(1, 2, @{key = "value"})
                    }
                }

                # Act
                $result = ConvertTo-JsonRpcResponse -InputObject $complex -ID 1

                # Assert
                $result.result.nested.level1.level2 | Should -Be "deep value"
                $result.result.array[2].key | Should -Be "value"
            }
        }

        It 'should handle empty array' {
            InModuleScope MCP.SDK {
                # Act
                $result = ConvertTo-JsonRpcResponse -InputObject @() -ID 1

                # Assert
                $result.Keys | Should -Contain 'result'
                $result.result.Count | Should -Be 0
            }
        }

        It 'should preserve data types in result' {
            InModuleScope MCP.SDK {
                # Arrange
                $input = @{
                    result = @{
                        string = "text"
                        number = 42
                        boolean = $true
                        null = $null
                    }
                }

                # Act
                $result = ConvertTo-JsonRpcResponse -InputObject $input -ID 1

                # Assert
                $result.result.string | Should -BeOfType [string]
                $result.result.number | Should -BeOfType [int]
                $result.result.boolean | Should -BeOfType [bool]
            }
        }
    }

    Context 'JSON-RPC Specification Compliance' {

        It 'should have exactly 3 keys for success response' {
            InModuleScope MCP.SDK {
                # Act
                $result = ConvertTo-JsonRpcResponse -InputObject @{result = "test"} -ID 1

                # Assert
                $result.Keys.Count | Should -Be 3
                $result.Keys | Should -Contain 'jsonrpc'
                $result.Keys | Should -Contain 'id'
                $result.Keys | Should -Contain 'result'
            }
        }

        It 'should have exactly 3 keys for error response with existing error' {
            InModuleScope MCP.SDK {
                # Arrange
                $input = @{
                    error = @{code = -32600; message = "Invalid"}
                }

                # Act
                $result = ConvertTo-JsonRpcResponse -InputObject $input -ID 1

                # Assert
                $result.Keys.Count | Should -Be 3
                $result.Keys | Should -Contain 'jsonrpc'
                $result.Keys | Should -Contain 'id'
                $result.Keys | Should -Contain 'error'
            }
        }

        It 'should have exactly 3 keys for exception error response' {
            InModuleScope MCP.SDK {
                # Arrange
                $exception = [System.Exception]::new("Error")

                # Act
                $result = ConvertTo-JsonRpcResponse -InputObject $exception -ID 1

                # Assert
                $result.Keys.Count | Should -Be 3
                $result.Keys | Should -Contain 'jsonrpc'
                $result.Keys | Should -Contain 'id'
                $result.Keys | Should -Contain 'error'
            }
        }

        It 'should format error object with code and message' {
            InModuleScope MCP.SDK {
                # Arrange
                $exception = [System.Exception]::new("Test error")

                # Act
                $result = ConvertTo-JsonRpcResponse -InputObject $exception -ID 1

                # Assert
                $result.error | Should -BeOfType [hashtable]
                $result.error.Keys | Should -Contain 'code'
                $result.error.Keys | Should -Contain 'message'
                $result.error.Keys.Count | Should -Be 2
            }
        }
    }
}
