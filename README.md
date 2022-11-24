# Lottery Smart Contract

This project showcases and tests Lottery Smart Contract.
The contract allows owner to open up lotteries, add participants of the lottery, get a random number, pick winners of the lottery and payout the winnings to them.

This is a hardhat repository. Before doing anything run

```bash
yarn
```

to install all the dependencies.

In order to properly run this project you must fill out .env file with the following variables:

```bash
MUMBAI_RPC_URL= // the rpc url for the mumbai testnet
PRIVATE_KEY= // private key of the account deploying the contracts
COINMARKETCAP_API_KEY= // coinmarketcap api key
POLYGONSCAN_API_KEY= // polygonscan api key
REPORT_GAS= // true or false
ETHERSCAN_API_KEY= // etherscan api key
```

You will need some testnet MATIC in order to deploy contracts to the testnet. To get some test MATIC go to:

```bash
https://faucet.polygon.technology/
```

Also, make sure you have a subscription created for the Chainlink VRF below:

```bash
https://vrf.chain.link/
```

After creating the subscription fund it with testnet LINK. In order to get testnet LINK visit:

```bash
https://faucets.chain.link/
```

Make sure you swap the subscriptionId in the helper-hardhat-config.js with your own.

Also, after deploying the contract to the mumbai testnet you need to add the contract as the consumer of the subscription.

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
