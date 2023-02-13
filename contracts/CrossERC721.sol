// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.18;

import "evm-gateway-contract/contracts/ICrossTalkApplication.sol";
import "evm-gateway-contract/contracts/Utils.sol";
import "@routerprotocol/router-crosstalk-utils/contracts/CrossTalkUtils.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract CrossERC721 is ERC721, ICrossTalkApplication {
    // Address of the Owner of the contract.
    address public admin;

    // Address of the gateway contract on the chain will contract deployed.
    address public gatewayContract;

    // Gas limit required to handle cross-chain request on the destination chain
    uint64 public destGasLimit;

    // chain type + chain id => address of our contract in bytes
    mapping(uint64 => mapping(string => bytes)) public ourContractOnChains;

    // Transfer parameter which include tokenId and the address(in bytes) of the receiver on destination chain.
    struct TransferParams {
        uint256 nftId;
        bytes recipient;
    }

    /// @notice Constructor to initialize the contract.
    /// @param gatewayAddress - Address of the gateway contract on the chain on which the contract is going to deployed.
    /// @param _destGasLimit - Gas limit required to handle cross-chain request on the destination chain.
    /// @param tokenId - Token Id of the NFT to be minted for testing.
    constructor(
        address payable gatewayAddress,
        uint64 _destGasLimit,
        uint256 tokenId
    ) ERC721("CrossERC721", "cerc721") {
        gatewayContract = gatewayAddress;

        destGasLimit = _destGasLimit;

        admin = msg.sender;

        _mint(msg.sender, tokenId);
    }

    /// @notice Function to map all the contract addresses of the contract on different chains.
    /// @param chainType - Type of the chain specified by the Router Protocol on which the contract is deployed.
    /// @param chainId - Chain Id of the chain on which the contract is deployed.
    /// @param contractAddress - Address of the contract on the chain
    function setContractOnChain(
        uint64 chainType,
        string memory chainId,
        address contractAddress
    ) external {
        require(msg.sender == admin, "only admin");

        // CrossTalkUtils.toBytes() is a function which converts the address to bytes.
        ourContractOnChains[chainType][chainId] = CrossTalkUtils.toBytes(
            contractAddress
        );
    }

    /// @notice Function to transfer the NFT from the source chain to the destination chain.
    /// @param chainType - Type of the chain specified by the Router Protocol on which the nft needs to transferred.
    /// @param chainId - Chain Id of the destination chain.
    /// @param expiryDurationInSeconds - Expiry duration in seconds of the request.
    /// @param destGasPrice - Gas price required to handle the cross-chain request on the destination chain.
    /// @param _nftId - Token Id of the NFT to be transferred.
    /// @param _recepient - Address of the recipient on the destination chain.
    function transferCrossChain(
        uint64 chainType,
        string memory chainId,
        uint64 expiryDurationInSeconds,
        uint64 destGasPrice,
        uint256 _nftId,
        address _recepient
    ) public payable {
        require(
            keccak256(ourContractOnChains[chainType][chainId]) !=
                keccak256(CrossTalkUtils.toBytes(address(0))),
            "ERR:CROSS_CHAIN_CONTRACT_NOT_SET"
        );

        TransferParams memory transferParams = TransferParams(
            _nftId,
            CrossTalkUtils.toBytes(_recepient)
        );

        require(_ownerOf(transferParams.nftId) == msg.sender, "ERR:NOT_OWNER");

        // Burn the NFT of the user on the source chain.
        _burn(transferParams.nftId);

        // Encode the transfer parameters to bytes for sending it as payload to the gateway contract.
        bytes memory payload = abi.encode(transferParams);

        uint64 expiryTimestamp = uint64(block.timestamp) +
            expiryDurationInSeconds;

        Utils.DestinationChainParams memory destChainParams = Utils
            .DestinationChainParams(
                destGasLimit,
                destGasPrice,
                chainType,
                chainId
            );

        // Call the singleRequestWithoutAcknowledgement() function of to transfer the NFT from the source chain to the destination chain without getting any acknowledgement.
        CrossTalkUtils.singleRequestWithoutAcknowledgement(
            gatewayContract,
            expiryTimestamp,
            destChainParams,
            ourContractOnChains[chainType][chainId],
            payload
        );
    }

    // Function to min the NFT on the destination chain.
    function handleRequestFromSource(
        bytes memory srcContractAddress,
        bytes memory payload,
        string memory srcChainId,
        uint64 srcChainType
    ) external override returns (bytes memory) {
        require(msg.sender == gatewayContract, "only gateway");
        require(
            keccak256(srcContractAddress) ==
                keccak256(ourContractOnChains[srcChainType][srcChainId]),
            "only our contract on source chain"
        );

        TransferParams memory transferParams = abi.decode(
            payload,
            (TransferParams)
        );

        // Mint the NFT for the recipient address on the destination chain.
        _mint(
            CrossTalkUtils.toAddress(transferParams.recipient),
            transferParams.nftId
        );

        // Since we don't want to return any data, we will just return empty string
        return "";
    }

    // Function to handle the acknowledgement received by the gateway contract for the functions executed on the destination chain.
    function handleCrossTalkAck(
        uint64 eventIdentifier,
        bool[] memory execFlags,
        bytes[] memory execData
    ) external view override {}
}
