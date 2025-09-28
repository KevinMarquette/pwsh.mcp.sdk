# MCP.SDK Examples

This folder contains example implementations demonstrating various features of the PowerShell MCP Server SDK.

## Available Examples

### reference-server
A complete incident response management MCP server that demonstrates all SDK features:

- **Resources**: Static configuration files, dynamic PowerShell reports, markdown guidance documents, and individual incident records
- **Tools**: Incident creation, status updates, and search capabilities with full parameter validation
- **Prompts**: Response plan generation, status update templates, and post-mortem frameworks
- **Real-world Theme**: Practical incident management workflows that show immediate business value

**Location**: `reference-server/`

**Features Demonstrated**:
- Convention-based folder organization
- Static and dynamic resource serving
- PowerShell script execution with parameter validation
- JSON data management and manipulation
- Markdown documentation as contextual resources
- Complex business logic and workflows
- Security best practices (whitelist approach, input validation)
- Performance optimizations (pipeline usage, single-pass enumeration)

### Usage

Each example can be run as a standalone MCP server:

```powershell
# Import the MCP.SDK module
Import-Module .\MCP.SDK

# Start the reference server
Start-McpServer -RootPath .\Examples\reference-server -Name "incident-response"
```

## Creating Your Own Examples

When creating new examples:

1. **Choose a clear theme** that demonstrates real-world value
2. **Create the folder structure**: `resources/`, `tools/`, `prompts/`, `modules/` (as needed)
3. **Add an instructions.md** file with guidance for AI assistants
4. **Demonstrate progressively complex features** from simple to advanced
5. **Include proper error handling** and security practices
6. **Document the business value** and use cases clearly

## Testing Examples

All examples should be tested with the reference implementation to ensure they work correctly with the SDK.

```powershell
# Run tests for all examples
.\Test-Module.ps1 -TestType Integration
```

See individual example folders for specific setup and usage instructions.