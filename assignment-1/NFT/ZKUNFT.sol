// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.7; // solidity compiler version

// openzeppelin contract imports
// not sure why not t ERC721Extended
import "@openzeppelin/contracts/token/ERC721/ERC721.sol"; 
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
// import "./MerkleProof.sol";
import "./SbEMerkleProof.sol";


contract ZKUNFT is ERC721, ERC721URIStorage {
    using Counters for Counters.Counter; // using Counters to increment
    Counters.Counter private _tokenIds;

    bytes32 public merkleRoot = 0x6da304a4edb4b6f658ba4af9341ddfab5c5ea7b4aef58952dd51e22d8c11b1ad;
    // map a uint to Attr struct containing the name and description
    mapping(uint256 => Attr) public attributes;
    mapping(address => bool) public whitelistClaimed;
    mapping(uint256 => LeafData) public leafdata;



    // Define Attr struct to store name and description on-chain
    struct Attr {
        string name;
        string description;
    }

    struct LeafData {
        address from;
        address receiver;
        uint id;
        string URI;
    }

    uint8[] private _leaves = [
        1,
        2,
        3,
        4,
        5,
        6,
        7,
        8
    ];

    // The constructor is run once on instatition, name and symbol arguments given
    constructor() ERC721("ZKU NFT", "ZKU") {
        // merkleProof = new MerkleProof;
    }

    function getLeaves() public view returns(uint8[] memory){
        return _leaves;
    }
    
    // Necessary import
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    // 1. Mint to any address
    // 2. Store tokenURI on-chain
    function mintNFT(
        address to, 
        string memory _name, 
        string memory _description) 
        public {    
            _tokenIds.increment();
            uint256 newTokenId = _tokenIds.current();
            // [1]
            _safeMint(to, newTokenId);
            // [2] Store name and description fields for minted 
            attributes[newTokenId] = Attr(_name, _description);

            // function to add to merkle tree(
            //  keccak256(abi.encode(msg.sender, to, newTokenId, tokenURI(newTokenId))));
            //
            _commitToTree(to, newTokenId, tokenURI(newTokenId));
            
    }
    function merkleMintNFT(
        bytes32[] calldata _merkleProof,
        address to, 
        string memory _name, 
        string memory _description) 
        public {
            _tokenIds.increment();
            uint256 newTokenId = _tokenIds.current();

            // * * * * *
            require(!whitelistClaimed[msg.sender], "Address has already claimed");
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            require(SbEMerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid proof.");
            // * * * * *
            
            // [1]
            _safeMint(to, newTokenId);
            // [2] Store name and description fields for minted 
            attributes[newTokenId] = Attr(_name, _description);

            // function to add to merkle tree(
            //  keccak256(abi.encode(msg.sender, to, newTokenId, tokenURI(newTokenId))));
            //
            _commitToTree(to, newTokenId, tokenURI(newTokenId));     
    }

    // Retrieve on-chain tokenURI
    function tokenURI(uint256 tokenId) 
        override(ERC721, ERC721URIStorage) 
        public view returns (string memory) {
            string memory json = Base64.encode(
                bytes(string(
                abi.encodePacked(
                    '{"name": "', attributes[tokenId].name, '",',
                    '"description": ', attributes[tokenId].description, '},'
                    
                )
            ))
        );
        return string(abi.encodePacked('data:application/json;base64,', json));
    }

    function _commitToTree (
        address receiver,
        uint id,
        string memory URI
        ) private {
            leafdata[id] = LeafData(
                msg.sender,
                receiver,
                id,
                URI
            );
            // addLeaf(leafData);
        }
        
    }