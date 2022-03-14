import React, { useState, useEffect } from 'react';
import logo from './logo.png';
import './App.css';
import ZKUNFT from './artifacts/contracts/ZKUNFT.sol/ZKUNFT.json';
import verifier from './artifacts/contracts/verifier.sol/Verifier.json';
import { ethers } from 'ethers';
import Grid from '@mui/material/Grid';
import { blue } from '@mui/material/colors';
import Button from '@mui/material/Button';
import Box from '@mui/material/Box';
import TextField from '@mui/material/TextField';
import { InputAdornment } from '@mui/material';

// import { whitelist } from './_components/input';
// import mrWasm from './export/MerkleRoot.wasm'
// import mrZkey from './export/MerkleRoot_0001.zkey'
// const snarkjs = require(./export/snarkjs.min.js)

// const { MerkleTree } = require('merkletreejs');
// const keccak256 = require('keccak256');

// setup contracts references
const provider = new ethers.providers.Web3Provider(window.ethereum);
const signer = provider.getSigner();

// deploy contract and input address here 
const ZKUNFTAddress = '0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0';
const ZKUNFTContract = new ethers.Contract(
    ZKUNFTAddress,
    ZKUNFT.abi,
    signer,
);

// const verifierAddress = '0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0';
// const verifierContract = new ethers.Contract(
//     verifierAddress,
//     verifier.abi,
//     signer,
// );

