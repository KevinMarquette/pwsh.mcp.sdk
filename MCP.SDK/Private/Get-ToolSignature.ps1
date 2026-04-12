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

        # Index help parameters by name so we can look up descriptions while
        # iterating over the authoritative parameter list from Get-Command.
        # Get-Help returns $null for scripts without comment-based help, so it
        # cannot be the source of truth for the parameter list itself.
        $helpParams = @{}
        foreach ($hp in @($help.parameters.parameter)) {
            if ($hp) { $helpParams[$hp.Name] = $hp }
        }

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

        # Common parameters injected by [CmdletBinding()] must be excluded
        # from the published tool schema.
        $commonParams = [System.Management.Automation.PSCmdlet]::CommonParameters +
                        [System.Management.Automation.PSCmdlet]::OptionalCommonParameters

        $required = @()
        foreach ($paramName in $cmd.Parameters.Keys) {
            if ($paramName -in $commonParams) { continue }

            $paramInfo = $cmd.Parameters[$paramName]
            $paramType = $paramInfo.ParameterType

            $schema = [ordered]@{
                name = $paramName
            }

            $helpParam = $helpParams[$paramName]
            if ($helpParam -and $helpParam.description.text) {
                $schema.description = $helpParam.description.text -join ''
            }

            # Untyped parameters (`param($x)`) surface as [object]. JSON schema
            # has no "any" keyword, so omit 'type' entirely - that lets
            # Test-ToolParameter accept any value rather than narrowing to the
            # JSON object type.
            if ($paramType -ne [object]) {
                $schema += ($paramType.Name | ConvertTo-JsonType)
            }

            $enum = $paramInfo.Attributes.ValidValues
            if ($enum) {
                if ($schema.type -eq "array") {
                    $schema.items.enum = $enum
                }
                else {
                    $schema.enum = $enum
                }
            }

            $response.inputSchema.properties[$paramName] = $schema

            $isMandatory = $false
            foreach ($attr in $paramInfo.Attributes) {
                if ($attr -is [System.Management.Automation.ParameterAttribute] -and $attr.Mandatory) {
                    $isMandatory = $true
                    break
                }
            }
            if ($isMandatory) {
                $required += $paramName
            }
        }
        if ($required.Count -gt 0) {
            $response.inputSchema.required = $required
        }
        $response
    }
}