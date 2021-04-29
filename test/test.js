const { expect } = require("chai");
const { ethers } = require("hardhat");
const { abi: abiComp } = require("../artifacts/contracts/Comp.sol/Comp.json");
const { abi: abiGov } = require("../artifacts/contracts/GovernorBravoDelegate.sol/GovernorBravoDelegate.json");
const fs = require("fs"); 

//make sure you've switched defaultnetwork to Kovan and put a mnemonic.txt file in the test folder
describe("Cities-Protocol Governance v1", function () {
  let governance, taro, governanceAddress, taroAddress
  let main

  it("deploy/setup SKALE contracts", async () => {
    overrides = {
        gasLimit: ethers.BigNumber.from("10000000"),
      };
    
    // Define Variables
    const privateKey = '0x2c9aac9e06153f0507f60f8f138adc2af20d4035dff44c597decceff3998466d';

    // Define Provider
    const provider = new ethers.providers.JsonRpcProvider('http://eth-global-10.skalenodes.com:10323/');

    // Create Wallet
    main = new ethers.Wallet(privateKey, provider);
    
    taro = new ethers.Contract(
        "0xFf795577d9AC8bD7D90Ee22b6C1703490b6512FD", //set on deploy
        abiComp,
        main) 
    
    governance = new ethers.Contract(
      "0xFf795577d9AC8bD7D90Ee22b6C1703490b6512FD", //set on deploy
      abiComp,
      main) 
  })

  it("deploy governance and taro", async () => {
    const Taro = await ethers.getContractFactory(
       "Comp"
     );
    taro = await Taro.connect(main).deploy(main.getAddress()); //mints full supply to deployer
    await taro.deployed()
    console.log("taro Address: ", taro.address)
    taroAddress=taro.address
  
    const Governance = await ethers.getContractFactory(
      "GovernorAlpha"
    );
    governance = await Governance.connect(main).deploy();  
    await governance.deployed()
    console.log("governance Address: ", governance.address)
    governanceAddress=governance.address
  });

  xit("initialize governance",async () => {
    init_tx = governance.connect(main).init(0,taroAddress,ethers.BigNumber.from(80640),ethers.BigNumber.from(40320),ethers.BigNumber.from(100000e18))
    await init_tx.wait(1)
  })
});