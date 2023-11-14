pragma circom 2.1.0;

include "./poseidon.circom";


//a merkle layer with 8^N leaves
template LayerN(N){
    var total_gate = 8 ** (N-1); 
    signal input in[total_gate * 8];
    signal output out[total_gate]; 
    component poseidon[total_gate]; 
    for (var i = 0; i < total_gate; i++){
        poseidon[i] = Poseidon(8);
    }
    for(var i = 0; i < total_gate; i++){
        poseidon[i].inputs[0] <== in[8*i];
        poseidon[i].inputs[1] <== in[8*i+1];
        poseidon[i].inputs[2] <== in[8*i+2];
        poseidon[i].inputs[3] <== in[8*i+3];
        poseidon[i].inputs[4] <== in[8*i+4];
        poseidon[i].inputs[5] <== in[8*i+5];
        poseidon[i].inputs[6] <== in[8*i+6];
        poseidon[i].inputs[7] <== in[8*i+7];
        
        out[i] <== poseidon[i].out;
    }
}

// a 8-merkle tree with 512 leaves, which means it has 3 layers 

template hash512(){
    signal input in[512]; 
    signal output out;
    component l3 = LayerN(3);
    component l2 = LayerN(2);
    component l1 = LayerN(1);
    // write them together 
    for(var i = 0; i < 512; i++){
        l3.in[i] <== in[i];
    }
    for(var i = 0; i < 64; i++){
        l2.in[i] <== l3.out[i];
    }
    for(var i = 0; i < 8; i++){
        l1.in[i] <== l2.out[i];
    }
    out <== l1.out[0];
}

