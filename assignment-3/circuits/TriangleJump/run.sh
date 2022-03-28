#! /bin/bash

# ($1: string = cli input 1st argument, MerkleRoot in this case)

# With these options we generate three types of files:
#   --r1cs: it generates the file $1.r1cs that contains the
#           R1CS constraint system of the circuit in binary format.

#   --wasm: it generates the directory $1_js that contains 
#           the Wasm code ($1.wasm) and other files needed to generate the witness.

#   --sym : it generates the file $1.sym , a symbols file
#           required for debugging or for printing the constraint system in an annotated mode.

#   --c : it generates the directory $1_cpp that contains 
#           several files ($1.cpp, $1.dat, and other common files 
#           for every compiled program like main.cpp, MakeFile, etc) 
#           needed to compile the C code to generate the witness.

# Optionally we can use the option -o to specify the directory where these files are created.
# Compile the circuit, removed --c option 
circom $1.circom --r1cs --wasm --sym
echo
echo "Compiled $1.circom"

# - cd into $1 folder 
cd $1_js
# copy input.json file into js dir
cp ../input.json .
# generate witness.wtns file
node generate_witness.js $1.wasm input.json witness.wtns

# cd into parent dir
cd ..
# powers of tau 12
snarkjs powersoftau new bn128 12 pot12_0000.ptau -v
# contribute to ceremony (input="random text")
echo random text | snarkjs powersoftau contribute pot12_0000.ptau pot12_0001.ptau --name="First contribution" -v

# powers of tau phase 2 : slow
snarkjs powersoftau prepare phase2 pot12_0001.ptau pot12_final.ptau -v
# generate .zkey : fast
snarkjs groth16 setup $1.r1cs pot12_final.ptau $1_0000.zkey
# contr phase 2 ceremony (input="random text")
echo random text | snarkjs zkey contribute $1_0000.zkey $1_0001.zkey --name="1st Contributor Name" -v

# export verification key file
snarkjs zkey export verificationkey $1_0001.zkey verification_key.json
# copy witness.wtns into js dir
cp ./$1_js/witness.wtns .
# create public file 
snarkjs groth16 prove $1_0001.zkey witness.wtns proof.json public.json
# create proof file
snarkjs groth16 verify verification_key.json public.json proof.json
# create solidity verify smart contract
snarkjs zkey export solidityverifier $1_0001.zkey verifier.sol
# generate solidity inputs
snarkjs generatecall

