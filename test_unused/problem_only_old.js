const { expect } = require("chai");
const { ethers } = require("hardhat");
const { abi: abiDisk } = require("../artifacts/contracts/tokens/Disk.sol/Disk.json");
const { abi: abiProblem } = require("../artifacts/contracts/ProblemNFT.sol/ProblemNFT.json");
const fs = require("fs"); 
const BN = require('bn.js');

//make sure you've switched defaultnetwork to Kovan and put a mnemonic.txt file in the test folder
describe("ProblemNFT v1", function () {
  let problemNFT, disk, startProblem, usdc;
  let docHash;
  let writer1, writer2, publisher, user, governance;

  it("setup localhost", async () => {
    [writer1, writer2, publisher, user, governance] = await ethers.getSigners(); //jsonrpc signers from default 20 accounts with 10000 ETH each
  })

  it("deploy problem factory and disk", async () => {
    const Disk = await ethers.getContractFactory(
       "Disk"
    );
    disk = await Disk.connect(governance).deploy(); //mints full supply to deployer
    await disk.deployed()

    const USDC = await ethers.getContractFactory(
       "Disk"
    );
    usdc = await USDC.connect(governance).deploy(); //mints full supply to deployer
    await usdc.deployed()

    const StartProblem = await ethers.getContractFactory(
      "StartProblem"
    )  

    startProblem = await StartProblem.connect(governance).deploy(disk.address, governance.getAddress(),usdc.address); //replace with registry and USDC address later
    await startProblem.deployed()
  });

  it("deploy a new problem", async () => {    
    await usdc.connect(governance).transfer(publisher.getAddress(), ethers.utils.parseUnits("4000",18))

    const topic = -1234;
    problemHash = "0x"+(new BN(String(topic))).toTwos(256).toString('hex',64);

    await usdc.connect(publisher).approve(startProblem.address, ethers.utils.parseUnits("400000",18))
    await startProblem.connect(publisher).createProblem(problemHash,ethers.utils.parseUnits("4000",18),"What is our motto?")

    const problemAddress = await startProblem.getProblem(problemHash)
    problemNFT = new ethers.Contract(
      problemAddress,
      abiProblem,
      publisher)    
    
    const problemBalance = await usdc.balanceOf(problemAddress);
    console.log("new problemNFT has USDC balance of: ", problemBalance.toString());
    // console.log(problemNFT)
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

  //move time forward past expiry
  it("normalize rewards and claim writer claim rewards", async () => {
    await problemNFT.connect(publisher).rewardSplit() //normalizes rewards
    await problemNFT.connect(writer1).claimWinnings() 

    const balance = await usdc.balanceOf(writer1.getAddress());
    expect(balance.toString()).to.equal("2666666666666666666666")
    console.log("writer1 usdc balance post claim: ", balance.toString())
  })
});
