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

Write-Output "Test prompt execution"
"@

            New-Item -Path (Split-Path $Path -Parent) -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
            $content | Set-Content -Path $Path -NoNewline
            return $Path
        }
    }
}

Describe 'Get-PromptList' -Tag 'Unit' {

    Context 'Basic Functionality' {

        It 'should return a hashtable with prompts key' {
            InModuleScope MCP.SDK {
                # Arrange
                $mcpRoot = Join-Path $TestDrive 'basic-server'
                $promptsPath = Join-Path $mcpRoot 'prompts'
                New-Item -Path $promptsPath -ItemType Directory -Force | Out-Null
                New-TestPrompt -Path (Join-Path $promptsPath 'Prompt1.ps1') -Synopsis "Prompt 1" -Description "First prompt"

                # Act
                $result = Get-PromptList -MCPRoot $mcpRoot

                # Assert
                $result | Should -Not -BeNullOrEmpty
                $result.Keys | Should -Contain 'prompts'
            }
        }

        It 'should return prompts as an array' {
            InModuleScope MCP.SDK {
                # Arrange
                $mcpRoot = Join-Path $TestDrive 'array-server'
                $promptsPath = Join-Path $mcpRoot 'prompts'
                New-Item -Path $promptsPath -ItemType Directory -Force | Out-Null
                New-TestPrompt -Path (Join-Path $promptsPath 'Prompt1.ps1') -Synopsis "Prompt 1"
                New-TestPrompt -Path (Join-Path $promptsPath 'Prompt2.ps1') -Synopsis "Prompt 2"

                # Act
                $result = Get-PromptList -MCPRoot $mcpRoot

                # Assert
                @($result.prompts).Count | Should -Be 2
            }
        }

        It 'should return empty array when no prompts exist' {
            InModuleScope MCP.SDK {
                # Arrange
                $mcpRoot = Join-Path $TestDrive 'empty-server'
                $promptsPath = Join-Path $mcpRoot 'prompts'
                New-Item -Path $promptsPath -ItemType Directory -Force | Out-Null

                # Act
                $result = Get-PromptList -MCPRoot $mcpRoot

                # Assert
                @($result.prompts).Count | Should -Be 0
            }
        }

        It 'should only include .ps1 files from prompts directory' {
            InModuleScope MCP.SDK {
                # Arrange
                $mcpRoot = Join-Path $TestDrive 'filter-server'
                $promptsPath = Join-Path $mcpRoot 'prompts'
                New-Item -Path $promptsPath -ItemType Directory -Force | Out-Null
                New-TestPrompt -Path (Join-Path $promptsPath 'Valid.ps1') -Synopsis "Valid prompt"
                "Not a PowerShell file" | Set-Content (Join-Path $promptsPath 'readme.txt')
                "Also not a PowerShell file" | Set-Content (Join-Path $promptsPath 'config.json')

                # Act
                $result = Get-PromptList -MCPRoot $mcpRoot

                # Assert
                @($result.prompts).Count | Should -Be 1
                $result.prompts[0].name | Should -Be 'Valid'
            }
        }

        It 'should not recurse into subdirectories' {
            InModuleScope MCP.SDK {
                # Arrange
                $mcpRoot = Join-Path $TestDrive 'norecurse-server'
                $promptsPath = Join-Path $mcpRoot 'prompts'
                $subPath = Join-Path $promptsPath 'subdir'
                New-Item -Path $subPath -ItemType Directory -Force | Out-Null
                New-TestPrompt -Path (Join-Path $promptsPath 'TopLevel.ps1') -Synopsis "Top level"
                New-TestPrompt -Path (Join-Path $subPath 'Nested.ps1') -Synopsis "Nested"

                # Act
                $result = Get-PromptList -MCPRoot $mcpRoot

                # Assert
                @($result.prompts).Count | Should -Be 1
                $result.prompts[0].name | Should -Be 'TopLevel'
            }
        }

        It 'should work when prompts directory does not exist' {
            InModuleScope MCP.SDK {
                # Arrange
                $mcpRoot = Join-Path $TestDrive 'noprompts-server'
                New-Item -Path $mcpRoot -ItemType Directory -Force | Out-Null

                # Act & Assert
                { Get-PromptList -MCPRoot $mcpRoot } | Should -Not -Throw
            }
        }
    }

    Context 'Prompt Ordering' {

        It 'should return prompts in alphabetical order by filename' {
            InModuleScope MCP.SDK {
                # Arrange
                $mcpRoot = Join-Path $TestDrive 'ordered-server'
                $promptsPath = Join-Path $mcpRoot 'prompts'
                New-Item -Path $promptsPath -ItemType Directory -Force | Out-Null
                New-TestPrompt -Path (Join-Path $promptsPath 'Zebra.ps1') -Synopsis "Last"
                New-TestPrompt -Path (Join-Path $promptsPath 'Alpha.ps1') -Synopsis "First"
                New-TestPrompt -Path (Join-Path $promptsPath 'Middle.ps1') -Synopsis "Middle"

                # Act
                $result = Get-PromptList -MCPRoot $mcpRoot

                # Assert
                $result.prompts[0].name | Should -Be 'Alpha'
                $result.prompts[1].name | Should -Be 'Middle'
                $result.prompts[2].name | Should -Be 'Zebra'
            }
        }
    }

    Context 'Parameter Validation' {

        It 'should accept valid MCPRoot path' {
            InModuleScope MCP.SDK {
                # Arrange
                $mcpRoot = Join-Path $TestDrive 'valid-server'
                $promptsPath = Join-Path $mcpRoot 'prompts'
                New-Item -Path $promptsPath -ItemType Directory -Force | Out-Null

                # Act & Assert
                { Get-PromptList -MCPRoot $mcpRoot } | Should -Not -Throw
            }
        }
    }

    Context 'Integration with Get-PromptSignature' {

        It 'should include expected signature properties for each prompt' {
            InModuleScope MCP.SDK {
                # Arrange
                $mcpRoot = Join-Path $TestDrive 'signature-server'
                $promptsPath = Join-Path $mcpRoot 'prompts'
                New-Item -Path $promptsPath -ItemType Directory -Force | Out-Null
                New-TestPrompt -Path (Join-Path $promptsPath 'Test.ps1') -Synopsis "Test" `
                    -Parameters @(@{Name='Param1'; Type='string'; Mandatory=$true; Description='Test parameter'})

                # Act
                $result = Get-PromptList -MCPRoot $mcpRoot

                # Assert
                $prompt = $result.prompts[0]
                $prompt.Keys | Should -Contain 'name'
                $prompt.Keys | Should -Contain 'arguments'
            }
        }

        It 'should include argument information in signatures' {
            InModuleScope MCP.SDK {
                # Arrange
                $mcpRoot = Join-Path $TestDrive 'args-server'
                $promptsPath = Join-Path $mcpRoot 'prompts'
                New-Item -Path $promptsPath -ItemType Directory -Force | Out-Null
                New-TestPrompt -Path (Join-Path $promptsPath 'WithArgs.ps1') -Synopsis "Has arguments" `
                    -Parameters @(
                        @{Name='Required'; Type='string'; Mandatory=$true; Description='Required arg'},
                        @{Name='Optional'; Type='int'; Mandatory=$false; Description='Optional arg'}
                    )

                # Act
                $result = Get-PromptList -MCPRoot $mcpRoot

                # Assert
                $prompt = $result.prompts[0]
                @($prompt.arguments).Count | Should -Be 2
                $prompt.arguments[0].name | Should -Be 'Required'
                $prompt.arguments[0].required | Should -Be $true
                $prompt.arguments[1].name | Should -Be 'Optional'
                $prompt.arguments[1].required | Should -Be $false
            }
        }
    }

    Context 'Integration with reference-server' {

        It 'should successfully retrieve prompts from reference-server' {
            InModuleScope MCP.SDK {
                # Arrange
                $refServerPath = Join-Path $PSScriptRoot '..\..\Examples\reference-server'

                # Act & Assert
                if (Test-Path $refServerPath) {
                    $result = Get-PromptList -MCPRoot $refServerPath
                    @($result.prompts).Count | Should -BeGreaterThan 0
                }
            }
        }

        It 'should have required properties for reference-server prompts' {
            InModuleScope MCP.SDK {
                # Arrange
                $refServerPath = Join-Path $PSScriptRoot '..\..\Examples\reference-server'

                # Act & Assert
                if (Test-Path $refServerPath) {
                    $result = Get-PromptList -MCPRoot $refServerPath
                    foreach ($prompt in $result.prompts) {
                        $prompt.Keys | Should -Contain 'name'
                        $prompt.name | Should -Not -BeNullOrEmpty
                    }
                }
            }
        }
    }

    Context 'Return Structure' {

        It 'should return correct structure for single prompt' {
            InModuleScope MCP.SDK {
                # Arrange
                $mcpRoot = Join-Path $TestDrive 'single-server'
                $promptsPath = Join-Path $mcpRoot 'prompts'
                New-Item -Path $promptsPath -ItemType Directory -Force | Out-Null
                New-TestPrompt -Path (Join-Path $promptsPath 'Single.ps1') -Synopsis "Single prompt"

                # Act
                $result = Get-PromptList -MCPRoot $mcpRoot

                # Assert
                $result | Should -BeOfType [hashtable]
                $result.prompts | Should -Not -BeNullOrEmpty
                @($result.prompts).Count | Should -Be 1
            }
        }

        It 'should return correct structure for multiple prompts' {
            InModuleScope MCP.SDK {
                # Arrange
                $mcpRoot = Join-Path $TestDrive 'multiple-server'
                $promptsPath = Join-Path $mcpRoot 'prompts'
                New-Item -Path $promptsPath -ItemType Directory -Force | Out-Null
                New-TestPrompt -Path (Join-Path $promptsPath 'First.ps1') -Synopsis "First"
                New-TestPrompt -Path (Join-Path $promptsPath 'Second.ps1') -Synopsis "Second"
                New-TestPrompt -Path (Join-Path $promptsPath 'Third.ps1') -Synopsis "Third"

                # Act
                $result = Get-PromptList -MCPRoot $mcpRoot

                # Assert
                $result | Should -BeOfType [hashtable]
                @($result.prompts).Count | Should -Be 3
            }
        }

        It 'should return correct structure when no prompts exist' {
            InModuleScope MCP.SDK {
                # Arrange
                $mcpRoot = Join-Path $TestDrive 'noprompts-structure'
                $promptsPath = Join-Path $mcpRoot 'prompts'
                New-Item -Path $promptsPath -ItemType Directory -Force | Out-Null

                # Act
                $result = Get-PromptList -MCPRoot $mcpRoot

                # Assert
                $result | Should -BeOfType [hashtable]
                $result.Keys | Should -Contain 'prompts'
                @($result.prompts).Count | Should -Be 0
            }
        }
    }

    Context 'Edge Cases and Error Handling' {

        It 'should handle empty prompts directory gracefully' {
            InModuleScope MCP.SDK {
                # Arrange
                $mcpRoot = Join-Path $TestDrive 'empty-edge'
                $promptsPath = Join-Path $mcpRoot 'prompts'
                New-Item -Path $promptsPath -ItemType Directory -Force | Out-Null

                # Act
                $result = Get-PromptList -MCPRoot $mcpRoot

                # Assert
                $result.Keys | Should -Contain 'prompts'
                @($result.prompts).Count | Should -Be 0
            }
        }

        It 'should handle missing prompts directory gracefully' {
            InModuleScope MCP.SDK {
                # Arrange
                $mcpRoot = Join-Path $TestDrive 'missing-dir'
                New-Item -Path $mcpRoot -ItemType Directory -Force | Out-Null

                # Act & Assert
                { Get-PromptList -MCPRoot $mcpRoot } | Should -Not -Throw
            }
        }

        It 'should handle prompt files with no parameters' {
            InModuleScope MCP.SDK {
                # Arrange
                $mcpRoot = Join-Path $TestDrive 'noparams-server'
                $promptsPath = Join-Path $mcpRoot 'prompts'
                New-Item -Path $promptsPath -ItemType Directory -Force | Out-Null
                New-TestPrompt -Path (Join-Path $promptsPath 'NoParams.ps1') -Synopsis "No parameters"

                # Act
                $result = Get-PromptList -MCPRoot $mcpRoot

                # Assert
                @($result.prompts).Count | Should -Be 1
                $result.prompts[0].name | Should -Be 'NoParams'
                @($result.prompts[0].arguments).Count | Should -Be 0
            }
        }

        It 'should return consistent structure across multiple calls' {
            InModuleScope MCP.SDK {
                # Arrange
                $mcpRoot = Join-Path $TestDrive 'consistent-server'
                $promptsPath = Join-Path $mcpRoot 'prompts'
                New-Item -Path $promptsPath -ItemType Directory -Force | Out-Null
                New-TestPrompt -Path (Join-Path $promptsPath 'Consistent.ps1') -Synopsis "Consistent"

                # Act
                $result1 = Get-PromptList -MCPRoot $mcpRoot
                $result2 = Get-PromptList -MCPRoot $mcpRoot

                # Assert
                $result1.Keys | Should -Be $result2.Keys
                @($result1.prompts).Count | Should -Be @($result2.prompts).Count
            }
        }
    }
}
