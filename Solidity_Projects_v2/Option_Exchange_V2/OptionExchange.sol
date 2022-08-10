pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {LinkTokenInterface} from "../interfaces/LinkTokenInterface.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract OptionExchangeFactory is IERC721Receiver {
    address[] deployedOptions;

    function deployOption(
        string memory option_name,
        string memory option_symbol,
        address __owner,
        address _payToken,
        address _sellToken,
        address _premiumToken
    ) public {
        OptionExchange newOption = new OptionExchange(
            option_name,
            option_symbol,
            __owner,
            _payToken,
            _sellToken,
            _premiumToken
        );
        deployedOptions.push(address(newOption));
    }

    function getDeployedOptions() public view returns (address[] memory) {
        return deployedOptions;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) public override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

contract OptionExchange is ERC721, IERC721Receiver {
    using SafeMath for uint256;
    ERC721 nft;
    ERC20 pay_token;
    ERC20 sell_token;
    ERC20 premium_token;

    string public nft_name;
    string public nft_symbol;

    address public payTokenAddress;
    address public sellTokenAddress;
    address public premiumTokenAddress;
    address public owner;
    uint256 public exerciseVal;
    address payable contractAddress;
    uint256 private tokenID;
    mapping(uint256 => address) private _owners;
    bool withdrawn_premium;
    bool funded;

    struct option {
        uint256 strike; //Price in USD (18 decimal places) option allows buyer to purchase tokens at
        uint256 premium; //Fee in contract token that option writer charges
        uint256 expiry; //Unix timestamp of expiration time
        uint256 amount; //Amount of tokens the option contract is for
        bool exercised; //Has option been exercised
        bool canceled; //Has option been canceled
        address payable writer; //Issuer of option
        address payable buyer; //Buyer of option
    }

    option public TokenOpts;
    enum State {
        Deployed,
        Available,
        Covered,
        Sold
    }
    State public OptionState;

    constructor(
        string memory name,
        string memory symbol,
        address _owner,
        address _payTokenAddress,
        address _sellTokenAddress,
        address _premiumTokenAddress
    ) public ERC721(name, symbol) {
        OptionState = State.Deployed;
        nft_name = name;
        nft_symbol = symbol;
        owner = _owner;
        payTokenAddress = _payTokenAddress;
        sellTokenAddress = _sellTokenAddress;
        premiumTokenAddress = _premiumTokenAddress;
        tokenID += 1;
        _safeMint(owner, tokenID);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) public override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function writeOption(
        uint256 strike,
        uint256 premium,
        uint256 expiry,
        uint256 tokenAmount
    ) external onlyOwner {
        require(OptionState == State.Covered);
        sell_token = ERC20(sellTokenAddress);
        pay_token = ERC20(payTokenAddress);
        premium_token = ERC20(premiumTokenAddress);
        nft = ERC721(address(this));
        uint256 sell_token_decimals = sell_token.decimals();
        uint256 tokenV = tokenAmount * (10**sell_token_decimals);
        require(
            sell_token.transferFrom(msg.sender, address(this), tokenV),
            "Incorrect Amount Supplied"
        );
        uint256 pay_token_decimals = pay_token.decimals();
        uint256 premium_token_decimals = premium_token.decimals();
        TokenOpts = option(
            strike * (10**pay_token_decimals) * tokenAmount,
            premium * (10**premium_token_decimals) * tokenAmount, // Adjust the premium so if you increase the amount of tokens in the call, the larger the premium is demanded per contract
            expiry,
            tokenAmount * (10**sell_token_decimals),
            false,
            false,
            msg.sender,
            address(0)
        );
        OptionState = State.Available;
    }

    function transferNFT() external onlyOwner {
        require(OptionState == State.Deployed);
        ERC721 nft_obj = ERC721(address(this));
        nft_obj.safeTransferFrom(msg.sender, address(this), tokenID);
        OptionState = State.Covered;
    }

    //function balanceOf(address) external view returns (uint256);
    function ownerOf() public view virtual returns (address) {
        address owner_nft = nft.ownerOf(tokenID);
        return owner_nft;
    }

    function buyOption() public payable {
        require(OptionState == State.Available);
        nft = ERC721(address(this));
        require(
            premium_token.transferFrom(
                msg.sender,
                address(this),
                TokenOpts.premium
            ),
            "Incorrect amount sent for the premium"
        );
        TokenOpts.buyer = msg.sender;
        nft.safeTransferFrom(address(this), msg.sender, tokenID);
        OptionState = State.Sold;
        withdrawn_premium = false;
    }

    function withdrawPremium() public payable {
        require(withdrawn_premium == false);
        require(OptionState == State.Sold);
        require(msg.sender == owner);
        premium_token.transfer(msg.sender, TokenOpts.premium);
        withdrawn_premium = true;
    }

    function withdrawStrike() public payable {
        require(TokenOpts.exercised, "Option not yet exercised");
        require(msg.sender == owner);
        pay_token.transfer(msg.sender, TokenOpts.strike);
    }

    function exercise(uint256 _tokenID) public payable {
        require(OptionState == State.Sold);
        require(!TokenOpts.exercised, "Option already exercised expired");
        require(TokenOpts.expiry > now, "Option has expired");
        require(this.ownerOf(_tokenID) == msg.sender);
        pay_token = ERC20(payTokenAddress);
        require(
            pay_token.transferFrom(msg.sender, address(this), TokenOpts.strike),
            "Error: buyer has not paid"
        );
        sell_token.transfer(msg.sender, TokenOpts.amount);
        TokenOpts.exercised = true;
    }

    function getSummary()
        public
        view
        returns (
            address,
            address,
            address,
            address,
            uint256
        )
    {
        return (
            sellTokenAddress,
            payTokenAddress,
            owner,
            premiumTokenAddress,
            tokenID
        );
    }

    function getNameSymbol()
        public
        view
        returns (string memory, string memory)
    {
        return (nft_name, nft_symbol);
    }

    function getShowSummary()
        public
        view
        returns (
            State,
            uint256,
            uint256,
            uint256,
            uint256,
            bool,
            bool,
            address,
            address,
            uint256
        )
    {
        return (
            OptionState,
            TokenOpts.strike,
            TokenOpts.premium,
            TokenOpts.expiry,
            TokenOpts.amount,
            TokenOpts.exercised,
            TokenOpts.canceled,
            TokenOpts.writer,
            TokenOpts.buyer,
            exerciseVal
        );
    }
}
