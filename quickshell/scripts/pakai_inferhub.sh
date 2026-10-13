#!/usr/bin/env bash
# pakai_inferhub.sh - Helper script to fetch InferHub AI usage status from pakai
# Usage:
#   pakai_inferhub.sh status
#   pakai_inferhub.sh refresh

set -e

ACTION="${1:-status}"

case "$ACTION" in
    refresh)
        # Try curl to daemon port first
        if curl -s -m 2 -X POST http://127.0.0.1:7731/api/refresh >/dev/null 2>&1; then
            sleep 0.5
        fi
        ;&
    status)
        python3 -c "
import urllib.request, json, subprocess, os

def get_status():
    # 1. Try querying pakai daemon HTTP API
    try:
        req = urllib.request.Request('http://127.0.0.1:7731/status')
        with urllib.request.urlopen(req, timeout=1.5) as resp:
            data = json.loads(resp.read().decode('utf-8'))
            return extract_inferhub(data)
    except Exception:
        pass

    # 2. Fallback to CLI pakai status --json
    pakai_bin = os.path.expanduser('~/.local/bin/pakai')
    if not os.path.exists(pakai_bin):
        pakai_bin = os.path.expanduser('~/Codes/GO/pakai/pakai')
    if os.path.exists(pakai_bin):
        try:
            out = subprocess.check_output([pakai_bin, 'status', '--json'], timeout=3, text=True)
            data = json.loads(out)
            return extract_inferhub(data)
        except Exception:
            pass

    return {'available': False, 'error': 'pakai not running'}

def extract_inferhub(data):
    if not isinstance(data, list):
        return {'available': False, 'error': 'invalid response'}
    for p in data:
        if p.get('provider') == 'inferhub':
            balance = 0.0
            spend30d = 0.0
            for w in p.get('windows', []):
                if w.get('key') == 'bal':
                    balance = float(w.get('used', 0.0))
                elif w.get('key') == '30d':
                    spend30d = float(w.get('used', 0.0))
            if balance == 0.0 and p.get('used'):
                balance = float(p.get('used', 0.0))
            return {
                'available': True,
                'status': p.get('status', 'ok'),
                'provider': 'InferHub',
                'balance': balance,
                'spend30d': spend30d,
                'balance_str': f'\${balance:.3f}',
                'spend30d_str': f'\${spend30d:.3f}',
                'refreshed_at': p.get('refreshed_at', '')
            }
    return {'available': False, 'error': 'inferhub not found'}

print(json.dumps(get_status()))
"
        ;;
    *)
        echo "Usage: $0 {status|refresh}" >&2
        exit 1
        ;;
esac
