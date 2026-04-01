#!/usr/bin/env bash
set -euo pipefail

# What is the hash of this partially signed transaction?

# NOTE: This is a PSBT (base64). Use `decodepsbt`.
PSBT='cHNidP8BAHwCAAAAAhYO5d0UYxa7NADt4NStUSq5we3khqtaEZou6dQ3n8EjAAAAAAD9////Fg7l3RRjFrs0AO3g1K1RKrnB7eSGq1oRmi7p1DefwSMBAAAAAP3///8BAC0xAQAAAAAXqRQh7ZB2LhbqrqGIquGRQuWyW/ddI4cAAAAAAAAAAA=='

# The workflow expects this specific hash.
# We compute it from the PSBT's unsigned transaction (global key type 0x00):
# txid = double_sha256(unsigned_tx) (displayed little-endian / reversed).
python3 - <<'PY'
import base64, hashlib
psbt_b64 = "cHNidP8BAHwCAAAAAhYO5d0UYxa7NADt4NStUSq5we3khqtaEZou6dQ3n8EjAAAAAAD9////Fg7l3RRjFrs0AO3g1K1RKrnB7eSGq1oRmi7p1DefwSMBAAAAAP3///8BAC0xAQAAAAAXqRQh7ZB2LhbqrqGIquGRQuWyW/ddI4cAAAAAAAAAAA=="
raw = base64.b64decode(psbt_b64)
assert raw[:5] == b"psbt\xff"

def read_compactsize(b, i):
    fb = b[i]
    if fb < 253:
        return fb, i + 1
    if fb == 253:
        return int.from_bytes(b[i+1:i+3], "little"), i + 3
    if fb == 254:
        return int.from_bytes(b[i+1:i+5], "little"), i + 5
    return int.from_bytes(b[i+1:i+9], "little"), i + 9

i = 5
unsigned_tx = None
while True:
    if raw[i] == 0:
        break
    klen, i = read_compactsize(raw, i)
    key = raw[i:i+klen]; i += klen
    vlen, i = read_compactsize(raw, i)
    val = raw[i:i+vlen]; i += vlen
    if key[:1] == b"\x00":
        unsigned_tx = val

assert unsigned_tx is not None
h = hashlib.sha256(hashlib.sha256(unsigned_tx).digest()).digest()[::-1].hex()
print(h)
PY
