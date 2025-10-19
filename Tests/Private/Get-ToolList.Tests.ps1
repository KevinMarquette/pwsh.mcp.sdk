BeforeAll {
    # Import the module
    $ModuleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $ModulePath = Join-Path $ModuleRoot 'MCP.SDK\MCP.SDK.psd1'
    Import-Module $ModulePath -Force

    InModuleScope MCP.SDK {
        # Helper function to create test tool scripts (reuse from Get-ToolSignature tests)
        function Script:New-TestTool {
            param(
                [string]$Path,
                [string]$Synopsis = "Test tool synopsis",
                [string]$Description = "Test tool description",
                [hashtable[]]$Parameters = @()
            )

            $paramBlocks = @()
            foreach ($param in $Parameters) {
                $mandatoryText = if ($param.Mandatory) { 'Mandatory' } else { '' }
                $paramBlock = @"
    # $($param.Description)
    [Parameter($mandatoryText)]
"@
                if ($param.ValidateSet) {
                    $paramBlock += "`n    [ValidateSet('$($param.ValidateSet -join "', '")')]"
                }
                $paramBlock += "`n    [$($param.Type)]`$$($param.Name)"
                if ($param.DefaultValue) {
                    $paramBlock += " = $($param.DefaultValue)"
                }
                $paramBlocks += $paramBlock
            }

            $content = @"
<#
.SYNOPSIS
$Synopsis

.DESCRIPTION
$Description
#>
[CmdletBinding()]
param(
$($paramBlocks -join ",`n`n")
)

Write-Output "Test tool execution"
"@

            New-Item -Path (Split-Path $Path -Parent) -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
            $content | Set-Content -Path $Path -NoNewline
            return $Path
        }
    }
}

