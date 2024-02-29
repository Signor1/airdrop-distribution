//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MetaToken is ERC20, Ownable {
    constructor() ERC20("Meta Token", "MT") Ownable(msg.sender) {
        _mint(msg.sender, 1000000 * (10 ** 18));
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
