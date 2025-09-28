<#
.SYNOPSIS
Generates a simple status update message for incident communication

.DESCRIPTION
Creates a basic status update message with incident details filled in
from the provided parameters.

.EXAMPLE
Status-Update-Template -IncidentId "INC-2024-001" -Summary "Database performance issues resolved"
#>

[CmdletBinding()]
param(
    # ID of the incident being updated
    [Parameter(
        Mandatory,
        HelpMessage = "Enter the incident ID"
    )]
    [string]$IncidentId,

    # Brief summary of the current status
    [Parameter(
        Mandatory,
        HelpMessage = "Provide a brief status summary"
    )]
    [string]$Summary,

    # Name of the person providing the update
    [Parameter()]
    [string]$UpdatedBy = $env:USERNAME
)

@"
# Incident Status Update

**Incident ID:** $IncidentId
**Status:** $Summary
**Updated By:** $UpdatedBy
**Timestamp:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss UTC')

## Current Status
$Summary

## Next Update
The next status update will be provided within 2 hours or when significant progress is made.

---
*For questions about this incident, please contact the incident response team*
"@