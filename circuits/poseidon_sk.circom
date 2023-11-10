pragma circom 2.0.3; 

include "./poseidon/poseidon.circom"; 

template hash_sk(){
    signal input MK_0; 
    signal input MK_1; 
    signal input nonce; 
    signal input IV; 
    signal output hash; 
    component poseidon4 = Poseidon(4); 
    poseidon4.in[0] <== MK_0;
    poseidon4.in[1] <== MK_1;
    poseidon4.in[2] <== nonce;
    poseidon4.in[3] <== IV;
    hash <== poseidon4.out;
}

component main = hash_sk(); 