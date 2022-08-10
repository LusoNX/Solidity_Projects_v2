// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {LinkTokenInterface} from "../interfaces/LinkTokenInterface.sol";
import {IERC721_Luso} from "../interfaces/IERC721_Luso.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

contract PequenaAuction is IERC721Receiver {
    using SafeMath for uint256;
    event Start();
    event End(address highestBidder, uint256 highestBid);
    address public pequenaCoinAddress;
    ERC721 nft;
    ERC20 pequenaCoinToken;
    address payable public seller;
    bool public started;
    bool public ended;
    uint256 public endAt;
    uint256 public tokenID;
    uint256 public highestBid;
    address public highestBidder;
    mapping(address => uint256) public bids;
    uint256 public AutomSell;
    address public nft_address;
    uint256 public tokenDecimals;

    constructor(
        address _pequenaCoinAddress,
        address _nft_address,
        uint256 _tokenID
    ) public {
        nft_address = _nft_address;
        seller = payable(msg.sender);
        pequenaCoinAddress = _pequenaCoinAddress;
        tokenID = _tokenID;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) public override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function startAuction(
        address _nft,
        uint256 startingBid,
        uint256 _AutomSell
    ) external {
        require(!started, "Already Started");
        require(msg.sender == seller, "You did not start the Auction");
        AutomSell = _AutomSell * (10 * 100000000000000000);
        highestBid = startingBid * (10 * 100000000000000000);
        nft = ERC721(_nft);
        nft.safeTransferFrom(msg.sender, address(this), tokenID);
        started = true;
        endAt = block.timestamp + 2 days;
        emit Start();
    }

    function bid(uint256 tokenAmount) external {
        pequenaCoinToken = ERC20(pequenaCoinAddress);
        tokenDecimals = pequenaCoinToken.decimals();
        uint256 tokenV = tokenAmount * (10 * 100000000000000000);
        require(tokenV > highestBid);
        require(started, "Auction not Started");
        require(block.timestamp < endAt, "Ended!");
        require(
            pequenaCoinToken.transferFrom(msg.sender, address(this), tokenV),
            "Incorrect Amount of Token supplied"
        );

        if (highestBidder != address(0)) {
            bids[highestBidder] += highestBid;
        }

        highestBid = tokenAmount;
        highestBidder = msg.sender;

        if (highestBid >= AutomSell) {
            nft.safeTransferFrom(address(this), msg.sender, tokenID);
            ended = true;
        }
    }

    function withdraw() external {
        uint256 bal = bids[msg.sender];
        bids[msg.sender] = 0;
        pequenaCoinToken.transferFrom(payable(address(this)), msg.sender, bal);
    }

    function SellNFT() public {
        uint256 tokenV = AutomSell * (10 * 100000000000000000);
        require(
            pequenaCoinToken.transferFrom(msg.sender, address(this), tokenV),
            "Incorrect Amount of Token supplied"
        );
        nft.safeTransferFrom(address(this), msg.sender, tokenID);
        ended = true;
    }

    function EndAuction() external {
        tokenDecimals = pequenaCoinToken.decimals();
        require(started, "You need to start the Auction 1st");
        require(block.timestamp >= endAt, "Auction is still ongoing");
        require(!ended, "Auction already ended");

        if (highestBidder != address(0)) {
            nft.safeTransferFrom(address(this), highestBidder, tokenID);
            pequenaCoinToken.transferFrom(msg.sender, seller, highestBid);
        } else {
            nft.safeTransferFrom(address(this), seller, tokenID);
        }
        ended = true;
        emit End(highestBidder, highestBid);
    }

    function getAuctionSummary()
        public
        view
        returns (
            address,
            address,
            address,
            address,
            uint256,
            uint256,
            uint256,
            bool,
            bool,
            uint256,
            uint256
        )
    {
        return (
            nft_address,
            pequenaCoinAddress,
            seller,
            highestBidder,
            highestBid,
            AutomSell,
            tokenID,
            started,
            ended,
            endAt,
            tokenDecimals
        );
    }
}
