pragma circom 2.0.0;

include "MiMCSponge.circom";
// circom MerkleRoot.circom --r1cs --wasm --sym

// This circuit gets the Merkle root of its leaves
template MerkleRoot(n) {
    signal input leaves[n]; 
    // n amount of leaves
    signal output root; 
    // returns the root of the tree
    var hashes[2 * n - 1]; 
    // create an array with the size of the tree **
    component mimcs[n - 1]; 
    // define mimc array with content of type component

    for (var i = 0; i < n; i ++) {
        hashes[i] = leaves[i]; 
        // store input values inside hashes array
    }

    for (var i = 0; i < n - 1; i ++) {
        mimcs[i] = MiMCSponge(2, 220, 1);
        // instantiate circuit with 2 inputs and 1 output in mimc array position i
        mimcs[i].ins[0] <== hashes[i*2];  
        // store even numbers in 1st input starting from 0
        mimcs[i].ins[1] <== hashes[i*2+1]; 
        // store uneven numbers in 2nd input starting from 1
        mimcs[i].k <== 0; // set k variable to 0 every loop
        // after all the circuit signal inputs are set the component instatiation will be triggered
        hashes[i+n] = mimcs[i].outs[0]; 
        // fill the tree with hash output of mimcsponge circuit
    }

    root <== hashes[2 * n - 2]; 
    // the root is at 14th position  of the hashes array **
}

component main{public [leaves]} = MerkleRoot(8);

// **
//
//   0123 < root
//  01  23 < hashes
// 0 1 2 3 < leaves, 
// x x x x < data

// if n == 8, 2*8-2 = 14
//
//        14 < root
//    12      13 
//  8   9    10 11  
// 0 1 2 3  4 5 6 7   < leaves
// x x x x  x x x x    < input 