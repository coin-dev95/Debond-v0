const Bank = artifacts.require("Bank");
const USDC = artifacts.require("USDC");
const DBIT = artifacts.require("DBIT");
const DebondBond = artifacts.require("DebondBond");

contract('Bank', async (accounts: string[]) => {

    it('buy Bonds', async () => {
        const usdcContract = await USDC.deployed();
        const bankContract = await Bank.deployed();
        const bondContract = await DebondBond.deployed();
        const dbitContract = await DBIT.deployed();
        const issueRole = await bondContract.ISSUER_ROLE();
        const minterRole = await dbitContract.MINTER_ROLE();
        await bondContract.grantRole(issueRole, bankContract.address);
        await dbitContract.grantRole(minterRole, bankContract.address);
        console.log(await bondContract.hasRole(issueRole, bankContract.address));
        await usdcContract.mint(accounts[0], 100000);
        await usdcContract.approve(bankContract.address, 100000);
        console.log(bankContract.address, issueRole, minterRole)
        await bankContract.buyBond(1, 0, 1000, 50, 0);

        console.log("balance D/BIT: " + (await bondContract.balanceOf(accounts[0], 0, 0)));
        console.log("balance USDC : " + (await bondContract.balanceOf(accounts[0], 1, 0)));
    })
});
