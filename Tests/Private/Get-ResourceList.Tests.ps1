BeforeAll {
    # Import the module
    $ModuleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $ModulePath = Join-Path $ModuleRoot 'MCP.SDK\MCP.SDK.psd1'
    Import-Module $ModulePath -Force

    InModuleScope MCP.SDK {
        # Helper function to create test resource files
        function Script:New-TestResource {
            param(
                [string]$Path,
                [string]$Content = "Test resource content",
                [string]$Extension = ".txt"
            )

            $directory = Split-Path $Path -Parent
            New-Item -Path $directory -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null

            if ($Extension -eq ".ps1") {
                $Content | Set-Content -Path $Path -NoNewline
            } else {
                $Content | Set-Content -Path $Path
            }
            return $Path
        }
    }
}

Describe 'Get-ResourceList' -Tag 'Unit' {

    Context 'Basic Functionality' {

        It 'should return a hashtable with resources key' {
            InModuleScope MCP.SDK {
                # Arrange
                $mcpRoot = Join-Path $TestDrive 'basic-server'
                $resourcesPath = Join-Path $mcpRoot 'resources'
                New-Item -Path $resourcesPath -ItemType Directory -Force | Out-Null
                New-TestResource -Path (Join-Path $resourcesPath 'test.txt') -Content "Test content"

                # Act
                $result = Get-ResourceList -MCPRoot $mcpRoot

                # Assert
                $result | Should -Not -BeNullOrEmpty
                $result.Keys | Should -Contain 'resources'
            }
        }

        It 'should return resources as an array' {
            InModuleScope MCP.SDK {
                # Arrange
                $mcpRoot = Join-Path $TestDrive 'array-server'
                $resourcesPath = Join-Path $mcpRoot 'resources'
                New-Item -Path $resourcesPath -ItemType Directory -Force | Out-Null
                New-TestResource -Path (Join-Path $resourcesPath 'resource1.txt') -Content "First"
                New-TestResource -Path (Join-Path $resourcesPath 'resource2.txt') -Content "Second"

                # Act
                $result = Get-ResourceList -MCPRoot $mcpRoot

                # Assert
                @($result.resources).Count | Should -Be 2
            }
        }

        It 'should return empty array when no resources exist' {
            InModuleScope MCP.SDK {
                # Arrange
                $mcpRoot = Join-Path $TestDrive 'empty-server'
                $resourcesPath = Join-Path $mcpRoot 'resources'
                New-Item -Path $resourcesPath -ItemType Directory -Force | Out-Null

                # Act
                $result = Get-ResourceList -MCPRoot $mcpRoot

                # Assert
                @($result.resources).Count | Should -Be 0
            }
        }

        It 'should recurse into subdirectories' {
            InModuleScope MCP.SDK {
                # Arrange
                $mcpRoot = Join-Path $TestDrive 'recurse-server'
                $resourcesPath = Join-Path $mcpRoot 'resources'
                $subPath = Join-Path $resourcesPath 'subdir'
                New-Item -Path $subPath -ItemType Directory -Force | Out-Null
                New-TestResource -Path (Join-Path $resourcesPath 'top.txt') -Content "Top level"
                New-TestResource -Path (Join-Path $subPath 'nested.txt') -Content "Nested"

                # Act
                $result = Get-ResourceList -MCPRoot $mcpRoot

                # Assert
                @($result.resources).Count | Should -Be 2
            }
        }

        It 'should only include files, not directories' {
            InModuleScope MCP.SDK {
                # Arrange
                $mcpRoot = Join-Path $TestDrive 'files-only-server'
                $resourcesPath = Join-Path $mcpRoot 'resources'
                New-Item -Path (Join-Path $resourcesPath 'subdir') -ItemType Directory -Force | Out-Null
                New-TestResource -Path (Join-Path $resourcesPath 'file.txt') -Content "File"

                # Act
                $result = Get-ResourceList -MCPRoot $mcpRoot

                # Assert
                @($result.resources).Count | Should -Be 1
                $result.resources[0].name | Should -Be 'file'
            }
        }
    }

    Context 'URI Generation' {

        It 'should generate correct URIs with default prefix' {
            InModuleScope MCP.SDK {
                # Arrange
                $mcpRoot = Join-Path $TestDrive 'uri-server'
                $resourcesPath = Join-Path $mcpRoot 'resources'
                New-Item -Path $resourcesPath -ItemType Directory -Force | Out-Null
                New-TestResource -Path (Join-Path $resourcesPath 'test.txt') -Content "Test"

                # Act
                $result = Get-ResourceList -MCPRoot $mcpRoot

                # Assert
                $result.resources[0].uri | Should -Be 'MCP://test'
            }
        }

        It 'should generate URIs with custom prefix' {
            InModuleScope MCP.SDK {
                # Arrange
                $mcpRoot = Join-Path $TestDrive 'custom-uri-server'
                $resourcesPath = Join-Path $mcpRoot 'resources'
                New-Item -Path $resourcesPath -ItemType Directory -Force | Out-Null
                New-TestResource -Path (Join-Path $resourcesPath 'test.txt') -Content "Test"

                # Act
                $result = Get-ResourceList -MCPRoot $mcpRoot -UriPrefix "custom://"

                # Assert
                $result.resources[0].uri | Should -Be 'custom://test'
            }
        }

        It 'should use forward slashes in URIs for nested resources' {
            InModuleScope MCP.SDK {
                # Arrange
                $mcpRoot = Join-Path $TestDrive 'nested-uri-server'
                $resourcesPath = Join-Path $mcpRoot 'resources'
                $subPath = Join-Path $resourcesPath 'status'
                New-Item -Path $subPath -ItemType Directory -Force | Out-Null
                New-TestResource -Path (Join-Path $subPath 'current.txt') -Content "Current"

                # Act
                $result = Get-ResourceList -MCPRoot $mcpRoot

                # Assert
                $result.resources[0].uri | Should -Be 'MCP://status/current'
                $result.resources[0].uri | Should -Not -Match '\\'
            }
        }

        It 'should remove file extension from URI' {
            InModuleScope MCP.SDK {
                # Arrange
                $mcpRoot = Join-Path $TestDrive 'extension-server'
                $resourcesPath = Join-Path $mcpRoot 'resources'
                New-Item -Path $resourcesPath -ItemType Directory -Force | Out-Null
                New-TestResource -Path (Join-Path $resourcesPath 'document.md') -Content "# Document"

                # Act
                $result = Get-ResourceList -MCPRoot $mcpRoot

                # Assert
                $result.resources[0].uri | Should -Be 'MCP://document'
                $result.resources[0].uri | Should -Not -Match '\.md$'
            }
        }
    }

    Context 'MIME Type Detection' {

        It 'should detect text/plain for .txt files' {
            InModuleScope MCP.SDK {
                # Arrange
                $mcpRoot = Join-Path $TestDrive 'txt-server'
                $resourcesPath = Join-Path $mcpRoot 'resources'
                New-Item -Path $resourcesPath -ItemType Directory -Force | Out-Null
                New-TestResource -Path (Join-Path $resourcesPath 'file.txt') -Content "Text"

                # Act
                $result = Get-ResourceList -MCPRoot $mcpRoot

                # Assert
                $result.resources[0].mimeType | Should -Be 'text/plain'
            }
        }

        It 'should detect text/markdown for .md files' {
            InModuleScope MCP.SDK {
                # Arrange
                $mcpRoot = Join-Path $TestDrive 'md-server'
                $resourcesPath = Join-Path $mcpRoot 'resources'
                New-Item -Path $resourcesPath -ItemType Directory -Force | Out-Null
                New-TestResource -Path (Join-Path $resourcesPath 'file.md') -Content "# Markdown"

                # Act
                $result = Get-ResourceList -MCPRoot $mcpRoot

                # Assert
                $result.resources[0].mimeType | Should -Be 'text/markdown'
            }
        }

        It 'should detect application/json for .json files' {
            InModuleScope MCP.SDK {
                # Arrange
                $mcpRoot = Join-Path $TestDrive 'json-server'
                $resourcesPath = Join-Path $mcpRoot 'resources'
                New-Item -Path $resourcesPath -ItemType Directory -Force | Out-Null
                New-TestResource -Path (Join-Path $resourcesPath 'data.json') -Content '{"key":"value"}'

                # Act
                $result = Get-ResourceList -MCPRoot $mcpRoot

                # Assert
                $result.resources[0].mimeType | Should -Be 'application/json'
            }
        }

        It 'should detect application/yaml for .yaml and .yml files' {
            InModuleScope MCP.SDK {
                # Arrange
                $mcpRoot = Join-Path $TestDrive 'yaml-server'
                $resourcesPath = Join-Path $mcpRoot 'resources'
                New-Item -Path $resourcesPath -ItemType Directory -Force | Out-Null
                New-TestResource -Path (Join-Path $resourcesPath 'config.yaml') -Content 'key: value'
                New-TestResource -Path (Join-Path $resourcesPath 'config2.yml') -Content 'key: value'

                # Act
                $result = Get-ResourceList -MCPRoot $mcpRoot

                # Assert
                $result.resources[0].mimeType | Should -Be 'application/yaml'
                $result.resources[1].mimeType | Should -Be 'application/yaml'
            }
        }

        It 'should detect image MIME types' {
            InModuleScope MCP.SDK {
                # Arrange
                $mcpRoot = Join-Path $TestDrive 'image-server'
                $resourcesPath = Join-Path $mcpRoot 'resources'
                New-Item -Path $resourcesPath -ItemType Directory -Force | Out-Null
                New-TestResource -Path (Join-Path $resourcesPath 'photo.jpg') -Content "binary"
                New-TestResource -Path (Join-Path $resourcesPath 'graphic.png') -Content "binary"

                # Act
                $result = Get-ResourceList -MCPRoot $mcpRoot

                # Assert
                $jpgResource = $result.resources | Where-Object { $_.name -eq 'photo' }
                $pngResource = $result.resources | Where-Object { $_.name -eq 'graphic' }
                $jpgResource.mimeType | Should -Be 'image/jpeg'
                $pngResource.mimeType | Should -Be 'image/png'
            }
        }

        It 'should not include mimeType for unknown extensions' {
            InModuleScope MCP.SDK {
                # Arrange
                $mcpRoot = Join-Path $TestDrive 'unknown-server'
                $resourcesPath = Join-Path $mcpRoot 'resources'
                New-Item -Path $resourcesPath -ItemType Directory -Force | Out-Null
                New-TestResource -Path (Join-Path $resourcesPath 'file.unknown') -Content "Unknown"

                # Act
                $result = Get-ResourceList -MCPRoot $mcpRoot

                # Assert
                $result.resources[0].Keys | Should -Not -Contain 'mimeType'
            }
        }

        It 'should not include mimeType for .ps1 files' {
            InModuleScope MCP.SDK {
                # Arrange
                $mcpRoot = Join-Path $TestDrive 'ps1-server'
                $resourcesPath = Join-Path $mcpRoot 'resources'
                New-Item -Path $resourcesPath -ItemType Directory -Force | Out-Null
                $script = @'
<#
.SYNOPSIS
Test script
#>
Write-Output "Test"
'@
                New-TestResource -Path (Join-Path $resourcesPath 'script.ps1') -Content $script -Extension ".ps1"

                # Act
                $result = Get-ResourceList -MCPRoot $mcpRoot

                # Assert
                $result.resources[0].Keys | Should -Not -Contain 'mimeType'
            }
        }
    }

    Context 'PowerShell Script Resources' {

        It 'should extract synopsis from .ps1 files' {
            InModuleScope MCP.SDK {
                # Arrange
                $mcpRoot = Join-Path $TestDrive 'ps1-synopsis-server'
                $resourcesPath = Join-Path $mcpRoot 'resources'
                New-Item -Path $resourcesPath -ItemType Directory -Force | Out-Null
                $script = @'
<#
.SYNOPSIS
Current incident status
#>
Write-Output "Status"
'@
                New-TestResource -Path (Join-Path $resourcesPath 'status.ps1') -Content $script -Extension ".ps1"

                # Act
                $result = Get-ResourceList -MCPRoot $mcpRoot

                # Assert
                $result.resources[0].title | Should -Be 'Current incident status'
            }
        }

        It 'should extract description from .ps1 files' {
            InModuleScope MCP.SDK {
                # Arrange
                $mcpRoot = Join-Path $TestDrive 'ps1-desc-server'
                $resourcesPath = Join-Path $mcpRoot 'resources'
                New-Item -Path $resourcesPath -ItemType Directory -Force | Out-Null
                $script = @'
<#
.SYNOPSIS
Brief synopsis

.DESCRIPTION
Detailed description of the resource
#>
Write-Output "Content"
'@
                New-TestResource -Path (Join-Path $resourcesPath 'detailed.ps1') -Content $script -Extension ".ps1"

                # Act
                $result = Get-ResourceList -MCPRoot $mcpRoot

                # Assert
                $result.resources[0].description | Should -Be 'Detailed description of the resource'
            }
        }

        It 'should handle .ps1 files without help documentation' {
            InModuleScope MCP.SDK {
                # Arrange
                $mcpRoot = Join-Path $TestDrive 'ps1-nohelp-server'
                $resourcesPath = Join-Path $mcpRoot 'resources'
                New-Item -Path $resourcesPath -ItemType Directory -Force | Out-Null
                $script = 'Write-Output "No help"'
                New-TestResource -Path (Join-Path $resourcesPath 'nohelp.ps1') -Content $script -Extension ".ps1"

                # Act
                $result = Get-ResourceList -MCPRoot $mcpRoot

                # Assert
                # Note: Get-Help will still return a default synopsis, so we just verify the resource exists
                $result.resources[0].Keys | Should -Contain 'uri'
                $result.resources[0].Keys | Should -Contain 'name'
            }
        }
    }

    Context 'Markdown Resources' {

        It 'should extract title from markdown first line with # heading' {
            InModuleScope MCP.SDK {
                # Arrange
                $mcpRoot = Join-Path $TestDrive 'md-title-server'
                $resourcesPath = Join-Path $mcpRoot 'resources'
                New-Item -Path $resourcesPath -ItemType Directory -Force | Out-Null
                $markdown = @'
# Incident Summary

This is the content of the markdown file.
'@
                New-TestResource -Path (Join-Path $resourcesPath 'summary.md') -Content $markdown

                # Act
                $result = Get-ResourceList -MCPRoot $mcpRoot

                # Assert
                $result.resources[0].title | Should -Be 'Incident Summary'
            }
        }

        It 'should handle markdown without heading' {
            InModuleScope MCP.SDK {
                # Arrange
                $mcpRoot = Join-Path $TestDrive 'md-noheading-server'
                $resourcesPath = Join-Path $mcpRoot 'resources'
                New-Item -Path $resourcesPath -ItemType Directory -Force | Out-Null
                $markdown = 'Just plain text without heading'
                New-TestResource -Path (Join-Path $resourcesPath 'plain.md') -Content $markdown

                # Act
                $result = Get-ResourceList -MCPRoot $mcpRoot

                # Assert
                $result.resources[0].Keys | Should -Not -Contain 'title'
            }
        }

        It 'should trim whitespace from markdown title' {
            InModuleScope MCP.SDK {
                # Arrange
                $mcpRoot = Join-Path $TestDrive 'md-trim-server'
                $resourcesPath = Join-Path $mcpRoot 'resources'
                New-Item -Path $resourcesPath -ItemType Directory -Force | Out-Null
                $markdown = '#   Title with Spaces   '
                New-TestResource -Path (Join-Path $resourcesPath 'spaced.md') -Content $markdown

                # Act
                $result = Get-ResourceList -MCPRoot $mcpRoot

                # Assert
                $result.resources[0].title | Should -Be 'Title with Spaces'
            }
        }
    }

    Context 'Resource Properties' {

        It 'should include uri for all resources' {
            InModuleScope MCP.SDK {
                # Arrange
                $mcpRoot = Join-Path $TestDrive 'props-uri-server'
                $resourcesPath = Join-Path $mcpRoot 'resources'
                New-Item -Path $resourcesPath -ItemType Directory -Force | Out-Null
                New-TestResource -Path (Join-Path $resourcesPath 'test.txt') -Content "Test"

                # Act
                $result = Get-ResourceList -MCPRoot $mcpRoot

                # Assert
                $result.resources[0].Keys | Should -Contain 'uri'
                $result.resources[0].uri | Should -Not -BeNullOrEmpty
            }
        }

        It 'should include name for all resources' {
            InModuleScope MCP.SDK {
                # Arrange
                $mcpRoot = Join-Path $TestDrive 'props-name-server'
                $resourcesPath = Join-Path $mcpRoot 'resources'
                New-Item -Path $resourcesPath -ItemType Directory -Force | Out-Null
                New-TestResource -Path (Join-Path $resourcesPath 'test.txt') -Content "Test"

                # Act
                $result = Get-ResourceList -MCPRoot $mcpRoot

                # Assert
                $result.resources[0].Keys | Should -Contain 'name'
                $result.resources[0].name | Should -Be 'test'
            }
        }

        It 'should use BaseName for the name property' {
            InModuleScope MCP.SDK {
                # Arrange
                $mcpRoot = Join-Path $TestDrive 'basename-server'
                $resourcesPath = Join-Path $mcpRoot 'resources'
                New-Item -Path $resourcesPath -ItemType Directory -Force | Out-Null
                New-TestResource -Path (Join-Path $resourcesPath 'my-resource.json') -Content '{}'

                # Act
                $result = Get-ResourceList -MCPRoot $mcpRoot

                # Assert
                $result.resources[0].name | Should -Be 'my-resource'
            }
        }
    }

    Context 'Integration with reference-server' {

        It 'should successfully retrieve resources from reference-server' {
            InModuleScope MCP.SDK {
                # Arrange
                $refServerPath = Join-Path $PSScriptRoot '..\..\Examples\reference-server'

                # Act & Assert
                if (Test-Path $refServerPath) {
                    $result = Get-ResourceList -MCPRoot $refServerPath
                    @($result.resources).Count | Should -BeGreaterThan 0
                }
            }
        }

        It 'should have required properties for reference-server resources' {
            InModuleScope MCP.SDK {
                # Arrange
                $refServerPath = Join-Path $PSScriptRoot '..\..\Examples\reference-server'

                # Act & Assert
                if (Test-Path $refServerPath) {
                    $result = Get-ResourceList -MCPRoot $refServerPath
                    foreach ($resource in $result.resources) {
                        $resource.Keys | Should -Contain 'uri'
                        $resource.Keys | Should -Contain 'name'
                        $resource.uri | Should -Not -BeNullOrEmpty
                        $resource.name | Should -Not -BeNullOrEmpty
                    }
                }
            }
        }
    }

    Context 'Return Structure' {

        It 'should return correct structure for single resource' {
            InModuleScope MCP.SDK {
                # Arrange
                $mcpRoot = Join-Path $TestDrive 'single-server'
                $resourcesPath = Join-Path $mcpRoot 'resources'
                New-Item -Path $resourcesPath -ItemType Directory -Force | Out-Null
                New-TestResource -Path (Join-Path $resourcesPath 'single.txt') -Content "Single"

                # Act
                $result = Get-ResourceList -MCPRoot $mcpRoot

                # Assert
                $result | Should -BeOfType [hashtable]
                $result.resources | Should -Not -BeNullOrEmpty
                @($result.resources).Count | Should -Be 1
            }
        }

        It 'should return correct structure for multiple resources' {
            InModuleScope MCP.SDK {
                # Arrange
                $mcpRoot = Join-Path $TestDrive 'multiple-server'
                $resourcesPath = Join-Path $mcpRoot 'resources'
                New-Item -Path $resourcesPath -ItemType Directory -Force | Out-Null
                New-TestResource -Path (Join-Path $resourcesPath 'first.txt') -Content "First"
                New-TestResource -Path (Join-Path $resourcesPath 'second.json') -Content '{}'
                New-TestResource -Path (Join-Path $resourcesPath 'third.md') -Content '# Third'

                # Act
                $result = Get-ResourceList -MCPRoot $mcpRoot

                # Assert
                $result | Should -BeOfType [hashtable]
                @($result.resources).Count | Should -Be 3
            }
        }

        It 'should return correct structure when no resources exist' {
            InModuleScope MCP.SDK {
                # Arrange
                $mcpRoot = Join-Path $TestDrive 'noresources-structure'
                $resourcesPath = Join-Path $mcpRoot 'resources'
                New-Item -Path $resourcesPath -ItemType Directory -Force | Out-Null

                # Act
                $result = Get-ResourceList -MCPRoot $mcpRoot

                # Assert
                $result | Should -BeOfType [hashtable]
                $result.Keys | Should -Contain 'resources'
                @($result.resources).Count | Should -Be 0
            }
        }
    }

    Context 'Edge Cases and Error Handling' {

        It 'should handle resources with multiple dots in filename' {
            InModuleScope MCP.SDK {
                # Arrange
                $mcpRoot = Join-Path $TestDrive 'dots-server'
                $resourcesPath = Join-Path $mcpRoot 'resources'
                New-Item -Path $resourcesPath -ItemType Directory -Force | Out-Null
                New-TestResource -Path (Join-Path $resourcesPath 'file.name.with.dots.txt') -Content "Test"

                # Act
                $result = Get-ResourceList -MCPRoot $mcpRoot

                # Assert
                $result.resources[0].name | Should -Be 'file.name.with.dots'
                $result.resources[0].uri | Should -Be 'MCP://file.name.with.dots'
            }
        }

        It 'should handle deeply nested resources' {
            InModuleScope MCP.SDK {
                # Arrange
                $mcpRoot = Join-Path $TestDrive 'deep-server'
                $resourcesPath = Join-Path $mcpRoot 'resources'
                $deepPath = Join-Path $resourcesPath 'level1\level2\level3'
                New-Item -Path $deepPath -ItemType Directory -Force | Out-Null
                New-TestResource -Path (Join-Path $deepPath 'deep.txt') -Content "Deep"

                # Act
                $result = Get-ResourceList -MCPRoot $mcpRoot

                # Assert
                $result.resources[0].uri | Should -Be 'MCP://level1/level2/level3/deep'
            }
        }

        It 'should handle mixed file types in same directory' {
            InModuleScope MCP.SDK {
                # Arrange
                $mcpRoot = Join-Path $TestDrive 'mixed-server'
                $resourcesPath = Join-Path $mcpRoot 'resources'
                New-Item -Path $resourcesPath -ItemType Directory -Force | Out-Null
                New-TestResource -Path (Join-Path $resourcesPath 'text.txt') -Content "Text"
                New-TestResource -Path (Join-Path $resourcesPath 'data.json') -Content '{}'
                New-TestResource -Path (Join-Path $resourcesPath 'doc.md') -Content '# Doc'

                # Act
                $result = Get-ResourceList -MCPRoot $mcpRoot

                # Assert
                @($result.resources).Count | Should -Be 3
                @($result.resources | Where-Object { $_.mimeType -eq 'text/plain' }).Count | Should -Be 1
                @($result.resources | Where-Object { $_.mimeType -eq 'application/json' }).Count | Should -Be 1
                @($result.resources | Where-Object { $_.mimeType -eq 'text/markdown' }).Count | Should -Be 1
            }
        }
    }
}
