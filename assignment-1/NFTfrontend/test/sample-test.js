const { expect } = require("chai");
const { BigNumber } = require("ethers");
const { ethers } = require("hardhat");

describe("ZKUNFT", function () {
  it("Should return the new greeting once it's changed", async function () {
    const ZKUNFT = await ethers.getContractFactory("ZKUNFT");
    const zkunft = await ZKUNFT.deploy();
    await zkunft.deployed();


    console.log()
    // expect(await zkunft.getLeaves()).to.equal([ 1, 2, 3, 4, 5, 6, 7, 8 ]);
    // const tokenURITx = await zkunft.tokenURI(BigNumber.from(0));
    // const tokenURITx = await zkunft.tokenURI(0);
    expect(await zkunft.tokenURI(0)).to.equal('data:application/json;base64,eyJuYW1lIjogIiIsImRlc2NyaXB0aW9uIjogfSw=');
    
  
    // expect(await zkunft.tokenURI(0)).to.equal('data:application/json;base64,eyJuYW1lIjogIiIsImRlc2NyaXB0aW9uIjogfSw=');

    // wait until the transaction is mined
    // await tokenURITx.wait();

    console.log('succcess');
  });
});
