function Get-PromptSignature {
    param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias("FullName")]
        [string]$Path
    )
    process {
        $file = Get-Item $Path
        $help = Get-Help $Path

        $cmd = Get-Command $Path

        # Build response
        $response = [ordered]@{
            name = $file.BaseName
        }
        if ($help.synopsis) {
            $response.title = $help.synopsis -join "`n"
        }
        if ($help.description) {
            $response.description = $help.description.text -join "`n"
        }

        # Build arguments
        $response.arguments = @()
        foreach ($param in $help.parameters.parameter) {
            $enum = $cmd.Parameters[$param.Name].Attributes.ValidValues
            $argument = [ordered]@{
                name     = $param.Name
                required = ("true" -eq $param.required)
            }
            if ($param.description.text) {
                $argument.description = $param.description.text -join ''
            }
            # Add enum info to description
            if ($enum) {
                $argument.description += ". Valid Values [$($enum -join ',')]"
            }
            $response.arguments += $argument
        }
        $response
    }
}