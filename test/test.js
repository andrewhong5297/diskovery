const { expect } = require("chai");
const { ethers } = require("hardhat");
const { abi: abiComp } = require("../artifacts/contracts/Comp.sol/Comp.json");
const { abi: abiGov } = require("../artifacts/contracts/GovernorBravoDelegate.sol/GovernorBravoDelegate.json");
const fs = require("fs"); 
const BN = require('bn.js');

//make sure you've switched defaultnetwork to Kovan and put a mnemonic.txt file in the test folder
describe("ProblemNFT v1", function () {
  let problemNFT, disk
  let writer, publisher, user, governance

  xit("setup Skale", async () => {
    overrides = {
        gasLimit: ethers.BigNumber.from("10000000"),
      };
    
    // Define Variables
    const privateKey = '0x2c9aac9e06153f0507f60f8f138adc2af20d4035dff44c597decceff3998466d';

    // Define Provider
    const provider = new ethers.providers.JsonRpcProvider('http://eth-global-10.skalenodes.com:10323/');

    // Create Wallet
    main = new ethers.Wallet(privateKey, provider);
  })

  it("setup localhost", async () => {
    [writer, publisher, user, governance] = await ethers.getSigners(); //jsonrpc signers from default 20 accounts with 10000 ETH each

    //was there anything else to setup? lol
  })

  it("deploy problemNFT and dai", async () => {
    const Disk = await ethers.getContractFactory(
       "Dai"
    );
    disk = await Disk.connect(governance).deploy(ethers.BigNumber.from(0)); //mints full supply to deployer
    await disk.deployed()
      
    let num = -1234;
    let bytes32 = "0x"+(new BN(String(num))).toTwos(256).toString('hex',64);
    console.log(bytes32)

    const Problem = await ethers.getContractFactory(
      "ProblemNFT"
    );
    problemNFT = await Problem.connect(governance).deploy(bytes32,disk.address);  
    await problemNFT.deployed()
  });

  it("fund user and publisher", async () => {
    await disk.connect(governance).mint(user.getAddress(), ethers.BigNumber.from((10**20).toLocaleString('fullwide', {useGrouping:false})))
    await disk.connect(governance).mint(publisher.getAddress(), ethers.BigNumber.from((10**20).toLocaleString('fullwide', {useGrouping:false})))
  })

  xit("stake problem", async () => {
  // await problemNFT.
  });

  //move time forward
  xit("publish content", async () => {

  })

  xit("user stakes content", async () => {

  })

  //move time forward
  xit("reward writers/publishers", async () => {

  })
});