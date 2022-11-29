// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error RaffleErc20__NotEnoughSent();
error RaffleErc20__RewardsNotEqualToWinners();
error RaffleErc20__NftAddressesDoNotMatchWinners();
error RaffleErc20__NftAddressesDoNotMatchIds();
error RaffleErc20__WinnersDoNotMatchNftIds();

interface IERC721 {
     function transferFrom(address from, address to, uint256 tokenId) external;
     function balanceOf(address owner) external view returns (uint256 balance);
}

/// @title Contract that holds ERC20 and ERC721 tokens while the lottery is being processed
/// @author VAIOT team
/// @notice This contract should solely be used for storing tokens and paying out winners of the lottery
/// @dev In order to use this smart contract properly the author of the giveaway should send
/// ERC721 or ERC20 tokens to this smart contract's address. After sending the tokens we can
/// call transferERC20 to send ERC20 tokens to the winners, transferERC721 to send NFTs to winners and
/// getERC20Balance, getERC721Balance to check the balance of ERC20/ERC721 tokens.

contract RaffleERC20 is Ownable {

    /// @notice Transfer ERC20 tokens to the winners
    /// @param _token - address of the ERC20 token
    /// @param _addresses - array of addresses of the winners of the lottery for example ["0x", "0x2", ...]
    /// @param _rewards - array of the amount of tokens each winner should get. Input the amount of tokens
    /// for example if the top 3 winners should get 30, 20 and 10 tokens respectively you should input
    /// [30,20,10]

    function transferERC20(
        address _token,
        address payable[] memory _addresses,
        uint256[] memory _rewards 
    ) public onlyOwner {
        if (_addresses.length != _rewards.length) {
            revert RaffleErc20__RewardsNotEqualToWinners();
        }
        for (uint i = 0; i < _addresses.length; i++) {
            IERC20(_token).transfer(_addresses[i], _rewards[i] * (10 ** 18));
        }
    }

    /// @notice Transfer ERC721 tokens to the winners
    /// @param _NFTAddresses - array of the NFT Collection Addresses
    /// @param _winners - array of addresses of the winners of the lottery for example ["0x", "0x2", ...]
    /// @param _NFTIds - array containing IDs of tokens from certain NFT collections

    function transferERC721(
        address[] memory _NFTAddresses, 
        address[] memory _winners, 
        uint256[] memory _NFTIds
    ) external onlyOwner {
        if (_NFTAddresses.length != _winners.length) {
            revert RaffleErc20__NftAddressesDoNotMatchWinners();
        }
        if (_NFTAddresses.length != _NFTIds.length) {
            revert RaffleErc20__NftAddressesDoNotMatchIds();
        }
        if (_winners.length != _NFTIds.length) {
            revert RaffleErc20__WinnersDoNotMatchNftIds();
        }
        for (uint i=0; i<_winners.length; i++) {
            IERC721 NFT = IERC721(_NFTAddresses[i]);
            NFT.transferFrom(address(this), _winners[i], _NFTIds[i]);
        }
    }

    /// @notice Get the ERC20 holdings of the smart contract
    /// @param _token - address of the ERC20 token

    function getERC20Balance(
        address _token
    ) public view onlyOwner returns (uint) {
        return IERC20(_token).balanceOf(address(this));
    }

    /// @notice Get the ERC721 holdings of the smart contract
    /// @param _token - address of the ERC721 collection

    function getERC721Balance(
        address _token
    ) public view onlyOwner returns (uint) {
        return IERC721(_token).balanceOf(address(this));
    }
}
