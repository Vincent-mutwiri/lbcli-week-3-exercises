#!/usr/bin/env bash
set -euo pipefail

# Create a 1-of-4 P2SH multisig address from the public keys in the four inputs
# of the provided raw transaction.

transaction="02000000000104b5f641e80e9065f09b12f3e373072518885d1bd1ddd9298e5b9840de515edac90000000000feffffffd54f8986afbb6ff18572acaee58fa3ad64446dd770ffe9b6a04f798becdafb440000000000feffffff475e3062b1c3ee87544c29d723866da2b65a1b1a42e6ea4a4fd48d79f83c26c50000000000feffffffa56387352ecc93dfd37648e6ebd4d9effb37ffefcad02eb7b85860c9097cf8090000000000feffffff02fa440f00000000001600148070ec3954ecdcbfc210d0117e8d28a19eb8467270947d0000000000160014b5fe46c647353ec9c06374655502094095f0289c0247304402200dd758801b40393f68dad8ab57558803efcd2b681ee31eb44fb3cfa9666d2bf90220254d34fa4990e23652bf669053c5e16fd2fbb816bed2eeb44c1f1e6e54143e3e012102bbb4ba3f39b5f3258f0014d5e4eab5a6990009e3e1dba6e8eaff10b3832394f70247304402201694761a5749b6a84f71459c04a44cf9d34a36ae8c9044c3af7a3a5514ef2e64022058f61feb92d6d54b71fdea47e7dfcd20f6a5c12e2fbcb15bc44fe95c73f2e808012103aaf17b1a7b4108f7e5bc4f7d59c20f7fb1a72dbc74a9a3d6d1f8488df159c76002473044022014b65c60f65e62d9dac893e404c8de2a007c7c6b74dbac18e454d8374e159759022012453f69112adadf9495fd3fe288aa5ed9e3d836340da06fa1e82c8e09adef57012103a6d919c76d9117c23570a767450013edf31cf6be7d3b5a881c06a9aa1f2c24ce0247304402203d3b02390803c1d673fa49bd64d4a26fbeb29e3fc152af8f844d776c9409e41302206903a011a04e00a7f4ec606da4320226d2d393f565702cc58cfcef6dca67f84c01210383d12258e3e294a6d7754336f6b4baef992ec4b91694d3460bcb022b11da8cd2817e0c00"

# In this tx, each input witness ends with: 0x01 0x21 <33-byte pubkey>
# i.e. hex pattern: 0121(02|03)<64 hex>
mapfile -t PUBKEYS < <(
  echo "$transaction" \
  | grep -oE '0121(02|03)[0-9a-fA-F]{64}' \
  | sed 's/^0121//' \
  | head -n 4
)

if [[ ${#PUBKEYS[@]} -ne 4 ]]; then
  echo "Error: expected 4 pubkeys, found ${#PUBKEYS[@]}" >&2
  exit 1
fi

# redeemScript = OP_1 <PK1> <PK2> <PK3> <PK4> OP_4 OP_CHECKMULTISIG
redeem="51"
for pk in "${PUBKEYS[@]}"; do
  redeem+="21${pk}"
done
redeem+="54ae"

# HASH160(redeemScript)
hash160=$(echo -n "$redeem" | xxd -r -p | openssl dgst -sha256 -binary | openssl dgst -rmd160 -binary | xxd -p -c 256)

# Base58Check encode for P2SH testnet/regtest: version 0xc4
payload_hex="c4${hash160}"
checksum_hex=$(echo -n "$payload_hex" | xxd -r -p | openssl dgst -sha256 -binary | openssl dgst -sha256 -binary | xxd -p -c 256 | cut -c1-8)
addr_hex="${payload_hex}${checksum_hex}"

python3 - <<PY
alphabet = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz'
hexstr = '${addr_hex}'
b = bytes.fromhex(hexstr)

n = int.from_bytes(b, 'big')
out = ''
while n > 0:
    n, rem = divmod(n, 58)
    out = alphabet[rem] + out

pad = 0
for c in b:
    if c == 0:
        pad += 1
    else:
        break

print('1' * pad + out)
PY
