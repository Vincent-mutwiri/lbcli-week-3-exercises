#!/usr/bin/env bash
set -euo pipefail

# What is the hash of this partially signed transaction?
PSBT="cHNidP8BAHsCAAAAAhuVpgVRdOxkuC7wW2rvw4800OVxl+QCgezYKHtCYN7GAQAAAAD/////HPTH9wFgyf4iQ2xw4DIDP8t9IjCePWDjhqgs8fXvSIcAAAAAAP////8BigIAAAAAAAAWABTHctb5VULhHvEejvx8emmDCtOKBQAAAAAAAAAA"

# Decode PSBT -> get unsigned tx hex -> txid
TX_HEX=$(bitcoin-cli -regtest decodepsbt "$PSBT" | jq -r .tx.hex)
HASH=$(bitcoin-cli -regtest decoderawtransaction "$TX_HEX" | jq -r .txid)

echo "$HASH"
