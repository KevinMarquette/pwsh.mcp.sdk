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
            $exception = if ($InputObject -is [System.Management.Automation.ErrorRecord]) {
                $InputObject.Exception
            }
            else {
                $InputObject
            }
            $jsonRpcObject.error = @{
                code    = -32603
                message = $InputObject.ToString()
            }
            if ($exception -is [System.NotImplementedException]) {
                $jsonRpcObject.error.code = -32601
            }
            elseif ($exception -is [System.IO.FileNotFoundException]) {
                $jsonRpcObject.error.code = -32602
                $jsonRpcObject.error.data = @{
                    uri = $exception.FileName
                }
            }
            elseif ($exception -is [System.ArgumentException]) {
                # Schema / parameter validation failure -> JSON-RPC Invalid params
                $jsonRpcObject.error.code = -32602
                $jsonRpcObject.error.message = $exception.Message
            }
        }
        # handle everything else as result
        else {
            $jsonRpcObject.result = $InputObject
        }

        Write-Output $jsonRpcObject
    }
}