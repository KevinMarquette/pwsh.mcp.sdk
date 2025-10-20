function Get-Resource {
    param(
        [Parameter(Mandatory)]
        [string]$URI,

        [Parameter(Mandatory)]
        [string]$MCPRoot
    )

    # Extract URI prefix from incoming URI
    $uriPrefix = "file://"  # default
    if ($URI -match '^([a-zA-Z]+://)') {
        $uriPrefix = $matches[1]
    }

    $resourcesPath = Join-Path $MCPRoot "resources"

    if (-not (Test-Path $resourcesPath)) {
        throw "Resources folder not found at: $resourcesPath"
    }

    # Get all resources using Get-ResourceList
    $resourceList = Get-ResourceList -MCPRoot $MCPRoot -UriPrefix $uriPrefix
    $matchedResource = $resourceList.resources | Where-Object { $_.uri -eq $URI }

    if (-not $matchedResource) {
        throw "Resource '$URI' not found in resources folder"
    }

    # Find the actual file to get content
    $allFiles = Get-ChildItem -Path $resourcesPath -File -Recurse
    $resourceFile = $allFiles | Where-Object {
        $fileUri = ConvertTo-ResourceUri -FullName $_.FullName -Root $resourcesPath -UriPrefix $uriPrefix
        $fileUri -eq $URI
    }

    # Get the content
    $content = if ($resourceFile.Extension -eq '.ps1') {
        # Execute PS1 files
        & $resourceFile.FullName | Out-String
    }
    else {
        Get-Content -Path $resourceFile.FullName -Raw
    }

    # Add content to the resource record
    $matchedResource.text = $content
    return @{contents = @($matchedResource) }
}
