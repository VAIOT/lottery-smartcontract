const { assert, expect } = require("chai");
const { network, deployments, ethers } = require("hardhat");
const {
  developmentChains,
  networkConfig,
} = require("../../helper-hardhat-config");

!developmentChains.includes(network.name)
  ? describe.skip
  : describe("Raffle Whitelist Unit Tests", function () {
      let raffle, raffleContract, vrfCoordinatorV2Mock, player;

      beforeEach(async () => {
        accounts = await ethers.getSigners();
        player = accounts[1];
        playerTwo = accounts[2];
        await deployments.fixture(["rafflewhitelist"]); // Deploys modules with the tags "mocks" and "raffle"
        vrfCoordinatorV2Mock = await ethers.getContract("VRFCoordinatorV2Mock"); // Returns a new connection to the VRFCoordinatorV2Mock contract
        raffleContract = await ethers.getContract("RaffleWinnerPicker"); // Returns a new connection to the Raffle contract
        raffle = raffleContract.connect(player); // Returns a new instance of the Raffle contract connected to player
      });

      describe("constructor", function () {
        it("initializes the raffle with id 0", async () => {
          const lotteryId = (await raffle.getLotteryId()).toString();
          assert.equal(lotteryId, "0");
        });
      });

      describe("openLottery", function () {
        it("Reverts if not the owner calls the function", async () => {
          const playerConnected = await raffleContract.connect(player);
          await expect(
            playerConnected.openLottery(
              "0xD6D8903F2E900b176c5915A68144E4bd664aA153",
              "4"
            )
          ).to.be.reverted;
        });
        it("Sets the lottery Id and lottery parameters properly", async () => {
          await raffleContract.openLottery(
            "0xD6D8903F2E900b176c5915A68144E4bd664aA153",
            "4"
          );
          assert.equal(await raffleContract.getLotteryId(), "1");
          assert.equal(await raffleContract.checkIfLotteryExists(1), "1");
          assert.equal(
            await raffleContract.getLotteryAuthor(1),
            "0xD6D8903F2E900b176c5915A68144E4bd664aA153"
          );
          assert.equal(await raffleContract.getLotteryState(1), "1");
          assert.equal(await raffleContract.getNumberOfWinners(1), "4");
        });
      });
      describe("addLotteryParticipants", function () {
        it("Does not allow other people to call the function", async () => {
          const playerConnected = await raffleContract.connect(player);
          await expect(
            playerConnected.addLotteryParticipants("1", [
              "0xD6D8903F2E900b176c5915A68144E4bd664aA153",
              "0xD6D8903F2E900b176c5915A68144E4bd664aA153",
              "0xD6D8903F2E900b176c5915A68144E4bd664aA153",
              "0xD6D8903F2E900b176c5915A68144E4bd664aA153",
            ])
          ).to.be.reverted;
        });
        it("Does not allow to call this function when the lottery is not open or does not exist", async () => {
          await expect(
            raffleContract.addLotteryParticipants("2", [
              "0xD6D8903F2E900b176c5915A68144E4bd664aA153",
              "0xD6D8903F2E900b176c5915A68144E4bd664aA153",
              "0xD6D8903F2E900b176c5915A68144E4bd664aA153",
              "0xD6D8903F2E900b176c5915A68144E4bd664aA153",
            ])
          ).to.be.revertedWithCustomError(
            raffleContract,
            "Lottery__LotteryClosed"
          );
        });
        it("Updates the participants array properly", async () => {
          await raffleContract.openLottery(
            "0xD6D8903F2E900b176c5915A68144E4bd664aA153",
            "4"
          );
          await raffleContract.addLotteryParticipants("1", [
            "0xD6D8903F2E900b176c5915A68144E4bd664aA153",
            "0xD6D8903F2E900b176c5915A68144E4bd664aA153",
            "0xD6D8903F2E900b176c5915A68144E4bd664aA153",
            "0xD6D8903F2E900b176c5915A68144E4bd664aA153",
          ]);
          assert.equal((await raffleContract.getParticipants("1")).toString(), [
            "0xD6D8903F2E900b176c5915A68144E4bd664aA153",
            "0xD6D8903F2E900b176c5915A68144E4bd664aA153",
            "0xD6D8903F2E900b176c5915A68144E4bd664aA153",
            "0xD6D8903F2E900b176c5915A68144E4bd664aA153",
          ]);
        });
        it("Emits AddressesAdded event", async () => {
          await raffleContract.openLottery(
            "0xD6D8903F2E900b176c5915A68144E4bd664aA153",
            "4"
          );
          await expect(
            raffleContract.addLotteryParticipants("1", [
              "0xD6D8903F2E900b176c5915A68144E4bd664aA153",
              "0xD6D8903F2E900b176c5915A68144E4bd664aA153",
              "0xD6D8903F2E900b176c5915A68144E4bd664aA153",
              "0xD6D8903F2E900b176c5915A68144E4bd664aA153",
            ])
          ).to.emit(raffleContract, "AddressesAdded");
        });
      });
      describe("fulfillRandomWords", function () {
        beforeEach(async () => {
          await raffleContract.openLottery(
            "0xD6D8903F2E900b176c5915A68144E4bd664aA153",
            "4"
          );
          await raffleContract.addLotteryParticipants("1", [
            "0xD6D8903F2E900b176c5915A68144E4bd664aA153",
            "0xD6D8903F2E900b176c5915A68144E4bd664aA153",
            "0xD6D8903F2E900b176c5915A68144E4bd664aA153",
            "0xD6D8903F2E900b176c5915A68144E4bd664aA153",
          ]);
        });
        it("Can only be called after you request a random word", async () => {
          await expect(
            vrfCoordinatorV2Mock.fulfillRandomWords(0, raffle.address) // reverts if not fulfilled
          ).to.be.revertedWith("nonexistent request");
        });
      });
    });
