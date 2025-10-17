function ConvertTo-JsonType {
    <#
        .Synopsis
        Converts a PowerShell type name to a JSON schema type.
        .Example
        ConvertTo-JsonType -PStypeName $Path

        .Notes
        
    #>
    [cmdletbinding()]
    param(
        # Parameter help description
        [Parameter(
            Mandatory,
            Position = 0,
            ValueFromPipeline
        )]
        [ValidateNotNullOrEmpty()]
        [Alias("Type")]
        $PSTypeName
    )

    process {
        $jsonType = switch -Regex ($PSTypeName) {
            "String" { "string" }
            "Int32" { "integer" }
            "Int64" { "integer" }
            "Boolean" { "boolean" }
            "Double" { "number" }
            "Decimal" { "number" }
            "DateTime" { "string" }
            "SwitchParameter" { "boolean" }
            "Object" { "object" }
            "Hashtable" { "object" }
            "Array" { "array" }
            default { "string" }
        }
        # Check if the type is an array
        if ($PSTypeName -match "\[\]$") {
            return @{
                type  = "array"
                items = @{
                    type = $jsonType
                }
            }
        } else {
            return @{type=$jsonType}
        }
    }
}
