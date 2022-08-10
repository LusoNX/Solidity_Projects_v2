// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {LinkTokenInterface} from "../interfaces/LinkTokenInterface.sol";
import {IERC721_Luso} from "../interfaces/IERC721_Luso.sol";
import {PequenaNFT} from "./PequenaNFT.sol";

contract NFTFactory {
    address[] deployedNFTs;

    function deployNFT(
        string memory _name,
        string memory _symbol,
        string memory _tokenURI,
        uint256 _nft_id,
        string memory _imageURI
    ) public {
        PequenaNFT newNFT = new PequenaNFT(
            _name,
            _symbol,
            _tokenURI,
            _imageURI
        );
        deployedNFTs.push(address(newNFT));
    }

    function getDeployedNFT() public view returns (address[] memory) {
        return deployedNFTs;
    }
}
