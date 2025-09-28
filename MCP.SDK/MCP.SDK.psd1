@{
    # Module manifest for MCP.SDK
    RootModule = 'MCP.SDK.psm1'
    ModuleVersion = '0.1.0'
    GUID = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'

    Author = 'PowerShell MCP SDK Team'
    CompanyName = 'Open Source'
    Copyright = '(c) 2024 PowerShell MCP SDK Contributors. All rights reserved.'

    Description = 'PowerShell SDK for creating Model Context Protocol (MCP) servers that expose PowerShell scripts as MCP resources, tools, and prompts through simple folder organization.'

    # Minimum PowerShell version
    PowerShellVersion = '5.1'

    # Compatible PowerShell editions
    CompatiblePSEditions = @('Desktop', 'Core')

    # Functions to export from this module
    FunctionsToExport = @(
        'Start-McpServer'
    )

    # Cmdlets to export from this module
    CmdletsToExport = @()

    # Variables to export from this module
    VariablesToExport = @()

    # Aliases to export from this module
    AliasesToExport = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess
    PrivateData = @{
        PSData = @{
            # Tags applied to this module for online gallery searches
            Tags = @('MCP', 'ModelContextProtocol', 'AI', 'ToolKit')

            # License for this module
            LicenseUri = 'https://github.com/KevinMarquette/pwsh.mcp.sdk/blob/main/LICENSE'

            # Project site for this module
            ProjectUri = 'https://github.com/KevinMarquette/pwsh.mcp.sdk'

            # Icon for this module
            # IconUri = ''

            # Release notes for this module
            ReleaseNotes = @'
# Release Notes

## Version 0.1.0
- Initial release of PowerShell MCP Server SDK
'@

            # Prerelease string
            Prerelease = 'alpha'

            # Flag to indicate whether the module requires explicit user acceptance for install/update
            RequireLicenseAcceptance = $false

            # External dependent modules of this module
            ExternalModuleDependencies = @()
        }
    }

    # HelpInfo URI of this module
    # HelpInfoURI = ''

    # Default prefix for commands exported from this module
    # DefaultCommandPrefix = ''
}