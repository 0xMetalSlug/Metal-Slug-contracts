set -euo pipefail
pushd $(dirname "$0")/..

export RPC_URL="http://localhost:5050";
# export RPC_URL="https://api.cartridge.gg/x/metalslug-dev/katana";

# export OWNER_ADDRESS=0x662824b3acb2952f427d8aa03d09e37603b3ec79e9d11cb2607a4c239693f00;
# export OWNER_PK=0x3e3979c1ed728490308054fe357a9f49cf67f80f9721f44cc57235129e090f4;
export OWNER_ADDRESS=0x127fd5f1fe78a71f8bcd1fec63e3fe2f0486b6ecd5c86a0466c3a21fa5cfcec;
export OWNER_PK=0xc5b2fcab997346f3ea1c00b002ecf6f382c5f9c9659a3894eb783c5320f912;

sozo migrate apply --rpc-url $RPC_URL --account-address $OWNER_ADDRESS --private-key $OWNER_PK 