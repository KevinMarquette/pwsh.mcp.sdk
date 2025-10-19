function ConvertTo-JsonRpcResponse {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        $InputObject,
        $ID
    )

    process {
        if ( -not $InputObject) {
            $InputObject = @()
        }
        $jsonRpcObject = [ordered]@{
            jsonrpc = "2.0"
            id      = $ID
        }

        # handle result or error if already present
        if ($InputObject.result) {
            $jsonRpcObject.result = $InputObject.result
        }
        elseif ($InputObject.error) {
            $jsonRpcObject.error = $InputObject.error
        }
        # handle error records and exceptions
        elseif ($InputObject -is [System.Management.Automation.ErrorRecord] -or $InputObject -is [System.Exception]) {
            $jsonRpcObject.error = @{
                code    = -32603
                message = $InputObject.ToString()
            }
            if ($InputObject -is [System.NotImplementedException]) {
                $jsonRpcObject.error.code = -32601
            }
            if ($InputObject -is [System.IO.FileNotFoundException]) {
                $jsonRpcObject.error.code = -32602
                $jsonRpcObject.error.data = @{
                    uri = $InputObject.FileName
                }
            }
        }
        # handle everything else as result
        else {
            $jsonRpcObject.result = $InputObject
        }

        Write-Output $jsonRpcObject
    }
}