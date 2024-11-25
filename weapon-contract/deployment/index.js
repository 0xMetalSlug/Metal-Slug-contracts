const {
  RpcProvider,
  Account,
  json,
  CallData,
  stark,
  ec,
  hash,
  Contract,
  uint256,
} = require('starknet');
const fs = require('fs');

const address =
  '0xb3ff441a68610b30fd5e2abbf3a1548eb6ba6f3559f2862bf2dc757e5828ca';
const privateKey =
  '0x2bbf4f9fd0bbb2e60b0316c1fe0b76cf7a4d0198bd493ced9b8df2a3a24d68a';

const provider = new RpcProvider({
  nodeUrl: 'http://0.0.0.0:5050',
});

const deployer = new Account(provider, address, privateKey);

async function deployWeapon() {
  const compiledTreasureChestCasm = json.parse(
    fs
      .readFileSync(
        '../target/dev/metalslug_weapon_MetalSlugWeapon.compiled_contract_class.json'
      )
      .toString('ascii')
  );

  const compiledTreasureChestSierra = json.parse(
    fs
      .readFileSync(
        '../target/dev/metalslug_weapon_MetalSlugWeapon.contract_class.json'
      )
      .toString('ascii')
  );

  const contractCallData = new CallData(compiledTreasureChestSierra.abi);
  const constructorCalldata = contractCallData.compile('constructor', {
    token_uri: '',
    owner: address,
    system_address:
      '0xd0078818d18cbcd4a4bb59b20f11f590cd2492ef948c2de14e29704e2a01d1',
  });

  const deployContractResponse = await deployer.declareAndDeploy({
    contract: compiledTreasureChestSierra,
    casm: compiledTreasureChestCasm,
    constructorCalldata,
  });
  console.log(deployContractResponse.deploy.address);
} // 0x1fe67c3d66b6dfaa7831b659c69727bd5ee69db2626bbca6186e2bc3567bdcc

async function appendWeapon() {
  const { transaction_hash } = await deployer.execute([
    {
      contractAddress:
        '0x1fe67c3d66b6dfaa7831b659c69727bd5ee69db2626bbca6186e2bc3567bdcc',
      entrypoint: 'append_weapons',
      calldata: CallData.compile({
        tier: uint256.bnToUint256(1),
        weapon_ids: [
          uint256.bnToUint256(1),
          uint256.bnToUint256(2),
          uint256.bnToUint256(3),
          uint256.bnToUint256(4),
          uint256.bnToUint256(5),
        ],
      }),
    },
    {
      contractAddress:
        '0x1fe67c3d66b6dfaa7831b659c69727bd5ee69db2626bbca6186e2bc3567bdcc',
      entrypoint: 'append_weapons',
      calldata: CallData.compile({
        tier: uint256.bnToUint256(2),
        weapon_ids: [
          uint256.bnToUint256(6),
          uint256.bnToUint256(7),
          uint256.bnToUint256(8),
          uint256.bnToUint256(9),
          uint256.bnToUint256(10),
        ],
      }),
    },
    {
      contractAddress:
        '0x1fe67c3d66b6dfaa7831b659c69727bd5ee69db2626bbca6186e2bc3567bdcc',
      entrypoint: 'append_weapons',
      calldata: CallData.compile({
        tier: uint256.bnToUint256(3),
        weapon_ids: [
          uint256.bnToUint256(11),
          uint256.bnToUint256(12),
          uint256.bnToUint256(13),
          uint256.bnToUint256(14),
          uint256.bnToUint256(15),
        ],
      }),
    },
    {
      contractAddress:
        '0x1fe67c3d66b6dfaa7831b659c69727bd5ee69db2626bbca6186e2bc3567bdcc',
      entrypoint: 'append_weapons',
      calldata: CallData.compile({
        tier: uint256.bnToUint256(4),
        weapon_ids: [
          uint256.bnToUint256(16),
          uint256.bnToUint256(17),
          uint256.bnToUint256(18),
          uint256.bnToUint256(19),
          uint256.bnToUint256(20),
        ],
      }),
    },
  ]);

  console.log(transaction_hash);
}

appendWeapon();
