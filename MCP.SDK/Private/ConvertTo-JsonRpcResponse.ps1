function ConvertTo-JsonRpcResponse {
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline)]
        $InputObject,
        $ID
    )

    process {
        foreach ($item in $InputObject) {
            $jsonRpcObject = [ordered]@{
                jsonrpc = "2.0"
                id      = $ID
            }

            # handle result or error if already present
            if ($item.PSObject.Properties.Name -contains 'result') {
                $jsonRpcObject.result = $item.result
            } elseif ($item.PSObject.Properties.Name -contains 'error') {
                $jsonRpcObject.error = $item.error
                $jsonRpcObject.code = $item.code
            }
            # handle error records and exceptions
            elseif ($item -is [ErrorRecord] -or $item -is [System.Exception]) {
                $jsonRpcObject.error = @{
                    code    = -32603
                    message = $item.ToString()
                }
            }
            # handle everything else as result
            else {
                $jsonRpcObject.result = $item
            }

            Write-Output $jsonRpcObject
        }
    }
}