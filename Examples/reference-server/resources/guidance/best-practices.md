---
Title: Incident Management Best Practices
---

# Incident Management Best Practices

## Philosophy

### Blameless Culture
- Focus on **systems and processes**, not individual performance
- Ask "how did our systems allow this to happen?" not "who caused this?"
- Encourage transparent sharing of mistakes and near-misses
- Treat incidents as learning opportunities

### Customer First
- Prioritize **customer impact** over internal convenience
- Communicate proactively and honestly with affected users
- Provide realistic timelines, not optimistic guesses
- Default to over-communication rather than silence

## During Incidents

### Stay Calm and Methodical
- **Breathe** - Panic leads to mistakes and poor decisions
- Follow established procedures and checklists
- Document actions as you take them
- Don't try heroic one-person fixes during major incidents

### Communication Guidelines
- **Use clear, factual language** - avoid speculation
- **State what you know** and acknowledge what you don't
- **Provide specific timelines** for next updates
- **Use appropriate channels** - don't spam everyone for minor issues

### Technical Response
- **Stabilize first**, investigate root cause later
- **Prefer rollbacks** over forward fixes during active incidents
- **Test fixes** in staging/canary before production deployment
- **Have a backup plan** ready before attempting risky fixes

## Severity Guidelines

### Critical - Service Completely Down
- **All users cannot access core functionality**
- **Data loss or security breach occurring**
- **Financial/legal/regulatory impact imminent**
- **Response**: Immediate escalation, all hands on deck

### High - Major Degradation
- **Significant portion of users affected**
- **Core functionality severely impacted**
- **Business operations disrupted**
- **Response**: Urgent but measured response

### Medium - Limited Impact
- **Some users experiencing issues**
- **Non-core functionality affected**
- **Workarounds available**
- **Response**: Standard business hours response

### Low - Minor Issues
- **Few users affected**
- **Cosmetic or edge case issues**
- **No business impact**
- **Response**: Address in normal development cycle

## Post-Incident Excellence

### Effective Post-Mortems
- **Schedule within 5 business days** while details are fresh
- **Include all stakeholders** who were involved
- **Focus on timeline and decision points**, not blame
- **Identify specific, actionable improvements**

### Action Items
- **Make them SMART** - Specific, Measurable, Achievable, Relevant, Time-bound
- **Assign clear owners** with realistic deadlines
- **Track completion** and report progress
- **Don't create more action items than you can realistically complete**

### Knowledge Sharing
- **Update runbooks** with new troubleshooting steps
- **Share learnings** across teams and departments
- **Build monitoring** for issues discovered
- **Improve alerting** to catch problems earlier

## Common Anti-Patterns to Avoid

### During Incidents
- ❌ **Making changes without coordination** - Use incident commander
- ❌ **Investigating root cause during active incident** - Stabilize first
- ❌ **Being afraid to escalate** - Better to over-escalate than under-escalate
- ❌ **Trying multiple fixes simultaneously** - Change one thing at a time

### Communication
- ❌ **Going silent for long periods** - Provide regular updates even if "no change"
- ❌ **Over-promising timelines** - Under-promise and over-deliver
- ❌ **Using technical jargon** in customer communications
- ❌ **Blaming external services** publicly - Take ownership

### Post-Incident
- ❌ **Skipping post-mortems** for "simple" incidents
- ❌ **Creating action items without owners** or deadlines
- ❌ **Not following up** on action item completion
- ❌ **Repeating the same mistakes** - Learn from history

## Metrics That Matter

### Response Metrics
- **Time to acknowledge** incident
- **Time to engage** appropriate resources
- **Time to customer communication**
- **Time to resolution**

### Quality Metrics
- **Customer satisfaction** with incident handling
- **Accuracy of initial impact assessment**
- **Effectiveness of communication**
- **Action item completion rate**

### Learning Metrics
- **Repeat incidents** (same root cause)
- **Runbook usage** and effectiveness
- **Cross-team collaboration** quality
- **Knowledge sharing** participation

---
*Remember: The goal isn't to prevent all incidents, but to respond effectively when they occur and learn continuously from the experience.*