function Invoke-Tool {
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$MCPRoot,

        [hashtable]$Parameters = @{}
    )

    # Get the tool list
    $toolList = Get-ToolList -MCPRoot $MCPRoot
    $matchedTool = $toolList.tools | Where-Object { $_.name -eq $Name }

    if (-not $matchedTool) {
        throw "Tool '$Name' not found in tool list"
    }

    # Find the actual script file to execute
    $tool = Get-ChildItem -Path "$MCPRoot/tools" -Filter '*.ps1' |
        where basename -EQ $matchedTool.name

    if (-not $tool) {
        throw "Tool script file not found for tool [$Name]"
    }

    # Validate the caller's arguments against the tool's published inputSchema.
    # Any violations throw an ArgumentException which is surfaced to the client
    # as a JSON-RPC -32602 Invalid params error by ConvertTo-JsonRpcResponse.
    Test-ToolParameter -Schema $matchedTool.inputSchema -Parameters $Parameters

    # Execute the tool script with parameters
    $isError = $false
    $content = ""
    try {
        $content = Invoke-Script -Path $tool.FullName -Parameters $Parameters
    }
    catch {
        $isError = $true
        $content = $_.Exception
    }

    return @{
        result = @{
            isError           = $isError
            content           = @(
                @{
                    type = "text"
                    text = $content | Out-String
                }
            )
            structuredContent = $content
        }
    }
}