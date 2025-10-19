# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a PowerShell SDK for creating Model Context Protocol (MCP) servers. The SDK enables PowerShell scripts to be exposed as MCP resources, tools, and prompts through a convention-based folder structure.

**Key Principle**: The SDK uses a folder-based convention where PowerShell scripts placed in specific directories (`tools/`, `prompts/`, `resources/`) are automatically discovered and exposed via the MCP protocol.

## Module Structure

The module follows standard PowerShell module conventions:

- `MCP.SDK/MCP.SDK.psd1` - Module manifest defining metadata and exports
- `MCP.SDK/MCP.SDK.psm1` - Root module that loads all classes, private, and public functions
- `MCP.SDK/Private/` - Internal helper functions (currently exported for development/testing)
- `MCP.SDK/Public/` - Public-facing cmdlets (currently empty; main export is `Start-McpServer`)
- `Examples/reference-server/` - Example MCP server demonstrating the folder structure

## Development Commands

### Testing the Module
```powershell
# Import the module for testing
Import-Module ./MCP.SDK/MCP.SDK.psd1 -Force

# Test with the reference server example
Start-McpServer -MCPRoot ./Examples/reference-server
```

### Module Installation
```powershell
# Install locally for testing
Import-Module ./MCP.SDK/MCP.SDK.psm1
```

## Architecture

### MCP Request Processing Flow

1. **Entry Point**: The `Invoke-MCPRequest` function receives JSON-RPC requests via stdin
2. **Method Routing**: Based on the `method` field, requests are routed to appropriate handlers:
   - `initialize` → `Get-Initialization` (returns server capabilities)
   - `ping` → Returns empty object
   - `tools/list` → `Get-ToolList` (discovers .ps1 files in `tools/` directory)
   - `prompts/list` → `Get-PromptList` (discovers .ps1 files in `prompts/` directory)
   - `resources/list` → `Get-ResourceList` (discovers files in `resources/` directory)
3. **Response Formatting**: All responses use `ConvertTo-JsonRpcResponse` to wrap results in JSON-RPC format

### Convention-Based Discovery

The SDK discovers MCP capabilities by scanning the MCPRoot directory:

- **Tools**: PowerShell scripts in `{MCPRoot}/tools/*.ps1`
  - `Get-ToolSignature` extracts parameter info from PowerShell help and metadata
  - Parameters are converted to JSON schema using `ConvertTo-JsonType`
  - ValidateSet attributes become enum constraints in the schema

- **Prompts**: PowerShell scripts in `{MCPRoot}/prompts/*.ps1`
  - `Get-PromptSignature` extracts parameters and help information
  - Parameters become prompt arguments with descriptions

- **Resources**: Any files in `{MCPRoot}/resources/**/*`
  - Automatically assigned URIs based on relative path (e.g., `MCP://status/current-incidents`)
  - MIME types detected from file extensions
  - `.ps1` files: Help synopsis/description becomes resource metadata
  - `.md` files: First heading (`# Title`) becomes the resource title

### Type Conversion

`ConvertTo-JsonType` maps PowerShell types to JSON schema types:
- String → "string"
- Int32/Int64 → "integer"
- Boolean/SwitchParameter → "boolean"
- Double/Decimal → "number"
- Array types (e.g., `string[]`) → `{type: "array", items: {type: "string"}}`

### Signature Extraction

Both `Get-ToolSignature` and `Get-PromptSignature` rely on PowerShell's `Get-Help` and `Get-Command` to extract:
- Parameter names and types
- Required vs. optional parameters
- Help text for descriptions
- ValidateSet values for enum constraints

## Creating MCP Servers

To create a new MCP server:

1. Create a directory structure:
   ```
   my-server/
   ├── tools/          # Executable PowerShell scripts
   ├── prompts/        # Template scripts with parameters
   ├── resources/      # Static files or dynamic .ps1 scripts
   └── instructions.md # Optional: Server usage instructions
   ```

2. Write PowerShell scripts with proper help documentation:
   ```powershell
   <#
   .SYNOPSIS
   Brief description

   .DESCRIPTION
   Detailed description

   .EXAMPLE
   Example usage
   #>
   [CmdletBinding()]
   param(
       # Detailed description of the parameter
       [Parameter(Mandatory)]
       [ValidateSet('Option1', 'Option2')]
       [string]$ParamName
   )
   ```

3. Tools should return structured data (hashtables/objects)
4. Prompts should return text/markdown
5. Resources can be static files or .ps1 scripts that generate content

## Key Implementation Details

### JSON-RPC Protocol
- All requests/responses use JSON-RPC 2.0 format
- Protocol version: "2024-11-05"
- Errors use code -32603 for internal errors

### Capability Detection
`Get-Initialization` checks for the presence of files in each directory to determine server capabilities:
- If `tools/` contains .ps1 files → `capabilities.tools = {}`
- If `prompts/` contains .ps1 files → `capabilities.prompts = {}`
- If `resources/` contains files → `capabilities.resources = {}`

### Module Loading Order (MCP.SDK.psm1)
1. Classes (if any exist in `Classes/`)
2. Private functions (auto-exported for dev/testing)
3. Public functions (matches manifest exports)

## Example Reference Server

The `Examples/reference-server` demonstrates an incident management system with:
- **Tools**: Create-Incident, Update-IncidentStatus, Search-Incidents
- **Prompts**: Incident-Response-Plan, Status-Update-Template, Post-Mortem-Template
- **Resources**: current-incidents, incident-summary

Study these examples to understand the expected script structure and return formats.

## Important Notes

- The module requires PowerShell 5.1+ and supports both Desktop and Core editions
- Private functions are currently exported (see MCP.SDK.psm1:31) for development purposes
- The Public directory exists but contains no files yet - main functionality is in Private/
- Resource URIs use forward slashes regardless of OS path separators
- All timestamps should use ISO 8601 format for consistency
