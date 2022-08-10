pragma solidity >=0.6.0 <0.8.0;

// Contract Notes :

// 1. Chainlink decimals are 10**8 for usd pairs while 10**18 for ether path,

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/SafeCast.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {SignedSafeMath} from "@openzeppelin/contracts/math/SignedSafeMath.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

contract ERC20Factory {
    address[] public deployedTokens;
    address public FactoryOwner;

    constructor() public {
        FactoryOwner = msg.sender;
    }

    function deployToken(
        string memory name,
        string memory symbol,
        uint256 _initToken
    ) public {
        ERC20 newToken = new ERC20(name, symbol);
        deployedTokens.push(address(newToken));
    }

    function getDeployedTokens() public view returns (address[] memory) {
        return deployedTokens;
    }
}
