function Test-ToolParameter {
    <#
    .SYNOPSIS
        Validates a parameter hashtable against a tool's JSON inputSchema.

    .DESCRIPTION
        Checks required parameters, unknown parameters, primitive type
        compatibility, and enum / ValidateSet constraints. Throws an
        ArgumentException listing all violations if the parameters do not
        conform to the schema. The caller is expected to let the exception
        bubble up so ConvertTo-JsonRpcResponse can map it to JSON-RPC error
        code -32602 (Invalid params).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Schema,

        [hashtable]$Parameters = @{}
    )

    $errors = [System.Collections.Generic.List[string]]::new()
    $properties = $Schema.properties
    $required = @()
    if ($Schema.Contains('required')) {
        $required = @($Schema.required)
    }

    # Required parameters must be present
    foreach ($name in $required) {
        if (-not $Parameters.ContainsKey($name)) {
            $errors.Add("Missing required parameter '$name'.")
        }
    }

    foreach ($key in @($Parameters.Keys)) {
        if (-not $properties -or -not $properties.Contains($key)) {
            $errors.Add("Unknown parameter '$key' is not defined in the tool schema.")
            continue
        }

        $propSchema = $properties[$key]
        $value = $Parameters[$key]
        $expectedType = $propSchema.type

        if ($null -eq $value) {
            if ($key -in $required) {
                $errors.Add("Parameter '$key' cannot be null.")
            }
            continue
        }

        $typeValid = switch ($expectedType) {
            'string'  { $value -is [string] }
            'integer' { ($value -is [int] -or $value -is [long] -or $value -is [byte] -or $value -is [int16]) -and $value -isnot [bool] }
            'number'  { ($value -is [int] -or $value -is [long] -or $value -is [double] -or $value -is [decimal] -or $value -is [single]) -and $value -isnot [bool] }
            'boolean' { $value -is [bool] }
            'array'   { $value -is [array] -or $value -is [System.Collections.IList] }
            'object'  { $value -is [hashtable] -or $value -is [System.Collections.IDictionary] -or $value -is [pscustomobject] }
            default   { $true }
        }
        if (-not $typeValid) {
            $actual = $value.GetType().Name
            $errors.Add("Parameter '$key' expected type '$expectedType' but received '$actual'.")
            continue
        }

        # Enum / ValidateSet constraint on a scalar
        if ($propSchema.enum -and $expectedType -ne 'array') {
            if ($value -notin $propSchema.enum) {
                $allowed = ($propSchema.enum -join "', '")
                $errors.Add("Parameter '$key' value '$value' is not one of the allowed values: '$allowed'.")
            }
        }

        # Enum constraint on array items
        if ($expectedType -eq 'array' -and $propSchema.items -and $propSchema.items.enum) {
            foreach ($item in $value) {
                if ($item -notin $propSchema.items.enum) {
                    $allowed = ($propSchema.items.enum -join "', '")
                    $errors.Add("Parameter '$key' contains invalid item '$item'; allowed item values: '$allowed'.")
                }
            }
        }
    }

    if ($errors.Count -gt 0) {
        $message = "Invalid parameters: " + ($errors -join ' ')
        throw [System.ArgumentException]::new($message)
    }
}
