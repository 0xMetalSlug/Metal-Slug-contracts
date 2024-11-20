#!/bin/bash
set -euo pipefail
pushd $(dirname "$0")/..

need_cmd() {
  if ! check_cmd "$1"; then
    printf "need '$1' (command not found)"
    exit 1
  fi
}

check_cmd() {
  command -v "$1" &>/dev/null
}

need_cmd jq

export RPC_URL="http://localhost:5050"
# export RPC_URL="https://api.cartridge.gg/x/metalslug-dev/katana";



export WORLD_ADDRESS=$(cat ./manifests/dev/manifest.json | jq -r '.world.address')
export SYSTEM_ADDRESS=$(cat ./manifests/dev/manifest.json | jq -r '.contracts[0].address')

# export OWNER_ADDRESS=0x662824b3acb2952f427d8aa03d09e37603b3ec79e9d11cb2607a4c239693f00;
# export OWNER_PK=0x3e3979c1ed728490308054fe357a9f49cf67f80f9721f44cc57235129e090f4;
export OWNER_ADDRESS=0x127fd5f1fe78a71f8bcd1fec63e3fe2f0486b6ecd5c86a0466c3a21fa5cfcec;
export OWNER_PK=0xc5b2fcab997346f3ea1c00b002ecf6f382c5f9c9659a3894eb783c5320f912;

echo "---------------------------------------------------------------------------"
echo world : $WORLD_ADDRESS
echo "---------------------------------------------------------------------------"

# enable system -> models authorizations
sozo auth grant --world $WORLD_ADDRESS --rpc-url $RPC_URL --account-address $OWNER_ADDRESS --private-key $OWNER_PK --wait writer \
  PlayerData,$SYSTEM_ADDRESS\
  ValidatorSignature,$SYSTEM_ADDRESS\
  >/dev/null

echo "Default authorizations have been successfully set."