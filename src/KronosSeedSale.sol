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

    bool public seedSaleActive;

    uint256 public totalSupply;
    string public baseURI;

    uint256 public constant MINIMUM_PAYMENT = 250e6;
    uint256 public constant MAXIMUM_TOTAL_PAYMENT = 5000e6;
    uint256 public constant NFT_ID_OFFSET = 1;

    // starts at 1, but actual minted id will be nftIDForAddress - 1
    // this mapping also acts as the whitelist
    mapping(address => uint256) public nftIDForAddress;
    mapping(address => uint256) public USDTokenAmountCommitted;
    uint256 public totalUSDTokenAmountCommitted;

    event Payment(address from, uint256 amount, bool USDT);

    constructor(address _USDT, address _USDC) ERC721("Kronos Offical Seed Sale NFT", "TITAN") Owned(msg.sender) {
        USDT = _USDT;
        USDC = _USDC;
    }

    // use predefined NFT IDs for whitelist addition
    function addToWhitelist(address[] calldata wallets, uint256[] calldata nftIDs) external onlyOwner {
        require(wallets.length == nftIDs.length, "Wallets and NFT IDs must be the same length");
        for (uint256 i; i < wallets.length; i++) {
            require(nftIDForAddress[wallets[i]] == 0, "Address is already on the whitelist");
            nftIDForAddress[wallets[i]] = nftIDs[i];
        }
    }

    // no permit, approval required
    function payWithUSDT(uint256 amount) external {
        validation(amount);

        IERC20(USDT).transferFrom(msg.sender, address(this), amount);
        USDTokenAmountCommitted[msg.sender] += amount;
        totalUSDTokenAmountCommitted += amount;

        emit Payment(msg.sender, amount, true);
    }

    // permit, no approval required
    function payWithUSDC(uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external {
        IERC20Permit(USDC).permit(msg.sender, address(this), amount, deadline, v, r, s);

        validation(amount);

        IERC20(USDC).transferFrom(msg.sender, address(this), amount);
        USDTokenAmountCommitted[msg.sender] += amount;
        totalUSDTokenAmountCommitted += amount;

        emit Payment(msg.sender, amount, false);
    }

    function mint() external {
        require(seedSaleActive, "Seed Sale must be active");
        require(_ownerOf[nftIDForAddress[msg.sender] - NFT_ID_OFFSET] == address(0), "NFT is already minted");
        require(
            USDTokenAmountCommitted[msg.sender] >= MINIMUM_PAYMENT,
            "Address must have made a minimum payment of USD $250"
        );
        _safeMint(msg.sender, nftIDForAddress[msg.sender] - NFT_ID_OFFSET);
        totalSupply += 1;
    }

    function flipSeedSaleActive() external onlyOwner {
        seedSaleActive = !seedSaleActive;
    }

    function setBaseURI(string calldata newURI) external onlyOwner {
        baseURI = newURI;
    }

    function validation(uint256 amount) internal {
        require(seedSaleActive, "Seed Sale must be active");
        require(nftIDForAddress[msg.sender] > 0, "Address must be on the whitelist");
        require(amount >= MINIMUM_PAYMENT, "Amount must be a minimum of USD $250");
        require(
            USDTokenAmountCommitted[msg.sender] + amount <= MAXIMUM_TOTAL_PAYMENT,
            "Total amount must not exceed USD $5000"
        );
    }

    function tokenURI(uint256 tokenID) public view override returns (string memory) {
        require(tokenID < totalSupply, "This token does not exist");
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenID.toString())) : "";
    }

    function withdrawTokens(address token) external onlyOwner {
        IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
    }
}
