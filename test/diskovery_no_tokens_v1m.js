const { expect } = require("chai");
const { ethers } = require("hardhat");
const { abi: abiDisk } = require("../artifacts/contracts/tokens/Disk.sol/Disk.json");
const { abi: abiProblem } = require("../artifacts/contracts/ProblemNFT.sol/ProblemNFT.json");
const fs = require("fs"); 
const BN = require('bn.js');

describe("Diskover No_Tokens Proxy Test v1", function () {
  let problemNFT, startProblem, usdc;
  let disk, regtoken, probtoken, conttoken, registry;
  let problemHash, expiry;
  let writer1, writer2, reader, admin;
  let contentHash, contentHash2;
  let dao, daoMProxy, adminDao, leader1, leader2, editor1;

  it("setup localhost", async () => {
    [writer1, writer2, reader, admin, adminDao, leader1, leader2, editor1] = await ethers.getSigners(); //jsonrpc signers from default 20 accounts with 10000 ETH each
  })

  it("deploy all tokens", async () => {
    const Disk = await ethers.getContractFactory(
      "Disk"
    );
    disk = await Disk.connect(admin).deploy(); //mints full supply to deployer
    await disk.deployed()

    // const RegToken = await ethers.getContractFactory(
    //   "RegToken"
    // );
    // regtoken = await RegToken.connect(admin).deploy(); //mints full supply to deployer
    // await regtoken.deployed()
      
    // const ProbToken = await ethers.getContractFactory(
    //   "ProbToken"
    // );
    // probtoken = await ProbToken.connect(admin).deploy(); //mints full supply to deployer
    // await probtoken.deployed()

    // const ContToken = await ethers.getContractFactory(
    //   "ContToken"
    // );
    // conttoken = await ContToken.connect(admin).deploy(); //mints full supply to deployer
    // await conttoken.deployed()
    })

  it("deploy registry contract", async () => {
    const Registry = await ethers.getContractFactory(
      "AllRegistry"
    );
    registry = await Registry.connect(admin).deploy(disk.address)//regtoken.address,probtoken.address,conttoken.address); //mints full supply to deployer
    await registry.deployed()

    await disk.connect(admin).setRegistry(registry.address)
    // await regtoken.connect(admin).setRegistry(registry.address)
    // await probtoken.connect(admin).setRegistry(registry.address)
    // await conttoken.connect(admin).setRegistry(registry.address)    
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

    startProblem = await StartProblem.connect(admin).deploy(disk.address, registry.address, usdc.address)//, probtoken.address, conttoken.address);
    await startProblem.deployed()
  });

  //dao creation, roles setup, funding,
  it("deploy DAO contract", async () => {
    const DAOFACTORY = await ethers.getContractFactory(
      "PubDAOfactory"
    )
    daoMProxy = await DAOFACTORY.connect(adminDao).deploy(disk.address, usdc.address, registry.address, startProblem.address); //removed regtoken.address,probtoken.address,conttoken.address
    await daoMProxy.deployed()

    const daoCreated = await daoMProxy.connect(adminDao).createDao("First Dao");
    // console.log(daoCreated)
    const daoAddress = await daoMProxy.connect(adminDao).getDao("First Dao");
    console.log(daoAddress)
    dao = await ethers.getContractAt("PubDAOclones", daoAddress) 
    
    //set leaders and editors
    await dao.connect(adminDao).manageEditor(editor1.getAddress(),true)
    await dao.connect(adminDao).manageLeader(leader1.getAddress(),true)
    await dao.connect(adminDao).manageLeader(leader2.getAddress(),true)
  })

  // xit("test DAO buy reg token from Registry", async () => {
  //   //normally this would have to be earned
  //   await disk.connect(admin).transfer(dao.address,ethers.utils.parseUnits("500000",18)) 
  //   await dao.connect(adminDao).buyTokens(ethers.utils.parseUnits("1",18),ethers.BigNumber.from("0"))
  // })

  it("register DAO", async () => {
    await dao.connect(adminDao).register()
    const isPub = await registry.checkPubDAO(dao.address)
    expect(isPub).to.equal(true);
    // console.log("publisher state: ", isPub)
  })

  // xit("claim weekly DAO tokens, and purchase more tokens", async () => {
  //   await dao.connect(leader1).claimTokens()
  //   await expect(dao.connect(leader1).claimTokens()).to.be.revertedWith("pub has already claimed this week");
  // })
  
  xit("claim weekly reader tokens", async () => { 
    await registry.connect(reader).claimWeeklyUser()
    await expect(registry.connect(reader).claimWeeklyUser()).to.be.revertedWith("user has already claimed this week");
  })

  xit("DAO creates, votes, and deploys a new problem", async () => {    
    const topic = -1234;
    problemHash = "0x"+(new BN(String(topic))).toTwos(256).toString('hex',64);
    expiry = "50000"; //about a week or so
    reward = ethers.utils.parseUnits("4000",18)

    //this would normally be funded by dao themselves
    await usdc.connect(admin).transfer(dao.address, reward)

    await dao.connect(leader1).suggestProblem(problemHash, reward, "What is our motto?", expiry)
    await dao.connect(leader2).voteProblem(problemHash,true);
    await dao.connect(editor1).voteProblem(problemHash,true);

    const problemAddress = await startProblem.getProblem(problemHash)
    problemNFT = new ethers.Contract(
      problemAddress,
      abiProblem,
      adminDao)    

    const problemBalance = await usdc.balanceOf(problemAddress);
    expect(problemBalance).to.equal(reward)
  })

  xit("writers submit content to DAO", async () => {
    const num = 1559;
    contentHash = "0x"+(new BN(String(num))).toTwos(256).toString('hex',64);
    const _stake = ethers.utils.parseUnits("500",18);
    await disk.connect(writer1).approve(dao.address,_stake)
    //expiry should be pulled from contract as 
    await dao.connect(writer1).submitContent(contentHash,"Into the Ether",problemNFT.address,_stake,problemNFT.getExpiry()) 
    
    const num2 = 2059;
    contentHash2 = "0x"+(new BN(String(num2))).toTwos(256).toString('hex',64);
    const _stake2 = ethers.utils.parseUnits("300",18);
    await disk.connect(writer2).approve(dao.address,_stake2)
    await dao.connect(writer2).submitContent(contentHash2,"Out of the Ether",problemNFT.address,_stake2,problemNFT.getExpiry()) 
  })

  xit("DAO publishes the 2 pieces of content", async () => {
    await dao.connect(editor1).publishContent(contentHash);
    await dao.connect(editor1).publishContent(contentHash2);

    const balance = await problemNFT.balanceOf(writer1.getAddress())
    expect(parseInt(balance.toString())).to.equal(1)

    const content_count = await problemNFT.getContentCount();
    expect(parseInt(content_count.toString())).to.equal(2);
    // const content = await problemNFT.getContent(ethers.BigNumber.from(content_count)) 
  })

  xit("reader stakes content", async () => {
    await disk.connect(reader).approve(problemNFT.address,ethers.utils.parseUnits("5000",18))
    await problemNFT.connect(reader).stakeContent(ethers.BigNumber.from("1000"),ethers.BigNumber.from("1"))
    await problemNFT.connect(reader).stakeContent(ethers.BigNumber.from("500"),ethers.BigNumber.from("2"))
  })

  xit("normalize rewards and claim writer rewards", async () => {
    //move time forward past expiry
    await network.provider.send("evm_setNextBlockTimestamp", [Date.now()+parseInt(expiry)+100])
    await network.provider.send("evm_mine")

    await problemNFT.connect(writer1).rewardSplit() //normalizes rewards, called by anyone
    await problemNFT.connect(writer1).claimWinnings() 

    const balance = await usdc.balanceOf(writer1.getAddress());
    expect(balance.toString()).to.equal("2666666666666666666666")
    // console.log("writer1 usdc balance post claim: ", balance.toString())
  })
});
