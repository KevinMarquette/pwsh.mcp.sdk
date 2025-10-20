# Pester Testing Guidelines

This document outlines specific patterns and practices for writing Pester tests in this PowerShell project.

## Testing Private Functions

Use `InModuleScope` to test private functions that are not exported from the module:

```powershell
Describe 'Private-Function' -Tag 'Unit' {
    It 'should do something' {
        InModuleScope ModuleName {
            # Test private function here
            $result = Private-Function -Parameter "value"
            $result | Should -Be "expected"
        }
    }
}
```

## Helper Functions in Tests

Define helper functions that will be used within `InModuleScope` using the `Script:` prefix:

```powershell
BeforeAll {
    InModuleScope ModuleName {
        function Script:New-TestHelper {
            param([string]$Parameter)
            # Helper function implementation
        }
    }
}
```

## Using TestCases

When multiple tests follow the same pattern with different data, use TestCases to reduce duplication:

```powershell
It 'should handle <Description>' -TestCases @(
    @{ Input = "value1"; Expected = "result1"; Description = "first case" }
    @{ Input = "value2"; Expected = "result2"; Description = "second case" }
) {
    param($Input, $Expected)

    # Test implementation
    $result = Function-Under-Test -Parameter $Input
    $result | Should -Be $Expected
}
```

## TestCases with InModuleScope

When using TestCases with `InModuleScope`, parameters must be passed explicitly:

```powershell
It 'should handle <Description>' -TestCases @(
    @{ Input = "value1"; Expected = "result1"; Description = "first case" }
) {
    param($Input, $Expected)

    InModuleScope ModuleName -Parameters ([hashtable]$PSBoundParameters) {
        # Now $Input and $Expected are available in module scope
        $result = Private-Function -Parameter $Input
        $result | Should -Be $Expected
    }
}
```

## Key Points

- **Always use `InModuleScope`** for testing private functions.
- **Use `Script:` prefix** for helper functions defined within `InModuleScope`.
- **Use TestCases** to reduce code duplication when tests follow similar patterns.
- **Keep TestCases Simple** as just key value pairs with the validation inside the test. Each testcase in a set should specify all the keys.
- **Pass parameters explicitly** when combining TestCases with `InModuleScope` using `-Parameters ([hashtable]$PSBoundParameters)`.
- Use TestDrive: or $testdrive instead of $ENV:TEMP for temporary files