const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("DefiTest", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployTestFixture() {
    const ONE_YEAR_IN_SECS = 365 * 24 * 60 * 60;
    const ONE_DAY_IN_SECS = 24 * 60 * 60;
    const ONE_GWEI = 1_000_000_000;

  

    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount] = await ethers.getSigners();

    const Token = await ethers.getContractFactory("TestERC20");
    const token = await Token.deploy("Test Token", "TST", { deployer: owner });

    const Defi = await ethers.getContractFactory("DEFIStaking");
    const defi = await Defi.deploy(token.getAddress(), { deployer: owner });

    return { token, defi, ONE_YEAR_IN_SECS, ONE_DAY_IN_SECS, owner, otherAccount };
  }

  describe("Deployment", function () {
    it("Should deploy the contract", async function () {
      const { defi } = await loadFixture(deployTestFixture);

      expect(defi.getAddress()).to.not.be.undefined;
    });

  
  })

  describe("Staking", function () {
    it("Should stake", async function () {
      const { token, defi, owner, otherAccount } = await loadFixture(deployTestFixture);
      await token.connect(owner).transfer(otherAccount.getAddress(), ethers.parseEther("1000"));
      await token.connect(otherAccount).approve(defi.getAddress(), ethers.parseEther("1000"));
      await defi.connect(otherAccount).stake(ethers.parseEther("1000"));
      expect(await defi.getUserBalance(otherAccount.getAddress())).to.equal(ethers.parseEther("1000"));
    });
    it("should allow to stake multiple times", async function () {
      const { token, defi, owner, otherAccount } = await loadFixture(deployTestFixture);
      await token.connect(owner).transfer(otherAccount.getAddress(), ethers.parseEther("4000"));
      await token.connect(otherAccount).approve(defi.getAddress(), ethers.parseEther("1000"));
      await defi.connect(otherAccount).stake(ethers.parseEther("1000"));
      expect(await defi.getUserBalance(otherAccount.getAddress())).to.equal(ethers.parseEther("1000"))
      await network.provider.send("evm_increaseTime", [7200]); // Increase by 7200 seconds
      await network.provider.send("evm_mine");
      await token.connect(otherAccount).approve(defi.getAddress(), ethers.parseEther("1000"));
      await defi.connect(otherAccount).stake(ethers.parseEther("1000"));;
      expect(await defi.getReward(otherAccount.getAddress())).to.be.greaterThan(ethers.parseEther("0"));
      expect(await defi.getUserBalance(otherAccount.getAddress())).to.equal(ethers.parseEther("2000"))
    })
  })

  describe("Unstaking", function () {
    it("Should unstake", async function () {
      const { token, defi, owner, otherAccount } = await loadFixture(deployTestFixture);
      await token.connect(owner).transfer(otherAccount.getAddress(), ethers.parseEther("1000"));
      await token.connect(owner).transfer(defi.getAddress(), ethers.parseEther("1000000"));
      await token.connect(otherAccount).approve(defi.getAddress(), ethers.parseEther("1000"));
      await defi.connect(otherAccount).stake(ethers.parseEther("1000"));
      expect(await defi.getUserBalance(otherAccount.getAddress())).to.equal(ethers.parseEther("1000"));

      await defi.connect(otherAccount).withdraw();
      // expect(await defi.getUserBalance(otherAccount.getAddress())).to.equal(ethers.parseEther("0"));
    })
  })


});
