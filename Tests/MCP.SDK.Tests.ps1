BeforeAll {
    # Set up paths
    $ModuleRoot = Split-Path -Parent $PSScriptRoot
    $SourcePath = Join-Path $ModuleRoot 'MCP.SDK'
    $TestsPath = $PSScriptRoot
}

Describe 'MCP.SDK Module Tests' -Tag 'Module' {

    Context 'Test Coverage' {

        It 'should have a test file for every Private function' {
            # Arrange
            $privatePath = Join-Path $SourcePath 'Private'
            $privateFunctions = Get-ChildItem -Path $privatePath -Filter '*.ps1' -File -ErrorAction SilentlyContinue

            $missingTests = @()

            # Act
            foreach ($function in $privateFunctions) {
                $expectedTestFile = Join-Path $TestsPath "Private\$($function.BaseName).Tests.ps1"

                if (-not (Test-Path $expectedTestFile)) {
                    $missingTests += "Private\$($function.Name)"
                }
            }

            # Assert
            if ($missingTests.Count -gt 0) {
                $message = "Missing test files for the following functions:`n  - " + ($missingTests -join "`n  - ")
                $missingTests.Count | Should -Be 0 -Because $message
            }
        }

        It 'should have a test file for every Public function' {
            # Arrange
            $publicPath = Join-Path $SourcePath 'Public'
            $publicFunctions = Get-ChildItem -Path $publicPath -Filter '*.ps1' -File -ErrorAction SilentlyContinue

            $missingTests = @()

            # Act
            foreach ($function in $publicFunctions) {
                $expectedTestFile = Join-Path $TestsPath "Public\$($function.BaseName).Tests.ps1"

                if (-not (Test-Path $expectedTestFile)) {
                    $missingTests += "Public\$($function.Name)"
                }
            }

            # Assert
            if ($missingTests.Count -gt 0) {
                $message = "Missing test files for the following functions:`n  - " + ($missingTests -join "`n  - ")
                $missingTests.Count | Should -Be 0 -Because $message
            }
        }
    }

    Context 'Module Structure' {

        It 'should have a module manifest' {
            # Arrange
            $manifestPath = Join-Path $SourcePath 'MCP.SDK.psd1'

            # Assert
            Test-Path $manifestPath | Should -Be $true
        }

        It 'should have a root module file' {
            # Arrange
            $moduleFilePath = Join-Path $SourcePath 'MCP.SDK.psm1'

            # Assert
            Test-Path $moduleFilePath | Should -Be $true
        }

        It 'should have a Private functions directory' {
            # Arrange
            $privatePath = Join-Path $SourcePath 'Private'

            # Assert
            Test-Path $privatePath | Should -Be $true
        }

        It 'should have a Public functions directory if public functions exist' {
            # Arrange
            $publicPath = Join-Path $SourcePath 'Public'

            # Assert - This is optional as modules may only have private functions
            if (Test-Path $publicPath) {
                (Get-Item $publicPath).PSIsContainer | Should -Be $true
            }
            else {
                # Public directory is optional
                $true | Should -Be $true
            }
        }
    }

    Context 'Module Manifest Validation' {

        It 'should have a valid module manifest' {
            # Arrange
            $manifestPath = Join-Path $SourcePath 'MCP.SDK.psd1'

            # Act & Assert
            { Test-ModuleManifest -Path $manifestPath -ErrorAction Stop } | Should -Not -Throw
        }

        It 'should export functions defined in manifest' {
            # Arrange
            $manifestPath = Join-Path $SourcePath 'MCP.SDK.psd1'
            $manifest = Test-ModuleManifest -Path $manifestPath

            # Assert
            $manifest.ExportedFunctions.Count | Should -BeGreaterThan 0
        }
    }

    Context 'Test Organization' {

        It 'should have all Private test files in Tests/Private directory' {
            # Arrange
            $privateTestPath = Join-Path $TestsPath 'Private'

            # Assert
            Test-Path $privateTestPath | Should -Be $true
        }

        It 'should only have test files for existing functions' {
            # Arrange
            $privatePath = Join-Path $SourcePath 'Private'
            $privateTestPath = Join-Path $TestsPath 'Private'

            $privateFunctions = Get-ChildItem -Path $privatePath -Filter '*.ps1' -File -ErrorAction SilentlyContinue |
                ForEach-Object { $_.BaseName }

            $privateTests = Get-ChildItem -Path $privateTestPath -Filter '*.Tests.ps1' -File -ErrorAction SilentlyContinue

            $orphanedTests = @()

            # Act
            foreach ($test in $privateTests) {
                $functionName = $test.BaseName -replace '\.Tests$', ''

                if ($functionName -notin $privateFunctions) {
                    $orphanedTests += $test.Name
                }
            }

            # Assert
            if ($orphanedTests.Count -gt 0) {
                $message = "Found test files without corresponding functions:`n  - " + ($orphanedTests -join "`n  - ")
                $orphanedTests.Count | Should -Be 0 -Because $message
            }
        }
    }
}
