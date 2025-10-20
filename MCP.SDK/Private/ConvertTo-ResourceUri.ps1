function ConvertTo-ResourceUri {
    param(
        [string]$FullName,
        [string]$Root,
        [string]$UriPrefix = "file://"
    )
    $relativePath = $FullName.Substring($Root.Length).TrimStart('\', '/')
    # Remove file extension for name
    $resourceName = if ($relativePath -match '(.+)\.[^.]+$') { $matches[1] } else { $relativePath }
    $uri = $UriPrefix + $resourceName -replace '\\', '/'
    return $uri
}