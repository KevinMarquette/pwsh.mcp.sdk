@{
    Severity=@('Error','Warning', 'Information')
    ExcludeRules=@(
        'PSUseShouldProcessForStateChangingFunctions'
        'PSUseOutputTypeCorrectly'
        'PSUseSingularNouns'
    )
    # allow where and select alias names
    Rules =@{
        PSAvoidUsingCmdletAliases  = @{
            Enable = $true
            Whitelist = @('Where', 'Select')
        }
    }
}