const { expect } = require("chai");
const { ethers } = require("hardhat");
const { abi: abiDisk } = require("../artifacts/contracts/tokens/Disk.sol/Disk.json");
const { abi: abiProblem } = require("../artifacts/contracts/ProblemNFT.sol/ProblemNFT.json");
const fs = require("fs"); 
const BN = require('bn.js');

describe("ProblemNFT v1", function () {
  let problemNFT, startProblem, usdc;
  let disk, regtoken, probtoken, conttoken, registry;
  let problemHash, expiry;
  let writer1, writer2, publisher, user, admin;

  it("setup localhost", async () => {
    [writer1, writer2, publisher, user, admin] = await ethers.getSigners(); //jsonrpc signers from default 20 accounts with 10000 ETH each
  })

  it("deploy tokens", async () => {
    const Disk = await ethers.getContractFactory(
      "Disk"
    );
    disk = await Disk.connect(admin).deploy(); //mints full supply to deployer
    await disk.deployed()

    const RegToken = await ethers.getContractFactory(
      "RegToken"
    );
    regtoken = await RegToken.connect(admin).deploy(); //mints full supply to deployer
    await regtoken.deployed()
      
    const ProbToken = await ethers.getContractFactory(
      "ProbToken"
    );
    probtoken = await ProbToken.connect(admin).deploy(); //mints full supply to deployer
    await probtoken.deployed()

    const ContToken = await ethers.getContractFactory(
      "ContToken"
    );
    conttoken = await ContToken.connect(admin).deploy(); //mints full supply to deployer
    await conttoken.deployed()
    
    await disk.connect(admin).transfer(publisher.getAddress(),ethers.utils.parseUnits("1000",18))
    await regtoken.connect(admin).transfer(publisher.getAddress(),ethers.utils.parseUnits("10",18))
    await probtoken.connect(admin).transfer(publisher.getAddress(),ethers.utils.parseUnits("10",18))
    await conttoken.connect(admin).transfer(publisher.getAddress(),ethers.utils.parseUnits("10",18))
  })

  it("deploy registry", async () => {
    const Registry = await ethers.getContractFactory(
      "AllRegistry"
    );
    registry = await Registry.connect(admin).deploy(disk.address,regtoken.address,probtoken.address,conttoken.address); //mints full supply to deployer
    await registry.deployed()

    await disk.connect(admin).setRegistry(registry.address)
    await regtoken.connect(admin).setRegistry(registry.address)
    await probtoken.connect(admin).setRegistry(registry.address)
    await conttoken.connect(admin).setRegistry(registry.address)    
  })
  
  it("register DAO", async () => {
    await regtoken.connect(publisher).approve(registry.address,ethers.utils.parseUnits("1000",18))
    await registry.connect(publisher).registerPub()
    const isPub = await registry.checkPubDAO(publisher.getAddress())
    expect(isPub).to.equal(true);
    // console.log("publisher state: ", isPub)
  })

  it("claim weekly DAO and purchase tokens", async () => {
    await registry.connect(publisher).claimWeeklyPub()
    await expect(registry.connect(publisher).claimWeeklyPub()).to.be.revertedWith("pub has already claimed this week");

    await disk.connect(publisher).approve(registry.address,ethers.utils.parseUnits("100000",18))
    await registry.connect(publisher).buyTokens(ethers.utils.parseUnits("1",18), ethers.BigNumber.from("2"))
  })
  
  it("claim weekly user", async () => { 
    await registry.connect(user).claimWeeklyUser()
    await expect(registry.connect(user).claimWeeklyUser()).to.be.revertedWith("user has already claimed this week");
    await disk.connect(admin).transfer(user.getAddress(),ethers.utils.parseUnits("5000",18)) //for staking later
  })

  it("deploy problem factory", async () => {
    const USDC = await ethers.getContractFactory(
       "Disk"
    );
    usdc = await USDC.connect(admin).deploy(); //mints full supply to deployer
    await usdc.deployed()

    const StartProblem = await ethers.getContractFactory(
      "StartProblem"
    )  

    startProblem = await StartProblem.connect(admin).deploy(disk.address, registry.address, usdc.address, probtoken.address, conttoken.address);
    await startProblem.deployed()
  });

  it("deploy a new problem", async () => {    
    await usdc.connect(admin).transfer(publisher.getAddress(), ethers.utils.parseUnits("4000",18))

    const topic = -1234;
    problemHash = "0x"+(new BN(String(topic))).toTwos(256).toString('hex',64);
    expiry = "50000"; //about a week or so

    await probtoken.connect(publisher).approve(startProblem.address, ethers.utils.parseUnits("100",18))
    await usdc.connect(publisher).approve(startProblem.address, ethers.utils.parseUnits("400000",18))
    await startProblem.connect(publisher).createProblem(problemHash,ethers.utils.parseUnits("4000",18),ethers.BigNumber.from(expiry),"What is our motto?")

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
    await conttoken.connect(publisher).approve(problemNFT.address,ethers.utils.parseUnits("10",18))

    const num = 1559;
    const contentHash = "0x"+(new BN(String(num))).toTwos(256).toString('hex',64);
    await problemNFT.connect(publisher).newContent(writer1.getAddress(),"Into the Ether",contentHash)

    const num2 = 2059;
    const contentHash2 = "0x"+(new BN(String(num2))).toTwos(256).toString('hex',64);
    await problemNFT.connect(publisher).newContent(writer2.getAddress(),"Out of the Ether",contentHash2)

    const balance = await problemNFT.balanceOf(writer1.getAddress())
    expect(parseInt(balance.toString())).to.equal(1)

    const content_count = await problemNFT.getContentCount();
    const content = await problemNFT.getContent(ethers.BigNumber.from(content_count)) 
    // console.log(content)
  })

  it("user stakes content", async () => {
    await disk.connect(user).approve(problemNFT.address,ethers.utils.parseUnits("5000",18))
    await problemNFT.connect(user).stakeContent(ethers.BigNumber.from("1000"),ethers.BigNumber.from("1"))
    await problemNFT.connect(user).stakeContent(ethers.BigNumber.from("500"),ethers.BigNumber.from("2"))
  })

  it("normalize rewards and claim writer claim rewards", async () => {
    //move time forward past expiry
    await network.provider.send("evm_setNextBlockTimestamp", [Date.now()+parseInt(expiry)+100])
    await network.provider.send("evm_mine")

    await problemNFT.connect(publisher).rewardSplit() //normalizes rewards
    await problemNFT.connect(writer1).claimWinnings() 

    const balance = await usdc.balanceOf(writer1.getAddress());
    expect(balance.toString()).to.equal("2666666666666666666666")
    console.log("writer1 usdc balance post claim: ", balance.toString())
  })
});
