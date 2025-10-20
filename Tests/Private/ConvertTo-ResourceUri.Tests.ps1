BeforeAll {
    # Import the module
    $ModuleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $ModulePath = Join-Path $ModuleRoot 'MCP.SDK\MCP.SDK.psd1'
    Import-Module $ModulePath -Force
}

Describe 'ConvertTo-ResourceUri' -Tag 'Unit' {

    Context 'Basic Functionality' {

        It 'should convert file path to URI with default prefix' {
            InModuleScope MCP.SDK {
                # Arrange
                $root = "C:\test\resources"
                $fullName = "C:\test\resources\file.txt"

                # Act
                $result = ConvertTo-ResourceUri -FullName $fullName -Root $root

                # Assert
                $result | Should -Be "file://file"
            }
        }

        It 'should convert file path to URI with custom prefix' {
            InModuleScope MCP.SDK {
                # Arrange
                $root = "C:\test\resources"
                $fullName = "C:\test\resources\document.md"
                $uriPrefix = "file://"

                # Act
                $result = ConvertTo-ResourceUri -FullName $fullName -Root $root -UriPrefix $uriPrefix

                # Assert
                $result | Should -Be "file://document"
            }
        }

        It 'should remove file extension from URI' {
            InModuleScope MCP.SDK {
                # Arrange
                $root = "C:\test\resources"
                $fullName = "C:\test\resources\data.json"

                # Act
                $result = ConvertTo-ResourceUri -FullName $fullName -Root $root

                # Assert
                $result | Should -Be "file://data"
                $result | Should -Not -Match "\.json$"
            }
        }

        It 'should handle nested directories' {
            InModuleScope MCP.SDK {
                # Arrange
                $root = "C:\test\resources"
                $fullName = "C:\test\resources\status\current.txt"

                # Act
                $result = ConvertTo-ResourceUri -FullName $fullName -Root $root

                # Assert
                $result | Should -Be "file://status/current"
            }
        }

        It 'should convert backslashes to forward slashes in URI' {
            InModuleScope MCP.SDK {
                # Arrange
                $root = "C:\test\resources"
                $fullName = "C:\test\resources\level1\level2\deep.txt"

                # Act
                $result = ConvertTo-ResourceUri -FullName $fullName -Root $root

                # Assert
                $result | Should -Be "file://level1/level2/deep"
                $result | Should -Not -Match "\\"
            }
        }
    }

    Context 'Edge Cases' {

        It 'should handle <Description>' -TestCases @(
            @{ Root = "C:\test\resources"; FullName = "C:\test\resources\file.name.with.dots.txt"; Expected = "file://file.name.with.dots"; Description = "files with multiple dots in name" }
            @{ Root = "C:\test\resources"; FullName = "C:\test\resources\README"; Expected = "file://README"; Description = "files without extension" }
            @{ Root = "C:\test\resources\"; FullName = "C:\test\resources\file.txt"; Expected = "file://file"; Description = "root path with trailing slash" }
            @{ Root = "C:/test/resources"; FullName = "C:/test/resources/file.txt"; Expected = "file://file"; Description = "root path with forward slashes" }
            @{ Root = "C:\test\resources"; FullName = "C:\test\resources\.gitignore"; Expected = "file://.gitignore"; Description = "empty file name (just extension)" }
            @{ Root = "C:\test\resources"; FullName = "C:\test\resources\level1\level2\deep.txt"; Expected = "file://level1/level2/deep"; Description = "deeply nested files" }
        ) {
            param($Root, $FullName, $Expected)
            $parameters = [hashtable]$PSBoundParameters
            InModuleScope MCP.SDK -Parameters $parameters {
                # Act
                $result = ConvertTo-ResourceUri -FullName $FullName -Root $Root

                # Assert
                $result | Should -Be $Expected
            }
        }
    }

    Context 'URI Prefix Variations' {

        It 'should work with <Description>' -TestCases @(
            @{ UriPrefix = "http://"; FileName = "api.json"; Expected = "http://api"; Description = "http prefix" }
            @{ UriPrefix = "myscheme://"; FileName = "config.yaml"; Expected = "myscheme://config"; Description = "custom scheme" }
            @{ UriPrefix = "custom"; FileName = "test.txt"; Expected = "customtest"; Description = "no trailing slashes in prefix" }
            @{ UriPrefix = "file://"; FileName = "document.md"; Expected = "file://document"; Description = "file prefix" }
            @{ UriPrefix = "https://"; FileName = "data.xml"; Expected = "https://data"; Description = "https prefix" }
        ) {
            param($UriPrefix, $FileName, $Expected)

            $parameters = [hashtable]$PSBoundParameters
            InModuleScope MCP.SDK -Parameters $parameters {
                # Arrange
                $root = "C:\test\resources"
                $fullName = "C:\test\resources\$FileName"

                # Act
                $result = ConvertTo-ResourceUri -FullName $fullName -Root $root -UriPrefix $UriPrefix

                # Assert
                $result | Should -Be $Expected
            }
        }
    }

    Context 'Parameter Validation' {

        It 'should handle when FullName equals Root' {
            InModuleScope MCP.SDK {
                # This shouldn't happen in practice but test edge case
                # Arrange
                $root = "C:\test\resources"
                $fullName = "C:\test\resources"

                # Act & Assert
                { ConvertTo-ResourceUri -FullName $fullName -Root $root } | Should -Not -Throw
            }
        }
    }
}