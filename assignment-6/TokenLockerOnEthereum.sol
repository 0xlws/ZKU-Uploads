// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.3;
pragma experimental ABIEncoderV2;

import "./HarmonyLightClient.sol";
import "./lib/MMRVerifier.sol";
import "./HarmonyProver.sol";
import "./TokenLocker.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

// this contract locks and burns tokens on the Ethereum bridge smart contract
contract TokenLockerOnEthereum is TokenLocker, OwnableUpgradeable {
    HarmonyLightClient public lightclient;

    // keep track of processed txs
    mapping(bytes32 => bool) public spentReceipt;

    // set owner
    function initialize() external initializer {
        __Ownable_init();
    }

    // only owner can set a new HarmonyLightClient
    function changeLightClient(HarmonyLightClient newClient)
        external
        onlyOwner
    {
        lightclient = newClient;
    }

    // bind 
    function bind(address otherSide) external onlyOwner {
        otherSideBridge = otherSide;
    }

    // proof of burn, check if the blockHeader is included inside mmr
    function validateAndExecuteProof(
        HarmonyParser.BlockHeader memory header,
        MMRVerifier.MMRProof memory mmrProof,
        MPT.MerkleProof memory receiptdata
    ) external {
        require(lightclient.isValidCheckPoint(header.epoch, mmrProof.root), "checkpoint validation failed");
        bytes32 blockHash = HarmonyParser.getBlockHash(header);
        bytes32 rootHash = header.receiptsRoot;
        // check inclusion of header in mmr
        (bool status, string memory message) = HarmonyProver.verifyHeader(
            header,
            mmrProof
        );
        require(status, "block header could not be verified");
        bytes32 receiptHash = keccak256(
            abi.encodePacked(blockHash, rootHash, receiptdata.key)
        );
        // prevent double spending by checking if the receipthash is not already present inside spentReceipt mapping
        require(spentReceipt[receiptHash] == false, "double spent!");
        (status, message) = HarmonyProver.verifyReceipt(header, receiptdata);
        require(status, "receipt data could not be verified");
        spentReceipt[receiptHash] = true;
        // after decoding rpl data and verification, execute token lock/burn and return incremented executedEvents
        uint256 executedEvents = execute(receiptdata.expectedValue);
        require(executedEvents > 0, "no valid event");
    }
}
