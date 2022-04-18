// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.3;
pragma experimental ABIEncoderV2;

import "./HarmonyParser.sol";
import "./lib/SafeCast.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
// import "openzeppelin-solidity/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
// import "openzeppelin-solidity/contracts/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

// used in Harmony to Ethereum flow
contract HarmonyLightClient is
    Initializable,
    PausableUpgradeable,
    AccessControlUpgradeable
{
    using SafeCast for *;
    using SafeMathUpgradeable for uint256;

    struct BlockHeader {
        bytes32 parentHash;
        bytes32 stateRoot;
        bytes32 transactionsRoot;
        bytes32 receiptsRoot;
        uint256 number;
        uint256 epoch;
        uint256 shard;
        uint256 time;
        bytes32 mmrRoot;
        bytes32 hash;
    }

    event CheckPoint(
        bytes32 stateRoot,
        bytes32 transactionsRoot,
        bytes32 receiptsRoot,
        uint256 number,
        uint256 epoch,
        uint256 shard,
        uint256 time,
        bytes32 mmrRoot,
        bytes32 hash
    );

    BlockHeader firstBlock;
    BlockHeader lastCheckPointBlock;

    // epoch to block numbers, as there could be >=1 mmr entries per epoch
    mapping(uint256 => uint256[]) epochCheckPointBlockNumbers;

    // block number to BlockHeader
    mapping(uint256 => BlockHeader) checkPointBlocks;

    // epoch to mmrRoot to bool value
    mapping(uint256 => mapping(bytes32 => bool)) epochMmrRoots;

    uint8 relayerThreshold;

    event RelayerThresholdChanged(uint256 newThreshold);
    event RelayerAdded(address relayer);
    event RelayerRemoved(address relayer);

    bytes32 public constant RELAYER_ROLE = keccak256("RELAYER_ROLE");

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "sender doesn't have admin role");
        _;
    }

    modifier onlyRelayers() {
        require(hasRole(RELAYER_ROLE, msg.sender), "sender doesn't have relayer role");
        _;
    }

    // only the admin has the right to pause the light client and unpause
    // pausing prevents contract calls to proceed
    function adminPauseLightClient() external onlyAdmin {
        _pause();
    }

    function adminUnpauseLightClient() external onlyAdmin {
        _unpause();
    }

    // if caller of the function has admin role he/she can assign a new admin and gives up admin role him/herself
    function renounceAdmin(address newAdmin) external onlyAdmin {
        require(msg.sender != newAdmin, 'cannot renounce self');
        grantRole(DEFAULT_ADMIN_ROLE, newAdmin);
        renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // only admin can change the relayer threshold
    function adminChangeRelayerThreshold(uint256 newThreshold) external onlyAdmin {
        relayerThreshold = newThreshold.toUint8();
        emit RelayerThresholdChanged(newThreshold);
    }

    // only admin can add relayer if address is not already
    function adminAddRelayer(address relayerAddress) external onlyAdmin {
        require(!hasRole(RELAYER_ROLE, relayerAddress), "addr already has relayer role!");
        grantRole(RELAYER_ROLE, relayerAddress);
        emit RelayerAdded(relayerAddress);
    }

    // only admin can remove a relayer
    function adminRemoveRelayer(address relayerAddress) external onlyAdmin {
        require(hasRole(RELAYER_ROLE, relayerAddress), "addr doesn't have relayer role!");
        revokeRole(RELAYER_ROLE, relayerAddress);
        emit RelayerRemoved(relayerAddress);
    }


    // initialize contract state variables 
    function initialize(
        bytes memory firstRlpHeader,
        address[] memory initialRelayers,
        uint8 initialRelayerThreshold
    ) external initializer {
        // inside harmonParser.sol is theBlockHeader state variable
        HarmonyParser.BlockHeader memory header = HarmonyParser.toBlockHeader(
            firstRlpHeader
        );
        
        // initialize values for the firstBlock
        firstBlock.parentHash = header.parentHash;
        firstBlock.stateRoot = header.stateRoot;
        firstBlock.transactionsRoot = header.transactionsRoot;
        firstBlock.receiptsRoot = header.receiptsRoot;
        firstBlock.number = header.number;
        firstBlock.epoch = header.epoch;
        firstBlock.shard = header.shardID;
        firstBlock.time = header.timestamp;
        firstBlock.mmrRoot = HarmonyParser.toBytes32(header.mmrRoot);
        firstBlock.hash = header.hash;
        
        // initialize state variables with first block values
        epochCheckPointBlockNumbers[header.epoch].push(header.number);
        checkPointBlocks[header.number] = firstBlock;

        epochMmrRoots[header.epoch][firstBlock.mmrRoot] = true;

        relayerThreshold = initialRelayerThreshold;
        // give function caller admin role
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        // give multiple relayers admin rights
        for (uint256 i; i < initialRelayers.length; i++) {
            grantRole(RELAYER_ROLE, initialRelayers[i]);
        }

    }

    // subit new BlockHeader when called by relayer and is not paused by admin
    function submitCheckpoint(bytes memory rlpHeader) external onlyRelayers whenNotPaused {
        HarmonyParser.BlockHeader memory header = HarmonyParser.toBlockHeader(
            rlpHeader
        );

        BlockHeader memory checkPointBlock;
        
        // update state variables after rlpHeader is broken down by HarmonyParser
        checkPointBlock.parentHash = header.parentHash;
        checkPointBlock.stateRoot = header.stateRoot;
        checkPointBlock.transactionsRoot = header.transactionsRoot;
        checkPointBlock.receiptsRoot = header.receiptsRoot;
        checkPointBlock.number = header.number;
        checkPointBlock.epoch = header.epoch;
        checkPointBlock.shard = header.shardID;
        checkPointBlock.time = header.timestamp;
        checkPointBlock.mmrRoot = HarmonyParser.toBytes32(header.mmrRoot);
        checkPointBlock.hash = header.hash;
        
        epochCheckPointBlockNumbers[header.epoch].push(header.number);
        checkPointBlocks[header.number] = checkPointBlock;

        // store mmrRoot mapped to timestamp and set bool to True
        epochMmrRoots[header.epoch][checkPointBlock.mmrRoot] = true;

        emit CheckPoint(
            checkPointBlock.stateRoot,
            checkPointBlock.transactionsRoot,
            checkPointBlock.receiptsRoot,
            checkPointBlock.number,
            checkPointBlock.epoch,
            checkPointBlock.shard,
            checkPointBlock.time,
            checkPointBlock.mmrRoot,
            checkPointBlock.hash
        );
    }

    // get latest blockHeader based on given blockNumber from checkPointBlocks
    function getLatestCheckPoint(uint256 blockNumber, uint256 epoch)
        public
        view
        returns (BlockHeader memory checkPointBlock)
    {
        // check if epochCheckPointBlockNumbers for given epoch is not empty
        require(
            epochCheckPointBlockNumbers[epoch].length > 0,
            "no checkpoints for epoch"
        );
        uint256[] memory checkPointBlockNumbers = epochCheckPointBlockNumbers[epoch];
        uint256 nearest = 0;
        for (uint256 i = 0; i < checkPointBlockNumbers.length; i++) {
            uint256 checkPointBlockNumber = checkPointBlockNumbers[i];
            if (
                checkPointBlockNumber > blockNumber &&
                checkPointBlockNumber < nearest
            ) {
                nearest = checkPointBlockNumber;
            }
        }
        // return latest BlockHeader in checkPointBlocks mapping
        checkPointBlock = checkPointBlocks[nearest];
    }

    // check if the epoch and mmrRoot is valid by confirming inclusion in epochMmrRoot mapping
    function isValidCheckPoint(uint256 epoch, bytes32 mmrRoot) public view returns (bool status) {
        return epochMmrRoots[epoch][mmrRoot];
    }
}
