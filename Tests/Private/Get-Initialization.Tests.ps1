BeforeAll {
    # Import the module
    $ModuleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $ModulePath = Join-Path $ModuleRoot 'MCP.SDK\MCP.SDK.psd1'
    Import-Module $ModulePath -Force

    InModuleScope MCP.SDK {
        # Helper function to create test directory structure
        function Script:New-TestMCPServer {
            param(
                [string]$BasePath,
                [switch]$IncludeTools,
                [switch]$IncludePrompts,
                [switch]$IncludeResources,
                [switch]$IncludeInstructions,
                [string]$InstructionsContent = "# Test Instructions`nThis is a test server."
            )

            New-Item -Path $BasePath -ItemType Directory -Force | Out-Null

            if ($IncludeTools) {
                $toolsPath = Join-Path $BasePath 'tools'
                New-Item -Path $toolsPath -ItemType Directory -Force | Out-Null
                $testTool = Join-Path $toolsPath 'Test-Tool.ps1'
                @'
<#
.SYNOPSIS
Test tool
#>
param([string]$TestParam)
Write-Output "Test"
'@ | Set-Content -Path $testTool
            }

            if ($IncludePrompts) {
                $promptsPath = Join-Path $BasePath 'prompts'
                New-Item -Path $promptsPath -ItemType Directory -Force | Out-Null
                $testPrompt = Join-Path $promptsPath 'Test-Prompt.ps1'
                @'
<#
.SYNOPSIS
Test prompt
#>
param([string]$TestParam)
"# Test Prompt"
'@ | Set-Content -Path $testPrompt
            }

            if ($IncludeResources) {
                $resourcesPath = Join-Path $BasePath 'resources'
                New-Item -Path $resourcesPath -ItemType Directory -Force | Out-Null
                $testResource = Join-Path $resourcesPath 'test-resource.txt'
                'Test resource content' | Set-Content -Path $testResource -NoNewline
            }

            if ($IncludeInstructions) {
                $instructionsPath = Join-Path $BasePath 'instructions.md'
                $InstructionsContent | Set-Content -Path $instructionsPath -NoNewline
            }

            return $BasePath
        }
    }
}

