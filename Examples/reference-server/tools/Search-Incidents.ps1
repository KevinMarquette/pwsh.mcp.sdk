<#
.SYNOPSIS
Searches for incidents based on various criteria

.DESCRIPTION
Searches the incident database using filters for severity, type, status,
assignee, and date ranges. Returns matching incidents with summary information.

.EXAMPLE
Search-Incidents -Severity "High" -Status "Open"
#>

[CmdletBinding()]
param(
    # Filter by incident severity
    [Parameter()]
    [ValidateSet('Low', 'Medium', 'High', 'Critical')]
    [string]$Severity,

    # Filter by incident type
    [Parameter()]
    [ValidateSet('Security', 'Performance', 'Outage', 'DataLoss', 'Maintenance')]
    [string]$Type,

    # Filter by incident status
    [Parameter()]
    [ValidateSet('Open', 'In Progress', 'Investigating', 'Resolved', 'Closed', 'On Hold')]
    [string]$Status,

    # Filter by assigned person
    [Parameter()]
    [string]$Assignee,

    # Filter by incidents created after this date
    [Parameter()]
    [datetime]$CreatedAfter,

    # Filter by incidents created before this date
    [Parameter()]
    [datetime]$CreatedBefore,

    # Maximum number of results to return
    [Parameter()]
    [int]$Limit = 50
)

# Load all incidents from files (in a real implementation, this could be a database query)
$incidentsPath = Join-Path $PSScriptRoot "..\resources\incidents"
$allIncidents = Get-ChildItem -Path $incidentsPath -Filter "*.json" -ErrorAction SilentlyContinue |
    Get-Content -Raw | ConvertFrom-Json -AsHashtable

# Apply filters
$filteredIncidents = $allIncidents | Where-Object {
    $incident = $_

    # Apply severity filter
    if ($Severity -and $incident.severity -ne $Severity) { return $false }

    # Apply type filter
    if ($Type -and $incident.type -ne $Type) { return $false }

    # Apply status filter
    if ($Status -and $incident.status -ne $Status) { return $false }

    # Apply assignee filter
    if ($Assignee -and $incident.assignee -notlike "*$Assignee*") { return $false }

    # Apply date filters
    $createdAt = [datetime]::Parse($incident.createdAt)
    if ($CreatedAfter -and $createdAt -lt $CreatedAfter) { return $false }
    if ($CreatedBefore -and $createdAt -gt $CreatedBefore) { return $false }

    return $true
}

# Limit results
$results = $filteredIncidents | Select-Object -First $Limit

# Build response
@{
    SearchCriteria = @{
        Severity = $Severity
        Type = $Type
        Status = $Status
        Assignee = $Assignee
        CreatedAfter = if ($CreatedAfter) { $CreatedAfter.ToString("yyyy-MM-dd") } else { $null }
        CreatedBefore = if ($CreatedBefore) { $CreatedBefore.ToString("yyyy-MM-dd") } else { $null }
        Limit = $Limit
    }
    Summary = @{
        TotalFound = $filteredIncidents.Count
        Returned = $results.Count
        Truncated = $filteredIncidents.Count -gt $Limit
    }
    Results = $results | ForEach-Object {
        $age = (Get-Date) - [datetime]::Parse($_.createdAt)
        [PSCustomObject]@{
            Id = $_.id
            Title = $_.title
            Severity = $_.severity
            Status = $_.status
            Type = $_.type
            Assignee = $_.assignee
            Age = "{0:dd}d {0:hh}h {0:mm}m" -f $age
            CreatedAt = ([datetime]::Parse($_.createdAt)).ToString("yyyy-MM-dd HH:mm")
            LastUpdated = ([datetime]::Parse($_.lastUpdated)).ToString("yyyy-MM-dd HH:mm")
        }
    }
    SearchedAt = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss UTC")
}