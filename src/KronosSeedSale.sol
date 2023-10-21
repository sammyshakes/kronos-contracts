// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "solmate/auth/Owned.sol";
import "solmate/tokens/ERC721.sol";
import "solady/src/utils/LibString.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Permit.sol";

/// @title Kronos Seed Sale Contract
/// @notice This contract is used to participate in the Kronos Seed Sale
/// @dev This contract is used to participate in the Kronos Seed Sale
contract KronosSeedSale is Owned, ERC721 {
    using LibString for uint256;

    address USDT;
    address USDC;

    bool public seedSaleActive;

    uint256 public totalSupply;
    string public baseURI;

    uint256 public constant MINIMUM_PAYMENT = 250e6;
    uint256 public constant MAXIMUM_TOTAL_PAYMENT = 5000e6;
    uint256 public constant MAXIMUM_RAISE = 250_000e6;
    uint256 public constant NFT_ID_OFFSET = 1;

    // starts at 1, but actual minted id will be nftIDForAddress - 1
    // this mapping also acts as the whitelist
    mapping(address => uint256) public nftIDForAddress;
    mapping(uint256 => uint256) public tokenIdToMetadataId;
    mapping(address => uint256) public USDTokenAmountCommitted;
    uint256 public totalUSDTokenAmountCommitted;
    uint256 public totalWhitelisted;

    event Payment(address from, uint256 amount, bool USDT);

    /// @notice Constructor
    /// @param _USDT The address of the USDT contract
    /// @param _USDC The address of the USDC contract
    constructor(address _USDT, address _USDC)
        ERC721("Kronos Offical Seed Sale NFT", "TITAN")
        Owned(msg.sender)
    {
        USDT = _USDT;
        USDC = _USDC;
    }

    /// @notice Add an address to the whitelist
    /// @param wallets The addresses to add to the whitelist
    /// @param metadataId The metadata id to assign to the address
    /// @dev The metadata id is the id of the metadata json file that will be used for the token id
    function addToWhitelist(address[] calldata wallets, uint256 metadataId) external onlyOwner {
        uint256 nextNFTID = totalWhitelisted;
        for (uint256 i; i < wallets.length; i++) {
            require(nftIDForAddress[wallets[i]] == 0, "Address is already on the whitelist");
            nftIDForAddress[wallets[i]] = ++nextNFTID;
            tokenIdToMetadataId[nextNFTID] = metadataId;
        }
        totalWhitelisted += wallets.length;
    }

    /// @notice Participate in the seed sale with USDT or USDC, if whitelisted
    /// @param token The address of the token to commit
    /// @param amount The amount of tokens to commit
    /// @dev The amount must be a minimum of USD $250
    /// @dev The total amount must not exceed USD $5000
    function payWithToken(address token, uint256 amount) private {
        // Ensure that the specified token is either USDT or USDC
        require(token == USDT || token == USDC, "Invalid token");

        validation(amount);

        // Transfer tokens from the sender to the contract
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        USDTokenAmountCommitted[msg.sender] += amount;
        totalUSDTokenAmountCommitted += amount;

        emit Payment(msg.sender, amount, token == USDT);
    }

    /// @notice Participate in the seed sale with USDT, if whitelisted
    /// @param amount The amount of USDT to commit
    /// @dev The amount must be a minimum of USD $250
    /// @dev The total amount must not exceed USD $5000
    function payWithUSDT(uint256 amount) external {
        payWithToken(USDT, amount);
    }

    /// @notice Participate in the seed sale with USDC, if whitelisted
    /// @param amount The amount of USDC to commit
    /// @dev The amount must be a minimum of USD $250
    /// @dev The total amount must not exceed USD $5000
    function payWithUSDC(uint256 amount) external {
        payWithToken(USDC, amount);
    }

    /// @notice Mint an NFT, if whitelisted
    /// @dev The address must have made a minimum payment of USD $250
    function mint() external {
        require(seedSaleActive, "Seed Sale must be active");
        require(
            _ownerOf[nftIDForAddress[msg.sender] - NFT_ID_OFFSET] == address(0),
            "NFT is already minted"
        );
        require(
            USDTokenAmountCommitted[msg.sender] >= MINIMUM_PAYMENT,
            "Address must have made a minimum payment of USD $250"
        );
        _safeMint(msg.sender, nftIDForAddress[msg.sender] - NFT_ID_OFFSET);
        totalSupply += 1;
    }

    /// @notice Flip the seed sale active state
    /// @dev Only the owner can call this function
    function flipSeedSaleActive() external onlyOwner {
        seedSaleActive = !seedSaleActive;
    }

    /// @notice Set the base URI
    /// @param newURI The new base URI
    /// @dev Only the owner can call this function
    function setBaseURI(string calldata newURI) external onlyOwner {
        baseURI = newURI;
    }

    /// @notice Validate the payment
    /// @param amount The amount of tokens to commit
    /// @dev The amount must be a minimum of USD $250
    /// @dev The total amount must not exceed USD $5000
    /// @dev The total amount must not exceed USD $250,000
    /// @dev The address must be on the whitelist
    function validation(uint256 amount) internal view {
        require(seedSaleActive, "Seed Sale must be active");
        require(nftIDForAddress[msg.sender] > 0, "Address must be on the whitelist");
        require(amount >= MINIMUM_PAYMENT, "Amount must be a minimum of USD $250");
        require(
            USDTokenAmountCommitted[msg.sender] + amount <= MAXIMUM_TOTAL_PAYMENT,
            "Total amount must not exceed USD $5000"
        );
        require(
            totalUSDTokenAmountCommitted + amount <= MAXIMUM_RAISE,
            "Total amount must not exceed USD $250,000"
        );
    }

    /// @notice Get the URI for a token
    /// @param tokenID The id of the token
    /// @return The URI for the token
    /// @dev The URI is the base URI + the metadata id
    /// @dev The metadata id is the id of the metadata json file that will be used for the token id
    function tokenURI(uint256 tokenID) public view override returns (string memory) {
        require(tokenID < totalSupply, "This token does not exist");
        //get metadata id from token id
        uint256 metadataId = tokenIdToMetadataId[tokenID];
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, metadataId.toString()))
            : "";
    }

    /// @notice Withdraw tokens from the contract
    /// @param token The address of the token to withdraw
    /// @dev Only the owner can call this function
    function withdrawTokens(address token) external onlyOwner {
        IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
    }
}
