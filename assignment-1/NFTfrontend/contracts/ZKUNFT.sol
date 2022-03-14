// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// openzeppelin MerkleProof
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling _hashes on the branch from the leaf to the root of the tree. Each
     * pair of _leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}


// NFT mint contract extending ERC721URIStorage contract 
contract ZKUNFT is ERC721URIStorage{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds; 
    // Using Counters to safely increment _tokenIds;
    // _tokenIds keeps count of NFTs minted
    
    struct URI {
        string name;
        string description;
    }

    struct LeafData {
        address from;
        address receiver;
        uint256 id;
        string tokenURI;
    }

    mapping(uint256 => URI) private _readableURI;
    mapping(uint256 => LeafData) public leafData;

    uint256 public NFTsLeft;
    bytes32 public root;
    uint256 private _maxSupply;
    uint256 private _price;
    bytes32[] private _tree;
    bytes32[] private _hashes;
    bytes32[8] private _leaves;


    // initialize contract with name and symbol given
    constructor() ERC721("ZKUNFT", "$ZKU") {  
        // PRICE = 1;
        _maxSupply = 8;
        NFTsLeft = _maxSupply;
    }

    /*
     Create an ERC721 contract that can mint an NFT to any address. 
     The token URI should be on-chain and should include a name field and a description field. 
     // [Bonus points for well-commented codebase]
    */
    function mintNFT(
        address receiver, 
        string memory _name, 
        string memory _description
    ) 
        public 
    {
        // require(msg.value >= PRICE, "Not enough funds.");
        require(_tokenIds.current() != 8, "All NFTs minted already.");
        address from = msg.sender;
        uint256 newTokenId = _tokenIds.current();
        _tokenIds.increment();
        _safeMint(receiver, newTokenId);
        NFTsLeft -= 1;
        _readableURI[newTokenId] = URI(_name, _description);
        _commitToTree(from, receiver, newTokenId, tokenURI(newTokenId));
        
    }

    function tokenURI(uint256 newTokenId) 
        override(ERC721URIStorage) 
        public 
        view 
        returns (string memory) 
    {
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "', _readableURI[newTokenId].name, '",',
                        '"description": ', _readableURI[newTokenId].description, '},'
                    )
                )
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }
        

    function getLeaves() public view returns (bytes32[8] memory) {
        return _leaves;
    }

    function getLeavesLength() public view returns (uint256) {
        return _leaves.length;
    }
    
    function getTree() public view returns (bytes32[] memory) {
        return _tree;
    }

    function getTreeLength() public view returns (uint256) {
        return _tree.length;
    }

    function getRoot() public view returns (bytes32) {
        // require(_hashes.length != 0, "Empty tree");
        return _tree[_tree.length - 1];
    }

    function verify(bytes32[] memory proof, bytes32 _root, bytes32 leaf) 
        public
        pure
        returns (bool) 
    {
        return MerkleProof.verify(proof, _root, leaf);
    }

    function _burn(uint256 tokenId) internal override(ERC721URIStorage) {
        super._burn(tokenId);
    }

    /*  
     Commit the msg.sender, 
     receiver address, 
     tokenId, 
     and tokenURI 
     to a Merkle tree using the keccak256 hash function. 
     //  Update the Merkle tree using a minimal amount of gas.
    */
    function _commitToTree (
        address from,
        address receiver,
        uint256 id,
        string memory _uri
    ) 
        private 
    {
        leafData[id] = LeafData(
            from,
            receiver,
            id,
            _uri
        );
        _addLeaf(id);
        // B > C
    }

    function _addLeaf(uint256 id) private {
        bytes32 hashedLeaf = keccak256(abi.encode(leafData[id]));
        _hashes.push(hashedLeaf);
        _leaves[id] = hashedLeaf;
        _createTree();
        // C > D
    }

    function _createTree() private {
        _tree = _hashes;
        uint256 n = _tree.length;
        uint256 offset = 0;
        while (n > 0) {
            for (uint256 i = 0; i < n-1; i += 2) {
                _tree.push(
                    keccak256(
                        abi.encodePacked(
                            _tree[offset+i], _tree[offset+i + 1]
                        )
                    )
                );
            }
            offset += n; 
            n = n / 2;
            // D.
        }
    }
}

  