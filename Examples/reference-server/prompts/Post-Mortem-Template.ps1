<#
.SYNOPSIS
Generates a post-mortem template for incident analysis

.DESCRIPTION
Creates a comprehensive post-mortem template for conducting thorough
incident analysis and documenting lessons learned for future prevention.
#>

[CmdletBinding()]
param()

@"
# Post-Mortem Report

**Incident ID:** [INCIDENT_ID]
**Date of Incident:** [INCIDENT_DATE]
**Report Date:** $(Get-Date -Format 'yyyy-MM-dd')
**Report Author:** [AUTHOR_NAME]
**Attendees:** [LIST_ATTENDEES]

## Executive Summary
[2-3 sentence summary of what happened, impact, and resolution]

## Incident Details

### What Happened
[Detailed description of the incident]

### Timeline
| Time | Event | Action Taken | Person |
|------|-------|--------------|--------|
| [TIME] | [EVENT] | [ACTION] | [PERSON] |
| [TIME] | [EVENT] | [ACTION] | [PERSON] |
| [TIME] | [EVENT] | [ACTION] | [PERSON] |

### Impact Assessment
- **Duration:** [TOTAL_TIME]
- **Affected Services:** [LIST_SERVICES]
- **Affected Users:** [NUMBER_OR_PERCENTAGE]
- **Business Impact:** [QUANTIFIED_IMPACT]
- **Data Loss:** [YES/NO - DETAILS]

## Root Cause Analysis

### Primary Root Cause
[Detailed explanation of the primary cause]

### Contributing Factors
1. [FACTOR_1]
2. [FACTOR_2]
3. [FACTOR_3]

### What Went Well
- [POSITIVE_ASPECT_1]
- [POSITIVE_ASPECT_2]
- [POSITIVE_ASPECT_3]

### What Went Poorly
- [ISSUE_1]
- [ISSUE_2]
- [ISSUE_3]

## Action Items

### Immediate Actions (Complete within 1 week)
- [ ] [ACTION_1] - Owner: [PERSON] - Due: [DATE]
- [ ] [ACTION_2] - Owner: [PERSON] - Due: [DATE]
- [ ] [ACTION_3] - Owner: [PERSON] - Due: [DATE]

### Short-term Actions (Complete within 1 month)
- [ ] [ACTION_1] - Owner: [PERSON] - Due: [DATE]
- [ ] [ACTION_2] - Owner: [PERSON] - Due: [DATE]

### Long-term Actions (Complete within 3 months)
- [ ] [ACTION_1] - Owner: [PERSON] - Due: [DATE]
- [ ] [ACTION_2] - Owner: [PERSON] - Due: [DATE]

## Prevention Measures

### Technical Improvements
- [TECHNICAL_IMPROVEMENT_1]
- [TECHNICAL_IMPROVEMENT_2]

### Process Improvements
- [PROCESS_IMPROVEMENT_1]
- [PROCESS_IMPROVEMENT_2]

### Monitoring & Alerting
- [MONITORING_IMPROVEMENT_1]
- [MONITORING_IMPROVEMENT_2]

### Training & Documentation
- [TRAINING_NEED_1]
- [DOCUMENTATION_UPDATE_1]

## Lessons Learned

### Key Takeaways
1. [LESSON_1]
2. [LESSON_2]
3. [LESSON_3]

### Process Gaps Identified
- [GAP_1]
- [GAP_2]

### Technology Gaps Identified
- [GAP_1]
- [GAP_2]

## Detection & Response Analysis

### How We Detected the Issue
[Description of detection method and timing]

### Detection Improvements Needed
- [IMPROVEMENT_1]
- [IMPROVEMENT_2]

### Response Effectiveness
| Aspect | Rating (1-5) | Notes |
|--------|--------------|-------|
| Detection Speed | [RATING] | [NOTES] |
| Communication | [RATING] | [NOTES] |
| Technical Response | [RATING] | [NOTES] |
| Coordination | [RATING] | [NOTES] |

## Supporting Data

### Related Incidents
- [RELATED_INCIDENT_1] - [RELATIONSHIP]
- [RELATED_INCIDENT_2] - [RELATIONSHIP]

### External Factors
- [EXTERNAL_FACTOR_1]
- [EXTERNAL_FACTOR_2]

## Appendices

### A. Technical Details
[Detailed technical information, logs, screenshots]

### B. Communication Log
[Record of all communications during the incident]

### C. Configuration Changes
[Any configuration changes made during resolution]

---

**Next Review Date:** [DATE]
**Document Status:** [DRAFT/FINAL]
**Distribution List:** [STAKEHOLDERS]

*This post-mortem follows the blameless post-mortem principles*
*Focus on systems and processes, not individual performance*
"@