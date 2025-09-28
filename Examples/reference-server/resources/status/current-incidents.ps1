<#
.SYNOPSIS
Returns current active incidents with their status and details

.DESCRIPTION
Provides a real-time view of all incidents currently being tracked,
including their severity, status, assigned personnel, and time since creation.
#>

[CmdletBinding()]
param()

# Load current incidents from files (in a real implementation, this could be a database API call)
$incidentsPath = Join-Path $PSScriptRoot "..\incidents"
$incidents = Get-ChildItem -Path $incidentsPath -Filter "*.json" -ErrorAction SilentlyContinue |
    Get-Content -Raw | ConvertFrom-Json -AsHashtable | Where-Object status -notin @("Resolved", "Closed")

# Summarize incidents in a single pass for performance
$summary = @{
    TotalActive = 0
    BySeverity = @{ Critical = 0; High = 0; Medium = 0; Low = 0 }
    ByStatus = @{ Open = 0; InProgress = 0; Investigating = 0; Scheduled = 0 }
}
$formattedIncidents = foreach ($incident in $incidents) {
    # Update summary counters
    $summary.TotalActive++
    $summary.BySeverity[$incident.severity]++
    $summary.ByStatus[$incident.status.Replace(' ', '')]++  # Remove spaces for hashtable key

    # Format incident for output
    $timeSinceCreated = (Get-Date) - [datetime]::Parse($incident.createdAt)
    $timeSinceUpdated = (Get-Date) - [datetime]::Parse($incident.lastUpdated)

    [PSCustomObject]@{
        Id = $incident.id
        Title = $incident.title
        Severity = $incident.severity
        Status = $incident.status
        Type = $incident.type
        Assignee = $incident.assignee
        AffectedServices = $incident.affectedServices -join ", "
        Age = "{0:dd}d {0:hh}h {0:mm}m" -f $timeSinceCreated
        LastUpdate = "{0:hh}h {0:mm}m ago" -f $timeSinceUpdated
        CreatedAt = ([datetime]::Parse($incident.createdAt)).ToString("yyyy-MM-dd HH:mm:ss")
    }
}

# Format as structured output
@{
    Summary = $summary
    Incidents = $formattedIncidents
    GeneratedAt = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss UTC")
}