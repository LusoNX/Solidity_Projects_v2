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

contract TokenCreatorFactory {
    address[] public deployedTokens;

    function deployToken(
        string memory name,
        string memory symbol,
        uint256 initToken
    ) public payable {
        TokenCreatorERC20 new_token = new TokenCreatorERC20(
            symbol,
            name,
            initToken,
            msg.sender
        );
        deployedTokens.push(address(new_token));
    }

    function getdeployedTokens() public view returns (address[] memory) {
        return deployedTokens;
    }
}

contract TokenCreatorERC20 is ERC20 {
    using SafeCast for int256;
    using SafeCast for uint256;
    using SignedSafeMath for int256;
    using Address for address;
    address public manager;
    string public _symbol;
    string public _name;
    uint256 initToken;
    address[] tokenPrice;

    mapping(address => address) addressPrice;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    mapping(address => uint256) components;
    address[] public componentsList;
    address[] public componentsTokenFeed;
    uint256[] public components_balance;
    int256 public initInvestment;
    int256 public EthRequired;
    mapping(address => int256) PriceDict;

    constructor(
        string memory symbol,
        string memory name,
        uint256 _initToken,
        address _manager
    ) public ERC20(symbol, name) {
        manager = _manager;
        _symbol = symbol;
        _name = name;
        _mint(manager, _initToken * 10**uint256(decimals()));
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        transferFrom(from, to, amount);
    }

    function transfer(address to, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function getSummary() public view returns (address) {
        return (address(this));
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
}
