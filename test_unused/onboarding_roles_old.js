const { expect } = require("chai");
const { ethers } = require("hardhat");
const { abi: abiDisk } = require("../artifacts/contracts/tokens/Disk.sol/Disk.json");

//to include creation of DAO, content approval processes, and maybe user/DAO token claiming
describe("Onboarding and Registry v1", function () {
  let disk, regtoken, probtoken, conttoken, registry, usdc;
  let admin, publisher, user;
  let dao, leader1, leader2, editor1;

  it("setup localhost", async () => {
    [admin, publisher, user, leader1, leader2, editor1] = await ethers.getSigners(); //jsonrpc signers from default 20 accounts with 10000 ETH each
  })

  xit("setup dao minimal proxy", async () => {
    const contract = await ethers.getContractAt("ImplementationContract", addressOfProxy)
    //init
  })

  it("deploy tokens", async () => {
    const USDC = await ethers.getContractFactory(
      "Disk"
    );
    usdc = await USDC.connect(admin).deploy(); //mints full supply to deployer
    await usdc.deployed()

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
    registry = await Registry.connect(admin).deploy(disk.address,regtoken.address,probtoken.address,conttoken.address); 
    await registry.deployed()

    await disk.connect(admin).setRegistry(registry.address)
    await regtoken.connect(admin).setRegistry(registry.address)
    await probtoken.connect(admin).setRegistry(registry.address)
    await conttoken.connect(admin).setRegistry(registry.address)    
  })

  it("deploy DAO", async () => {
    const DAO = await ethers.getContractFactory(
      "PubDAO"
    );
    dao = await DAO.connect(admin).deploy(disk.address,usdc.address,regtoken.address,probtoken.address,conttoken.address, registry.address, registry.address); 
    await dao.deployed()

    //set leaders and editors
    await dao.connect(admin).manageEditor(editor1.getAddress(),true)
    await dao.connect(admin).manageLeader(leader1.getAddress(),true)
    await dao.connect(admin).manageLeader(leader2.getAddress(),true)
  })

  it("test DAO buy reg token", async () => {
    //normally this would have to be earned
    await disk.connect(admin).transfer(dao.address,ethers.utils.parseUnits("500000",18)) 
    await dao.connect(admin).buyTokens(ethers.utils.parseUnits("1",18),ethers.BigNumber.from("0"))
  })

  it("register DAO", async () => {
    await dao.connect(admin).register()
    const isPub = await registry.checkPubDAO(dao.address)
    expect(isPub).to.equal(true);
    // console.log("publisher state: ", isPub)
  })

  it("claim weekly DAO and purchase tokens", async () => {
    await dao.connect(leader1).claimTokens()
    await expect(dao.connect(leader1).claimTokens()).to.be.revertedWith("pub has already claimed this week");
  })
  
  it("claim weekly user", async () => { 
    await registry.connect(user).claimWeeklyUser()
    await expect(registry.connect(user).claimWeeklyUser()).to.be.revertedWith("user has already claimed this week");
  })
})
