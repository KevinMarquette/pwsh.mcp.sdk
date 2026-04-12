BeforeAll {
    # Import the module
    $ModuleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $ModulePath = Join-Path $ModuleRoot 'MCP.SDK\MCP.SDK.psd1'
    Import-Module $ModulePath -Force
}

Describe 'Test-ToolParameter' -Tag 'Unit' {

    Context 'Required parameter enforcement' {

        It 'should pass when all required parameters are supplied' {
            InModuleScope MCP.SDK {
                $schema = @{
                    type       = 'object'
                    properties = [ordered]@{
                        Name = @{ name = 'Name'; type = 'string' }
                    }
                    required   = @('Name')
                }

                { Test-ToolParameter -Schema $schema -Parameters @{ Name = 'alice' } } |
                    Should -Not -Throw
            }
        }

        It 'should throw ArgumentException when a required parameter is missing' {
            InModuleScope MCP.SDK {
                $schema = @{
                    type       = 'object'
                    properties = [ordered]@{
                        Name = @{ name = 'Name'; type = 'string' }
                    }
                    required   = @('Name')
                }

                $thrown = $null
                try { Test-ToolParameter -Schema $schema -Parameters @{} }
                catch { $thrown = $_.Exception }

                $thrown | Should -Not -BeNullOrEmpty
                $thrown | Should -BeOfType [System.ArgumentException]
                $thrown.Message | Should -Match "Missing required parameter 'Name'"
            }
        }

        It 'should list every missing required parameter in a single exception' {
            InModuleScope MCP.SDK {
                $schema = @{
                    type       = 'object'
                    properties = [ordered]@{
                        A = @{ name = 'A'; type = 'string' }
                        B = @{ name = 'B'; type = 'string' }
                    }
                    required   = @('A', 'B')
                }

                $thrown = $null
                try { Test-ToolParameter -Schema $schema -Parameters @{} }
                catch { $thrown = $_.Exception }

                $thrown.Message | Should -Match "'A'"
                $thrown.Message | Should -Match "'B'"
            }
        }
    }

    Context 'Unknown parameter rejection' {

        It 'should throw when an unknown parameter is supplied' {
            InModuleScope MCP.SDK {
                $schema = @{
                    type       = 'object'
                    properties = [ordered]@{
                        Name = @{ name = 'Name'; type = 'string' }
                    }
                }

                $thrown = $null
                try { Test-ToolParameter -Schema $schema -Parameters @{ Name = 'x'; Bogus = 'y' } }
                catch { $thrown = $_.Exception }

                $thrown | Should -BeOfType [System.ArgumentException]
                $thrown.Message | Should -Match "Unknown parameter 'Bogus'"
            }
        }
    }

    Context 'Primitive type checking' {

        It 'should accept <Type> value for a matching schema' -TestCases @(
            @{ Type = 'string';  Value = 'hello' }
            @{ Type = 'integer'; Value = 42 }
            @{ Type = 'number';  Value = 3.14 }
            @{ Type = 'boolean'; Value = $true }
            @{ Type = 'array';   Value = @('a', 'b') }
            @{ Type = 'object';  Value = @{ key = 'val' } }
        ) {
            InModuleScope MCP.SDK -Parameters @{ Type = $Type; Value = $Value } {
                param($Type, $Value)
                $schema = @{
                    properties = [ordered]@{
                        Field = @{ name = 'Field'; type = $Type }
                    }
                }

                { Test-ToolParameter -Schema $schema -Parameters @{ Field = $Value } } |
                    Should -Not -Throw
            }
        }

        It 'should reject a string when integer is expected' {
            InModuleScope MCP.SDK {
                $schema = @{
                    properties = [ordered]@{
                        Count = @{ name = 'Count'; type = 'integer' }
                    }
                }

                $thrown = $null
                try { Test-ToolParameter -Schema $schema -Parameters @{ Count = 'not-a-number' } }
                catch { $thrown = $_.Exception }

                $thrown | Should -BeOfType [System.ArgumentException]
                $thrown.Message | Should -Match "Parameter 'Count' expected type 'integer'"
            }
        }

        It 'should reject a boolean when integer is expected' {
            InModuleScope MCP.SDK {
                $schema = @{
                    properties = [ordered]@{
                        Count = @{ name = 'Count'; type = 'integer' }
                    }
                }

                { Test-ToolParameter -Schema $schema -Parameters @{ Count = $true } } |
                    Should -Throw
            }
        }
    }

    Context 'Enum / ValidateSet enforcement' {

        It 'should accept a value that is in the enum set' {
            InModuleScope MCP.SDK {
                $schema = @{
                    properties = [ordered]@{
                        Severity = @{
                            name = 'Severity'
                            type = 'string'
                            enum = @('Low', 'High')
                        }
                    }
                }

                { Test-ToolParameter -Schema $schema -Parameters @{ Severity = 'Low' } } |
                    Should -Not -Throw
            }
        }

        It 'should reject a value that is not in the enum set' {
            InModuleScope MCP.SDK {
                $schema = @{
                    properties = [ordered]@{
                        Severity = @{
                            name = 'Severity'
                            type = 'string'
                            enum = @('Low', 'High')
                        }
                    }
                }

                $thrown = $null
                try { Test-ToolParameter -Schema $schema -Parameters @{ Severity = 'Bogus' } }
                catch { $thrown = $_.Exception }

                $thrown | Should -BeOfType [System.ArgumentException]
                $thrown.Message | Should -Match "Severity"
                $thrown.Message | Should -Match "Bogus"
            }
        }

        It 'should reject an array item that is not in the items.enum set' {
            InModuleScope MCP.SDK {
                $schema = @{
                    properties = [ordered]@{
                        Tags = @{
                            name  = 'Tags'
                            type  = 'array'
                            items = @{ type = 'string'; enum = @('alpha', 'beta') }
                        }
                    }
                }

                $thrown = $null
                try {
                    Test-ToolParameter -Schema $schema -Parameters @{ Tags = @('alpha', 'gamma') }
                }
                catch { $thrown = $_.Exception }

                $thrown | Should -BeOfType [System.ArgumentException]
                $thrown.Message | Should -Match "gamma"
            }
        }
    }

    Context 'Empty / missing schema shapes' {

        It 'should accept empty parameters when schema has no required fields' {
            InModuleScope MCP.SDK {
                $schema = @{
                    properties = [ordered]@{
                        Name = @{ name = 'Name'; type = 'string' }
                    }
                }

                { Test-ToolParameter -Schema $schema -Parameters @{} } | Should -Not -Throw
            }
        }
    }
}
