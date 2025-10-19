BeforeAll {
    # Import the module
    $ModuleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $ModulePath = Join-Path $ModuleRoot 'MCP.SDK\MCP.SDK.psd1'
    Import-Module $ModulePath -Force

    InModuleScope MCP.SDK {
        # Helper function to create test tool scripts
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

Describe 'Get-ToolSignature' -Tag 'Unit' {

    Context 'Basic Functionality' {

        It 'should return a valid tool signature structure' {
            InModuleScope MCP.SDK {
                # Arrange
                $toolPath = Join-Path $TestDrive 'basic-tool.ps1'
                New-TestTool -Path $toolPath -Synopsis "Basic tool" -Description "A basic test tool"

                # Act
                $result = Get-ToolSignature -Path $toolPath

                # Assert
                $result | Should -Not -BeNullOrEmpty
                $result.name | Should -Be 'basic-tool'
                $result.description | Should -Be "A basic test tool"
                $result.inputSchema | Should -Not -BeNullOrEmpty
                $result.inputSchema.type | Should -Be 'object'
                $result.inputSchema.properties | Should -Not -BeNullOrEmpty
            }
        }

        It 'should include title from synopsis' {
            InModuleScope MCP.SDK {
                # Arrange
                $toolPath = Join-Path $TestDrive 'tool-with-synopsis.ps1'
                New-TestTool -Path $toolPath -Synopsis "Tool Synopsis Title" -Description "Tool description"

                # Act
                $result = Get-ToolSignature -Path $toolPath

                # Assert
                $result.title | Should -Be "Tool Synopsis Title"
            }
        }

        It 'should extract tool name from file basename' {
            InModuleScope MCP.SDK {
                # Arrange
                $toolPath = Join-Path $TestDrive 'My-Custom-Tool.ps1'
                New-TestTool -Path $toolPath -Synopsis "Test" -Description "Test"

                # Act
                $result = Get-ToolSignature -Path $toolPath

                # Assert
                $result.name | Should -Be 'My-Custom-Tool'
            }
        }

        It 'should handle tools with no parameters' {
            InModuleScope MCP.SDK {
                # Arrange
                $toolPath = Join-Path $TestDrive 'no-params-tool.ps1'
                New-TestTool -Path $toolPath -Synopsis "No params" -Description "Tool with no parameters" -Parameters @()

                # Act
                $result = Get-ToolSignature -Path $toolPath

                # Assert
                $result.inputSchema.properties.Count | Should -Be 0
                $result.inputSchema.required | Should -BeNullOrEmpty
            }
        }
    }

    Context 'Parameter Detection' {

        It 'should detect mandatory string parameter' {
            InModuleScope MCP.SDK {
                # Arrange
                $toolPath = Join-Path $TestDrive 'mandatory-string-tool.ps1'
                New-TestTool -Path $toolPath -Synopsis "Test" -Description "Test" -Parameters @(
                    @{ Name = 'TestParam'; Type = 'string'; Mandatory = $true; Description = 'A test parameter' }
                )

                # Act
                $result = Get-ToolSignature -Path $toolPath

                # Assert
                $result.inputSchema.properties.TestParam | Should -Not -BeNullOrEmpty
                $result.inputSchema.properties.TestParam.type | Should -Be 'string'
                $result.inputSchema.properties.TestParam.description | Should -Be 'A test parameter'
                $result.inputSchema.required | Should -Contain 'TestParam'
            }
        }

        It 'should detect optional parameter without default value' {
            InModuleScope MCP.SDK {
                # Arrange
                $toolPath = Join-Path $TestDrive 'optional-tool.ps1'
                New-TestTool -Path $toolPath -Synopsis "Test" -Description "Test" -Parameters @(
                    @{ Name = 'OptionalParam'; Type = 'string'; Mandatory = $false; Description = 'Optional parameter' }
                )

                # Act
                $result = Get-ToolSignature -Path $toolPath

                # Assert
                $result.inputSchema.properties.OptionalParam | Should -Not -BeNullOrEmpty
                $result.inputSchema.required | Should -Not -Contain 'OptionalParam'
            }
        }

        It 'should detect integer parameter type' {
            InModuleScope MCP.SDK {
                # Arrange
                $toolPath = Join-Path $TestDrive 'int-tool.ps1'
                New-TestTool -Path $toolPath -Synopsis "Test" -Description "Test" -Parameters @(
                    @{ Name = 'Count'; Type = 'int'; Mandatory = $true; Description = 'Count value' }
                )

                # Act
                $result = Get-ToolSignature -Path $toolPath

                # Assert
                $result.inputSchema.properties.Count.type | Should -Be 'integer'
            }
        }

        It 'should detect boolean parameter type' {
            InModuleScope MCP.SDK {
                # Arrange
                $toolPath = Join-Path $TestDrive 'bool-tool.ps1'
                New-TestTool -Path $toolPath -Synopsis "Test" -Description "Test" -Parameters @(
                    @{ Name = 'Enabled'; Type = 'bool'; Mandatory = $false; Description = 'Enable feature' }
                )

                # Act
                $result = Get-ToolSignature -Path $toolPath

                # Assert
                $result.inputSchema.properties.Enabled.type | Should -Be 'boolean'
            }
        }

        It 'should detect array parameter type' {
            InModuleScope MCP.SDK {
                # Arrange
                $toolPath = Join-Path $TestDrive 'array-tool.ps1'
                New-TestTool -Path $toolPath -Synopsis "Test" -Description "Test" -Parameters @(
                    @{ Name = 'Items'; Type = 'string[]'; Mandatory = $false; Description = 'List of items' }
                )

                # Act
                $result = Get-ToolSignature -Path $toolPath

                # Assert
                $result.inputSchema.properties.Items.type | Should -Be 'array'
                $result.inputSchema.properties.Items.items.type | Should -Be 'string'
            }
        }

        It 'should detect multiple parameters' {
            InModuleScope MCP.SDK {
                # Arrange
                $toolPath = Join-Path $TestDrive 'multi-param-tool.ps1'
                New-TestTool -Path $toolPath -Synopsis "Test" -Description "Test" -Parameters @(
                    @{ Name = 'Name'; Type = 'string'; Mandatory = $true; Description = 'Name parameter' }
                    @{ Name = 'Age'; Type = 'int'; Mandatory = $false; Description = 'Age parameter' }
                    @{ Name = 'Active'; Type = 'bool'; Mandatory = $false; Description = 'Active parameter' }
                )

                # Act
                $result = Get-ToolSignature -Path $toolPath

                # Assert
                $result.inputSchema.properties.Keys.Count | Should -Be 3
                $result.inputSchema.properties.Name | Should -Not -BeNullOrEmpty
                $result.inputSchema.properties.Age | Should -Not -BeNullOrEmpty
                $result.inputSchema.properties.Active | Should -Not -BeNullOrEmpty
                $result.inputSchema.required.Count | Should -Be 1
                $result.inputSchema.required | Should -Contain 'Name'
            }
        }
    }

    Context 'ValidateSet Enum Handling' {

        It 'should detect ValidateSet as enum for string parameters' {
            InModuleScope MCP.SDK {
                # Arrange
                $toolPath = Join-Path $TestDrive 'enum-tool.ps1'
                New-TestTool -Path $toolPath -Synopsis "Test" -Description "Test" -Parameters @(
                    @{ Name = 'Level'; Type = 'string'; Mandatory = $true; Description = 'Level'; ValidateSet = @('Low', 'Medium', 'High') }
                )

                # Act
                $result = Get-ToolSignature -Path $toolPath

                # Assert
                $result.inputSchema.properties.Level.enum | Should -Not -BeNullOrEmpty
                $result.inputSchema.properties.Level.enum | Should -Contain 'Low'
                $result.inputSchema.properties.Level.enum | Should -Contain 'Medium'
                $result.inputSchema.properties.Level.enum | Should -Contain 'High'
            }
        }

        It 'should detect ValidateSet as enum for array parameters' {
            InModuleScope MCP.SDK {
                # Arrange
                $toolPath = Join-Path $TestDrive 'enum-array-tool.ps1'
                New-TestTool -Path $toolPath -Synopsis "Test" -Description "Test" -Parameters @(
                    @{ Name = 'Options'; Type = 'string[]'; Mandatory = $false; Description = 'Options'; ValidateSet = @('Option1', 'Option2', 'Option3') }
                )

                # Act
                $result = Get-ToolSignature -Path $toolPath

                # Assert
                $result.inputSchema.properties.Options.type | Should -Be 'array'
                $result.inputSchema.properties.Options.items.enum | Should -Not -BeNullOrEmpty
                $result.inputSchema.properties.Options.items.enum | Should -Contain 'Option1'
                $result.inputSchema.properties.Options.items.enum | Should -Contain 'Option2'
                $result.inputSchema.properties.Options.items.enum | Should -Contain 'Option3'
            }
        }
    }

    Context 'Pipeline Support' {

        It 'should accept Path parameter' {
            InModuleScope MCP.SDK {
                # Arrange
                $toolPath = Join-Path $TestDrive 'pipeline-test.ps1'
                New-TestTool -Path $toolPath -Synopsis "Test" -Description "Test"

                # Act & Assert
                { Get-ToolSignature -Path $toolPath } | Should -Not -Throw
            }
        }

        It 'should accept pipeline input from Get-ChildItem' {
            InModuleScope MCP.SDK {
                # Arrange
                $toolsDir = Join-Path $TestDrive 'pipeline-tools'
                New-Item -Path $toolsDir -ItemType Directory -Force | Out-Null
                New-TestTool -Path (Join-Path $toolsDir 'Tool1.ps1') -Synopsis "Tool 1" -Description "First tool"
                New-TestTool -Path (Join-Path $toolsDir 'Tool2.ps1') -Synopsis "Tool 2" -Description "Second tool"

                # Act
                $results = Get-ChildItem -Path $toolsDir -Filter '*.ps1' | Get-ToolSignature

                # Assert
                $results.Count | Should -Be 2
                $results[0].name | Should -BeIn @('Tool1', 'Tool2')
                $results[1].name | Should -BeIn @('Tool1', 'Tool2')
            }
        }

        It 'should support FullName alias for Path parameter' {
            InModuleScope MCP.SDK {
                # Arrange
                $toolPath = Join-Path $TestDrive 'alias-test.ps1'
                New-TestTool -Path $toolPath -Synopsis "Test" -Description "Test"
                $fileInfo = Get-Item $toolPath

                # Act
                $result = Get-ToolSignature -Path $fileInfo.FullName

                # Assert
                $result.name | Should -Be 'alias-test'
            }
        }
    }

    Context 'Integration with reference-server' {

        It 'should correctly parse Create-Incident tool from reference-server' {
            InModuleScope MCP.SDK {
                # Arrange
                $referenceServerPath = Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))) 'Examples\reference-server\tools\Create-Incident.ps1'

                if (Test-Path $referenceServerPath) {
                    # Act
                    $result = Get-ToolSignature -Path $referenceServerPath

                    # Assert
                    $result.name | Should -Be 'Create-Incident'
                    $result.title | Should -Be 'Creates a new incident record with specified details'
                    $result.description | Should -Match 'Creates a new incident'

                    # Check mandatory parameters
                    $result.inputSchema.required | Should -Contain 'Type'
                    $result.inputSchema.required | Should -Contain 'Severity'
                    $result.inputSchema.required | Should -Contain 'Description'

                    # Check ValidateSet enums
                    $result.inputSchema.properties.Type.enum | Should -Contain 'Security'
                    $result.inputSchema.properties.Severity.enum | Should -Contain 'Critical'

                    # Check optional parameters
                    $result.inputSchema.required | Should -Not -Contain 'Assignee'
                    $result.inputSchema.properties.Assignee | Should -Not -BeNullOrEmpty

                    # Check array parameter
                    $result.inputSchema.properties.AffectedServices.type | Should -Be 'array'
                }
            }
        }

        It 'should correctly parse Search-Incidents tool from reference-server' {
            InModuleScope MCP.SDK {
                # Arrange
                $referenceServerPath = Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))) 'Examples\reference-server\tools\Search-Incidents.ps1'

                if (Test-Path $referenceServerPath) {
                    # Act
                    $result = Get-ToolSignature -Path $referenceServerPath

                    # Assert
                    $result.name | Should -Be 'Search-Incidents'
                    $result.inputSchema | Should -Not -BeNullOrEmpty
                    $result.inputSchema.properties | Should -Not -BeNullOrEmpty
                }
            }
        }

        It 'should correctly parse Update-IncidentStatus tool from reference-server' {
            InModuleScope MCP.SDK {
                # Arrange
                $referenceServerPath = Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))) 'Examples\reference-server\tools\Update-IncidentStatus.ps1'

                if (Test-Path $referenceServerPath) {
                    # Act
                    $result = Get-ToolSignature -Path $referenceServerPath

                    # Assert
                    $result.name | Should -Be 'Update-IncidentStatus'
                    $result.inputSchema | Should -Not -BeNullOrEmpty
                    $result.inputSchema.properties | Should -Not -BeNullOrEmpty
                }
            }
        }
    }

    Context 'Return Structure Validation' {

        It 'should return an ordered hashtable' {
            InModuleScope MCP.SDK {
                # Arrange
                $toolPath = Join-Path $TestDrive 'ordered-test.ps1'
                New-TestTool -Path $toolPath -Synopsis "Test" -Description "Test"

                # Act
                $result = Get-ToolSignature -Path $toolPath

                # Assert
                $result | Should -BeOfType [System.Collections.Specialized.OrderedDictionary]
            }
        }

        It 'should have correct top-level keys' {
            InModuleScope MCP.SDK {
                # Arrange
                $toolPath = Join-Path $TestDrive 'keys-test.ps1'
                New-TestTool -Path $toolPath -Synopsis "Test" -Description "Test" -Parameters @(
                    @{ Name = 'Param1'; Type = 'string'; Mandatory = $true; Description = 'Test param' }
                )

                # Act
                $result = Get-ToolSignature -Path $toolPath

                # Assert
                $result.Keys | Should -Contain 'name'
                $result.Keys | Should -Contain 'description'
                $result.Keys | Should -Contain 'inputSchema'
                $result.Keys | Should -Contain 'title'
            }
        }

        It 'should have inputSchema with correct structure' {
            InModuleScope MCP.SDK {
                # Arrange
                $toolPath = Join-Path $TestDrive 'schema-test.ps1'
                New-TestTool -Path $toolPath -Synopsis "Test" -Description "Test" -Parameters @(
                    @{ Name = 'Param1'; Type = 'string'; Mandatory = $true; Description = 'Test param' }
                )

                # Act
                $result = Get-ToolSignature -Path $toolPath

                # Assert
                $result.inputSchema.type | Should -Be 'object'
                $result.inputSchema.properties | Should -Not -BeNullOrEmpty
                $result.inputSchema.properties | Should -BeOfType [System.Collections.Specialized.OrderedDictionary]
            }
        }

        It 'should include name field in each property schema' {
            InModuleScope MCP.SDK {
                # Arrange
                $toolPath = Join-Path $TestDrive 'property-name-test.ps1'
                New-TestTool -Path $toolPath -Synopsis "Test" -Description "Test" -Parameters @(
                    @{ Name = 'TestParam'; Type = 'string'; Mandatory = $true; Description = 'Test parameter' }
                )

                # Act
                $result = Get-ToolSignature -Path $toolPath

                # Assert
                $result.inputSchema.properties.TestParam.name | Should -Be 'TestParam'
            }
        }
    }

    Context 'Edge Cases and Error Handling' {

        It 'should handle tool with minimal help documentation' {
            InModuleScope MCP.SDK {
                # Arrange
                $toolPath = Join-Path $TestDrive 'minimal-doc.ps1'
                @'
param([string]$Param1)
Write-Output "Test"
'@ | Set-Content -Path $toolPath -NoNewline

                # Act
                $result = Get-ToolSignature -Path $toolPath

                # Assert
                $result.name | Should -Be 'minimal-doc'
                $result | Should -Not -BeNullOrEmpty
            }
        }

        It 'should handle parameter with no description' {
            InModuleScope MCP.SDK {
                # Arrange
                $toolPath = Join-Path $TestDrive 'no-param-desc.ps1'
                @'
<#
.SYNOPSIS
Test tool

.DESCRIPTION
Test description
#>
param(
    [Parameter(Mandatory)]
    [string]$Param1
)
'@ | Set-Content -Path $toolPath -NoNewline

                # Act
                $result = Get-ToolSignature -Path $toolPath

                # Assert
                $result.inputSchema.properties.Param1 | Should -Not -BeNullOrEmpty
            }
        }

        It 'should produce errors for non-existent file path' {
            InModuleScope MCP.SDK {
                # Arrange
                $nonExistentPath = Join-Path $TestDrive 'does-not-exist.ps1'

                # Act & Assert
                # The function doesn't throw terminating errors but generates non-terminating errors
                $result = Get-ToolSignature -Path $nonExistentPath -ErrorAction SilentlyContinue -ErrorVariable errors

                # Should have generated errors
                $errors.Count | Should -BeGreaterThan 0
            }
        }
    }
}