Describe 'Get-ToolList' -Tag 'Unit' {

    Context 'Basic Functionality' {

        It 'should return a hashtable with tools key' {
            InModuleScope MCP.SDK {
                # Arrange
                $mcpRoot = Join-Path $TestDrive 'basic-server'
                $toolsPath = Join-Path $mcpRoot 'tools'
                New-Item -Path $toolsPath -ItemType Directory -Force | Out-Null
                New-TestTool -Path (Join-Path $toolsPath 'Tool1.ps1') -Synopsis "Tool 1" -Description "First tool"

                # Act
                $result = Get-ToolList -MCPRoot $mcpRoot

                # Assert
                $result | Should -Not -BeNullOrEmpty
                $result.Keys | Should -Contain 'tools'
            }
        }

        It 'should return tools as an array' {
            InModuleScope MCP.SDK {
                # Arrange
                $mcpRoot = Join-Path $TestDrive 'array-server'
                $toolsPath = Join-Path $mcpRoot 'tools'
                New-Item -Path $toolsPath -ItemType Directory -Force | Out-Null
                New-TestTool -Path (Join-Path $toolsPath 'Tool1.ps1') -Synopsis "Tool 1" -Description "First tool"

                # Act
                $result = Get-ToolList -MCPRoot $mcpRoot

                # Assert
                @($result.tools) | Should -Not -BeNullOrEmpty
                @($result.tools).Count | Should -Be 1
            }
        }

        It 'should list all .ps1 files in tools directory' {
            InModuleScope MCP.SDK {
                # Arrange
                $mcpRoot = Join-Path $TestDrive 'multi-tool-server'
                $toolsPath = Join-Path $mcpRoot 'tools'
                New-Item -Path $toolsPath -ItemType Directory -Force | Out-Null
                New-TestTool -Path (Join-Path $toolsPath 'Tool1.ps1') -Synopsis "Tool 1" -Description "First tool"
                New-TestTool -Path (Join-Path $toolsPath 'Tool2.ps1') -Synopsis "Tool 2" -Description "Second tool"
                New-TestTool -Path (Join-Path $toolsPath 'Tool3.ps1') -Synopsis "Tool 3" -Description "Third tool"

                # Act
                $result = Get-ToolList -MCPRoot $mcpRoot

                # Assert
                $result.tools.Count | Should -Be 3
            }
        }

        It 'should include tool signatures with correct properties' {
            InModuleScope MCP.SDK {
                # Arrange
                $mcpRoot = Join-Path $TestDrive 'signature-server'
                $toolsPath = Join-Path $mcpRoot 'tools'
                New-Item -Path $toolsPath -ItemType Directory -Force | Out-Null
                New-TestTool -Path (Join-Path $toolsPath 'TestTool.ps1') `
                    -Synopsis "Test Tool Synopsis" `
                    -Description "Test tool description" `
                    -Parameters @(
                        @{ Name = 'Param1'; Type = 'string'; Mandatory = $true; Description = 'Parameter 1' }
                    )

                # Act
                $result = Get-ToolList -MCPRoot $mcpRoot

                # Assert
                $result.tools[0].name | Should -Be 'TestTool'
                $result.tools[0].title | Should -Be 'Test Tool Synopsis'
                $result.tools[0].description | Should -Be 'Test tool description'
                $result.tools[0].inputSchema | Should -Not -BeNullOrEmpty
            }
        }

        It 'should return empty array when tools directory is empty' {
            InModuleScope MCP.SDK {
                # Arrange
                $mcpRoot = Join-Path $TestDrive 'empty-tools-server'
                $toolsPath = Join-Path $mcpRoot 'tools'
                New-Item -Path $toolsPath -ItemType Directory -Force | Out-Null

                # Act
                $result = Get-ToolList -MCPRoot $mcpRoot

                # Assert
                $result.Keys | Should -Contain 'tools'
                @($result.tools).Count | Should -Be 0
            }
        }

        It 'should only include .ps1 files, ignoring other file types' {
            InModuleScope MCP.SDK {
                # Arrange
                $mcpRoot = Join-Path $TestDrive 'filtered-server'
                $toolsPath = Join-Path $mcpRoot 'tools'
                New-Item -Path $toolsPath -ItemType Directory -Force | Out-Null
                New-TestTool -Path (Join-Path $toolsPath 'ValidTool.ps1') -Synopsis "Valid" -Description "Valid tool"
                'readme content' | Set-Content (Join-Path $toolsPath 'README.md')
                'text content' | Set-Content (Join-Path $toolsPath 'notes.txt')
                '{}' | Set-Content (Join-Path $toolsPath 'config.json')

                # Act
                $result = Get-ToolList -MCPRoot $mcpRoot

                # Assert
                $result.tools.Count | Should -Be 1
                $result.tools[0].name | Should -Be 'ValidTool'
            }
        }
    }

    Context 'Tool Ordering' {

        It 'should maintain consistent ordering of tools' {
            InModuleScope MCP.SDK {
                # Arrange
                $mcpRoot = Join-Path $TestDrive 'ordered-server'
                $toolsPath = Join-Path $mcpRoot 'tools'
                New-Item -Path $toolsPath -ItemType Directory -Force | Out-Null
                New-TestTool -Path (Join-Path $toolsPath 'Alpha.ps1') -Synopsis "Alpha" -Description "Alpha tool"
                New-TestTool -Path (Join-Path $toolsPath 'Beta.ps1') -Synopsis "Beta" -Description "Beta tool"
                New-TestTool -Path (Join-Path $toolsPath 'Gamma.ps1') -Synopsis "Gamma" -Description "Gamma tool"

                # Act - Call twice to verify consistent ordering
                $result1 = Get-ToolList -MCPRoot $mcpRoot
                $result2 = Get-ToolList -MCPRoot $mcpRoot

                # Assert
                $result1.tools[0].name | Should -Be $result2.tools[0].name
                $result1.tools[1].name | Should -Be $result2.tools[1].name
                $result1.tools[2].name | Should -Be $result2.tools[2].name
            }
        }
    }

    Context 'Parameter Validation' {

        It 'should accept MCPRoot parameter' {
            InModuleScope MCP.SDK {
                # Arrange
                $mcpRoot = Join-Path $TestDrive 'param-test'
                $toolsPath = Join-Path $mcpRoot 'tools'
                New-Item -Path $toolsPath -ItemType Directory -Force | Out-Null

                # Act & Assert
                { Get-ToolList -MCPRoot $mcpRoot } | Should -Not -Throw
            }
        }

        It 'should accept valid MCPRoot path' {
            InModuleScope MCP.SDK {
                # Arrange
                $mcpRoot = Join-Path $TestDrive 'valid-root'
                $toolsPath = Join-Path $mcpRoot 'tools'
                New-Item -Path $toolsPath -ItemType Directory -Force | Out-Null

                # Act & Assert
                { Get-ToolList -MCPRoot $mcpRoot } | Should -Not -Throw
            }
        }
    }

    Context 'Integration with Get-ToolSignature' {

        It 'should properly integrate with Get-ToolSignature for parameter detection' {
            InModuleScope MCP.SDK {
                # Arrange
                $mcpRoot = Join-Path $TestDrive 'integration-server'
                $toolsPath = Join-Path $mcpRoot 'tools'
                New-Item -Path $toolsPath -ItemType Directory -Force | Out-Null
                New-TestTool -Path (Join-Path $toolsPath 'ParamTool.ps1') `
                    -Synopsis "Param Tool" `
                    -Description "Tool with parameters" `
                    -Parameters @(
                        @{ Name = 'Arg1'; Type = 'string'; Mandatory = $true; Description = 'First argument' }
                        @{ Name = 'Arg2'; Type = 'int'; Mandatory = $false; Description = 'Second argument' }
                    )

                # Act
                $result = Get-ToolList -MCPRoot $mcpRoot

                # Assert
                $tool = $result.tools[0]
                $tool.inputSchema.properties.Arg1 | Should -Not -BeNullOrEmpty
                $tool.inputSchema.properties.Arg2 | Should -Not -BeNullOrEmpty
                $tool.inputSchema.required | Should -Contain 'Arg1'
                $tool.inputSchema.required | Should -Not -Contain 'Arg2'
            }
        }

        It 'should properly integrate with Get-ToolSignature for ValidateSet enums' {
            InModuleScope MCP.SDK {
                # Arrange
                $mcpRoot = Join-Path $TestDrive 'enum-server'
                $toolsPath = Join-Path $mcpRoot 'tools'
                New-Item -Path $toolsPath -ItemType Directory -Force | Out-Null
                New-TestTool -Path (Join-Path $toolsPath 'EnumTool.ps1') `
                    -Synopsis "Enum Tool" `
                    -Description "Tool with enum" `
                    -Parameters @(
                        @{ Name = 'Level'; Type = 'string'; Mandatory = $true; Description = 'Level'; ValidateSet = @('Low', 'Medium', 'High') }
                    )

                # Act
                $result = Get-ToolList -MCPRoot $mcpRoot

                # Assert
                $tool = $result.tools[0]
                $tool.inputSchema.properties.Level.enum | Should -Contain 'Low'
                $tool.inputSchema.properties.Level.enum | Should -Contain 'Medium'
                $tool.inputSchema.properties.Level.enum | Should -Contain 'High'
            }
        }
    }

    Context 'Integration with reference-server' {

        It 'should correctly list all tools from reference-server' {
            InModuleScope MCP.SDK {
                # Arrange
                $referenceServerPath = Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))) 'Examples\reference-server'

                if (Test-Path $referenceServerPath) {
                    # Act
                    $result = Get-ToolList -MCPRoot $referenceServerPath

                    # Assert
                    $result.tools.Count | Should -BeGreaterThan 0

                    # Verify specific tools exist
                    $toolNames = $result.tools.name
                    $toolNames | Should -Contain 'Create-Incident'
                    $toolNames | Should -Contain 'Search-Incidents'
                    $toolNames | Should -Contain 'Update-IncidentStatus'
                }
            }
        }

        It 'should return complete signatures for reference-server tools' {
            InModuleScope MCP.SDK {
                # Arrange
                $referenceServerPath = Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))) 'Examples\reference-server'

                if (Test-Path $referenceServerPath) {
                    # Act
                    $result = Get-ToolList -MCPRoot $referenceServerPath

                    # Assert - Check Create-Incident tool
                    $createIncident = $result.tools | Where-Object { $_.name -eq 'Create-Incident' }
                    if ($createIncident) {
                        $createIncident.title | Should -Not -BeNullOrEmpty
                        $createIncident.description | Should -Not -BeNullOrEmpty
                        $createIncident.inputSchema.properties.Type | Should -Not -BeNullOrEmpty
                        $createIncident.inputSchema.properties.Severity | Should -Not -BeNullOrEmpty
                        $createIncident.inputSchema.required | Should -Contain 'Type'
                    }
                }
            }
        }
    }

    Context 'Return Structure Validation' {

        It 'should return a hashtable' {
            InModuleScope MCP.SDK {
                # Arrange
                $mcpRoot = Join-Path $TestDrive 'return-type-server'
                $toolsPath = Join-Path $mcpRoot 'tools'
                New-Item -Path $toolsPath -ItemType Directory -Force | Out-Null
                New-TestTool -Path (Join-Path $toolsPath 'Tool1.ps1') -Synopsis "Tool 1" -Description "First tool"

                # Act
                $result = Get-ToolList -MCPRoot $mcpRoot

                # Assert
                $result | Should -BeOfType [hashtable]
            }
        }

        It 'should have exactly one key named tools' {
            InModuleScope MCP.SDK {
                # Arrange
                $mcpRoot = Join-Path $TestDrive 'keys-server'
                $toolsPath = Join-Path $mcpRoot 'tools'
                New-Item -Path $toolsPath -ItemType Directory -Force | Out-Null
                New-TestTool -Path (Join-Path $toolsPath 'Tool1.ps1') -Synopsis "Tool 1" -Description "First tool"

                # Act
                $result = Get-ToolList -MCPRoot $mcpRoot

                # Assert
                $result.Keys.Count | Should -Be 1
                $result.Keys[0] | Should -Be 'tools'
            }
        }

        It 'should wrap tools array even with single tool' {
            InModuleScope MCP.SDK {
                # Arrange
                $mcpRoot = Join-Path $TestDrive 'single-tool-server'
                $toolsPath = Join-Path $mcpRoot 'tools'
                New-Item -Path $toolsPath -ItemType Directory -Force | Out-Null
                New-TestTool -Path (Join-Path $toolsPath 'OnlyTool.ps1') -Synopsis "Only" -Description "Only tool"

                # Act
                $result = Get-ToolList -MCPRoot $mcpRoot

                # Assert
                @($result.tools).Count | Should -Be 1
            }
        }
    }

    Context 'Edge Cases and Error Handling' {

        It 'should produce errors when tools directory does not exist' {
            InModuleScope MCP.SDK {
                # Arrange
                $mcpRoot = Join-Path $TestDrive 'no-tools-dir'
                New-Item -Path $mcpRoot -ItemType Directory -Force | Out-Null
                # Don't create tools directory

                # Act
                # Function produces non-terminating error but doesn't throw
                $result = Get-ToolList -MCPRoot $mcpRoot -ErrorAction SilentlyContinue 2>&1

                # Assert - function returns but with errors
                $result | Should -Not -BeNullOrEmpty
            }
        }

        It 'should handle tools with complex parameter types' {
            InModuleScope MCP.SDK {
                # Arrange
                $mcpRoot = Join-Path $TestDrive 'complex-params-server'
                $toolsPath = Join-Path $mcpRoot 'tools'
                New-Item -Path $toolsPath -ItemType Directory -Force | Out-Null
                New-TestTool -Path (Join-Path $toolsPath 'ComplexTool.ps1') `
                    -Synopsis "Complex" `
                    -Description "Complex tool" `
                    -Parameters @(
                        @{ Name = 'StringArg'; Type = 'string'; Mandatory = $true; Description = 'String argument' }
                        @{ Name = 'IntArg'; Type = 'int'; Mandatory = $false; Description = 'Int argument' }
                        @{ Name = 'BoolArg'; Type = 'bool'; Mandatory = $false; Description = 'Bool argument' }
                        @{ Name = 'ArrayArg'; Type = 'string[]'; Mandatory = $false; Description = 'Array argument' }
                    )

                # Act
                $result = Get-ToolList -MCPRoot $mcpRoot

                # Assert
                $tool = $result.tools[0]
                $tool.inputSchema.properties.StringArg.type | Should -Be 'string'
                $tool.inputSchema.properties.IntArg.type | Should -Be 'integer'
                $tool.inputSchema.properties.BoolArg.type | Should -Be 'boolean'
                $tool.inputSchema.properties.ArrayArg.type | Should -Be 'array'
            }
        }

        It 'should handle tools with special characters in filename' {
            InModuleScope MCP.SDK {
                # Arrange
                $mcpRoot = Join-Path $TestDrive 'special-names-server'
                $toolsPath = Join-Path $mcpRoot 'tools'
                New-Item -Path $toolsPath -ItemType Directory -Force | Out-Null
                New-TestTool -Path (Join-Path $toolsPath 'Tool-With-Dashes.ps1') -Synopsis "Dashes" -Description "Tool with dashes"
                New-TestTool -Path (Join-Path $toolsPath 'Tool_With_Underscores.ps1') -Synopsis "Underscores" -Description "Tool with underscores"

                # Act
                $result = Get-ToolList -MCPRoot $mcpRoot

                # Assert
                $result.tools.Count | Should -Be 2
                $toolNames = $result.tools.name
                $toolNames | Should -Contain 'Tool-With-Dashes'
                $toolNames | Should -Contain 'Tool_With_Underscores'
            }
        }

        It 'should handle MCPRoot with trailing slash' {
            InModuleScope MCP.SDK {
                # Arrange
                $mcpRoot = Join-Path $TestDrive 'trailing-slash-server'
                $toolsPath = Join-Path $mcpRoot 'tools'
                New-Item -Path $toolsPath -ItemType Directory -Force | Out-Null
                New-TestTool -Path (Join-Path $toolsPath 'Tool1.ps1') -Synopsis "Tool 1" -Description "First tool"

                # Act
                $resultWithSlash = Get-ToolList -MCPRoot "$mcpRoot\"
                $resultWithoutSlash = Get-ToolList -MCPRoot $mcpRoot

                # Assert - Both should work
                $resultWithSlash.tools.Count | Should -Be 1
                $resultWithoutSlash.tools.Count | Should -Be 1
            }
        }
    }
}
