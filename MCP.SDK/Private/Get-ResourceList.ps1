function Get-ResourceList {
    <#
    .SYNOPSIS
        Retrieves a list of available resources.
    #>
    [CmdletBinding()]
    param(
        [string]$MCPRoot,
        [string]$UriPrefix = "file://"
    )
    $resourcesPath = (Resolve-Path "$MCPRoot/resources").Path

    $resourceFiles = Get-ChildItem -Path "$resourcesPath" -File -Recurse

    $response = @()
    foreach ($resourceFile in $resourceFiles) {
        # Get URI using ConvertTo-ResourceUri
        Write-Verbose "FullName [$($resourceFile.FullName)] ResourcesPath [$($resourcesPath.Length)]"
        $uri = ConvertTo-ResourceUri -FullName $resourceFile.FullName -Root $resourcesPath -UriPrefix $UriPrefix
        # Determine Mime Type
        $mimeType = switch ($resourceFile.Extension.ToLower()) {
            ".txt" { "text/plain" }
            ".md" { "text/markdown" }
            ".json" { "application/json" }
            ".yaml" { "application/yaml" }
            ".yml" { "application/yaml" }
            ".xml" { "application/xml" }
            ".jpg" { "image/jpeg" }
            ".jpeg" { "image/jpeg" }
            ".png" { "image/png" }
            ".gif" { "image/gif" }
            ".html" { "text/html" }
        }
        $resourceRecord = [ordered]@{
            uri  = $uri
            name = $resourceFile.BaseName
        }
        if ($resourceFile.Extension -eq ".ps1") {
            # For script files, get help info
            $help = Get-Help $resourceFile.FullName
            if ($help.synopsis) {
                $resourceRecord.title = $help.synopsis -join "`n"
            }
            if ($help.description) {
                $resourceRecord.description = $help.description.text -join "`n"
            }
        }
        if ($resourceFile.Extension -eq ".md") {
            # For markdown files, extract title from first line
            $firstLine = Get-Content -Path $resourceFile.FullName -TotalCount 1
            if ($firstLine -match '^#\s+(.*)') {
                $resourceRecord.title = $Matches[1].Trim()
            }
        }
        if ($mimeType) {
            $resourceRecord.mimeType = $mimeType
        }
        $response += $resourceRecord
    }
    return @{resources = $response }
}