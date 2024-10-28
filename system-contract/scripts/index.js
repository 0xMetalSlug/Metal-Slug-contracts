const {
  Account,
  RpcProvider,
  shortString,
  uint256,
  stark,
  CallData,
} = require('starknet');

const provider = new RpcProvider({
  nodeUrl: 'http://0.0.0.0:5050',
});

const playerAddress =
  '0xe29882a1fcba1e7e10cad46212257fea5c752a4f9b1b1ec683c503a2cf5c8a';
const playerPrivateKey =
  '0x14d6672dcb4b77ca36a887e9a11cd9d637d5012468175829e9c6e770c61642';

const playerAccount = new Account(provider, playerAddress, playerPrivateKey);

const validatorAddress =
  '0xb3ff441a68610b30fd5e2abbf3a1548eb6ba6f3559f2862bf2dc757e5828ca';
const validatorPrivateKey =
  '0x2bbf4f9fd0bbb2e60b0316c1fe0b76cf7a4d0198bd493ced9b8df2a3a24d68a';

const validatorAccount = new Account(
  provider,
  validatorAddress,
  validatorPrivateKey
);

const systemAddress =
  '0x6fc2b43d118f26d99c66bc486011fe69a32af5623a1ae80ef73891498cc1b79';
async function claimEndMatchReward() {
  const saltNonce = Math.round(Date.now() / 1e3);

  const typedDataValidate = {
    types: {
      StarkNetDomain: [
        {
          name: 'name',
          type: 'felt',
        },
        {
          name: 'version',
          type: 'felt',
        },
        {
          name: 'chainId',
          type: 'felt',
        },
      ],
      EndMatchReward: [
        {
          name: 'player',
          type: 'ContractAddress',
        },
        {
          name: 'treasury',
          type: 'u256',
        },
        {
          name: 'match_level',
          type: 'u32',
        },
        {
          name: 'salt_nonce',
          type: 'u64',
        },
      ],
      u256: [
        { name: 'low', type: 'felt' },
        { name: 'high', type: 'felt' },
      ],
    },
    primaryType: 'EndMatchReward',
    domain: {
      name: 'metalslug',
      version: '1',
      chainId: shortString.encodeShortString('KATANA'),
    },
    message: {
      player: playerAddress,
      treasury: uint256.bnToUint256(100),
      match_level: 1,
      salt_nonce: saltNonce,
    },
  };

  const signature = await validatorAccount.signMessage(typedDataValidate);
  const sign = stark.formatSignature(signature);

  const { transaction_hash: txHash } = await playerAccount.execute([
    {
      contractAddress: systemAddress,
      entrypoint: 'claim_end_match_reward',
      calldata: CallData.compile({
        treasury: uint256.bnToUint256(100),
        match_level: 1,
        salt_nonce: saltNonce,
        sign,
      }),
    },
  ]);

  console.log(`Claim end match reward tx hash: ${txHash}`);
}

async function graftTreasureChest() {
  const chestAddress =
    '0x47c69e95527fa278ab90a6673a2560c9260ba693bb9cbf601f9862b63a30e1';

  const saltNonce = Math.round(Date.now() / 1e3);

  const typedDataValidate = {
    types: {
      StarkNetDomain: [
        {
          name: 'name',
          type: 'felt',
        },
        {
          name: 'version',
          type: 'felt',
        },
        {
          name: 'chainId',
          type: 'felt',
        },
      ],
      TreasureChest: [
        {
          name: 'player',
          type: 'ContractAddress',
        },
        {
          name: 'chest_address',
          type: 'ContractAddress',
        },
        {
          name: 'chest_id',
          type: 'u256',
        },
        {
          name: 'amount',
          type: 'u256',
        },
        {
          name: 'salt_nonce',
          type: 'u64',
        },
      ],
      u256: [
        { name: 'low', type: 'felt' },
        { name: 'high', type: 'felt' },
      ],
    },
    primaryType: 'TreasureChest',
    domain: {
      name: 'metalslug',
      version: '1',
      chainId: shortString.encodeShortString('KATANA'),
    },
    message: {
      player: playerAddress,
      chest_address: chestAddress,
      chest_id: uint256.bnToUint256(1),
      amount: uint256.bnToUint256(1),
      salt_nonce: saltNonce,
    },
  };

  const signature = await validatorAccount.signMessage(typedDataValidate);
  const sign = stark.formatSignature(signature);

  const { transaction_hash: txHash } = await playerAccount.execute([
    {
      contractAddress: systemAddress,
      entrypoint: 'graft_treasure_chest',
      calldata: CallData.compile({
        chest_address: chestAddress,
        chest_id: uint256.bnToUint256(1),
        amount: uint256.bnToUint256(1),
        salt_nonce: saltNonce,
        sign,
      }),
    },
  ]);

  console.log(`Graft treasure chest tx hash: ${txHash}`);
}

graftTreasureChest();
