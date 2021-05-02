//to include creation of DAO, content approval processes, and maybe user/DAO token claiming
//do we need to have content specific tokens? if it a min threshold of disk tokens, maybe token transfers need some rules on them.
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
    //was there anything else to setup here? lol
  })

  it("setup dao minimal proxy", async () => {
    const contract = await ethers.getContractAt("ImplementationContract", addressOfProxy)
    //init
  })

  it("deploy tokens", async () => {
      //deploy three tokens, mint to admin for testing
  })

//   it("")
})
