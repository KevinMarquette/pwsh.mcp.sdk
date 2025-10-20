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

        It 'should return <Description>' -TestCases @(
            @{ Description = "title from synopsis"; ToolPath = "tool-with-synopsis.ps1"; Synopsis = "Tool Synopsis Title"; ToolDescription = "Tool description"; ExpectedName = "tool-with-synopsis"; ExpectedTitle = "Tool Synopsis Title"; ExpectedType = "object"; }
            @{ Description = "tool name from file basename"; ToolPath = "My-Custom-Tool.ps1"; Synopsis = "Test"; ToolDescription = "Test"; ExpectedName = "My-Custom-Tool"; ExpectedType = "object";  ExpectedTitle = "Test" }
            @{ Description = "tools with no parameters"; ToolPath = "no-params-tool.ps1"; Synopsis = "No params"; ToolDescription = "Tool with no parameters"; ExpectedName = "no-params-tool";  ExpectedType = "object"; ExpectedTitle = "No params" }
        ) {
            param($Description, $ToolPath, $Synopsis, $ToolDescription, $ExpectedName, $ExpectedType, $ExpectedTitle)

            InModuleScope MCP.SDK -Parameters ([hashtable]$PSBoundParameters) {
                # Arrange
                $toolPath = Join-Path $TestDrive $ToolPath
                New-TestTool -Path $toolPath -Synopsis $Synopsis -Description $ToolDescription

                # Act
                $result = Get-ToolSignature -Path $toolPath

                # Assert
                $result | Should -Not -BeNullOrEmpty
                $result.name | Should -Be $ExpectedName
                $result.description | Should -Be $ToolDescription
                $result.inputSchema | Should -Not -BeNullOrEmpty
                $result.inputSchema.type | Should -Be $ExpectedType
                $result.inputSchema.properties | Should -Not -BeNullOrEmpty
                $result.title | Should -Be $ExpectedTitle
            }
        }
    }

    Context 'Parameter Detection' {

        It 'should detect <Description>' -TestCases @(
            @{ Description = "mandatory string parameter"; ToolPath = "mandatory-string-tool.ps1"; ParamName = "TestParam"; ParamType = "string"; ParamMandatory = $true; ParamDescription = "A test parameter" }
            @{ Description = "optional parameter without default value"; ToolPath = "optional-tool.ps1"; ParamName = "OptionalParam"; ParamType = "string"; ParamMandatory = $false; ParamDescription = "Optional parameter" }
            @{ Description = "integer parameter type"; ToolPath = "int-tool.ps1"; ParamName = "Count"; ParamType = "Int32"; ParamMandatory = $true; ParamDescription = "Count value" }
            @{ Description = "boolean parameter type"; ToolPath = "bool-tool.ps1"; ParamName = "Enabled"; ParamType = "Boolean"; ParamMandatory = $false; ParamDescription = "Enable feature" }
            @{ Description = "array parameter type"; ToolPath = "array-tool.ps1"; ParamName = "Items"; ParamType = "string[]"; ParamMandatory = $false; ParamDescription = "List of items" }
        ) {
            param($Description, $ToolPath, $ParamName, $ParamType, $ParamMandatory, $ParamDescription)

            InModuleScope MCP.SDK -Parameters ([hashtable]$PSBoundParameters) {
                # Arrange
                $toolPath = Join-Path $TestDrive $ToolPath
                New-TestTool -Path $toolPath -Synopsis "Test" -Description "Test" -Parameters @(
                    @{ Name = $ParamName; Type = $ParamType; Mandatory = $ParamMandatory; Description = $ParamDescription }
                )

                # Act
                $result = Get-ToolSignature -Path $toolPath

                # Assert
                $result.inputSchema.properties.$ParamName | Should -Not -BeNullOrEmpty
                
                # Determine expected type based on PowerShell parameter type
                $expectedType = switch ($ParamType) {
                    "Int32" { "integer" }
                    "Int64" { "integer" }
                    "Boolean" { "boolean" }
                    "SwitchParameter" { "boolean" }
                    default { $ParamType }
                }
                
                # For array types, check the items.type
                if ($ParamType -match "(?<type>.+)\[\]$") {
                    $result.inputSchema.properties.$ParamName.type | Should -Be "array"
                    $result.inputSchema.properties.$ParamName.items.type | Should -Be $matches.type
                }
                else {
                    $result.inputSchema.properties.$ParamName.type | Should -Be $expectedType
                }
                
                if ($ParamDescription) {
                    $result.inputSchema.properties.$ParamName.description | Should -Be $ParamDescription
                }
            }
        }
    }

    Context 'ValidateSet Enum Handling' {

        It 'should detect <Description>' -TestCases @(
            @{ Description = "ValidateSet as enum for string parameters"; ToolPath = "enum-tool.ps1"; ParamName = "Level"; ParamType = "string"; ParamMandatory = $true; ParamDescription = "Level"; ValidateSet = @('Low', 'Medium', 'High'); ExpectedPropertiesCount = 1 }
            @{ Description = "ValidateSet as enum for array parameters"; ToolPath = "enum-array-tool.ps1"; ParamName = "Options"; ParamType = "string[]"; ParamMandatory = $false; ParamDescription = "Options"; ValidateSet = @('Option1', 'Option2', 'Option3'); ExpectedPropertiesCount = 1 }
        ) {
            param($Description, $ToolPath, $ParamName, $ParamType, $ParamMandatory, $ParamDescription, $ValidateSet, $ExpectedPropertiesCount)

            InModuleScope MCP.SDK -Parameters ([hashtable]$PSBoundParameters) {
                # Arrange
                $toolPath = Join-Path $TestDrive $ToolPath
                New-TestTool -Path $toolPath -Synopsis "Test" -Description "Test" -Parameters @(
                    @{ Name = $ParamName; Type = $ParamType; Mandatory = $ParamMandatory; Description = $ParamDescription; ValidateSet = $ValidateSet }
                )

                # Act
                $result = Get-ToolSignature -Path $toolPath

                # Assert
                if ($ParamType -eq "string") {
                    $result.inputSchema.properties.$ParamName.enum | Should -Not -BeNullOrEmpty
                    $result.inputSchema.properties.$ParamName.enum | Should -Contain 'Low'
                    $result.inputSchema.properties.$ParamName.enum | Should -Contain 'Medium'
                    $result.inputSchema.properties.$ParamName.enum | Should -Contain 'High'
                }
                else {
                    $result.inputSchema.properties.$ParamName.type | Should -Be 'array'
                    $result.inputSchema.properties.$ParamName.items.enum | Should -Not -BeNullOrEmpty
                    $result.inputSchema.properties.$ParamName.items.enum | Should -Contain 'Option1'
                    $result.inputSchema.properties.$ParamName.items.enum | Should -Contain 'Option2'
                    $result.inputSchema.properties.$ParamName.items.enum | Should -Contain 'Option3'
                }
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
