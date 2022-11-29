# Lottery Smart Contract

This project showcases and tests Lottery Smart Contract.

The Raffle contract allows owner to open up lotteries, add participants of the lottery, get a random number, pick winners of the lottery and payout the winnings to them.

The RaffleWinnerPicker has a very similiar functionality to the Raffle contract with one main difference - the contract does not payout any money to the winners. The contract is strictly for opening up lotteries without money, adding participants of the giveaway and finding X amount of winners using the VRF Chainlink technology.

The RaffleERC20 contract is used for storing ERC20 and ERC721 during the lottery. Users are able to send both ERC20 and ERC721 tokens to this smart contract for safekeeping and after the lottery has ended, our back-end service will call transferERC20 to send ERC20 tokens to winners or transferERC721 to send ERC721 tokens to the winners.

This is a hardhat repository. Before doing anything run

```bash
yarn
```

to install all the dependencies.

In order to properly run this project you must fill out .env file with the following variables:

```bash
MUMBAI_RPC_URL= // the rpc url for the mumbai testnet
GOERLI_RPC_URL= // the rpc url for the goerli testnet
PRIVATE_KEY= // private key of the account deploying the contracts
COINMARKETCAP_API_KEY= // coinmarketcap api key
POLYGONSCAN_API_KEY= // polygonscan api key
REPORT_GAS= // true or false
ETHERSCAN_API_KEY= // etherscan api key
```

You will need some testnet MATIC in order to deploy Raffle.sol / RaffleWinnerPicker.sol contracts to the testnet. To get some test MATIC go to:

```bash
https://faucet.polygon.technology/
```

If you wish to deploy RaffleERC20.sol to the Goerli testnet, you can get Goerli ETH from here:

```bash
https://goerlifaucet.com/
```

To deploy Raffle.sol or RaffleWinnerPicker.sol make sure you have a subscription created for the Chainlink VRF below:

```bash
https://vrf.chain.link/
```

After creating the subscription fund it with testnet LINK. In order to get testnet LINK visit:

```bash
https://faucets.chain.link/
```

Make sure you swap the subscriptionId in the helper-hardhat-config.js with your own.

After deploying the contract to the mumbai testnet you need to add the contract as the consumer of the subscription.

To deploy the smart contract locally you need to write:

```bash
yarn hardhat deploy
```

Or if you wish to deploy to the mumbai testnet you must write:

```bash
yarn hardhat deploy --network mumbai
```

To run unit tests write:

```bash
yarn hardhat test
```

## Additional Information

- The Lottery ID starts with 1
- The contract is able to run many different lotteries simultaneously
- The maximum amount of participants that you can add in one go is 500, any more could exceed the maximum block size
- The function emergencyCashback should only be used if funds are stuck
- Contract is able to run both locally and on a testnet, there is a VRF mock included in the contract for local testing
- If you find any way to optimize the code, please submit a pull request

## Disclaimer

The RaffleWinnerPicker contract is meant mainly for whitelist giveaways, giveaways of physical items (something off the blockchain) and for picking winners for ERC20 / ERC721 giveaways.

If anyone wishes to giveaway for example ERC20 tokens the process is as follows:

- User calls the RaffleERC20 contract and sends the tokens that are being given away (either ERC20 or ERC721)
- The RaffleWinnerPicker contract is called and it opens up a new lottery 
- We ping our back-end service that the giveaway has started, and that after xxx amount of time it should pick up all the lottery participants from a given twitter url (it should filter out all the bots aswell and should not allow one wallet address to enter more than once)
- After xxx amount of time has passed, our service calls the RaffleWinnerPicker to find the winners of the lottery
- Our service calls the RaffleERC20 contract with these winners in order to send the winnings to the winners
