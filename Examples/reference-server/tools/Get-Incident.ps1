<#
.SYNOPSIS
Retrieves a single incident by its ID

.DESCRIPTION
Loads the full record for a specific incident, including all notes, affected
services, and metadata. Returns the complete incident object as stored.

.EXAMPLE
Get-Incident -IncidentId "INC-2026-04-11-171804"
#>

[CmdletBinding()]
param(
    # ID of the incident to retrieve
    [Parameter(
        Mandatory,
        HelpMessage = "Enter the incident ID (e.g., INC-2024-001)"
    )]
    [string]$IncidentId
)

# Validate incident ID format
if ($IncidentId -notmatch '^INC-\d{4}-\d{3}$|^INC-\d{4}-\d{2}-\d{2}-\d{6}$') {
    throw "Invalid incident ID format. Expected format: INC-YYYY-NNN or INC-YYYY-MM-DD-HHMMSS"
}

# Load incident from file (in a real implementation, this could be a database API call)
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
    Get-Content -Path $incidentFile -Raw | ConvertFrom-Json -AsHashtable
} catch {
    throw "Failed to load incident: $($_.Exception.Message)"
}
