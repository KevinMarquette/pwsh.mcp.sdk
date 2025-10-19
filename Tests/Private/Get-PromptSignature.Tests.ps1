BeforeAll {
    # Import the module
    $ModuleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $ModulePath = Join-Path $ModuleRoot 'MCP.SDK\MCP.SDK.psd1'
    Import-Module $ModulePath -Force

    InModuleScope MCP.SDK {
        # Helper function to create test prompt scripts
        function Script:New-TestPrompt {
            param(
                [string]$Path,
                [string]$Synopsis = "Test prompt synopsis",
                [string]$Description = "Test prompt description",
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

"# Generated prompt output"
"@

            New-Item -Path (Split-Path $Path -Parent) -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
            $content | Set-Content -Path $Path -NoNewline
            return $Path
        }
    }
}

Describe 'Get-PromptSignature' -Tag 'Unit' {

    Context 'Basic Functionality' {

        It 'should return a valid prompt signature structure' {
            InModuleScope MCP.SDK {
                # Arrange
                $promptPath = Join-Path $TestDrive 'basic-prompt.ps1'
                New-TestPrompt -Path $promptPath -Synopsis "Basic prompt" -Description "A basic test prompt"

                # Act
                $result = Get-PromptSignature -Path $promptPath

                # Assert
                $result | Should -Not -BeNullOrEmpty
                $result.name | Should -Be 'basic-prompt'
                $result.description | Should -Be "A basic test prompt"
                $result.Keys | Should -Contain 'arguments'
            }
        }

        It 'should include title from synopsis' {
            InModuleScope MCP.SDK {
                # Arrange
                $promptPath = Join-Path $TestDrive 'prompt-with-synopsis.ps1'
                New-TestPrompt -Path $promptPath -Synopsis "Prompt Synopsis Title" -Description "Prompt description"

                # Act
                $result = Get-PromptSignature -Path $promptPath

                # Assert
                $result.title | Should -Be "Prompt Synopsis Title"
            }
        }

        It 'should extract prompt name from file basename' {
            InModuleScope MCP.SDK {
                # Arrange
                $promptPath = Join-Path $TestDrive 'My-Custom-Prompt.ps1'
                New-TestPrompt -Path $promptPath -Synopsis "Test" -Description "Test"

                # Act
                $result = Get-PromptSignature -Path $promptPath

                # Assert
                $result.name | Should -Be 'My-Custom-Prompt'
            }
        }

        It 'should handle prompts with no parameters' {
            InModuleScope MCP.SDK {
                # Arrange
                $promptPath = Join-Path $TestDrive 'no-params-prompt.ps1'
                New-TestPrompt -Path $promptPath -Synopsis "No params" -Description "Prompt with no parameters" -Parameters @()

                # Act
                $result = Get-PromptSignature -Path $promptPath

                # Assert
                $result.Keys | Should -Contain 'arguments'
                # When there are no parameters, arguments will be an empty array
                if ($result.arguments) {
                    @($result.arguments).Count | Should -Be 0
                }
            }
        }

        It 'should include description when provided' {
            InModuleScope MCP.SDK {
                # Arrange
                $promptPath = Join-Path $TestDrive 'described-prompt.ps1'
                New-TestPrompt -Path $promptPath -Synopsis "Test" -Description "Detailed description of the prompt"

                # Act
                $result = Get-PromptSignature -Path $promptPath

                # Assert
                $result.description | Should -Be "Detailed description of the prompt"
            }
        }
    }

    Context 'Argument Detection' {

        It 'should detect mandatory string argument' {
            InModuleScope MCP.SDK {
                # Arrange
                $promptPath = Join-Path $TestDrive 'mandatory-string-prompt.ps1'
                New-TestPrompt -Path $promptPath -Synopsis "Test" -Description "Test" -Parameters @(
                    @{ Name = 'TestArg'; Type = 'string'; Mandatory = $true; Description = 'A test argument' }
                )

                # Act
                $result = Get-PromptSignature -Path $promptPath

                # Assert
                $result.arguments.Count | Should -Be 1
                $result.arguments[0].name | Should -Be 'TestArg'
                $result.arguments[0].required | Should -Be $true
                $result.arguments[0].description | Should -Be 'A test argument'
            }
        }

        It 'should detect optional argument' {
            InModuleScope MCP.SDK {
                # Arrange
                $promptPath = Join-Path $TestDrive 'optional-prompt.ps1'
                New-TestPrompt -Path $promptPath -Synopsis "Test" -Description "Test" -Parameters @(
                    @{ Name = 'OptionalArg'; Type = 'string'; Mandatory = $false; Description = 'Optional argument' }
                )

                # Act
                $result = Get-PromptSignature -Path $promptPath

                # Assert
                $result.arguments.Count | Should -Be 1
                $result.arguments[0].name | Should -Be 'OptionalArg'
                $result.arguments[0].required | Should -Be $false
            }
        }

        It 'should detect boolean argument' {
            InModuleScope MCP.SDK {
                # Arrange
                $promptPath = Join-Path $TestDrive 'bool-prompt.ps1'
                New-TestPrompt -Path $promptPath -Synopsis "Test" -Description "Test" -Parameters @(
                    @{ Name = 'Enabled'; Type = 'bool'; Mandatory = $false; Description = 'Enable feature' }
                )

                # Act
                $result = Get-PromptSignature -Path $promptPath

                # Assert
                $result.arguments[0].name | Should -Be 'Enabled'
                $result.arguments[0].description | Should -Be 'Enable feature'
            }
        }

        It 'should detect multiple arguments' {
            InModuleScope MCP.SDK {
                # Arrange
                $promptPath = Join-Path $TestDrive 'multi-arg-prompt.ps1'
                New-TestPrompt -Path $promptPath -Synopsis "Test" -Description "Test" -Parameters @(
                    @{ Name = 'Title'; Type = 'string'; Mandatory = $true; Description = 'Title argument' }
                    @{ Name = 'Count'; Type = 'int'; Mandatory = $false; Description = 'Count argument' }
                    @{ Name = 'Active'; Type = 'bool'; Mandatory = $false; Description = 'Active argument' }
                )

                # Act
                $result = Get-PromptSignature -Path $promptPath

                # Assert
                $result.arguments.Count | Should -Be 3
                $result.arguments[0].name | Should -Be 'Title'
                $result.arguments[0].required | Should -Be $true
                $result.arguments[1].name | Should -Be 'Count'
                $result.arguments[1].required | Should -Be $false
                $result.arguments[2].name | Should -Be 'Active'
                $result.arguments[2].required | Should -Be $false
            }
        }

        It 'should handle argument with no description' {
            InModuleScope MCP.SDK {
                # Arrange
                $promptPath = Join-Path $TestDrive 'no-desc-arg.ps1'
                @'
<#
.SYNOPSIS
Test prompt

.DESCRIPTION
Test description
#>
param(
    [Parameter(Mandatory)]
    [string]$Arg1
)
'@ | Set-Content -Path $promptPath -NoNewline

                # Act
                $result = Get-PromptSignature -Path $promptPath

                # Assert
                $result.arguments.Count | Should -Be 1
                $result.arguments[0].name | Should -Be 'Arg1'
            }
        }
    }

    Context 'ValidateSet Enum Handling' {

        It 'should append ValidateSet values to argument description' {
            InModuleScope MCP.SDK {
                # Arrange
                $promptPath = Join-Path $TestDrive 'enum-prompt.ps1'
                New-TestPrompt -Path $promptPath -Synopsis "Test" -Description "Test" -Parameters @(
                    @{ Name = 'Level'; Type = 'string'; Mandatory = $true; Description = 'Level'; ValidateSet = @('Low', 'Medium', 'High') }
                )

                # Act
                $result = Get-PromptSignature -Path $promptPath

                # Assert
                $result.arguments[0].description | Should -Match 'Level'
                $result.arguments[0].description | Should -Match '\. Valid Values \[Low,Medium,High\]'
            }
        }

        It 'should handle ValidateSet for optional arguments' {
            InModuleScope MCP.SDK {
                # Arrange
                $promptPath = Join-Path $TestDrive 'enum-optional-prompt.ps1'
                New-TestPrompt -Path $promptPath -Synopsis "Test" -Description "Test" -Parameters @(
                    @{ Name = 'Priority'; Type = 'string'; Mandatory = $false; Description = 'Priority level'; ValidateSet = @('P1', 'P2', 'P3', 'P4') }
                )

                # Act
                $result = Get-PromptSignature -Path $promptPath

                # Assert
                $result.arguments[0].description | Should -Match 'Priority level\. Valid Values \[P1,P2,P3,P4\]'
                $result.arguments[0].required | Should -Be $false
            }
        }

        It 'should handle argument with ValidateSet but no description' {
            InModuleScope MCP.SDK {
                # Arrange
                $promptPath = Join-Path $TestDrive 'enum-no-desc.ps1'
                @'
<#
.SYNOPSIS
Test prompt

.DESCRIPTION
Test description
#>
param(
    [Parameter(Mandatory)]
    [ValidateSet('Option1', 'Option2')]
    [string]$Choice
)
'@ | Set-Content -Path $promptPath -NoNewline

                # Act
                $result = Get-PromptSignature -Path $promptPath

                # Assert
                $result.arguments[0].description | Should -Match '\. Valid Values \[Option1,Option2\]'
            }
        }
    }

    Context 'Pipeline Support' {

        It 'should accept Path parameter' {
            InModuleScope MCP.SDK {
                # Arrange
                $promptPath = Join-Path $TestDrive 'pipeline-test.ps1'
                New-TestPrompt -Path $promptPath -Synopsis "Test" -Description "Test"

                # Act & Assert
                { Get-PromptSignature -Path $promptPath } | Should -Not -Throw
            }
        }

        It 'should accept pipeline input from Get-ChildItem' {
            InModuleScope MCP.SDK {
                # Arrange
                $promptsDir = Join-Path $TestDrive 'pipeline-prompts'
                New-Item -Path $promptsDir -ItemType Directory -Force | Out-Null
                New-TestPrompt -Path (Join-Path $promptsDir 'Prompt1.ps1') -Synopsis "Prompt 1" -Description "First prompt"
                New-TestPrompt -Path (Join-Path $promptsDir 'Prompt2.ps1') -Synopsis "Prompt 2" -Description "Second prompt"

                # Act
                $results = Get-ChildItem -Path $promptsDir -Filter '*.ps1' | Get-PromptSignature

                # Assert
                $results.Count | Should -Be 2
                $results[0].name | Should -BeIn @('Prompt1', 'Prompt2')
                $results[1].name | Should -BeIn @('Prompt1', 'Prompt2')
            }
        }
    }

    Context 'Integration with reference-server' {

        It 'should correctly parse Incident-Response-Plan prompt from reference-server' {
            InModuleScope MCP.SDK {
                # Arrange
                $referenceServerPath = Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))) 'Examples\reference-server\prompts\Incident-Response-Plan.ps1'

                if (Test-Path $referenceServerPath) {
                    # Act
                    $result = Get-PromptSignature -Path $referenceServerPath

                    # Assert
                    $result.name | Should -Be 'Incident-Response-Plan'
                    $result.title | Should -Be 'Generates a customized incident response plan based on severity and type'
                    $result.description | Should -Match 'Creates a detailed incident response plan'

                    # Check arguments
                    $result.arguments.Count | Should -BeGreaterThan 0

                    # Check for specific required arguments
                    $incidentTypeArg = $result.arguments | Where-Object { $_.name -eq 'IncidentType' }
                    $incidentTypeArg | Should -Not -BeNullOrEmpty
                    $incidentTypeArg.required | Should -Be $true
                    $incidentTypeArg.description | Should -Match 'Valid Values \[Security,Performance,Outage,DataLoss\]'

                    $severityArg = $result.arguments | Where-Object { $_.name -eq 'Severity' }
                    $severityArg | Should -Not -BeNullOrEmpty
                    $severityArg.required | Should -Be $true
                    $severityArg.description | Should -Match 'Valid Values \[Low,Medium,High,Critical\]'

                    # Check for optional arguments
                    $contactsArg = $result.arguments | Where-Object { $_.name -eq 'IncludeContacts' }
                    $contactsArg | Should -Not -BeNullOrEmpty
                    $contactsArg.required | Should -Be $false

                    $hoursArg = $result.arguments | Where-Object { $_.name -eq 'BusinessHours' }
                    $hoursArg | Should -Not -BeNullOrEmpty
                    $hoursArg.required | Should -Be $false
                }
            }
        }

        It 'should correctly parse Status-Update-Template prompt from reference-server' {
            InModuleScope MCP.SDK {
                # Arrange
                $referenceServerPath = Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))) 'Examples\reference-server\prompts\Status-Update-Template.ps1'

                if (Test-Path $referenceServerPath) {
                    # Act
                    $result = Get-PromptSignature -Path $referenceServerPath

                    # Assert
                    $result.name | Should -Be 'Status-Update-Template'
                    $result.title | Should -Match 'status update'
                    $result.arguments.Count | Should -BeGreaterThan 0

                    # Check for required arguments
                    $incidentIdArg = $result.arguments | Where-Object { $_.name -eq 'IncidentId' }
                    $incidentIdArg | Should -Not -BeNullOrEmpty
                    $incidentIdArg.required | Should -Be $true

                    $summaryArg = $result.arguments | Where-Object { $_.name -eq 'Summary' }
                    $summaryArg | Should -Not -BeNullOrEmpty
                    $summaryArg.required | Should -Be $true

                    # Check for optional argument
                    $updatedByArg = $result.arguments | Where-Object { $_.name -eq 'UpdatedBy' }
                    $updatedByArg | Should -Not -BeNullOrEmpty
                    $updatedByArg.required | Should -Be $false
                }
            }
        }

        It 'should correctly parse Post-Mortem-Template prompt from reference-server' {
            InModuleScope MCP.SDK {
                # Arrange
                $referenceServerPath = Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))) 'Examples\reference-server\prompts\Post-Mortem-Template.ps1'

                if (Test-Path $referenceServerPath) {
                    # Act
                    $result = Get-PromptSignature -Path $referenceServerPath

                    # Assert
                    $result.name | Should -Be 'Post-Mortem-Template'
                    $result.arguments | Should -Not -BeNullOrEmpty
                }
            }
        }
    }

    Context 'Return Structure Validation' {

        It 'should return an ordered hashtable' {
            InModuleScope MCP.SDK {
                # Arrange
                $promptPath = Join-Path $TestDrive 'ordered-test.ps1'
                New-TestPrompt -Path $promptPath -Synopsis "Test" -Description "Test"

                # Act
                $result = Get-PromptSignature -Path $promptPath

                # Assert
                $result | Should -BeOfType [System.Collections.Specialized.OrderedDictionary]
            }
        }

        It 'should have correct top-level keys' {
            InModuleScope MCP.SDK {
                # Arrange
                $promptPath = Join-Path $TestDrive 'keys-test.ps1'
                New-TestPrompt -Path $promptPath -Synopsis "Test" -Description "Test" -Parameters @(
                    @{ Name = 'Arg1'; Type = 'string'; Mandatory = $true; Description = 'Test arg' }
                )

                # Act
                $result = Get-PromptSignature -Path $promptPath

                # Assert
                $result.Keys | Should -Contain 'name'
                $result.Keys | Should -Contain 'title'
                $result.Keys | Should -Contain 'description'
                $result.Keys | Should -Contain 'arguments'
            }
        }

        It 'should have arguments as array' {
            InModuleScope MCP.SDK {
                # Arrange
                $promptPath = Join-Path $TestDrive 'args-array-test.ps1'
                New-TestPrompt -Path $promptPath -Synopsis "Test" -Description "Test" -Parameters @(
                    @{ Name = 'Arg1'; Type = 'string'; Mandatory = $true; Description = 'Test arg' }
                )

                # Act
                $result = Get-PromptSignature -Path $promptPath

                # Assert
                $result.arguments | Should -Not -BeNullOrEmpty
                @($result.arguments).Count | Should -BeGreaterThan 0
            }
        }

        It 'should have ordered hashtable for each argument' {
            InModuleScope MCP.SDK {
                # Arrange
                $promptPath = Join-Path $TestDrive 'arg-ordered-test.ps1'
                New-TestPrompt -Path $promptPath -Synopsis "Test" -Description "Test" -Parameters @(
                    @{ Name = 'TestArg'; Type = 'string'; Mandatory = $true; Description = 'Test argument' }
                )

                # Act
                $result = Get-PromptSignature -Path $promptPath

                # Assert
                $result.arguments[0] | Should -BeOfType [System.Collections.Specialized.OrderedDictionary]
                $result.arguments[0].Keys | Should -Contain 'name'
                $result.arguments[0].Keys | Should -Contain 'required'
                $result.arguments[0].Keys | Should -Contain 'description'
            }
        }

        It 'should have name as first key in response' {
            InModuleScope MCP.SDK {
                # Arrange
                $promptPath = Join-Path $TestDrive 'first-key-test.ps1'
                New-TestPrompt -Path $promptPath -Synopsis "Test" -Description "Test"

                # Act
                $result = Get-PromptSignature -Path $promptPath

                # Assert
                $result.Keys | Select-Object -First 1 | Should -Be 'name'
            }
        }
    }

    Context 'Edge Cases and Error Handling' {

        It 'should handle prompt with minimal help documentation' {
            InModuleScope MCP.SDK {
                # Arrange
                $promptPath = Join-Path $TestDrive 'minimal-doc.ps1'
                @'
param([string]$Arg1)
"# Prompt output"
'@ | Set-Content -Path $promptPath -NoNewline

                # Act
                $result = Get-PromptSignature -Path $promptPath

                # Assert
                $result.name | Should -Be 'minimal-doc'
                $result | Should -Not -BeNullOrEmpty
            }
        }

        It 'should handle prompt without synopsis' {
            InModuleScope MCP.SDK {
                # Arrange
                $promptPath = Join-Path $TestDrive 'no-synopsis.ps1'
                @'
<#
.DESCRIPTION
Test description only
#>
param([string]$Arg1)
'@ | Set-Content -Path $promptPath -NoNewline

                # Act
                $result = Get-PromptSignature -Path $promptPath

                # Assert
                $result.description | Should -Be 'Test description only'
                $result.title | Should -BeNullOrEmpty
            }
        }

        It 'should handle prompt without description' {
            InModuleScope MCP.SDK {
                # Arrange
                $promptPath = Join-Path $TestDrive 'no-description.ps1'
                @'
<#
.SYNOPSIS
Test synopsis only
#>
param([string]$Arg1)
'@ | Set-Content -Path $promptPath -NoNewline

                # Act
                $result = Get-PromptSignature -Path $promptPath

                # Assert
                $result.title | Should -Be 'Test synopsis only'
                $result.description | Should -BeNullOrEmpty
            }
        }

        It 'should handle non-existent file path' {
            InModuleScope MCP.SDK {
                # Arrange
                $nonExistentPath = Join-Path $TestDrive 'does-not-exist.ps1'

                # Act
                # Function will process but produce a partial result with errors
                $result = Get-PromptSignature -Path $nonExistentPath -ErrorAction SilentlyContinue 2>&1

                # Assert - errors were generated during execution
                # The result will be incomplete but function doesn't throw
                $result | Should -Not -BeNullOrEmpty
            }
        }
    }
}
