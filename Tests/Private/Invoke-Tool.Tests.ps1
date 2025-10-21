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

Describe 'Invoke-Tool' -Tag 'Unit' {

    Context 'Basic Functionality' {
        
        It 'should execute a tool when tool exists and script file exists' {
            InModuleScope MCP.SDK -Parameters @{ MCPRoot = $script:TestMCPRoot } {
                param($MCPRoot)
                # Arrange
                $toolScriptPath = Join-Path "$MCPRoot/tools" 'TestTool.ps1'
                $scriptContent = @'
param($message)
Write-Output "Test tool executed with message: $message"
'@
                Set-Content -Path $toolScriptPath -Value $scriptContent
                
                # Create a tool list entry
                $toolList = @{tools = @(@{name = 'TestTool'})}
                $toolList | ConvertTo-Json | Set-Content -Path "$MCPRoot/tools.json" -NoNewline

                # Act
                $result = Invoke-Tool -Name 'TestTool' -MCPRoot $MCPRoot -Parameters @{message = "Hello World"}

                # Assert
                $result.result.isError | Should -BeFalse
                $result.result.content | Should -Not -BeNullOrEmpty
                $result.result.structuredContent | Should -Not -BeNullOrEmpty
            }
        }

        It 'should handle tool not found error' {
            InModuleScope MCP.SDK -Parameters @{ MCPRoot = $script:TestMCPRoot } {
                param($MCPRoot)
                # Arrange
                $toolList = @{tools = @(@{name = 'OtherTool'})}
                $toolList | ConvertTo-Json | Set-Content -Path "$MCPRoot/tools.json" -NoNewline

                # Act & Assert
                { Invoke-Tool -Name 'NonExistentTool' -MCPRoot $MCPRoot } | Should -Throw "Tool 'NonExistentTool' not found in tool list"
            }
        }

        It 'should execute tool with parameters' {
            InModuleScope MCP.SDK -Parameters @{ MCPRoot = $script:TestMCPRoot } {
                param($MCPRoot)
                # Arrange
                $toolScriptPath = Join-Path "$MCPRoot/tools" 'ParamTool.ps1'
                $scriptContent = @'
param($param1, $param2)
Write-Output "Param1: $param1, Param2: $param2"
'@
                Set-Content -Path $toolScriptPath -Value $scriptContent
                
                # Create a tool list entry
                $toolList = @{tools = @(@{name = 'ParamTool'})}
                $toolList | ConvertTo-Json | Set-Content -Path "$MCPRoot/tools.json" -NoNewline

                # Act
                $result = Invoke-Tool -Name 'ParamTool' -MCPRoot $MCPRoot -Parameters @{param1 = "first"; param2 = "second"}

                # Assert
                $result.result.isError | Should -BeFalse
                $result.result.content | Should -Not -BeNullOrEmpty
            }
        }

        It 'should execute tool with empty parameters' {
            InModuleScope MCP.SDK -Parameters @{ MCPRoot = $script:TestMCPRoot } {
                param($MCPRoot)
                # Arrange
                $toolScriptPath = Join-Path "$MCPRoot/tools" 'EmptyParamTool.ps1'
                $scriptContent = @'
param()
Write-Output "No parameters tool executed"
'@
                Set-Content -Path $toolScriptPath -Value $scriptContent
                
                # Create a tool list entry
                $toolList = @{tools = @(@{name = 'EmptyParamTool'})}
                $toolList | ConvertTo-Json | Set-Content -Path "$MCPRoot/tools.json" -NoNewline

                # Act
                $result = Invoke-Tool -Name 'EmptyParamTool' -MCPRoot $MCPRoot -Parameters @{}

                # Assert
                $result.result.isError | Should -BeFalse
                $result.result.content | Should -Not -BeNullOrEmpty
            }
        }
    }

    Context 'Error Handling' {
        
        It 'should handle script execution errors gracefully' {
            InModuleScope MCP.SDK -Parameters @{ MCPRoot = $script:TestMCPRoot } {
                param($MCPRoot)
                # Arrange
                $toolScriptPath = Join-Path "$MCPRoot/tools" 'ErrorTool.ps1'
                $scriptContent = @'
param($message)
throw "Test error in tool execution"
'@
                Set-Content -Path $toolScriptPath -Value $scriptContent
                
                # Create a tool list entry
                $toolList = @{tools = @(@{name = 'ErrorTool'})}
                $toolList | ConvertTo-Json | Set-Content -Path "$MCPRoot/tools.json" -NoNewline

                # Act
                $result = Invoke-Tool -Name 'ErrorTool' -MCPRoot $MCPRoot -Parameters @{message = "Error test"}

                # Assert
                $result.result.isError | Should -BeTrue
                $result.result.content | Should -Not -BeNullOrEmpty
                $result.result.structuredContent | Should -Not -BeNullOrEmpty
            }
        }

        It 'should return structured content when error occurs' {
            InModuleScope MCP.SDK -Parameters @{ MCPRoot = $script:TestMCPRoot } {
                param($MCPRoot)
                # Arrange
                $toolScriptPath = Join-Path "$MCPRoot/tools" 'ErrorTool2.ps1'
                $scriptContent = @'
param()
throw "Another test error"
'@
                Set-Content -Path $toolScriptPath -Value $scriptContent
                
                # Create a tool list entry
                $toolList = @{tools = @(@{name = 'ErrorTool2'})}
                $toolList | ConvertTo-Json | Set-Content -Path "$MCPRoot/tools.json" -NoNewline

                # Act
                $result = Invoke-Tool -Name 'ErrorTool2' -MCPRoot $MCPRoot

                # Assert
                $result.result.isError | Should -BeTrue
                $result.result.structuredContent | Should -Not -BeNullOrEmpty
            }
        }
    }

    Context 'Response Format' {
        
        It 'should return proper result structure' {
            InModuleScope MCP.SDK -Parameters @{ MCPRoot = $script:TestMCPRoot } {
                param($MCPRoot)
                # Arrange
                $toolScriptPath = Join-Path "$MCPRoot/tools" 'FormatTool.ps1'
                $scriptContent = @'
param()
Write-Output "Format test"
'@
                Set-Content -Path $toolScriptPath -Value $scriptContent
                
                # Create a tool list entry
                $toolList = @{tools = @(@{name = 'FormatTool'})}
                $toolList | ConvertTo-Json | Set-Content -Path "$MCPRoot/tools.json" -NoNewline

                # Act
                $result = Invoke-Tool -Name 'FormatTool' -MCPRoot $MCPRoot

                # Assert
                $result.Keys | Should -Contain 'result'
                $result.result.Keys | Should -Contain 'isError'
                $result.result.Keys | Should -Contain 'content'
                $result.result.Keys | Should -Contain 'structuredContent'
            }
        }

        It 'should have correct content structure' {
            InModuleScope MCP.SDK -Parameters @{ MCPRoot = $script:TestMCPRoot } {
                param($MCPRoot)
                # Arrange
                $toolScriptPath = Join-Path "$MCPRoot/tools" 'ContentTool.ps1'
                $scriptContent = @'
param()
Write-Output "Content test"
'@
                Set-Content -Path $toolScriptPath -Value $scriptContent
                
                # Create a tool list entry
                $toolList = @{tools = @(@{name = 'ContentTool'})}
                $toolList | ConvertTo-Json | Set-Content -Path "$MCPRoot/tools.json" -NoNewline

                # Act
                $result = Invoke-Tool -Name 'ContentTool' -MCPRoot $MCPRoot

                # Assert
                $result.result.content | Should -Not -BeNullOrEmpty
                $result.result.content[0].type | Should -Be "text"
                $result.result.content[0].text | Should -Not -BeNullOrEmpty
            }
        }
    }
}
