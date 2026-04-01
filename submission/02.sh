# Create a native segwit address and get the public key from the address.
ADDR=$(bitcoin-cli -regtest -rpcwallet="builderswallet" getnewaddress "" bech32)
PUBKEY=$(bitcoin-cli -regtest -rpcwallet="builderswallet" getaddressinfo "$ADDR" | jq -r .pubkey)

echo "$PUBKEY"                
