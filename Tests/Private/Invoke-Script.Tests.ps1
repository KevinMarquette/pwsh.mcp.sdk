BeforeAll {
    # Import the module
    $ModuleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $ModulePath = Join-Path $ModuleRoot 'MCP.SDK\MCP.SDK.psd1'
    Import-Module $ModulePath -Force
}

Describe 'Invoke-Script' -Tag 'Unit' {

    Context 'Basic Functionality' {
        
        It 'should execute a script when file exists' {
            InModuleScope MCP.SDK {
                # Arrange
                $tempScript = Join-Path $TestDrive 'test-script.ps1'
                $scriptContent = @'
param($message)
Write-Output "Test message: $message"
'@
                Set-Content -Path $tempScript -Value $scriptContent
                
                # Act
                $result = Invoke-Script -Path $tempScript -Parameters @{message = "Hello World"}
                
                # Assert
                $result | Should -Not -BeNullOrEmpty
                Remove-Item -Path $tempScript -Force
            }
        }

        It 'should throw error when script file does not exist' {
            InModuleScope MCP.SDK {
                # Act & Assert
                { Invoke-Script -Path "NonExistentScript.ps1" } | Should -Throw "Script file not found: NonExistentScript.ps1"
            }
        }

        It 'should execute script without parameters' {
            InModuleScope MCP.SDK {
                # Arrange
                $tempScript = Join-Path $TestDrive 'test-script-no-params.ps1'
                $scriptContent = @'
Write-Output "No parameters test"
'@
                Set-Content -Path $tempScript -Value $scriptContent
                
                # Act
                $result = Invoke-Script -Path $tempScript
                
                # Assert
                $result | Should -Not -BeNullOrEmpty
                Remove-Item -Path $tempScript -Force
            }
        }

        It 'should handle empty parameters hashtable' {
            InModuleScope MCP.SDK {
                # Arrange
                $tempScript = Join-Path $TestDrive 'test-script-empty-params.ps1'
                $scriptContent = @'
param($message)
Write-Output "Empty params test: $message"
'@
                Set-Content -Path $tempScript -Value $scriptContent
                
                # Act
                $result = Invoke-Script -Path $tempScript -Parameters @{}
                
                # Assert
                $result | Should -Not -BeNullOrEmpty
                Remove-Item -Path $tempScript -Force
            }
        }
    }

    Context 'Error Handling' {
        
        It 'should throw specific error for non-existent script path' {
            InModuleScope MCP.SDK {
                # Act & Assert
                { Invoke-Script -Path "C:\NonExistentPath\Script.ps1" } | Should -Throw "Script file not found: C:\NonExistentPath\Script.ps1"
            }
        }

        It 'should handle script execution errors' {
            InModuleScope MCP.SDK {
                # Arrange
                $tempScript = Join-Path $TestDrive 'test-script-error.ps1'
                $scriptContent = @'
param($message)
throw "Test error message"
'@
                Set-Content -Path $tempScript -Value $scriptContent
                
                # Act & Assert
                { Invoke-Script -Path $tempScript -Parameters @{message = "Error test"} } | Should -Throw "Test error message"
                Remove-Item -Path $tempScript -Force
            }
        }
    }

    Context 'Parameter Handling' {
        
        It 'should pass parameters correctly to script' {
            InModuleScope MCP.SDK {
                # Arrange
                $tempScript = Join-Path $TestDrive 'test-script-params.ps1'
                $scriptContent = @'
param($name, $value)
Write-Output "Name: $name, Value: $value"
'@
                Set-Content -Path $tempScript -Value $scriptContent
                
                # Act
                $result = Invoke-Script -Path $tempScript -Parameters @{name = "test"; value = 42}
                
                # Assert
                $result | Should -Not -BeNullOrEmpty
                Remove-Item -Path $tempScript -Force
            }
        }

        It 'should handle multiple parameters' {
            InModuleScope MCP.SDK {
                # Arrange
                $tempScript = Join-Path $TestDrive 'test-script-multi-params.ps1'
                $scriptContent = @'
param($param1, $param2, $param3)
Write-Output "Param1: $param1, Param2: $param2, Param3: $param3"
'@
                Set-Content -Path $tempScript -Value $scriptContent
                
                # Act
                $result = Invoke-Script -Path $tempScript -Parameters @{param1 = "first"; param2 = "second"; param3 = "third"}
                
                # Assert
                $result | Should -Not -BeNullOrEmpty
                Remove-Item -Path $tempScript -Force
            }
        }

        It 'should handle complex parameter types' {
            InModuleScope MCP.SDK {
                # Arrange
                $tempScript = Join-Path $TestDrive 'test-script-complex-params.ps1'
                $scriptContent = @'
param($array, $hash)
Write-Output "Array count: $($array.Count), Hash keys: $($hash.Keys)"
'@
                Set-Content -Path $tempScript -Value $scriptContent
                
                # Act
                $result = Invoke-Script -Path $tempScript -Parameters @{array = @(1,2,3); hash = @{key1 = "value1"; key2 = "value2"}}
                
                # Assert
                $result | Should -Not -BeNullOrEmpty
                Remove-Item -Path $tempScript -Force
            }
        }
    }

    Context 'Edge Cases' {
        
        It 'should handle script with no parameters defined' {
            InModuleScope MCP.SDK {
                # Arrange
                $tempScript = Join-Path $TestDrive 'test-script-no-def.ps1'
                $scriptContent = @'
Write-Output "No parameter definition"
'@
                Set-Content -Path $tempScript -Value $scriptContent
                
                # Act
                $result = Invoke-Script -Path $tempScript -Parameters @{invalid = "should not matter"}
                
                # Assert
                $result | Should -Not -BeNullOrEmpty
                Remove-Item -Path $tempScript -Force
            }
        }

        It 'should handle script with default parameters' {
            InModuleScope MCP.SDK {
                # Arrange
                $tempScript = Join-Path $TestDrive 'test-script-default.ps1'
                $scriptContent = @'
param($name = "default")
Write-Output "Name: $name"
'@
                Set-Content -Path $tempScript -Value $scriptContent
                
                # Act
                $result = Invoke-Script -Path $tempScript
                
                # Assert
                $result | Should -Not -BeNullOrEmpty
                Remove-Item -Path $tempScript -Force
            }
        }
    }
}
