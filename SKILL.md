---
name: safe-self-improvement
description: "Captures learnings, errors, and corrections for continuous improvement with human-approval gate. Use when: (1) A command or operation fails unexpectedly, (2) User corrects the agent ('No, that's wrong...', 'Actually...'), (3) User requests a capability that doesn't exist, (4) An external API or tool fails, (5) Agent realizes its knowledge is outdated or incorrect, (6) A better approach is discovered for a recurring task. Also review learnings before major tasks."
---

# Safe Self-Improvement

Log learnings and errors to markdown files for continuous improvement. Key differences from untrusted variants: **all promotions to core workspace files require explicit human approval**.

## First-Use Initialisation

If `.learnings/` directory or its files are missing, create them:

```bash
mkdir -p .learnings
[ -f .learnings/LEARNINGS.md ] || printf "# Learnings\n\nCorrections, insights, and knowledge gaps.\n\n**Categories**: correction | insight | knowledge_gap | best_practice\n\n---\n" > .learnings/LEARNINGS.md
[ -f .learnings/ERRORS.md ] || printf "# Errors\n\nCommand failures and integration errors.\n\n---\n" > .learnings/ERRORS.md
[ -f .learnings/FEATURE_REQUESTS.md ] || printf "# Feature Requests\n\nCapabilities requested by the user.\n\n---\n" > .learnings/FEATURE_REQUESTS.md
```

Never overwrite existing files.

## 🔒 Security Rules (Non-Negotiable)

1. **NEVER auto-modify core files** — `SOUL.md`, `AGENTS.md`, `TOOLS.md`, `MEMORY.md`, `IDENTITY.md` must NOT be modified without explicit user approval shown as a clear question and awaiting a "yes" response.
2. **No secrets in logs** — Never log tokens, API keys, passwords, private keys, env vars, or full config/source files. Use redacted summaries only.
3. **No cross-session sharing without approval** — Using `sessions_send` or `sessions_spawn` to share learnings requires the same approval gate as promotion: present what will be shared, to which session, and wait for explicit "yes". Never share automatically.
4. **No hook scripts** — This skill does not install or use hook scripts that read command output.
5. **No dynamic payload fetching** — Never fetch remote content at runtime for skill logic.
6. **Promotion = proposal, not action** — When a learning qualifies for promotion, ASK the user first.

## Quick Reference

| Situation | Action |
|-----------|--------|
| Command/operation fails | Log to `.learnings/ERRORS.md` |
| User corrects you | Log to `.learnings/LEARNINGS.md` (category: `correction`) |
| User wants missing feature | Log to `.learnings/FEATURE_REQUESTS.md` |
| API/external tool fails | Log to `.learnings/ERRORS.md` |
| Knowledge was outdated | Log to `.learnings/LEARNINGS.md` (category: `knowledge_gap`) |
| Found better approach | Log to `.learnings/LEARNINGS.md` (category: `best_practice`) |
| Learning seems broadly applicable | **Propose** promotion to user — do NOT auto-modify core files |

## Logging Format

### Learning Entry

Append to `.learnings/LEARNINGS.md`:

```markdown
## [LRN-YYYYMMDD-XXX] category

**Logged**: ISO-8601 timestamp
**Priority**: low | medium | high | critical
**Status**: pending
**Area**: frontend | backend | infra | tests | docs | config

### Summary
One-line description

### Details
Full context

### Suggested Action
Specific fix or improvement

### Metadata
- Source: conversation | error | user_feedback
- Related Files: path/to/file.ext
- Tags: tag1, tag2
- See Also: LRN-YYYYMMDD-XXX
- Pattern-Key: optional.stable_key
- Recurrence-Count: 1
- First-Seen: YYYY-MM-DD
- Last-Seen: YYYY-MM-DD

---
```

### Error Entry

Append to `.learnings/ERRORS.md`:

```markdown
## [ERR-YYYYMMDD-XXX] skill_or_command_name

**Logged**: ISO-8601 timestamp
**Priority**: high
**Status**: pending
**Area**: frontend | backend | infra | tests | docs | config

### Summary
Brief description of failure

### Error
```
Error message (redacted)
```

### Context
- Command attempted
- Environment details (no secrets)
- Redacted excerpt of relevant output

### Suggested Fix
Possible resolution

### Metadata
- Reproducible: yes | no | unknown
- Related Files: path/to/file.ext
- See Also: ERR-YYYYMMDD-XXX

---
```

### Feature Request Entry

Append to `.learnings/FEATURE_REQUESTS.md`:

```markdown
## [FEAT-YYYYMMDD-XXX] capability_name

**Logged**: ISO-8601 timestamp
**Priority**: medium
**Status**: pending
**Area**: frontend | backend | infra | tests | docs | config

### Requested Capability
What the user wanted

### User Context
Why they needed it

### Complexity Estimate
simple | medium | complex

### Metadata
- Frequency: first_time | recurring

---
```

