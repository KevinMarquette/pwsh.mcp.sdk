BeforeAll {
    # Import the module
    $ModuleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $ModulePath = Join-Path $ModuleRoot 'MCP.SDK\MCP.SDK.psd1'
    Import-Module $ModulePath -Force
}

Describe 'ConvertTo-JsonType' -Tag 'Unit' {

    Context 'Basic Type Conversion' {

        It 'should convert <PSTypeName> to <ExpectedType>' -TestCases @(
            @{ PSTypeName = 'String'; ExpectedType = 'string' }
            @{ PSTypeName = 'Int32'; ExpectedType = 'integer' }
            @{ PSTypeName = 'Int64'; ExpectedType = 'integer' }
            @{ PSTypeName = 'Boolean'; ExpectedType = 'boolean' }
            @{ PSTypeName = 'Double'; ExpectedType = 'number' }
            @{ PSTypeName = 'Decimal'; ExpectedType = 'number' }
            @{ PSTypeName = 'DateTime'; ExpectedType = 'string' }
            @{ PSTypeName = 'SwitchParameter'; ExpectedType = 'boolean' }
            @{ PSTypeName = 'Object'; ExpectedType = 'object' }
            @{ PSTypeName = 'Hashtable'; ExpectedType = 'object' }
            @{ PSTypeName = 'Array'; ExpectedType = 'array' }
            @{ PSTypeName = 'UnknownType'; ExpectedType = 'string' }
        ) {
            InModuleScope MCP.SDK -Parameters @{ PSTypeName = $PSTypeName; ExpectedType = $ExpectedType } {
                param($PSTypeName, $ExpectedType)
                # Act
                $result = ConvertTo-JsonType -PSTypeName $PSTypeName

                # Assert
                $result.type | Should -Be $ExpectedType
            }
        }
    }

    Context 'Array Type Conversion' {

        It 'should convert <PSTypeName> to array of <ExpectedItemType>' -TestCases @(
            @{ PSTypeName = 'String[]'; ExpectedItemType = 'string' }
            @{ PSTypeName = 'Int32[]'; ExpectedItemType = 'integer' }
            @{ PSTypeName = 'Int64[]'; ExpectedItemType = 'integer' }
            @{ PSTypeName = 'Boolean[]'; ExpectedItemType = 'boolean' }
            @{ PSTypeName = 'Double[]'; ExpectedItemType = 'number' }
            @{ PSTypeName = 'Object[]'; ExpectedItemType = 'object' }
            @{ PSTypeName = 'Hashtable[]'; ExpectedItemType = 'object' }
            @{ PSTypeName = 'CustomType[]'; ExpectedItemType = 'string' }
        ) {
            InModuleScope MCP.SDK -Parameters @{ PSTypeName = $PSTypeName; ExpectedItemType = $ExpectedItemType } {
                param($PSTypeName, $ExpectedItemType)
                # Act
                $result = ConvertTo-JsonType -PSTypeName $PSTypeName

                # Assert
                $result.type | Should -Be 'array'
                $result.items | Should -Not -BeNullOrEmpty
                $result.items.type | Should -Be $ExpectedItemType
            }
        }
    }

    Context 'Return Structure' {

        It 'should return a hashtable for non-array types' {
            InModuleScope MCP.SDK {
                # Act
                $result = ConvertTo-JsonType -PSTypeName 'String'

                # Assert
                $result | Should -BeOfType [hashtable]
                $result.Keys | Should -Contain 'type'
            }
        }

        It 'should return a hashtable with type and items for array types' {
            InModuleScope MCP.SDK {
                # Act
                $result = ConvertTo-JsonType -PSTypeName 'String[]'

                # Assert
                $result | Should -BeOfType [hashtable]
                $result.Keys | Should -Contain 'type'
                $result.Keys | Should -Contain 'items'
                $result.type | Should -Be 'array'
                $result.items | Should -BeOfType [hashtable]
            }
        }

        It 'should only have type property for non-array types' {
            InModuleScope MCP.SDK {
                # Act
                $result = ConvertTo-JsonType -PSTypeName 'Int32'

                # Assert
                $result.Keys.Count | Should -Be 1
                $result.Keys | Should -Contain 'type'
            }
        }

        It 'should have exactly two keys for array types' {
            InModuleScope MCP.SDK {
                # Act
                $result = ConvertTo-JsonType -PSTypeName 'Int32[]'

                # Assert
                $result.Keys.Count | Should -Be 2
                $result.Keys | Should -Contain 'type'
                $result.Keys | Should -Contain 'items'
            }
        }
    }

    Context 'Pipeline Support' {

        It 'should accept input from pipeline' {
            InModuleScope MCP.SDK {
                # Act
                $result = 'String' | ConvertTo-JsonType

                # Assert
                $result.type | Should -Be 'string'
            }
        }

        It 'should process multiple types from pipeline' {
            InModuleScope MCP.SDK {
                # Act
                $results = 'String', 'Int32', 'Boolean' | ConvertTo-JsonType

                # Assert
                $results.Count | Should -Be 3
                $results[0].type | Should -Be 'string'
                $results[1].type | Should -Be 'integer'
                $results[2].type | Should -Be 'boolean'
            }
        }
    }

    Context 'Parameter Validation' {


        It 'should not accept <InvalidValue> for PSTypeName' -TestCases @(
            @{ InvalidValue = $null; Description = 'null' }
            @{ InvalidValue = ''; Description = 'empty string' }
        ) {
            InModuleScope MCP.SDK -Parameters @{ InvalidValue = $InvalidValue } {
                param($InvalidValue)
                # Act & Assert
                { ConvertTo-JsonType -PSTypeName $InvalidValue } | Should -Throw
            }
        }

        It 'should accept PSTypeName by position' {
            InModuleScope MCP.SDK {
                # Act
                $result = ConvertTo-JsonType 'String'

                # Assert
                $result.type | Should -Be 'string'
            }
        }

        It 'should accept PSTypeName via Type alias' {
            InModuleScope MCP.SDK {
                # Act
                $result = ConvertTo-JsonType -Type 'String'

                # Assert
                $result.type | Should -Be 'string'
            }
        }
    }

    Context 'Case Sensitivity and Regex Matching' {

        It 'should be case-insensitive for <PSTypeName>' -TestCases @(
            @{ PSTypeName = 'string'; ExpectedType = 'string' }
            @{ PSTypeName = 'STRING'; ExpectedType = 'string' }
            @{ PSTypeName = 'String'; ExpectedType = 'string' }
        ) {
            InModuleScope MCP.SDK -Parameters @{ PSTypeName = $PSTypeName; ExpectedType = $ExpectedType } {
                param($PSTypeName, $ExpectedType)
                # Act
                $result = ConvertTo-JsonType -PSTypeName $PSTypeName

                # Assert
                $result.type | Should -Be $ExpectedType
            }
        }

        It 'should match types containing the pattern' {
            InModuleScope MCP.SDK {
                # Act - System.String should match "String"
                $result = ConvertTo-JsonType -PSTypeName 'System.String'

                # Assert
                $result.type | Should -Be 'string'
            }
        }

        It 'should handle fully qualified type name <PSTypeName>' -TestCases @(
            @{ PSTypeName = 'System.Int32'; ExpectedType = 'integer' }
            @{ PSTypeName = 'System.Boolean'; ExpectedType = 'boolean' }
            @{ PSTypeName = 'System.Double'; ExpectedType = 'number' }
        ) {
            InModuleScope MCP.SDK -Parameters @{ PSTypeName = $PSTypeName; ExpectedType = $ExpectedType } {
                param($PSTypeName, $ExpectedType)
                # Act
                $result = ConvertTo-JsonType -PSTypeName $PSTypeName

                # Assert
                $result.type | Should -Be $ExpectedType
            }
        }

        It 'should handle fully qualified array type names' {
            InModuleScope MCP.SDK {
                # Act
                $result = ConvertTo-JsonType -PSTypeName 'System.String[]'

                # Assert
                $result.type | Should -Be 'array'
                $result.items.type | Should -Be 'string'
            }
        }
    }

    Context 'Edge Cases' {

        It 'should handle type names with spaces' {
            InModuleScope MCP.SDK {
                # Act
                $result = ConvertTo-JsonType -PSTypeName 'Custom Type'

                # Assert
                $result.type | Should -Be 'string'
            }
        }

        It 'should handle array notation at the end only' {
            InModuleScope MCP.SDK {
                # Act
                $result = ConvertTo-JsonType -PSTypeName 'String[]'

                # Assert
                $result.type | Should -Be 'array'
            }
        }

        It 'should return consistent results for the same input' {
            InModuleScope MCP.SDK {
                # Act
                $result1 = ConvertTo-JsonType -PSTypeName 'String'
                $result2 = ConvertTo-JsonType -PSTypeName 'String'

                # Assert
                $result1.type | Should -Be $result2.type
            }
        }
    }
}
