import {
  time,
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("Lock", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployFeeSplittingContractFixture() {
    const [admin, user1] = await ethers.getSigners();
    const feePercentage = 2;
    const FeeSplitting = await ethers.getContractFactory(
      "FeeSplittingContract"
    );
    const feeSplittingContract = await FeeSplitting.deploy(
      admin,
      feePercentage
    );
    const USDT = await ethers.getContractFactory("TetherToken");
    const USDTContract = await USDT.deploy(
      1000000000000000,
      "Tether USD",
      "USDT",
      6
    );

    return { feeSplittingContract, USDTContract, admin, user1 };
  }

  describe("Deployment", function () {
    it("Should set the right unlockTime", async function () {
      const { feeSplittingContract, admin } = await loadFixture(
        deployFeeSplittingContractFixture
      );

      // expect(await lock.unlockTime()).to.equal(unlockTime);
    });
  });

  describe("Test the functionality.", function () {
    it("should deposit and withdraw ERC-20 tokens successfully", async function () {
      const { feeSplittingContract, admin, USDTContract } = await loadFixture(
        deployFeeSplittingContractFixture
      );

      await USDTContract.approve(await feeSplittingContract.getAddress(), 100);

      var tokenAddress = await USDTContract.getAddress();

      var txn = await feeSplittingContract.depositERC20(tokenAddress, 10);
      await feeSplittingContract.connect(admin).withdrawERC20(tokenAddress, 10);
      expect(
        await feeSplittingContract.getUserDepositCount(admin.address)
      ).to.equal(1);
      expect(
        await feeSplittingContract.getUserWithdrawalCount(admin.address)
      ).to.equal(1);
      var balance = await USDTContract.balanceOf(admin.address);
      expect(balance).to.equal("1000000000000000");
    });
    it("Should allow depositing and withdrawing ETH correctly", async function () {
      const { feeSplittingContract, admin } = await loadFixture(
        deployFeeSplittingContractFixture
      );
      const timestamp = await ethers.provider.getBlockNumber();
      const currentBlock = await ethers.provider.getBlock(timestamp);
      const currentBlockTimestamp = (currentBlock?.timestamp || 10000) + 1;

      const depositAmount = ethers.parseEther("1");
      await expect(feeSplittingContract.deposit({ value: depositAmount }))
        .to.emit(feeSplittingContract, "DepositEvent")
        .withArgs(admin, depositAmount, currentBlockTimestamp);

      const withdrawalAmount = ethers.parseEther("0.5");
      expect(feeSplittingContract.withdraw(withdrawalAmount));
    });
  });
});
