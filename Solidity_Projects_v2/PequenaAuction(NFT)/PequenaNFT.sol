// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {LinkTokenInterface} from "../interfaces/LinkTokenInterface.sol";
import {IERC721_Luso} from "../interfaces/IERC721_Luso.sol";

contract PequenaNFT is ERC721 {
    uint256 private nft_id;
    string public tokenURI;
    address public nft_artist;
    string public _name;
    string public _symbol;
    string public imageURI;

    constructor(
        string memory name,
        string memory symbol,
        string memory _tokenURI,
        string memory _imageURI
    ) public ERC721(name, symbol) {
        tokenURI = _tokenURI;
        nft_artist = msg.sender;
        _name = name;
        _symbol = symbol;
        imageURI = _imageURI;
    }

    function mint() public returns (uint256) {
        nft_id += 1;
        _safeMint(msg.sender, nft_id);
        _setTokenURI(nft_id, tokenURI);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function contractSummary()
        public
        view
        returns (
            address,
            address,
            string memory,
            string memory,
            string memory,
            string memory,
            uint256
        )
    {
        return (
            address(this),
            nft_artist,
            tokenURI,
            _name,
            _symbol,
            imageURI,
            nft_id
        );
    }
}
