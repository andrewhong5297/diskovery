const { expect } = require("chai");
const { ethers } = require("hardhat");
const { abi: abiDisk } = require("../artifacts/contracts/tokens/Disk.sol/Disk.json");

//to include creation of DAO, content approval processes, and maybe user/DAO token claiming
describe("ProblemNFT v1", function () {
  let disk, regtoken, probtoken, conttoken, registry;
  let admin, publisher, user;

  it("setup localhost", async () => {
    [admin, publisher, user] = await ethers.getSigners(); //jsonrpc signers from default 20 accounts with 10000 ETH each
  })

  xit("setup dao minimal proxy", async () => {
    const contract = await ethers.getContractAt("ImplementationContract", addressOfProxy)
    //init
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
  })
})
