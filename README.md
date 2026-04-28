# Safe Self-Improvement Agent

> A security-hardened self-improvement skill for [OpenClaw](https://github.com/openclaw/openclaw) that captures learnings, errors, and corrections — with **mandatory human approval** before any changes to core workspace files.

## Why This Exists

The popular [Self-Improving Agent](https://github.com/peterskoett/self-improving-agent) skill is excellent at solving a real problem: AI agents forget everything between sessions. However, it carries significant security risks:

- **Auto-modifies core files** — `SOUL.md`, `AGENTS.md`, `TOOLS.md` can be changed without user consent
- **Hook scripts read command output** — `error-detector.sh` can see sensitive data in Bash output
- **Cross-session data sharing** — Learnings can be sent to other sessions automatically
- **No secret redaction enforcement** — Sensitive data may end up in log files

This skill preserves the best parts while closing every risk vector.

## What It Does

### Core Features (from the original)

- 📝 **Structured logging** — Errors, learnings, and feature requests stored in `.learnings/` directory with standardized formats and IDs
- 🔍 **Automatic trigger detection** — Logs when users correct the agent, commands fail, knowledge is outdated, or better approaches are found
- 📈 **Recurring pattern detection** — Links related entries with `See Also`, tracks `Recurrence-Count`, and bumps priority
- 🚀 **Learning promotion** — Recurring learnings (≥3 occurrences in 30 days, across ≥2 tasks) get proposed for promotion to permanent workspace files
- 📋 **Periodic review** — Built-in workflow to review, resolve, and promote pending learnings

### Security Hardening (what's new)

| Risk | Original | Safe Version |
|------|----------|-------------|
| Auto-modify `SOUL.md` / `AGENTS.md` / `TOOLS.md` | ✅ Yes, automatically | ❌ **Must get explicit user approval** |
| Hook scripts reading command output | ✅ `error-detector.sh` | ❌ **Completely removed** |
| Cross-session learning sharing | ✅ Via `sessions_send` | ❌ **Forbidden unless user explicitly asks** |
| Secrets in log files | ⚠️ Soft guidance only | ❌ **Hard rule: never log secrets/tokens/keys** |
| Dynamic remote payload fetching | ⚠️ Not addressed | ❌ **Explicitly forbidden** |
| Skill extraction scripts | ✅ `extract-skill.sh` | ❌ **Removed (reduces attack surface)** |

## Installation

### Option 1: Clone directly (recommended)

```bash
git clone https://github.com/gateswell/safe-self-improvement-agent.git ~/.openclaw/skills/safe-self-improvement
```

### Option 2: Manual copy

Download or copy the `skills/safe-self-improvement/` directory to your OpenClaw skills directory:

```bash
mkdir -p ~/.openclaw/skills/safe-self-improvement
# Copy SKILL.md into it
```

OpenClaw will auto-load the skill on next session.

## Usage

The skill activates automatically when it detects:

1. A command or operation fails unexpectedly
2. You correct the agent ("No, that's wrong...", "Actually...")
3. You request a capability that doesn't exist
4. An external API or tool fails
5. The agent's knowledge is outdated
6. A better approach is discovered

### Quick Start

On first use, the skill creates a `.learnings/` directory in your workspace:

```
~/.openclaw/workspace/.learnings/
├── LEARNINGS.md          # Corrections, insights, knowledge gaps
├── ERRORS.md             # Command failures, exceptions
└── FEATURE_REQUESTS.md   # User-requested capabilities
```

### Logging Examples

**When a command fails:**
```
Agent: Running `pnpm install`...
Error: command not found: pnpm

→ Automatically logged to .learnings/ERRORS.md as ERR-20260428-001
```

**When you correct the agent:**
```
You: No, we use pnpm not npm in this project.
Agent: Noted, logging this correction.

→ Automatically logged to .learnings/LEARNINGS.md as LRN-20260428-001
```

### The Promotion Flow

When a learning recurs enough times, the skill will **ask you** before making any changes:

```
Agent: This learning has recurred 3 times. Propose adding to TOOLS.md:
       "Use pnpm, not npm — project uses pnpm workspaces"
       Approve?

You: yes

→ Agent adds the rule to TOOLS.md and marks the learning as "promoted"
```

**You always have the final say.** The skill will never silently modify your core workspace files.

### Periodic Review

Before major tasks, you can ask the agent to review learnings:

```bash
# Count pending items
grep -h "Status**: pending" .learnings/*.md | wc -l

# High-priority pending items  
grep -B5 "Priority**: high" .learnings/*.md | grep "^## \["
```

## File Structure

```
safe-self-improvement/
├── SKILL.md              # Core skill instructions (required)
└── references/           # Additional reference docs (optional)
```

The skill is intentionally minimal — just `SKILL.md` with all instructions inline. No scripts, no hooks, no hidden payloads.

## Security Rules

These 6 rules are non-negotiable and enforced in the skill:

1. 🔒 **Never auto-modify core files** — `SOUL.md`, `AGENTS.md`, `TOOLS.md`, `MEMORY.md`, `IDENTITY.md` require explicit user approval
2. 🙈 **No secrets in logs** — Never log tokens, API keys, passwords, or full config files
3. 🚫 **No cross-session sharing** — Unless the user explicitly asks
4. ❌ **No hook scripts** — Nothing reads your command output
5. 🛡️ **No dynamic payload fetching** — No runtime remote content loading
6. ✋ **Promotion = proposal** — Always ask, never auto-execute

## Comparison with Original

| Feature | Self-Improving Agent | Safe Self-Improvement |
|---------|---------------------|----------------------|
| Structured error/learning logging | ✅ | ✅ |
| Automatic trigger detection | ✅ | ✅ |
| Recurring pattern detection | ✅ | ✅ |
| Learning promotion | ✅ Auto | ✅ **Human-approval gate** |
| Hook scripts | ✅ Included | ❌ Removed |
| Cross-session sharing | ✅ Built-in | ❌ Disabled by default |
| Secret redaction | ⚠️ Soft | ✅ **Hard rule** |
| Skill extraction | ✅ Script included | ❌ Removed |
| Size | ~500 lines | ~200 lines |

## Credits

Based on the original [Self-Improving Agent](https://github.com/peterskoett/self-improving-agent) by [peterskoett](https://github.com/peterskoett), which itself was remade from [pskoett-ai-skills](https://github.com/pskoett/pskoett-ai-skills).

This project reimagines that work with a security-first approach. The core improvement workflow is preserved; the risky automation is replaced with human-in-the-loop controls.

## License

MIT
