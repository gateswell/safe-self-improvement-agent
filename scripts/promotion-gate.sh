#!/usr/bin/env bash
# SECURITY MANIFEST:
# Environment variables accessed: none
# External endpoints called: none
# Local files read: .learnings/.promotion_state.json
# Local files written: .learnings/.promotion_state.json
# Purpose: Enforce human-approval gate and rate-limiting on learning promotions.
#          Blocks bulk promotions and enforces a cooldown period.

set -euo pipefail

STATE_FILE="${LEARNINGS_DIR:-.learnings}/.promotion_state.json"

# Thresholds
MAX_PROMOTIONS_PER_WINDOW=3
WINDOW_HOURS=24
COOLDOWN_HOURS=6

# --- Helpers ---

get_state() {
    if [ -f "$STATE_FILE" ]; then
        cat "$STATE_FILE"
    else
        echo '{"promotions":[],"last_batch":0}'
    fi
}

save_state() {
    echo "$1" > "$STATE_FILE"
}

now_ts() { date +%s; }

python_eval() {
    python3 -c "$1" 2>/dev/null
}

# --- Commands ---

cmd_check() {
    local state=$(get_state)
    local count=$(python_eval "
import json, sys
d=json.loads('''$state''')
now=int(${NOW_TS:-$(date +%s)})
window=${WINDOW_HOURS}*3600
recent=[p for p in d.get('promotions',[]) if now - p.get('ts',0) < window]
sys.stdout.write(str(len(recent)))
")
    if [ "$count" -ge "$MAX_PROMOTIONS_PER_WINDOW" ]; then
        echo "🚫 RATE LIMIT: $MAX_PROMOTIONS_PER_WINDOW promotions reached in ${WINDOW_HOURS}h window."
        exit 1
    fi

    local last_batch=$(python_eval "
import json
d=json.loads('''$state''')
ts=d.get('last_batch', 0) or 0
sys.stdout.write(str(ts))
")
    if [ "$last_batch" -gt 0 ]; then
        local elapsed=$(($(date +%s) - last_batch))
        local cooldown_s=$((COOLDOWN_HOURS * 3600))
        if [ "$elapsed" -lt "$cooldown_s" ]; then
            local remaining=$((cooldown_s - elapsed))
            echo "🚫 COOLDOWN: Last batch ${elapsed}s ago. Wait ${remaining}s."
            exit 1
        fi
    fi
    echo "✅ Promotion gate clear."
}

cmd_approve() {
    local id="${1:-}"
    [ -z "$id" ] && { echo "Usage: promotion-gate.sh approve <learning_id>"; exit 1; }
    cmd_check
    local state=$(get_state)
    local new_state=$(python_eval "
import json, sys
d=json.loads('''$state''')
now=int(${NOW_TS:-$(date +%s)})
d['promotions'].append({'id': '$id', 'ts': now})
d['last_batch'] = now
cutoff = now - 7*24*3600
d['promotions'] = [p for p in d['promotions'] if p.get('ts',0) > cutoff]
sys.stdout.write(json.dumps(d))
")
    save_state "$new_state"
    echo "✅ $id approved and recorded."
}

cmd_status() {
    local state=$(get_state)
    python_eval "
import json, sys
d=json.loads('''$state''')
now=int(${NOW_TS:-$(date +%s)})
window=${WINDOW_HOURS}*3600
recent=[p for p in d.get('promotions',[]) if now - p.get('ts',0) < window]
print(f'Promotions in last ${WINDOW_HOURS}h: {len(recent)}/${MAX_PROMOTIONS_PER_WINDOW}')
last=d.get('last_batch', 0) or 0
print(f'Last batch: {\"never\" if last==0 else str(last)}')
"
}

cmd_force() {
    local id="${1:-}"
    local reason="${2:-unknown}"
    [ -z "$id" ] && { echo "Usage: promotion-gate.sh force <learning_id> <reason>"; exit 1; }
    echo "⚠️  FORCE: bypassing gate on user responsibility."
    local state=$(get_state)
    local new_state=$(python_eval "
import json
d=json.loads('''$state''')
now=int(${NOW_TS:-$(date +%s)})
d['promotions'].append({'id': '$id', 'ts': now})
d['last_batch'] = now
cutoff=now-7*24*3600
d['promotions']=[p for p in d['promotions'] if p.get('ts',0)>cutoff]
print(json.dumps(d))
")
    save_state "$new_state"
    echo "✅ Force-recorded $id. Reason: $reason"
}

# --- Dispatch ---

COMMAND="${1:-check}"
NOW_TS=$(date +%s)

case "$COMMAND" in
    check)  cmd_check ;;
    approve) shift; cmd_approve "$@" ;;
    status) cmd_status ;;
    force)  shift; cmd_force "$@" ;;
    *)      echo "Usage: promotion-gate.sh [check|approve <id>|status|force <id> <reason>]" ;;
esac
