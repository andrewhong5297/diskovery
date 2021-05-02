const { expect } = require("chai");
const { ethers } = require("hardhat");
const { abi: abiDisk } = require("../artifacts/contracts/tokens/Disk.sol/Disk.json");
const { abi: abiProblem } = require("../artifacts/contracts/ProblemNFT.sol/ProblemNFT.json");
const fs = require("fs"); 
const BN = require('bn.js');

//make sure you've switched defaultnetwork to Kovan and put a mnemonic.txt file in the test folder
describe("ProblemNFT v1", function () {
  let problemNFT, disk, startProblem;
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

    const StartProblem = await ethers.getContractFactory(
      "StartProblem"
    )  

    startProblem = await StartProblem.connect(governance).deploy(disk.address, governance.getAddress(),disk.address); //replace with registry and USDC address later
    await startProblem.deployed()
  });

  it("deploy a new problem", async () => {
    const topic = -1234;
    docHash = "0x"+(new BN(String(topic))).toTwos(256).toString('hex',64);
    await startProblem.connect(governance).createProblem(docHash,ethers.BigNumber.from("4000"))
    await startProblem.connect(governance).stakeProblem(docHash,ethers.BigNumber.from("1000"))
    await startProblem.connect(publisher).stakeProblem(docHash,ethers.BigNumber.from("3000"))

    const problemAddress = await startProblem.getProblem(docHash)
    problemNFT = new ethers.Contract(
      problemAddress,
      abiProblem,
      governance)    
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
  })
});
