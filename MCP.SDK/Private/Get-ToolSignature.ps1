function Get-ToolSignature {
    param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias("FullName")]
        [string]    
        $Path
    )
    process {

        $help = Get-Help $Path
        $file = Get-Item $Path
        $cmd = Get-Command $Path

        $parameters = $help.parameters.parameter
    
        $response = [ordered]@{
            name        = $file.BaseName
            description = $help.description.text -join "`n"
            inputSchema = @{
                type       = "object"
                properties = [ordered]@{}                     
            }
        }
        if ($help.synopsis) {
            $response.title = $help.synopsis -join "`n"
        }
        $required = @()
        foreach ($param in $parameters) {
            $type = $param.parameterValue | ConvertTo-JsonType
            $enum = $cmd.Parameters[$param.Name].Attributes.ValidValues
    
            $schema = [ordered]@{
                name = $param.Name
            }
            if ($param.description.text) {
                $schema.description = $param.description.text -join ''
            }
    
            $schema += $type
            if ($enum) {
                if ($schema.type -eq "array") {
                    $schema.items.enum = $enum
                }
                else {
                    $schema.enum = $enum
                }
            }
            
            $response.inputSchema.properties[$param.Name] = $schema
            if ("true" -eq $param.required) {
                $required += $param.Name
            }
        }
        if ($required.Count -gt 0) {
            $response.inputSchema.required = $required
        }
        $response
    }
}