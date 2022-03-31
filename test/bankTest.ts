const Bank = artifacts.require("Bank");
const USDC = artifacts.require("USDC");
const DBIT = artifacts.require("DBIT");
const APM = artifacts.require("APM");
const DebondBond = artifacts.require("DebondBond");

contract('Bank', async (accounts: string[]) => {

    it('buy Bonds', async () => {
        const usdcContract = await USDC.deployed();
        const bankContract = await Bank.deployed();
        const bondContract = await DebondBond.deployed();
        const dbitContract = await DBIT.deployed();
        const apmAddress = (await APM.deployed()).address;
        await usdcContract.mint(accounts[0], 100000);
        // await bankContract.buyBond(1, 0, 1000, 50, 0);
        await bankContract.buyBond(1, 0, 3000, 0, 1);

        console.log("balance Bond D/BIT: " + (await bondContract.balanceOf(accounts[0], 0, 0)));
        console.log("balance Bond USDC : " + (await bondContract.balanceOf(accounts[0], 1, 0)));
        console.log("balance USDC in APM : " + (await usdcContract.balanceOf(apmAddress)));
        console.log("balance D/BIT in APM : " + (await dbitContract.balanceOf(apmAddress)));

        console.log((await bondContract.getNoncesPerAddress(accounts[0], 0)).map(c => c.toNumber()));

        const details = await bondContract.bondDetails(0, 0);
        console.log("bond details of 0, 0: " + details["0"], details["1"].toNumber(), details["2"], details["3"].toNumber(), details["4"].toNumber(), details["5"].toNumber());

    })
    console.log('on test sell');

    it('sell Bonds', async () => {
        const usdcContract = await USDC.deployed();
        const bankContract = await Bank.deployed();
        const bondContract = await DebondBond.deployed();
        const dbitContract = await DBIT.deployed();
        const apmAddress = (await APM.deployed()).address;
        await usdcContract.mint(accounts[0], 100000);
        await bankContract.buyBond(1, 0, 1000, 50, 0);

        console.log("balance Bond D/BIT: " + (await bondContract.balanceOf(accounts[0], 0, 0)));
        console.log("balance Bond USDC : " + (await bondContract.balanceOf(accounts[0], 1, 0)));
        console.log("balance USDC in APM : " + (await usdcContract.balanceOf(apmAddress)));
        console.log("balance D/BIT in APM BEFORE: " + (await dbitContract.balanceOf(apmAddress)));


        await bankContract.sellBonds(1,0, 17);

        
        
        
        console.log("balance Bond D/BIT: AFTER " + (await bondContract.balanceOf(accounts[0], 0, 0)));
        console.log("balance Bond USDC : " + (await bondContract.balanceOf(accounts[0], 1, 0)));
        console.log("balance USDC in APM : " + (await usdcContract.balanceOf(apmAddress)));

        let balance = await usdcContract.balanceOf(apmAddress);
        expect(balance.toString()).to.equal('3983');

    })


});
