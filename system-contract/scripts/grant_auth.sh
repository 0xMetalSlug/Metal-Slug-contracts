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

export WORLD_ADDRESS=$(cat ./manifests/dev/manifest.json | jq -r '.world.address')
export SYSTEM_ADDRESS=$(cat ./manifests/dev/manifest.json | jq -r '.contracts[0].address')

export OWNER_ADDRESS=0xb3ff441a68610b30fd5e2abbf3a1548eb6ba6f3559f2862bf2dc757e5828ca;
export OWNER_PK=0x2bbf4f9fd0bbb2e60b0316c1fe0b76cf7a4d0198bd493ced9b8df2a3a24d68a;

echo "---------------------------------------------------------------------------"
echo world : $WORLD_ADDRESS
echo "---------------------------------------------------------------------------"

# enable system -> models authorizations
sozo auth grant --world $WORLD_ADDRESS --rpc-url $RPC_URL --account-address $OWNER_ADDRESS --private-key $OWNER_PK --wait writer \
  PlayerData,$SYSTEM_ADDRESS\
  ValidatorSignature,$SYSTEM_ADDRESS\
  >/dev/null

echo "Default authorizations have been successfully set."