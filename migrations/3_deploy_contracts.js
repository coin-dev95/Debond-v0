const DAI = artifacts.require("DAI");
const DBIT = artifacts.require("DBIT");
const USDC = artifacts.require("USDC");
const USDT = artifacts.require("USDT");

const DebondBond = artifacts.require("DebondBond");
const DebondData = artifacts.require("DebondData");
const APM = artifacts.require("APM");
const Bank = artifacts.require("Bank");

module.exports = async function (deployer) {

  const DAIInstance = await DAI.deployed();
  const DBITInstance = await DBIT.deployed();
  const USDCInstance = await USDC.deployed();
  const USDTInstance = await USDT.deployed();

  console.log(DAIInstance.address, DBITInstance.address)

  await deployer.deploy(DebondBond, DBITInstance.address, USDCInstance.address, USDTInstance.address, DAIInstance.address)
  await deployer.deploy(DebondData, DBITInstance.address, USDCInstance.address, USDTInstance.address, DAIInstance.address)
  await deployer.deploy(APM, USDCInstance.address, DBITInstance.address);

  const bondInstance = await DebondBond.deployed()
  const bondAddress = bondInstance.address
  const dataAddress = (await DebondData.deployed()).address
  const apmAddress = (await APM.deployed()).address

  await deployer.deploy(Bank, apmAddress, dataAddress, bondAddress).then((a) =>{
   console.log("Bank address:" + a.address)
  })

  const bankInstance = await Bank.deployed();

  const bondIssueRole = await bondInstance.ISSUER_ROLE();
  const DBITMinterRole = await DBITInstance.MINTER_ROLE();
  await bondInstance.grantRole(bondIssueRole, bankInstance.address);
  await DBITInstance.grantRole(DBITMinterRole, bankInstance.address);


};
