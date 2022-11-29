// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error RaffleErc20__NotEnoughSent();
error RaffleErc20__RewardsNotEqualToWinners();

contract RaffleErc20 is Ownable {
    function payOutWinners(
        address _token,
        address payable[] memory _addresses,
        uint256[] memory rewards // input has to be for example 1 = 1 ether
    ) public onlyOwner {
        if (_addresses.length != rewards.length) {
            revert RaffleErc20__RewardsNotEqualToWinners();
        }
        for (uint i = 0; i < _addresses.length; i++) {
            IERC20(_token).transfer(_addresses[i], rewards[i] * (10 ** 18));
        }
    }

    function getTokenBalance(
        address _token
    ) public view onlyOwner returns (uint) {
        return IERC20(_token).balanceOf(address(this));
    }
}
