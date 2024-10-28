#!/bin/bash
set -euo pipefail
pushd $(dirname "$0")/..

export RPC_URL="http://localhost:5050";

export WORLD_ADDRESS=$(cat ./manifests/dev/manifest.json | jq -r '.world.address')
export SYSTEM_ADDRESS=$(cat ./manifests/dev/manifest.json | jq -r '.contracts[0].address')

export OWNER_ADDRESS=0xb3ff441a68610b30fd5e2abbf3a1548eb6ba6f3559f2862bf2dc757e5828ca;
export OWNER_PK=0x2bbf4f9fd0bbb2e60b0316c1fe0b76cf7a4d0198bd493ced9b8df2a3a24d68a;

export VALIDATOR_ADDRESS=0xb3ff441a68610b30fd5e2abbf3a1548eb6ba6f3559f2862bf2dc757e5828ca;


# sozo execute --world <WORLD_ADDRESS> <CONTRACT> <ENTRYPOINT>
sozo execute --world $WORLD_ADDRESS $SYSTEM_ADDRESS initialize -c $VALIDATOR_ADDRESS --rpc-url $RPC_URL --account-address $OWNER_ADDRESS --private-key $OWNER_PK --wait
echo "System initialized successfully."
