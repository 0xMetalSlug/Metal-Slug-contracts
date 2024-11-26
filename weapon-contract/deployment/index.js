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
    name: 'Metal Slug Weapon',
    symbol: 'MSW',
    token_uri: '',
    owner: address,
    system_address:
      '0x4e7fbde9052123a42c9b9e2eab87d24bca1634088b715912df73a3c1b6fc4e4',
  });

  const deployContractResponse = await deployer.declareAndDeploy({
    contract: compiledTreasureChestSierra,
    casm: compiledTreasureChestCasm,
    constructorCalldata,
  });
  console.log(deployContractResponse.deploy.address);
} // 0x460b03a1cdd1fea6ea53f3098c1753397ef76bbcd3fab0c10706d9ef50ef7af

deployWeapon();
