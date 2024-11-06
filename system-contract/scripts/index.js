const {
  Account,
  RpcProvider,
  shortString,
  uint256,
  stark,
  CallData,
  ec,
  hash,
  typedData,
} = require('starknet');

const provider = new RpcProvider({
  nodeUrl: 'http://0.0.0.0:5050',
});

const playerAddress =
  '0x23888a0ae98fad47558650b69b39299290ae746838325a9fa6f4d40efe17ddd';
const playerPrivateKey =
  '0x14d6672dcb4b77ca36a887e9a11cd9d637d5012468175829e9c6e770c61642';

const playerAccount = new Account(provider, playerAddress, playerPrivateKey);

const validatorAddress =
  '0xb3ff441a68610b30fd5e2abbf3a1548eb6ba6f3559f2862bf2dc757e5828ca';
const validatorPrivateKey =
  '0x2bbf4f9fd0bbb2e60b0316c1fe0b76cf7a4d0198bd493ced9b8df2a3a24d68a';

const ETH = '0x49d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7';

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
    '0x48dc6d951159ce9cd914621db348886a5510f7406f0bc2f1389103361503728';

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

async function createAccount() {
  const privateKey =
    '0x2bbf4f9fd0bbb2e60b0316c1fe0b76cf7a4d0198bd493ced9b8df2a3a24d68a';
  const starkKeyPub = ec.starkCurve.getStarkKey(privateKey);

  const classHash =
    '0x05400e90f7e0ae78bd02c77cd75527280470e2fe19c54970dd79dc37a9d3645c';

  const OZaccountConstructorCallData = CallData.compile({
    publicKey: starkKeyPub,
  });
  const OZcontractAddress = hash.calculateContractAddressFromHash(
    starkKeyPub,
    classHash,
    OZaccountConstructorCallData,
    0
  );
  console.log('Precalculated account address=', OZcontractAddress); // 0x23888a0ae98fad47558650b69b39299290ae746838325a9fa6f4d40efe17ddd

  const OZaccount = new Account(provider, OZcontractAddress, privateKey);

  const { transaction_hash, contract_address } = await OZaccount.deployAccount({
    classHash,
    constructorCalldata: OZaccountConstructorCallData,
    addressSalt: starkKeyPub,
  });
}

async function transferETH() {
  const account = new Account(
    provider,
    '0x6b4248639af4ccd49983dd73c09e40ba0a0e3f50e59ceabcacdd2a1fee128bb',
    '0x2bbf4f9fd0bbb2e60b0316c1fe0b76cf7a4d0198bd493ced9b8df2a3a24d68a'
  );

  const { transaction_hash } = await account.execute([
    {
      contractAddress: ETH,
      entrypoint: 'transfer',
      calldata: CallData.compile({
        recipient:
          '0x628696a518ae32bab0c309fdb313a19ff7ad996a6b161d82064359de6097373',
        amount: uint256.bnToUint256(1e18),
      }),
    },
  ]);

  console.log(`Transfer ETH tx hash: ${transaction_hash}`);
}

function getMessageHash() {
  const saltNonce = 3000;
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
          type: 'felt',
        },
        {
          name: 'treasury',
          type: 'u256',
        },
        {
          name: 'match_level',
          type: 'felt',
        },
        {
          name: 'salt_nonce',
          type: 'felt',
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
      chainId: 'KATANA',
    },
    message: {
      player:
        '0x06b4248639af4ccd49983dd73c09e40ba0a0e3f50e59ceabcacdd2a1fee128bb',
      treasury: uint256.bnToUint256(100),
      match_level: '1',
      salt_nonce: saltNonce,
    },
  };

  const hash = typedData.getMessageHash(
    typedDataValidate,
    '0x06b4248639af4ccd49983dd73c09e40ba0a0e3f50e59ceabcacdd2a1fee128bb'
  );
  console.log(hash);
}

getMessageHash();
