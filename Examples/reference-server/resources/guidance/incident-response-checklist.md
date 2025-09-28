# Incident Response Checklist

## Immediate Response (First 15 minutes)

### 🚨 Critical Incidents
- [ ] **STOP** - Assess if this is truly critical before proceeding
- [ ] Notify incident commander immediately
- [ ] Create war room/bridge call
- [ ] Page on-call manager
- [ ] Begin executive notification sequence

### 🔥 High Priority Incidents
- [ ] Notify team lead within 15 minutes
- [ ] Create incident ticket with full details
- [ ] Begin impact assessment
- [ ] Identify affected services and user count

### ⚠️ Standard Incidents
- [ ] Document incident details thoroughly
- [ ] Assign to appropriate team member
- [ ] Set realistic timeline expectations
- [ ] Notify relevant stakeholders

## Investigation Phase

### Technical Assessment
- [ ] Identify scope of impact (users, services, regions)
- [ ] Check monitoring dashboards and alerts
- [ ] Review recent deployments and changes
- [ ] Collect relevant logs and metrics
- [ ] Determine if this is a known issue

### Communication
- [ ] Update incident status every 30 minutes for Critical
- [ ] Update incident status every 2 hours for High/Medium
- [ ] Prepare customer-facing communication if needed
- [ ] Keep internal stakeholders informed

## Resolution Phase

### Immediate Actions
- [ ] Implement workaround if available
- [ ] Apply hotfix or rollback if identified
- [ ] Verify fix in staging/canary environment first
- [ ] Monitor key metrics during deployment

### Verification
- [ ] Confirm issue is resolved
- [ ] Verify affected services are healthy
- [ ] Check that user experience is restored
- [ ] Monitor for 30+ minutes to ensure stability

## Post-Incident

### Immediate Closure
- [ ] Update incident status to "Resolved"
- [ ] Notify all stakeholders of resolution
- [ ] Document resolution steps taken
- [ ] Schedule post-mortem if warranted

### Follow-up
- [ ] Conduct blameless post-mortem within 5 business days
- [ ] Identify action items to prevent recurrence
- [ ] Update runbooks and documentation
- [ ] Share lessons learned with broader team

## Key Contacts

### Always Available
- **Incident Commander**: On-call rotation
- **Engineering Manager**: [Contact info]
- **DevOps Lead**: [Contact info]

### Business Hours Only
- **Product Manager**: [Contact info]
- **Customer Success**: [Contact info]
- **Marketing/PR**: [Contact info]

## Tools and Resources

### Monitoring
- [Monitoring Dashboard URL]
- [Log Aggregation URL]
- [APM/Tracing URL]

### Communication
- [Incident Bridge/War Room Info]
- [Status Page URL]
- [Customer Communication Templates]

---
*This checklist should be customized for your organization's specific processes and tools*