Describe 'Get-Initialization' -Tag 'Unit' {

    Context 'Basic Functionality' {

        It 'should return a valid initialization response structure' {
            InModuleScope MCP.SDK {
                # Arrange
                $testPath = Join-Path $TestDrive 'empty-server'
                New-Item -Path $testPath -ItemType Directory -Force | Out-Null

                # Act
                $result = Get-Initialization -MCPRoot $testPath

                # Assert
                $result | Should -Not -BeNullOrEmpty
                $result.protocolVersion | Should -Be '2024-11-05'
                $result.capabilities | Should -BeNullOrEmpty
                $result.serverInfo | Should -Not -BeNullOrEmpty
            }
        }

        It 'should include correct serverInfo structure' {
            InModuleScope MCP.SDK {
                # Arrange
                $testPath = Join-Path $TestDrive 'server-info-test'
                New-Item -Path $testPath -ItemType Directory -Force | Out-Null

                # Act
                $result = Get-Initialization -MCPRoot $testPath

                # Assert
                $result.serverInfo.name | Should -Be 'PowerShell'
                $result.serverInfo.title | Should -Be 'Example PowerShell Server'
                $result.serverInfo.version | Should -Be '1.0.0'
            }
        }

        It 'should have empty capabilities for server with no tools, prompts, or resources' {
            InModuleScope MCP.SDK {
                # Arrange
                $testPath = Join-Path $TestDrive 'no-capabilities'
                New-Item -Path $testPath -ItemType Directory -Force | Out-Null

                # Act
                $result = Get-Initialization -MCPRoot $testPath

                # Assert
                $result.capabilities.Keys.Count | Should -Be 0
                $result.capabilities.tools | Should -BeNullOrEmpty
                $result.capabilities.prompts | Should -BeNullOrEmpty
                $result.capabilities.resources | Should -BeNullOrEmpty
            }
        }
    }

    Context 'Tools Capability Detection' {

        It 'should detect tools capability when .ps1 files exist in tools directory' {
            InModuleScope MCP.SDK {
                # Arrange
                $testPath = New-TestMCPServer -BasePath (Join-Path $TestDrive 'server-with-tools') -IncludeTools

                # Act
                $result = Get-Initialization -MCPRoot $testPath

                # Assert
                $result.capabilities.tools | Should -BeOfType [hashtable]
            }
        }

        It 'should not detect tools capability when tools directory is empty' {
            InModuleScope MCP.SDK {
                # Arrange
                $testPath = Join-Path $TestDrive 'server-empty-tools'
                New-Item -Path $testPath -ItemType Directory -Force | Out-Null
                New-Item -Path (Join-Path $testPath 'tools') -ItemType Directory -Force | Out-Null

                # Act
                $result = Get-Initialization -MCPRoot $testPath

                # Assert
                $result.capabilities.tools | Should -BeNullOrEmpty
            }
        }

        It 'should not detect tools capability when tools directory does not exist' {
            InModuleScope MCP.SDK {
                # Arrange
                $testPath = Join-Path $TestDrive 'server-no-tools-dir'
                New-Item -Path $testPath -ItemType Directory -Force | Out-Null

                # Act
                $result = Get-Initialization -MCPRoot $testPath

                # Assert
                $result.capabilities.tools | Should -BeNullOrEmpty
            }
        }

        It 'should not detect tools capability when tools directory only has non-.ps1 files' {
            InModuleScope MCP.SDK {
                # Arrange
                $testPath = Join-Path $TestDrive 'server-tools-no-ps1'
                $toolsPath = Join-Path $testPath 'tools'
                New-Item -Path $toolsPath -ItemType Directory -Force | Out-Null
                'test' | Set-Content (Join-Path $toolsPath 'readme.txt')

                # Act
                $result = Get-Initialization -MCPRoot $testPath

                # Assert
                $result.capabilities.tools | Should -BeNullOrEmpty
            }
        }
    }

    Context 'Prompts Capability Detection' {

        It 'should detect prompts capability when .ps1 files exist in prompts directory' {
            InModuleScope MCP.SDK {
                # Arrange
                $testPath = New-TestMCPServer -BasePath (Join-Path $TestDrive 'server-with-prompts') -IncludePrompts

                # Act
                $result = Get-Initialization -MCPRoot $testPath

                # Assert
                $result.capabilities.prompts | Should -BeOfType [hashtable]
            }
        }

        It 'should not detect prompts capability when prompts directory is empty' {
            InModuleScope MCP.SDK {
                # Arrange
                $testPath = Join-Path $TestDrive 'server-empty-prompts'
                New-Item -Path $testPath -ItemType Directory -Force | Out-Null
                New-Item -Path (Join-Path $testPath 'prompts') -ItemType Directory -Force | Out-Null

                # Act
                $result = Get-Initialization -MCPRoot $testPath

                # Assert
                $result.capabilities.prompts | Should -BeNullOrEmpty
            }
        }

        It 'should not detect prompts capability when prompts directory does not exist' {
            InModuleScope MCP.SDK {
                # Arrange
                $testPath = Join-Path $TestDrive 'server-no-prompts-dir'
                New-Item -Path $testPath -ItemType Directory -Force | Out-Null

                # Act
                $result = Get-Initialization -MCPRoot $testPath

                # Assert
                $result.capabilities.prompts | Should -BeNullOrEmpty
            }
        }
    }

    Context 'Resources Capability Detection' {

        It 'should detect resources capability when files exist in resources directory' {
            InModuleScope MCP.SDK {
                # Arrange
                $testPath = New-TestMCPServer -BasePath (Join-Path $TestDrive 'server-with-resources') -IncludeResources

                # Act
                $result = Get-Initialization -MCPRoot $testPath

                # Assert
                $result.capabilities.resources | Should -BeOfType [hashtable]
            }
        }

        It 'should detect resources capability with non-.ps1 files' {
            InModuleScope MCP.SDK {
                # Arrange
                $testPath = Join-Path $TestDrive 'server-with-json-resources'
                $resourcesPath = Join-Path $testPath 'resources'
                New-Item -Path $resourcesPath -ItemType Directory -Force | Out-Null
                '{"test": true}' | Set-Content (Join-Path $resourcesPath 'data.json')

                # Act
                $result = Get-Initialization -MCPRoot $testPath

                # Assert
                $result.capabilities.resources | Should -BeOfType [hashtable]
            }
        }

        It 'should not detect resources capability when resources directory is empty' {
            InModuleScope MCP.SDK {
                # Arrange
                $testPath = Join-Path $TestDrive 'server-empty-resources'
                New-Item -Path $testPath -ItemType Directory -Force | Out-Null
                New-Item -Path (Join-Path $testPath 'resources') -ItemType Directory -Force | Out-Null

                # Act
                $result = Get-Initialization -MCPRoot $testPath

                # Assert
                $result.capabilities.resources | Should -BeNullOrEmpty
            }
        }

        It 'should not detect resources capability when resources directory does not exist' {
            InModuleScope MCP.SDK {
                # Arrange
                $testPath = Join-Path $TestDrive 'server-no-resources-dir'
                New-Item -Path $testPath -ItemType Directory -Force | Out-Null

                # Act
                $result = Get-Initialization -MCPRoot $testPath

                # Assert
                $result.capabilities.resources | Should -BeNullOrEmpty
            }
        }
    }

    Context 'Instructions File Handling' {

        It 'should include instructions when instructions.md exists' {
            InModuleScope MCP.SDK {
                # Arrange
                $instructionsContent = "# Test Server`n`nThis is a test server with instructions."
                $testPath = New-TestMCPServer -BasePath (Join-Path $TestDrive 'server-with-instructions') `
                    -IncludeInstructions `
                    -InstructionsContent $instructionsContent

                # Act
                $result = Get-Initialization -MCPRoot $testPath

                # Assert
                $result.instructions | Should -Not -BeNullOrEmpty
                $result.instructions | Should -Be $instructionsContent
            }
        }

        It 'should not include instructions when instructions.md does not exist' {
            InModuleScope MCP.SDK {
                # Arrange
                $testPath = Join-Path $TestDrive 'server-no-instructions'
                New-Item -Path $testPath -ItemType Directory -Force | Out-Null

                # Act
                $result = Get-Initialization -MCPRoot $testPath

                # Assert
                $result.instructions | Should -BeNullOrEmpty
            }
        }

        It 'should preserve markdown formatting in instructions' {
            InModuleScope MCP.SDK {
                # Arrange
                $instructionsContent = @"
# Main Title

## Section 1
- Bullet 1
- Bullet 2

## Section 2
**Bold text** and *italic text*
"@
                $testPath = New-TestMCPServer -BasePath (Join-Path $TestDrive 'server-formatted-instructions') `
                    -IncludeInstructions `
                    -InstructionsContent $instructionsContent

                # Act
                $result = Get-Initialization -MCPRoot $testPath

                # Assert
                $result.instructions | Should -Be $instructionsContent
            }
        }
    }

    Context 'Multiple Capabilities' {

        It 'should detect all capabilities when all types are present' {
            InModuleScope MCP.SDK {
                # Arrange
                $testPath = New-TestMCPServer -BasePath (Join-Path $TestDrive 'server-all-capabilities') `
                    -IncludeTools `
                    -IncludePrompts `
                    -IncludeResources

                # Act
                $result = Get-Initialization -MCPRoot $testPath

                # Assert
                $result.capabilities.tools | Should -BeOfType [hashtable]
                $result.capabilities.prompts | Should -BeOfType [hashtable]
                $result.capabilities.resources | Should -BeOfType [hashtable]
            }
        }

        It 'should detect subset of capabilities when only some types are present' {
            InModuleScope MCP.SDK {
                # Arrange
                $testPath = New-TestMCPServer -BasePath (Join-Path $TestDrive 'server-partial-capabilities') `
                    -IncludeTools `
                    -IncludeResources

                # Act
                $result = Get-Initialization -MCPRoot $testPath

                # Assert
                $result.capabilities.tools | Should -BeOfType [hashtable]
                $result.capabilities.prompts | Should -BeNullOrEmpty
                $result.capabilities.resources | Should -BeOfType [hashtable]
            }
        }
    }

    Context 'Parameter Handling' {

        It 'should accept MCPRoot parameter' {
            InModuleScope MCP.SDK {
                # Arrange
                $testPath = Join-Path $TestDrive 'server-param-test'
                New-Item -Path $testPath -ItemType Directory -Force | Out-Null

                # Act & Assert
                { Get-Initialization -MCPRoot $testPath } | Should -Not -Throw
            }
        }

        It 'should accept Name parameter (currently unused)' {
            InModuleScope MCP.SDK {
                # Arrange
                $testPath = Join-Path $TestDrive 'server-name-param'
                New-Item -Path $testPath -ItemType Directory -Force | Out-Null

                # Act & Assert
                { Get-Initialization -MCPRoot $testPath -Name "CustomServer" } | Should -Not -Throw
            }
        }

        It 'should accept Title parameter (currently unused)' {
            InModuleScope MCP.SDK {
                # Arrange
                $testPath = Join-Path $TestDrive 'server-title-param'
                New-Item -Path $testPath -ItemType Directory -Force | Out-Null

                # Act & Assert
                { Get-Initialization -MCPRoot $testPath -Title "Custom Server Title" } | Should -Not -Throw
            }
        }

        It 'should use default values for optional parameters' {
            InModuleScope MCP.SDK {
                # Arrange
                $testPath = Join-Path $TestDrive 'server-defaults'
                New-Item -Path $testPath -ItemType Directory -Force | Out-Null

                # Act
                $result = Get-Initialization -MCPRoot $testPath

                # Assert
                $result | Should -Not -BeNullOrEmpty
            }
        }
    }

    Context 'Integration with reference-server' {

        It 'should correctly initialize the reference-server example' {
            InModuleScope MCP.SDK {
                # Arrange
                $referenceServerPath = Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))) 'Examples\reference-server'

                if (Test-Path $referenceServerPath) {
                    # Act
                    $result = Get-Initialization -MCPRoot $referenceServerPath

                    # Assert
                    $result.capabilities.tools | Should -Not -BeNullOrEmpty -Because "reference-server has tool scripts"
                    $result.capabilities.prompts | Should -Not -BeNullOrEmpty -Because "reference-server has prompt scripts"
                    $result.capabilities.resources | Should -Not -BeNullOrEmpty -Because "reference-server has resource files"
                    $result.instructions | Should -Not -BeNullOrEmpty -Because "reference-server has instructions.md"
                }
            }
        }
    }

    Context 'Return Type and Structure' {

        It 'should return an ordered hashtable' {
            InModuleScope MCP.SDK {
                # Arrange
                $testPath = Join-Path $TestDrive 'server-return-type'
                New-Item -Path $testPath -ItemType Directory -Force | Out-Null

                # Act
                $result = Get-Initialization -MCPRoot $testPath

                # Assert
                $result | Should -BeOfType [System.Collections.Specialized.OrderedDictionary]
            }
        }

        It 'should have protocolVersion as first key' {
            InModuleScope MCP.SDK {
                # Arrange
                $testPath = Join-Path $TestDrive 'server-key-order'
                New-Item -Path $testPath -ItemType Directory -Force | Out-Null

                # Act
                $result = Get-Initialization -MCPRoot $testPath

                # Assert
                $result.Keys | Select-Object -First 1 | Should -Be 'protocolVersion'
            }
        }

        It 'should have correct key order in response' {
            InModuleScope MCP.SDK {
                # Arrange
                $testPath = Join-Path $TestDrive 'server-key-structure'
                New-Item -Path $testPath -ItemType Directory -Force | Out-Null

                # Act
                $result = Get-Initialization -MCPRoot $testPath

                # Assert
                $keys = @($result.Keys)
                $keys[0] | Should -Be 'protocolVersion'
                $keys[1] | Should -Be 'capabilities'
                $keys[2] | Should -Be 'serverInfo'
            }
        }
    }
}
