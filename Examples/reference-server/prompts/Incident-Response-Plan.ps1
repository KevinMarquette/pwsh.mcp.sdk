<#
.SYNOPSIS
Generates a customized incident response plan based on severity and type

.DESCRIPTION
Creates a detailed incident response plan that adapts its content based on
the incident severity and type, including specific procedures, stakeholders,
and communication requirements for each scenario.

.EXAMPLE
Incident-Response-Plan -IncidentType "Security" -Severity "Critical" -IncludeContacts $true
#>

[CmdletBinding()]
param(
    # Type of incident requiring response
    [Parameter(
        Mandatory,
        HelpMessage = "Select the type of incident"
    )]
    [ValidateSet('Security', 'Performance', 'Outage', 'DataLoss')]
    [string]$IncidentType,

    # Severity level of the incident
    [Parameter(
        Mandatory,
        HelpMessage = "Select incident severity level"
    )]
    [ValidateSet('Low', 'Medium', 'High', 'Critical')]
    [string]$Severity,

    # Include emergency contact information in the plan
    [Parameter()]
    [bool]$IncludeContacts = $false,

    # Whether the incident is occurring during business hours
    [Parameter()]
    [bool]$BusinessHours = $true
)

# Build the incident response plan using pipeline
@"
# Incident Response Plan

## Incident Details
- **Type**: $IncidentType
- **Severity**: $Severity
- **Timestamp**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss UTC')
- **Business Hours**: $(if ($BusinessHours) { 'Yes' } else { 'No' })

## Immediate Actions
"@

# Add severity-specific immediate actions
switch ($Severity) {
    'Critical' {
        @"

### CRITICAL SEVERITY - IMMEDIATE ESCALATION REQUIRED
1. **STOP** - Do not proceed without management approval
2. Notify incident commander immediately
3. Activate crisis communication protocols
4. Begin executive notification sequence
"@
    }
    'High' {
        @"

### HIGH SEVERITY - URGENT RESPONSE
1. Notify team lead within 15 minutes
2. Begin impact assessment
3. Prepare stakeholder communication
"@
    }
    'Medium' {
        @"

### MEDIUM SEVERITY - STANDARD RESPONSE
1. Document incident details
2. Notify relevant team members
3. Begin investigation
"@
    }
    'Low' {
        @"

### LOW SEVERITY - ROUTINE HANDLING
1. Log incident in tracking system
2. Assign to appropriate team member
3. Set standard resolution timeline
"@
    }
}

# Add incident-type specific procedures
"`n## Type-Specific Procedures"

switch ($IncidentType) {
    'Security' {
        @"
### Security Incident Response
- [ ] Isolate affected systems immediately
- [ ] Preserve forensic evidence
- [ ] Check for data exfiltration
- [ ] Review access logs for suspicious activity
- [ ] Notify security team and legal department
"@
        if ($Severity -in @('High', 'Critical')) {
            @"
- [ ] Contact law enforcement if required
- [ ] Prepare breach notification procedures
"@
        }
    }
    'Performance' {
        @"
### Performance Incident Response
- [ ] Identify affected services and user impact
- [ ] Check system resources (CPU, memory, disk)
- [ ] Review recent deployments or changes
- [ ] Monitor key performance metrics
- [ ] Implement temporary workarounds if available
"@
    }
    'Outage' {
        @"
### Service Outage Response
- [ ] Confirm outage scope and affected users
- [ ] Check service dependencies and upstream issues
- [ ] Implement failover procedures if available
- [ ] Prepare customer communication
- [ ] Monitor restoration progress
"@
    }
    'DataLoss' {
        @"
### Data Loss Incident Response
- [ ] Stop all write operations to affected systems
- [ ] Assess scope of data loss
- [ ] Check backup integrity and availability
- [ ] Notify data protection officer
- [ ] Begin data recovery procedures
"@
        if ($Severity -in @('High', 'Critical')) {
            @"
- [ ] Prepare regulatory notifications
- [ ] Document potential compliance impacts
"@
        }
    }
}

# Add communication section with business hours consideration
"`n## Communication Protocol"

if ($BusinessHours) {
    @"
### Business Hours Communication
- Primary: Email and Slack notifications
- Secondary: Phone calls for High/Critical severity
- Stakeholder updates every 30 minutes for Critical incidents
"@
} else {
    @"
### After Hours Communication
- Primary: Phone calls and emergency notification system
- Secondary: Email for documentation
- Activate on-call escalation procedures
- Consider waiting until business hours for non-critical updates
"@
}

# Add contact information if requested
if ($IncludeContacts) {
    @"

## Emergency Contacts
- **Incident Commander**: [Contact Information]
- **Technical Lead**: [Contact Information]
- **Management Escalation**: [Contact Information]
- **External Vendors**: [Vendor Contact List]

*Note: Actual contact information should be stored securely and updated regularly*
"@
}

# Add resolution and follow-up section
@"

## Resolution Steps
1. Implement fix or workaround
2. Verify service restoration
3. Monitor for recurrence
4. Update incident status in tracking system

## Post-Incident Activities
- [ ] Conduct post-mortem review
- [ ] Document lessons learned
- [ ] Update procedures if needed
- [ ] Communicate resolution to stakeholders
- [ ] Close incident ticket

---
*This incident response plan was generated automatically*
*Review and customize based on your organization's specific procedures*
"@