function App() {
    // declare variables
    // const [dataInput, setDataInput] = useState('');
    // const [approved, setApproved] = useState(false);
    const [address, setAddress] = useState('');
    const [root, setRoot] = useState('');
    const [leaves, setLeaves] = useState('');
    const [tree, setHashes] = useState('');
    // const [connected, setConnected] = useState('Not connected.');
    const [leavesCopied, setLeavesCopied] = useState(false);
    const [treeCopied, setTreeCopied] = useState(false);
    const [rootCopied, setRootCopied] = useState(false);
    const [treeLength, setHashesLength] = useState('');
    const [leavesLength, setLeavesLength] = useState('');
    const [NFTsNr, setNFTsNr] = useState('');
    const [receiver, setReceiver] = useState('');
    // const [proof, setProof] = useState('');
    // const [watcher, setWatcher] = useState('');

    // on reload see if user is connected to MetaMask and how many NFTs are left
    useEffect(() => {
        loadWeb3();
        nftsleft();
    }, []);

    // check if user is connected
    async function loadWeb3() {
        if (window.ethereum) {
            const accounts = await window.ethereum.request({
                method: 'eth_requestAccounts',
            });

            console.log('Account', accounts[0]);
            setAddress(accounts[0]);
            // setConnected('✅ Connected');
        } else {
            // setConnected('❌ Not connected');
            window.alert(
                'Non-Ethereum browser detected. You should consider trying MetaMask!',
            );
        }
    }
    // copy to clipboard on click of text area handler
    async function handleCopy(elem) {
        if (elem == 'leaves') {
            setLeavesCopied(true);
            setTimeout(() => {
                setLeavesCopied(false);
            }, 2000);
        } else if (elem == 'tree') {
            setTreeCopied(true);
            setTimeout(() => {
                setTreeCopied(false);
            }, 2000);
        } else if (elem == 'root') {
            setRootCopied(true);
            setTimeout(() => {
                setRootCopied(false);
            }, 2000);
        }
    }

    //  how many nfts are left?
    async function nftsleft() {
        let res = await ZKUNFTContract.NFTsLeft();
        let numberLeft = parseInt(
            ethers.utils.formatEther(res) * 10 ** 18,
        );
        setNFTsNr(numberLeft);
        console.log(numberLeft);
    }

    async function getLeaves() {
        let res = await ZKUNFTContract.getLeaves();
        let res2 = await ZKUNFTContract.getLeavesLength();
        setLeaves(JSON.stringify(res, null, 2));
        setLeavesLength(res2);
    }

    async function getRoot() {
        let res = await ZKUNFTContract.getRoot();
        setRoot(JSON.stringify(res, null, 2));
    }

    async function getTree() {
        let res = await ZKUNFTContract.getTree();
        let res2 = await ZKUNFTContract.getTreeLength();
        setHashes(JSON.stringify(res, null, 2));
        setHashesLength(res2);
    }

    // Mint NFT function
    async function mintNFT() {
        if (!receiver) {
            window.alert('Please set receiver address!');
        }

        await ZKUNFTContract.mintNFT(receiver, 'Name', 'Description');
        nftsleft();
        window.alert('NFT minted! 💎🤑');
        nftsleft();
    }

    // Tried snark js and failed
    async function verify() {
        let res = await verifierContract.verifyProof();
        console.log(res);
    }
 

    // async function runProof() {
    //     let _leaves = [];
    //     for (let i = 0; i < NFTsNr; i++) {
    //         if (
    //             leaves[i] !=
    //             '0x0000000000000000000000000000000000000000000000000000000000000000'
    //         ) {
    //             _leaves.push(leaves[i]);
    //         }
    //         if (
    //             leaves[i] ==
    //             '0x0000000000000000000000000000000000000000000000000000000000000000'
    //         ) {
    //             console.log('empty');
    //         }
    //     }
    // }

    // testing merkletreejs
    // async function merkle() {
    //     const _dataInput = parseInt(dataInput);
    //     const buf2hex = x => '0x' + x.toString('hex');
    //     console.log('leaves\n', whitelist);
    //     const leaves = whitelist.map(x => keccak256(x));
    //     const leaf = keccak256(_dataInput);
    //     const tree = new MerkleTree(leaves, keccak256, {
    //         sortPairs: true,
    //     });
    //     console.log(leaves[0].toString('hex') === leaf.toString('hex'));
    //     const hexProof = tree.getHexProof(leaf);
    //     console.log(JSON.stringify(hexProof));
    //     let _root = await ZKUNFTContract.getRoot();
    //     console.log('_root\n', _root);
    //     setRoot(_root);
    //     let result = await ZKUNFTContract.verify(hexProof, _root, leaf);
    //     console.log(result);
    //     setApproved(result[0]);
    //     // }
    // }

    return (
        <div className="App">
            <header className="App-header">
                <div className="scale-connected">
                    <img
                        src={logo}
                        className="App-logo"
                        alt="ethereum_logo"
                    />
                </div>
                {/* button for NFTs left */}
                <Button variant="outlined" color="error">{NFTsNr} NFTs left!</Button>


                {/* Address field */}
                <TextField
                    size="small"
                    label="👤 Welcome"
                    id="outlined-start-adornment"
                    focused
                    autoComplete="off"
                    value={address}
                    sx={{ m: 1, width: '25rem' }}
                    InputProps={{
                        style: {
                            color: blue[100],
                            fontSize: '0.75rem',
                            fontFamily: 'Monospace',
                            lineHeight: 1,
                        },
                        startAdornment: (
                            <InputAdornment position="start"></InputAdornment>
                        ),
                    }}
                />

                {/* Input field for address of the receiver of the NFT */}
                <TextField
                    onChange={e => setReceiver(e.target.value)}
                    size="small"
                    label="Receiver address"
                    id="outlined-start-adornment"
                    focused
                    sx={{ m: 1, width: '25rem' }}
                    InputProps={{
                        style: {
                            color: blue[100],
                            fontSize: '0.75rem',
                            fontFamily: 'Monospace',
                            lineHeight: 1,
                        },
                        startAdornment: (
                            <InputAdornment position="start"></InputAdornment>
                        ),
                    }}
                />

                {/* Mint NFT button */}

                <Button
                    variant="contained"
                    size="small"
                    onClick={() => mintNFT()}
                >
                    💎 Mint NFT(s)
                </Button>

                {/* box containing buttons and textfields */}

                <Box
                    sx={{
                        alignItems: 'center',
                        maxWidth: 0.85,
                        paddingBottom: '10rem',
                    }}
                >
                    <Grid
                        container
                        rowSpacing={1}
                        columnSpacing={{ xs: 1, sm: 2, md: 3 }}
                    >
                        <Grid item xs={12} sm={4}>
                            <p>
                                <Button
                                    sx={{ width: '100%' }}
                                    size="small"
                                    variant="outlined"
                                    onClick={() => getLeaves()}
                                >
                                    {leavesCopied
                                        ? 'Copied!'
                                        : 'Get leaves'}
                                </Button>
                            </p>
                            <p></p>
                            <TextField
                                sx={{ width: '100%' }}
                                onClick={() => handleCopy('leaves')}
                                id="outlined-textarea"
                                label={
                                    !leavesLength
                                        ? '🌿 Leaves '
                                        : `🌿 Leaves (${leavesLength})`
                                }
                                inputProps={{
                                    style: {
                                        color: blue[100],
                                        fontSize: '0.75rem',
                                        fontFamily: 'Monospace',
                                        lineHeight: 1,
                                    },
                                }}
                                rows={16}
                                value={leaves}
                                multiline
                                focused
                            />
                        </Grid>
                        <Grid item xs={12} sm={4}>
                            <p>
                                <Button
                                    sx={{ width: '100%' }}
                                    size="small"
                                    variant="outlined"
                                    onClick={() => getTree()}
                                >
                                    {treeCopied ? 'Copied!' : 'Get tree'}
                                </Button>
                            </p>
                            <p></p>
                            <TextField
                                sx={{ width: '100%' }}
                                onClick={() => handleCopy('tree')}
                                id="outlined-textarea"
                                label={
                                    !treeLength
                                        ? '🌲 Tree  '
                                        : `🌲 Tree (${treeLength})`
                                }
                                inputProps={{
                                    style: {
                                        color: blue[100],
                                        fontSize: '0.75rem',
                                        fontFamily: 'Monospace',
                                        lineHeight: 1,
                                    },
                                }}
                                rows={16}
                                value={tree}
                                multiline
                                focused
                            />
                        </Grid>
                        <Grid item xs={12} sm={4}>
                            <p>
                                <Button
                                    sx={{ width: '100%' }}
                                    size="small"
                                    variant="outlined"
                                    onClick={() => getRoot()}
                                >
                                    {rootCopied
                                        ? 'Copied!'
                                        : 'Get Merkle root'}
                                </Button>
                            </p>
                            <TextField
                                sx={{ width: '100%' }}
                                onClick={() => handleCopy('root')}
                                id="outlined-textarea"
                                label="🌱 Merkle root"
                                inputProps={{
                                    style: {
                                        color: blue[100],
                                        fontSize: '0.75rem',
                                        fontFamily: 'Monospace',
                                        lineHeight: 1,
                                    },
                                }}
                                rows={16}
                                value={root}
                                multiline
                                focused
                            />
                        </Grid>
                    </Grid>
                </Box>
            </header>
        </div>
    );
}

export default App;
