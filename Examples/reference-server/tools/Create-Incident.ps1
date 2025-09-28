<#
.SYNOPSIS
Creates a new incident record with specified details

.DESCRIPTION
Creates a new incident in the incident management system with the provided
type, severity, description, and optional assignee information.

.EXAMPLE
Create-Incident -Type "Security" -Severity "Critical" -Description "Unauthorized access detected"
#>

[CmdletBinding()]
param(
    # Type of incident being reported
    [Parameter(
        Mandatory,
        HelpMessage = "Select the type of incident"
    )]
    [ValidateSet('Security', 'Performance', 'Outage', 'DataLoss', 'Maintenance')]
    [string]$Type,

    # Severity level of the incident
    [Parameter(
        Mandatory,
        HelpMessage = "Select incident severity level"
    )]
    [ValidateSet('Low', 'Medium', 'High', 'Critical')]
    [string]$Severity,

    # Detailed description of the incident
    [Parameter(
        Mandatory,
        HelpMessage = "Provide a detailed description of the incident"
    )]
    [string]$Description,

    # Person to assign the incident to
    [Parameter()]
    [string]$Assignee = "Unassigned",

    # Affected services or systems
    [Parameter()]
    [string[]]$AffectedServices = @(),

    # Reporter's contact information
    [Parameter()]
    [string]$Reporter = $env:USERNAME
)

# Generate incident ID
$timestamp = Get-Date -Format "yyyy-MM-dd-HHmmss"
$incidentId = "INC-$timestamp"

# Create incident object
$incident = @{
    id = $incidentId
    title = $Description
    type = $Type
    severity = $Severity
    status = "Open"
    reporter = $Reporter
    assignee = $Assignee
    affectedServices = $AffectedServices
    createdAt = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    lastUpdated = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    description = $Description
    notes = @()
}

# Save incident to file (in a real implementation, this could be a database API call)
$incidentsPath = Join-Path $PSScriptRoot "..\resources\incidents"
$incidentFile = Join-Path $incidentsPath "$incidentId.json"

try {
    $incident | ConvertTo-Json -Depth 10 | Set-Content -Path $incidentFile -Encoding UTF8
    Write-Verbose "Incident saved to: $incidentFile"
} catch {
    throw "Failed to save incident: $($_.Exception.Message)"
}
# Return success response
@{
    Success = $true
    Message = "Incident $incidentId created successfully"
    Incident = [PSCustomObject]$incident
    NextSteps = @(
        "Incident has been logged and assigned to: $Assignee"
        "Automatic notifications have been sent based on severity level: $Severity"
        if ($Severity -in @('High', 'Critical')) {
            "Escalation procedures have been initiated due to $Severity severity"
        }
        "Track progress using incident ID: $incidentId"
        "Incident file saved to: $incidentFile"
    )
}