## ID Generation

Format: `TYPE-YYYYMMDD-XXX`
- TYPE: `LRN`, `ERR`, `FEAT`
- XXX: Sequential (`001`, `002`...)

## Resolving Entries

When an issue is fixed:
1. Change `**Status**: pending` → `**Status**: resolved`
2. Add resolution block:
```markdown
### Resolution
- **Resolved**: ISO-8601 timestamp
- **Notes**: What was done
```

Other status values: `in_progress`, `wont_fix`, `promoted`

## Promotion (Human-Approval Gate)

When a learning is broadly applicable, propose promotion — **never auto-execute**.

### When a Learning Qualifies for Promotion

- Recurrence-Count ≥ 3 (within 30 days)
- Seen across ≥ 2 distinct tasks
- Non-obvious, verified, or user-flagged

### Promotion Targets

| Learning Type | Target File | Example |
|---------------|-------------|---------|
| Behavioral patterns | `SOUL.md` | "Be concise, avoid disclaimers" |
| Workflow improvements | `AGENTS.md` | "Spawn sub-agents for long tasks" |
| Tool gotchas | `TOOLS.md` | "Git push needs auth configured" |

### Promotion Procedure

**STOP. Do not modify the target file yet.**

Instead, present the user with:

1. The proposed rule/insight (distilled, concise)
2. The target file
3. Where in the file it would go
4. The original learning entry ID

Ask: *"This learning has recurred X times. Propose adding to [file]: [rule]. Approve?"*

Only proceed on explicit "yes"/"approve"/"确认". Any other response = do not promote.

After promotion:
- Update original entry: `**Status**: promoted`
- Add `**Promoted**: <filename>`

## Recurring Pattern Detection

When logging something similar to an existing entry:
1. Search: `grep -r "keyword" .learnings/`
2. Link: Add `**See Also**: LRN-...` in Metadata
3. Bump priority if recurring
4. Increment `Recurrence-Count` and update `Last-Seen`
5. If promotion threshold met → follow Promotion Procedure above

## Detection Triggers

Automatically log when you notice:

- **Corrections**: "No, that's not right...", "Actually...", "You're wrong about..."
- **Feature Requests**: "Can you also...", "I wish you could...", "Is there a way to..."
- **Knowledge Gaps**: User provides info you didn't know, docs are outdated, API differs
- **Errors**: Non-zero exit codes, exceptions, unexpected output, timeouts

### Pre-Log Sanitization (Mandatory)

Before writing ANY entry, scan the content for sensitive data:

1. **Strip** tokens, API keys, passwords, phone numbers, IP addresses, SSID/password, device IDs, personal names/addresses
2. **Replace** with `<TYPE>` placeholders (e.g., `<API_KEY>`, `<IP>`, `<PHONE>`)
3. **If the correction itself IS sensitive** (e.g. user says "the password is X"), do NOT log the value — log only: "User corrected credential for <SERVICE>. Actual value not logged."

This step is NOT optional. Skip it and you risk leaking user data into log files.

## Periodic Review

Before major tasks, check learnings:

```bash
# Count pending items
grep -h "Status\*\*: pending" .learnings/*.md | wc -l

# High-priority pending items
grep -B5 "Priority\*\*: high" .learnings/*.md | grep "^## \["

# Learnings for specific area
grep -l "Area\*\*: backend" .learnings/*.md
```

Review actions: resolve fixed items, propose promotions, link related entries.

### Context Compression

Periodically (when `.learnings/*.md` exceeds 500 lines or monthly, whichever comes first):

1. **Distill resolved/promoted entries** into one-line summaries:
   - Before: Full entry with Summary/Details/Context/Fix/Metadata (~15 lines)
   - After: `> [LRN-20260428-001] Use pnpm not npm (promoted→TOOLS.md)` (~1 line)
2. **Merge duplicate patterns** — if 3+ entries share the same `Pattern-Key`, keep one summary and drop the rest
3. **Expire stale entries** — `wont_fix` older than 90 days, delete; `pending` with no activity >60 days, demote to `low` priority and compress
4. **Keep compressed log** in `.learnings/archive/SUMMARY.md` — a concise index of all past learnings, one line per entry
5. Active files (`LEARNINGS.md`, `ERRORS.md`, `FEATURE_REQUESTS.md`) only retain `pending` and `in_progress` entries in full detail

```bash
# Check file sizes
grep -c "" .learnings/*.md
# Create compressed summary
mkdir -p .learnings/archive
```

## Best Practices

1. Log immediately — context fades fast
2. Be specific — future sessions need clarity
3. Redact secrets — always
4. Include reproduction steps for errors
5. Suggest concrete fixes, not just "investigate"
6. Link related files
7. Propose promotions promptly when threshold met — but wait for approval
