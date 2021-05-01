const { expect } = require("chai");
const { ethers } = require("hardhat");
const { abi: abiDisk } = require("../artifacts/contracts/Dai.sol/Dai.json");
const { abi: abiProblem } = require("../artifacts/contracts/ProblemNFT.sol/ProblemNFT.json");
const fs = require("fs"); 
const BN = require('bn.js');

//make sure you've switched defaultnetwork to Kovan and put a mnemonic.txt file in the test folder
describe("ProblemNFT v1", function () {
  let problemNFT, disk, startProblem;
  let docHash;
  let writer1, writer2, publisher, user, governance;

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
    [writer1, writer2, publisher, user, governance] = await ethers.getSigners(); //jsonrpc signers from default 20 accounts with 10000 ETH each
    //was there anything else to setup here? lol
  })

  it("deploy problem factory and disk", async () => {
    const Disk = await ethers.getContractFactory(
       "Dai"
    );
    disk = await Disk.connect(governance).deploy(ethers.BigNumber.from(0)); //mints full supply to deployer
    await disk.deployed()

    const StartProblem = await ethers.getContractFactory(
      "StartProblem"
    )  
    startProblem = await StartProblem.connect(governance).deploy(disk.address, governance.getAddress()); //replace governance address later
    await startProblem.deployed()
  });

  it("deploy a new problem", async () => {
    const num = -1234;
    docHash = "0x"+(new BN(String(num))).toTwos(256).toString('hex',64);
    const deployedProblem = await startProblem.connect(governance).deployNewProblem(docHash);
    await deployedProblem.wait(1)

    const problemAddress = await startProblem.getProblem(docHash)
    problemNFT = new ethers.Contract(
      problemAddress,
      abiProblem,
      governance)    
    // console.log(problemNFT)
  })

  // xit("fund user and publisher", async () => {
  //   await disk.connect(governance).mint(user.getAddress(), ethers.BigNumber.from((10**20).toLocaleString('fullwide', {useGrouping:false})))
  //   await disk.connect(governance).mint(publisher.getAddress(), ethers.BigNumber.from((10**20).toLocaleString('fullwide', {useGrouping:false})))
  // })

  it("stake problem", async () => {
    await problemNFT.connect(governance).stakeProblem(ethers.BigNumber.from("10000"))
    const reward = await problemNFT.totalReward()
    console.log("reward staked " + reward.toString())
  });

  it("move state to writing", async () => {
    await problemNFT.connect(governance).endStaking()
    await expect(problemNFT.connect(governance).stakeProblem(ethers.BigNumber.from("10000"))).to.be.revertedWith("Staking period has already ended");
  })

  it("publish 2 pieces of content", async () => {
    const num = 1559;
    const contentHash = "0x"+(new BN(String(num))).toTwos(256).toString('hex',64);
    await problemNFT.connect(publisher).newContent(writer1.getAddress(),"Into the Ether",contentHash)

    const num2 = 2059;
    const contentHash2 = "0x"+(new BN(String(num2))).toTwos(256).toString('hex',64);
    await problemNFT.connect(publisher).newContent(writer2.getAddress(),"Out of the Ether",contentHash2)

    const balance = await problemNFT.balanceOf(writer1.getAddress())
    expect(parseInt(balance.toString())).to.equal(1)

    const content = await problemNFT.getContent() //do we want to return the struct or just an array?
    // console.log(content)
  })

  it("user stakes content", async () => {
    await problemNFT.connect(user).stakeContent(ethers.BigNumber.from("1000"),ethers.BigNumber.from("1"))
    await problemNFT.connect(user).stakeContent(ethers.BigNumber.from("500"),ethers.BigNumber.from("2"))

  })

  //move time forward
  xit("reward writers/publishers", async () => {

  })
});