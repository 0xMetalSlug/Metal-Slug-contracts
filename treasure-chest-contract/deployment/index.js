const {
  RpcProvider,
  Account,
  json,
  CallData,
  stark,
  ec,
  hash,
  Contract,
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

async function deployChest() {
  const compiledTreasureChestCasm = json.parse(
    fs
      .readFileSync(
        '../target/dev/metalslug_chest_MetalSlugChest.compiled_contract_class.json'
      )
      .toString('ascii')
  );

  const compiledTreasureChestSierra = json.parse(
    fs
      .readFileSync(
        '../target/dev/metalslug_chest_MetalSlugChest.contract_class.json'
      )
      .toString('ascii')
  );

  const contractCallData = new CallData(compiledTreasureChestSierra.abi);
  const constructorCalldata = contractCallData.compile('constructor', {
    owner: address,
    system_address:
      '0x6fc2b43d118f26d99c66bc486011fe69a32af5623a1ae80ef73891498cc1b79',
    token_uri: '',
  });

  const deployContractResponse = await deployer.declareAndDeploy({
    contract: compiledTreasureChestSierra,
    casm: compiledTreasureChestCasm,
    constructorCalldata,
  });
  console.log(deployContractResponse.deploy.address);
}

deployChest();
