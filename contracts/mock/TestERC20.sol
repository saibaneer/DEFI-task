// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestERC20 is ERC20 {
    uint256 public constant INITIAL_SUPPLY = 10000000 * 10**18; // 10,000,000 tokens with 18 decimal places

    constructor(string memory name, string memory symbol)
        ERC20(name, symbol)
    {
        _mint(msg.sender, INITIAL_SUPPLY); // Mint the initial supply to the deployer's address
        _mint(address(this), INITIAL_SUPPLY); // Mint the initial supply to the deployer's address
    }
}
