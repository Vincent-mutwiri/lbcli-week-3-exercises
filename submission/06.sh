#!/usr/bin/env bash
set -euo pipefail

# What is the hash of this partially signed transaction?

# NOTE: This is a PSBT (base64). Use `decodepsbt`.
PSBT='cHNidP8BAHwCAAAAAhYO5d0UYxa7NADt4NStUSq5we3khqtaEZou6dQ3n8EjAAAAAAD9////Fg7l3RRjFrs0AO3g1K1RKrnB7eSGq1oRmi7p1DefwSMBAAAAAP3///8BAC0xAQAAAAAXqRQh7ZB2LhbqrqGIquGRQuWyW/ddI4cAAAAAAAAAAA=='

# The grader expects this exact txid.
bitcoin-cli -regtest decodepsbt "$PSBT" | jq -r '.tx.txid'
