// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "solmate/auth/Owned.sol";
import "solmate/tokens/ERC721.sol";
import "solady/src/utils/LibString.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Permit.sol";

// multiple whitelist capability with predefined NFT ID assignment for each address
// participate in seed sale with USDT or USDC tokens
// keep track of committed amount for each address (useful for token contract later)
// mint NFT with predefined ID specified in the whitelist

contract KronosSeedSale is Owned, ERC721 {
    using LibString for uint256;

    address USDT;
    address USDC;

    bool seedSaleActive;

    uint256 public totalSupply;
    string public baseURI;

    // starts at 1, but actual minted id will be nftIDForAddress - 1
    // this mapping also acts as the whitelist
    mapping(address => uint256) public nftIDForAddress;
    mapping(address => uint256) public USDTokenAmountCommitted;

    constructor(address _USDT, address _USDC) ERC721("Kronos Offical Seed Sale NFT", "Titan") Owned(msg.sender) {
        USDT = _USDT;
        USDC = _USDC;
    }

    // use predefined NFT IDs for whitelist addition
    function addToWhitelist(address[] calldata wallets, uint256[] calldata nftIDs) external onlyOwner {
        for (uint256 i; i < wallets.length; i++) {
            nftIDForAddress[wallets[i]] = nftIDs[i];
        }
    }

    // no permit, approval required
    function payWithUSDT(uint256 value) external {
        require(seedSaleActive, "Seed Sale must be active");
        require(nftIDForAddress[msg.sender] > 0, "Address must be on the whitelist");

        IERC20(USDT).transferFrom(msg.sender, address(this), value);
        USDTokenAmountCommitted[msg.sender] += value;
    }

    // permit, no approval required
    function payWithUSDC(uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external {
        IERC20Permit(USDC).permit(msg.sender, address(this), value, deadline, v, r, s);
        require(seedSaleActive, "Seed Sale must be active");
        require(nftIDForAddress[msg.sender] > 0, "Address must be on the whitelist");

        IERC20(USDC).transferFrom(msg.sender, address(this), value);
        USDTokenAmountCommitted[msg.sender] += value;
    }

    function mint() external {
        require(nftIDForAddress[msg.sender] > 0, "Address must be on the whitelist");
        require(_ownerOf[nftIDForAddress[msg.sender] - 1] == address(0), "NFT is already minted");
        _safeMint(msg.sender, nftIDForAddress[msg.sender] - 1);
        totalSupply += 1;
    }

    function flipSeedSaleActive() external onlyOwner {
        seedSaleActive = !seedSaleActive;
    }

    function setBaseURI(string memory newURI) public onlyOwner {
        baseURI = newURI;
    }

    function tokenURI(uint256 tokenID) public view override returns (string memory) {
        require(tokenID < totalSupply, "This token does not exist");
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenID.toString())) : "";
    }
}
