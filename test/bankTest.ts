import {APMInstance, BankInstance, DBITInstance, DebondBondInstance, USDCInstance} from "../types/truffle-contracts";

const Bank = artifacts.require("Bank");
const USDC = artifacts.require("USDC");
const DBIT = artifacts.require("DBIT");
const APM = artifacts.require("APM");
const DebondBond = artifacts.require("DebondBond");

contract('Bank', async (accounts: string[]) => {

    let usdcContract: USDCInstance
    let bankContract: BankInstance
    let bondContract: DebondBondInstance
    let dbitContract: DBITInstance
    let apmContract : APMInstance

    it('buy Bonds', async () => {
        usdcContract = await USDC.deployed();
        bankContract = await Bank.deployed();
        bondContract = await DebondBond.deployed();
        dbitContract = await DBIT.deployed();
        apmContract = (await APM.deployed());
        await apmContract.updaReserveAfterAddingLiquidity(usdcContract.address, 10**9) // adding reserve
        await apmContract.updaReserveAfterAddingLiquidity(dbitContract.address, 10**9) // adding reserve
        await usdcContract.mint(accounts[0], 100000);
        // await bankContract.buyBond(1, 0, 1000, 50, 0);
        await bankContract.buyBond(1, 0, 3000, 0, 1);

        console.log("balance Bond D/BIT: " + (await bondContract.balanceOf(accounts[0], 0, 0)));
        console.log("balance Bond USDC : " + (await bondContract.balanceOf(accounts[0], 1, 0)));
        console.log("balance USDC in APM : " + (await usdcContract.balanceOf(apmContract.address)));
        console.log("balance D/BIT in APM : " + (await dbitContract.balanceOf(apmContract.address)));

        console.log((await bondContract.getNoncesPerAddress(accounts[0], 0)).map(c => c.toNumber()));

        const details = await bondContract.bondDetails(0, 0);
        console.log("bond details of 0, 0: " + details["0"], details["1"].toNumber(), details["2"], details["3"].toNumber(), details["4"].toNumber(), details["5"].toNumber());

    })

    it('sell Bonds', async () => {

        await bankContract.sellBonds(1,0, 17);

        console.log("balance Bond D/BIT: AFTER " + (await bondContract.balanceOf(accounts[0], 0, 0)));
        console.log("balance Bond USDC : " + (await bondContract.balanceOf(accounts[0], 1, 0)));
        console.log("balance USDC in APM : " + (await usdcContract.balanceOf(apmContract.address)));

        let balance = await usdcContract.balanceOf(apmContract.address);
        expect(balance.toString()).to.equal('2983');
    })
});
