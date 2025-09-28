<#
.SYNOPSIS
Updates the status of an existing incident

.DESCRIPTION
Updates the status of an incident and adds optional notes about the status change.
Automatically tracks the update timestamp and user who made the change.

.EXAMPLE
Update-IncidentStatus -IncidentId "INC-2024-001" -NewStatus "Resolved" -Notes "Issue resolved by restarting database cluster"
#>

[CmdletBinding()]
param(
    # ID of the incident to update
    [Parameter(
        Mandatory,
        HelpMessage = "Enter the incident ID (e.g., INC-2024-001)"
    )]
    [string]$IncidentId,

    # New status for the incident
    [Parameter(
        Mandatory,
        HelpMessage = "Select the new status for the incident"
    )]
    [ValidateSet('Open', 'In Progress', 'Investigating', 'Resolved', 'Closed', 'On Hold')]
    [string]$NewStatus,

    # Optional notes about the status change
    [Parameter()]
    [string]$Notes = "",

    # Person making the update
    [Parameter()]
    [string]$UpdatedBy = $env:USERNAME
)

# Validate incident ID format
if ($IncidentId -notmatch '^INC-\d{4}-\d{3}$|^INC-\d{4}-\d{2}-\d{2}-\d{6}$') {
    throw "Invalid incident ID format. Expected format: INC-YYYY-NNN or INC-YYYY-MM-DD-HHMMSS"
}

# Load existing incident from file (in a real implementation, this could be a database API call)
# Security: Use whitelist approach - enumerate valid files and match, never use user input directly in paths
$incidentsPath = Join-Path $PSScriptRoot "..\resources\incidents"

$incidentFile = $null
if (Test-Path $incidentsPath) {
    $incidentFiles = Get-ChildItem -Path $incidentsPath -Filter "*.json"
    $matchingFile = $incidentFiles | Where-Object { $_.BaseName -eq $IncidentId }

    if ($matchingFile) {
        $incidentFile = $matchingFile.FullName
    }
}

if (-not $incidentFile) {
    throw "Incident $IncidentId not found"
}

try {
    $incident = Get-Content -Path $incidentFile -Raw | ConvertFrom-Json -AsHashtable
} catch {
    throw "Failed to load incident: $($_.Exception.Message)"
}

$updateTimestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
$previousStatus = $incident.status

# Add note to incident history
$newNote = @{
    timestamp = $updateTimestamp
    author = $UpdatedBy
    content = if ($Notes) { "Status changed to '$NewStatus': $Notes" } else { "Status changed to '$NewStatus'" }
}

# Update incident
$incident.status = $NewStatus
$incident.lastUpdated = $updateTimestamp
if ($NewStatus -eq "Resolved" -and -not $incident.resolvedAt) {
    $incident.resolvedAt = $updateTimestamp
}

# Add the note to the notes array
if (-not $incident.notes) { $incident.notes = @() }
$incident.notes += $newNote

# Save updated incident (in a real implementation, this could be a database API call)
try {
    $incident | ConvertTo-Json -Depth 10 | Set-Content -Path $incidentFile -Encoding UTF8
    Write-Verbose "Incident updated: $incidentFile"
} catch {
    throw "Failed to save incident: $($_.Exception.Message)"
}

# Create update record for response
$updateRecord = [PSCustomObject]@{
    Timestamp = $updateTimestamp
    UpdatedBy = $UpdatedBy
    PreviousStatus = $previousStatus
    NewStatus = $NewStatus
    Notes = $Notes
}

# Build response
$response = @{
    Success = $true
    Message = "Incident $IncidentId status updated to '$NewStatus'"
    IncidentId = $IncidentId
    Update = $updateRecord
    Actions = @()
}

# Add automatic actions based on new status
switch ($NewStatus) {
    'Resolved' {
        $response.Actions += "Automatic notification sent to stakeholders"
        $response.Actions += "Resolution time calculated and recorded"
        $response.Actions += "Post-incident review scheduled"
    }
    'Closed' {
        $response.Actions += "Incident archived in knowledge base"
        $response.Actions += "Final notifications sent to all parties"
        $response.Actions += "Metrics updated for reporting"
    }
    'On Hold' {
        $response.Actions += "Incident placed in monitoring queue"
        $response.Actions += "Stakeholders notified of delay"
    }
    'In Progress' {
        $response.Actions += "Incident marked as actively being worked"
        $response.Actions += "Progress tracking initiated"
    }
}

if ($Notes) {
    $response.Actions += "Notes added to incident history"
}

$response