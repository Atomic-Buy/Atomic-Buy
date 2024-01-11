pragma circom 2.0.0;
include "./lib.circom";
include "./rsa/pow_mod.circom";
// check hash of base (data encrypted)
// return base ^ 65537 % modulus


template RsaEnc(){
    signal input MK0; 
    signal input MK1; 
    signal input NS; 
    signal input h_sk; 
    signal input exp[32];
    signal input modulus[32]; 
    signal output out[32];
    component enc = PowerMod(64, 32, 17);
    // little endian 
    signal MK_0[4]; 
    signal MK_1[4];
    signal nonce[4];
    // split MK_0, MK_1, nonce into 4 64-bit numbers

    // const number 2^64; 
    var t = 18446744073709551616; 
    
    MK_0[0] <-- MK0 % t;
    MK_0[1] <-- (MK0 >> 64) % t;
    MK_0[2] <-- (MK0 >> 128) % t;
    MK_0[3] <-- MK0 >> 192;

    MK_1[0] <-- MK1 % t;
    MK_1[1] <-- (MK1 >> 64) % t;
    MK_1[2] <-- (MK1 >> 128) % t;
    MK_1[3] <-- MK1 >> 192;

    nonce[0] <-- NS % t;
    nonce[1] <-- (NS >> 64) % t;
    nonce[2] <-- (NS >> 128) % t;
    nonce[3] <-- NS >> 192;

    
    // combine MK_0, Mk_1, nonce into the first 12 number ofo base 
    for (var i = 0; i < 4; i++) {
        enc.base[i] <== MK_0[i];
        enc.base[i+4] <== MK_1[i];
        enc.base[i+8] <== nonce[i];
    }
    // padding the base with 0 
    for (var i = 12; i < 32; i++) {
        enc.base[i] <== 0;
    }
    // add exp and modulus 
    enc.exp <== exp; 
    enc.modulus <== modulus;
    
    // check the hash of MK_0, MK_1, MK_2; 
    component sk_checker = sk_hash(); 
    sk_checker.MK_0 <== MK0; 
    sk_checker.MK_1 <== MK1;
    sk_checker.nonce <== NS;
    h_sk === sk_checker.h_sk; 
    out <== enc.out; 

}

