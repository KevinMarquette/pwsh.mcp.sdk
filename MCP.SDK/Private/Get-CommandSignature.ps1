function Get-CommandSignature {
    param($CommandName)
    $cmd = Get-Command $CommandName
    $help = $cmd | Get-Help
 
    $parameters = $help.parameters.parameter

    $response = @{
        name        = $CommandName
        title       = $help.synopsis ?? "No description available"
        description = $help.description.text
        inputSchema = @{
            type       = "object"
            properties = @{}                     
        }
    }
    $required = @()
    foreach ($param in $parameters) {
        $type = $param.parameterValue -replace "SwitchParameter", "boolean"
        $response.inputSchema.properties[$param.Name] = @{
            type        = $type
            description = $param.description.text -join '' ?? "No description available"        
        }
        if ("true" -eq $param.required) {
            Write-Host "Adding required parameter: $($param.Name)"
            $required += $param.Name
        }
    }
    if ($required.Count -gt 0) {
        $response.inputSchema.required = $required
    }
    $response
}