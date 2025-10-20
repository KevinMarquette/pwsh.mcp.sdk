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

            $Content | Set-Content -Path $Path -NoNewline

            return $Path
        }
    }
}

Describe 'Get-Resource' -Tag 'Unit' {

    Context 'Basic Functionality' {

        It 'should retrieve resource by URI with default prefix' {
            InModuleScope MCP.SDK {
                # Arrange
                $mcpRoot = Join-Path $TestDrive 'basic-server'
                $resourcesPath = Join-Path $mcpRoot 'resources'
                New-Item -Path $resourcesPath -ItemType Directory -Force | Out-Null
                New-TestResource -Path (Join-Path $resourcesPath 'test.txt') -Content "Test content"

                # Act
                $result = Get-Resource -URI "file://test" -MCPRoot $mcpRoot

                # Assert
                $result | Should -Not -BeNullOrEmpty
                $result.contents | Should -HaveCount 1
                $result.contents[0].text | Should -Be "Test content"
                $result.contents[0].uri | Should -Be "file://test"
                $result.contents[0].name | Should -Be "test"
            }
        }

        It 'should retrieve resource by URI with custom prefix' {
            InModuleScope MCP.SDK {
                # Arrange
                $mcpRoot = Join-Path $TestDrive 'custom-server'
                $resourcesPath = Join-Path $mcpRoot 'resources'
                New-Item -Path $resourcesPath -ItemType Directory -Force | Out-Null
                New-TestResource -Path (Join-Path $resourcesPath 'document.md') -Content "# Document"

                # Act
                $result = Get-Resource -URI "file://document" -MCPRoot $mcpRoot

                # Assert
                $result | Should -Not -BeNullOrEmpty
                $result.contents | Should -HaveCount 1
                $result.contents[0].text | Should -Be "# Document"
                $result.contents[0].uri | Should -Be "file://document"
                $result.contents[0].mimeType | Should -Be "text/markdown"
            }
        }

        It 'should retrieve nested resource' {
            InModuleScope MCP.SDK {
                # Arrange
                $mcpRoot = Join-Path $TestDrive 'nested-server'
                $resourcesPath = Join-Path $mcpRoot 'resources'
                $subPath = Join-Path $resourcesPath 'status'
                New-Item -Path $subPath -ItemType Directory -Force | Out-Null
                New-TestResource -Path (Join-Path $subPath 'current.txt') -Content "Current status"

                # Act
                $result = Get-Resource -URI "file://status/current" -MCPRoot $mcpRoot

                # Assert
                $result | Should -Not -BeNullOrEmpty
                $result.contents | Should -HaveCount 1
                $result.contents[0].text | Should -Be "Current status"
                $result.contents[0].uri | Should -Be "file://status/current"
            }
        }

        It 'should execute PowerShell script and return output' {
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
Write-Output "Script executed successfully"
'@
                New-TestResource -Path (Join-Path $resourcesPath 'script.ps1') -Content $script -Extension ".ps1"

                # Act
                $result = Get-Resource -URI "file://script" -MCPRoot $mcpRoot

                # Assert
                $result | Should -Not -BeNullOrEmpty
                $result.contents | Should -HaveCount 1
                $result.contents[0].text | Should -Match "Script executed successfully"
                $result.contents[0].title | Should -Be "Test script"
            }
        }
    }

    Context 'Resource Metadata' {

        It 'should include all metadata from Get-ResourceList' {
            InModuleScope MCP.SDK {
                # Arrange
                $mcpRoot = Join-Path $TestDrive 'metadata-server'
                $resourcesPath = Join-Path $mcpRoot 'resources'
                New-Item -Path $resourcesPath -ItemType Directory -Force | Out-Null
                New-TestResource -Path (Join-Path $resourcesPath 'data.json') -Content '{"key":"value"}'

                # Act
                $result = Get-Resource -URI "file://data" -MCPRoot $mcpRoot

                # Assert
                $result.contents[0].uri | Should -Be "file://data"
                $result.contents[0].name | Should -Be "data"
                $result.contents[0].mimeType | Should -Be "application/json"
                $result.contents[0].text | Should -Be '{"key":"value"}'
            }
        }

        It 'should include title for markdown files' {
            InModuleScope MCP.SDK {
                # Arrange
                $mcpRoot = Join-Path $TestDrive 'md-title-server'
                $resourcesPath = Join-Path $mcpRoot 'resources'
                New-Item -Path $resourcesPath -ItemType Directory -Force | Out-Null
                $markdown = @'
# Important Document

This is the content.
'@
                New-TestResource -Path (Join-Path $resourcesPath 'doc.md') -Content $markdown

                # Act
                $result = Get-Resource -URI "file://doc" -MCPRoot $mcpRoot

                # Assert
                $result.contents[0].title | Should -Be "Important Document"
                $result.contents[0].text | Should -Be $markdown
            }
        }

        It 'should include title and description for PowerShell scripts' {
            InModuleScope MCP.SDK {
                # Arrange
                $mcpRoot = Join-Path $TestDrive 'ps1-help-server'
                $resourcesPath = Join-Path $mcpRoot 'resources'
                New-Item -Path $resourcesPath -ItemType Directory -Force | Out-Null
                $script = @'
<#
.SYNOPSIS
Status checker

.DESCRIPTION
Checks the current system status
#>
Write-Output "System OK"
'@
                New-TestResource -Path (Join-Path $resourcesPath 'status.ps1') -Content $script -Extension ".ps1"

                # Act
                $result = Get-Resource -URI "file://status" -MCPRoot $mcpRoot

                # Assert
                $result.contents[0].title | Should -Be "Status checker"
                $result.contents[0].description | Should -Be "Checks the current system status"
                $result.contents[0].text | Should -Match "System OK"
            }
        }
    }

    Context 'Error Handling' {

        It 'should throw when resource not found' {
            InModuleScope MCP.SDK {
                # Arrange
                $mcpRoot = Join-Path $TestDrive 'notfound-server'
                $resourcesPath = Join-Path $mcpRoot 'resources'
                New-Item -Path $resourcesPath -ItemType Directory -Force | Out-Null

                # Act & Assert
                { Get-Resource -URI "file://nonexistent" -MCPRoot $mcpRoot } | Should -Throw "*not found*"
            }
        }

        It 'should throw when resources folder does not exist' {
            InModuleScope MCP.SDK {
                # Arrange
                $mcpRoot = Join-Path $TestDrive 'nofolder-server'

                # Act & Assert
                { Get-Resource -URI "file://test" -MCPRoot $mcpRoot } | Should -Throw "*Resources folder not found*"
            }
        }

        It 'should include URI in error message' {
            InModuleScope MCP.SDK {
                # Arrange
                $mcpRoot = Join-Path $TestDrive 'error-uri-server'
                $resourcesPath = Join-Path $mcpRoot 'resources'
                New-Item -Path $resourcesPath -ItemType Directory -Force | Out-Null

                # Act & Assert
                { Get-Resource -URI "custom://missing" -MCPRoot $mcpRoot } | Should -Throw "*custom://missing*"
            }
        }
    }

    Context 'URI Prefix Handling' {

        It 'should handle <Description>' -TestCases @(
            @{ URI = "file://test"; FileName = "test.txt"; Content = "File content"; Description = "file:// prefix" }
            @{ URI = "http://api"; FileName = "api.json"; Content = '{"status":"ok"}'; Description = "http:// prefix" }
            @{ URI = "myscheme://config"; FileName = "config.yaml"; Content = "key: value"; Description = "custom scheme" }
            @{ URI = "https://secure"; FileName = "secure.txt"; Content = "Secure content"; Description = "https:// prefix" }
        ) {
            param($URI, $FileName, $Content)

            InModuleScope MCP.SDK -Parameters ([hashtable]$PSBoundParameters) {
                # Arrange
                $mcpRoot = Join-Path $TestDrive "prefix-server-$(Get-Random)"
                $resourcesPath = Join-Path $mcpRoot 'resources'
                New-Item -Path $resourcesPath -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
                New-TestResource -Path (Join-Path $resourcesPath $FileName) -Content $Content

                # Act
                $result = Get-Resource -URI $URI -MCPRoot $mcpRoot

                # Assert
                $result.contents[0].text | Should -Be $Content
                $result.contents[0].uri | Should -Be $URI
            }
        }
    }

    Context 'File Type Handling' {

        It 'should handle <Description>' -TestCases @(
            @{ FileName = "readme.txt"; Content = "Plain text content"; ExpectedMimeType = "text/plain"; Description = "text files" }
            @{ FileName = "config.json"; Content = '{"setting": "value"}'; ExpectedMimeType = "application/json"; Description = "JSON files" }
            @{ FileName = "config.yml"; Content = "setting: value"; ExpectedMimeType = "application/yaml"; Description = "YAML files" }
            @{ FileName = "config.yaml"; Content = "key: value"; ExpectedMimeType = "application/yaml"; Description = "YAML files with .yaml extension" }
            @{ FileName = "document.md"; Content = "# Title"; ExpectedMimeType = "text/markdown"; Description = "Markdown files" }
            @{ FileName = "data.xml"; Content = "<root></root>"; ExpectedMimeType = "application/xml"; Description = "XML files" }
        ) {
            param($FileName, $Content, $ExpectedMimeType)

            InModuleScope MCP.SDK -Parameters ([hashtable]$PSBoundParameters) {
                # Arrange
                $mcpRoot = Join-Path $TestDrive "filetype-server-$(Get-Random)"
                $resourcesPath = Join-Path $mcpRoot 'resources'
                New-Item -Path $resourcesPath -ItemType Directory -Force | Out-Null
                New-TestResource -Path (Join-Path $resourcesPath $FileName) -Content $Content

                $baseName = [System.IO.Path]::GetFileNameWithoutExtension($FileName)
                $uri = "file://$baseName"

                # Act
                $result = Get-Resource -URI $uri -MCPRoot $mcpRoot

                # Assert
                $result.contents[0].text | Should -Be $Content
                $result.contents[0].mimeType | Should -Be $ExpectedMimeType
            }
        }
    }

    Context 'Edge Cases' {

        It 'should handle <Description>' -TestCases @(
            @{
                FileName     = "file.name.with.dots.txt"
                SubPath      = ""
                URI          = "file://file.name.with.dots"
                Content      = "Dotted content"
                ExpectedName = "file.name.with.dots"
                Description  = "files with multiple dots in name"
            }
            @{
                FileName     = "deep.txt"
                SubPath      = "level1\level2\level3"
                URI          = "file://level1/level2/level3/deep"
                Content      = "Deep content"
                ExpectedName = "deep"
                Description  = "deeply nested resources"
            }
            @{
                FileName     = "LICENSE"
                SubPath      = ""
                URI          = "file://LICENSE"
                Content      = "MIT License"
                ExpectedName = "LICENSE"
                Description  = "files without extension"
            }
        ) {
            param($FileName, $SubPath, $URI, $Content, $ExpectedName)

            InModuleScope MCP.SDK -Parameters ([hashtable]$PSBoundParameters) {
                # Arrange
                $mcpRoot = Join-Path $TestDrive "edge-server-$(Get-Random)"
                $resourcesPath = Join-Path $mcpRoot 'resources'
                $targetPath = if ($SubPath) { Join-Path $resourcesPath $SubPath } else { $resourcesPath }
                New-Item -Path $targetPath -ItemType Directory -Force | Out-Null
                New-TestResource -Path (Join-Path $targetPath $FileName) -Content $Content

                # Act
                $result = Get-Resource -URI $URI -MCPRoot $mcpRoot

                # Assert
                $result.contents[0].text | Should -Be $Content
                $result.contents[0].name | Should -Be $ExpectedName
                $result.contents[0].uri | Should -Be $URI
            }
        }
    }

    Context 'Integration' {

        It 'should work with reference-server if available' {
            InModuleScope MCP.SDK {
                # Arrange
                $refServerPath = Join-Path $PSScriptRoot '..\..\Examples\reference-server'

                # Act & Assert
                if (Test-Path $refServerPath) {
                    $refServerPath = (Resolve-Path $refServerPath).Path
                    $resourceList = Get-ResourceList -MCPRoot $refServerPath
                    if (@($resourceList.resources).Count -gt 0) {
                        $firstResource = $resourceList.resources[0]
                        $result = Get-Resource -URI $firstResource.uri -MCPRoot $refServerPath

                        $result | Should -Not -BeNullOrEmpty
                        $result.contents | Should -HaveCount 1
                        $result.contents[0].uri | Should -Be $firstResource.uri
                        $result.contents[0].text | Should -Not -BeNullOrEmpty
                    }
                }
            }
        }
    }
}