<div align="center">
    <img src="assets/vaiotLogo.svg" alt="VAIOT Logo" width="400"/>
</div>

</br>
</br>

# Lottery Smart Contract

Welcome to the official repository for the Lottery Smart Contract which allows users to create their own decentralized lotteries. This repository houses the development and maintenance of the lottery contract designed for Ethereum-based tokens, utilizing the solidity programming language and the Hardhat development environment.

## Installation

To get started with the Lottery Contract:

```bash
git clone https://github.com/VAIOT/lottery-smartcontract.git
cd lottery-smartcontract
yarn
```

## Configuration

To properly configure the project, create a .env file in the root directory and include the following required variables:

```bash
MUMBAI_RPC_URL= // the rpc url for the mumbai testnet
GOERLI_RPC_URL= // the rpc url for the goerli testnet
PRIVATE_KEY= // private key of the account deploying the contracts
COINMARKETCAP_API_KEY= // coinmarketcap api key
POLYGONSCAN_API_KEY= // polygonscan api key
REPORT_GAS= // true or false
ETHERSCAN_API_KEY= // etherscan api key

```

## Smart Contract Overview

The Raffle contract allows owner to open up lotteries, add participants of the lottery, get a random number, pick winners of the lottery and payout the winnings to them.

The RaffleWinnerPicker has a very similiar functionality to the Raffle contract with one main difference - the contract does not payout any money to the winners. The contract is strictly for opening up lotteries without money, adding participants of the giveaway and finding X amount of winners using the VRF Chainlink technology.

The RaffleERC20 contract is used for storing ERC20 and ERC721 during the lottery. Users are able to send both ERC20 and ERC721 tokens to this smart contract for safekeeping and after the lottery has ended, a backend service should call transferERC20 to send ERC20 tokens to winners or transferERC721 to send ERC721 tokens to the winners.

For full functionality and method descriptions, refer to the source code.

## Deployment

Deploy the smart contract either locally or on a testnet using the Hardhat tool.

### Local Deployment

```bash
yarn hardhat deploy
```

### Mumbai Testnet Deployment

```bash
yarn hardhat deploy --network mumbai
```

## Testing

Run the unit tests to ensure code reliability:

```bash
yarn hardhat test
```

## Contributing

Contributions are what make the open-source community such an amazing place to learn, inspire, and create. Any contributions you make are greatly appreciated.
