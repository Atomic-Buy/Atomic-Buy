pragma circom 2.0.3; 

include "./ciminion/ciminion_enc.circom";
include "./ciminion/ciminion_dec.circom";
include "./poseidon/poseidon.circom";
include "./poseidon_recursive.circom";
template chunk_enc512(){
    signal input MK_0;
    signal input MK_1;
    signal input nonce;
    signal input IV;
    signal input PT[512];
    signal output CT[512];

    component enc = CiminionEnc(256);
    enc.MK_0 <== MK_0;
    enc.MK_1 <== MK_1;
    enc.nonce <== nonce;
    enc.IV <== IV;
    enc.PT <== PT;
    CT <== enc.CT;
}

template chunk_dec512(){
    signal input MK_0;
    signal input MK_1;
    signal input nonce;
    signal input IV;
    signal input CT[512];
    signal output PT[512];
    component dec = CiminionDec(256);
    dec.MK_0 <== MK_0;
    dec.MK_1 <== MK_1;
    dec.nonce <== nonce;
    dec.IV <== IV;
    dec.CT <== CT;
    PT <== dec.PT;
}

template chunk_enc64(){
    signal input MK_0;
    signal input MK_1;
    signal input nonce;
    signal input IV;
    signal input PT[64];
    signal output CT[64];

    component enc = CiminionEnc(32);
    enc.MK_0 <== MK_0;
    enc.MK_1 <== MK_1;
    enc.nonce <== nonce;
    enc.IV <== IV;
    enc.PT <== PT;
    CT <== enc.CT;
}

template chunk_dec64(){
    signal input MK_0;
    signal input MK_1;
    signal input nonce;
    signal input IV;
    signal input CT[64];
    signal output PT[64];
    component dec = CiminionDec(32);
    dec.MK_0 <== MK_0;
    dec.MK_1 <== MK_1;
    dec.nonce <== nonce;
    dec.IV <== IV;
    dec.CT <== CT;
    PT <== dec.PT;
}

template nonce_derive(){
    signal input pre_nonce; 
    signal input r; 
    signal output post_nonce; 

    component hash = Poseidon(2);
    hash.inputs[0] <== pre_nonce;
    hash.inputs[1] <== r;
    post_nonce <== hash.out;
}

template sk_enc() {
    signal input MK_0;
    signal input MK_1;
    signal input nonce;
    signal input IV;
    signal input sk[4];
    signal output CT[4];

    component enc = CiminionEnc(2);
    enc.MK_0 <== MK_0;
    enc.MK_1 <== MK_1;
    enc.nonce <== nonce;
    enc.IV <== IV;
    enc.PT <== sk;
    CT <== enc.CT;
}
template sk_dec(){
    signal input MK_0;
    signal input MK_1;
    signal input nonce;
    signal input IV;
    signal input CT[4];
    signal output sk[4];

    component dec = CiminionDec(2);
    dec.MK_0 <== MK_0;
    dec.MK_1 <== MK_1;
    dec.nonce <== nonce;
    dec.IV <== IV;
    dec.CT <== CT;
    sk <== dec.PT;
}
template sk_hash(){
    signal input MK_0;
    signal input MK_1;
    signal input nonce;
    signal input IV;
    signal output h_sk;
    component hash = Poseidon(4); 
    hash.inputs[0] <== MK_0;
    hash.inputs[1] <== MK_1;
    hash.inputs[2] <== nonce;
    hash.inputs[3] <== IV;
    h_sk <== hash.out;
}

template PoD512(){
    signal input MK_0_payee; 
    signal input MK_1_payee;
    signal input nonce_payee;
    signal input IV_payee;
    signal input MK_0_payer; 
    signal input MK_1_payer;
    signal input nonce_payer;
    signal input IV_payer;
    signal input PTC_r[512]; 
    signal input COM_r; 
    signal input r; 
    signal input h_sk_payer;
    signal input h_sk_payee; 
    signal output CT_sk[4]; 
    
    // check sk_payee 
    component payee_check = sk_hash();
    payee_check.MK_0 <== MK_0_payee;
    payee_check.MK_1 <== MK_1_payee;
    payee_check.nonce <== nonce_payee;
    payee_check.IV <== IV_payee;
    payee_check.h_sk === h_sk_payee;

    // check sk_payer
    component payer_check = sk_hash();
    payer_check.MK_0 <== MK_0_payer;
    payer_check.MK_1 <== MK_1_payer;
    payer_check.nonce <== nonce_payer;
    payer_check.IV <== IV_payer;
    payer_check.h_sk === h_sk_payer;

    // derive nonce 
    component nonce_derive = nonce_derive();
    nonce_derive.pre_nonce <== nonce_payee;
    nonce_derive.r <== r;
    signal nonce_derive_out <== nonce_derive.post_nonce;

    // enc PTC_r
    component enc = chunk_enc512();
    enc.MK_0 <== MK_0_payee;
    enc.MK_1 <== MK_1_payee;
    enc.nonce <== nonce_derive_out;
    enc.IV <== IV_payee;
    enc.PT <== PTC_r;

    // calculate recursive hash of CTC_r
    component hash_CTC = hash512(); 
    hash_CTC.in <== enc.CT; 
    signal h_CTC_r <== hash_CTC.out;
    COM_r === h_CTC_r;

    // enc sk
    component enc_sk = sk_enc();
    enc_sk.MK_0 <== MK_0_payer;
    enc_sk.MK_1 <== MK_1_payer;
    enc_sk.nonce <== nonce_payer;
    enc_sk.IV <== IV_payer;
    enc_sk.sk[0] <== MK_0_payee;
    enc_sk.sk[1] <== MK_1_payee;
    enc_sk.sk[2] <== nonce_derive_out;
    enc_sk.sk[3] <== IV_payee;
    CT_sk <== enc_sk.CT;
}
/*
Inputs: 
- private sk_payee 
- private sk_payer
- private plaintext chunk 
- public commitment to chunk ciphertext 
- public chunk index 
- public hash of sk_payer 
- public hash of sk_payee
- public ouputs: encrypted sk_payee
*/
template PoD64(){
    signal input MK_0_payee; 
    signal input MK_1_payee;
    signal input nonce_payee;
    signal input IV_payee;
    signal input MK_0_payer; 
    signal input MK_1_payer;
    signal input nonce_payer;
    signal input IV_payer;
    signal input PTC_r[64]; 
    signal input COM_r; 
    signal input r; 
    signal input h_sk_payer;
    signal input h_sk_payee; 
    signal output CT_sk[4]; 
    
    // check sk_payee 
    component payee_check = sk_hash();
    payee_check.MK_0 <== MK_0_payee;
    payee_check.MK_1 <== MK_1_payee;
    payee_check.nonce <== nonce_payee;
    payee_check.IV <== IV_payee;
    payee_check.h_sk === h_sk_payee;

    // check sk_payer
    component payer_check = sk_hash();
    payer_check.MK_0 <== MK_0_payer;
    payer_check.MK_1 <== MK_1_payer;
    payer_check.nonce <== nonce_payer;
    payer_check.IV <== IV_payer;
    payer_check.h_sk === h_sk_payer;

    // derive nonce 
    component nonce_derive = nonce_derive();
    nonce_derive.pre_nonce <== nonce_payee;
    nonce_derive.r <== r;
    signal nonce_derive_out <== nonce_derive.post_nonce;

    // enc PTC_r
    component enc = chunk_enc64();
    enc.MK_0 <== MK_0_payee;
    enc.MK_1 <== MK_1_payee;
    enc.nonce <== nonce_derive_out;
    enc.IV <== IV_payee;
    enc.PT <== PTC_r;

    // calculate recursive hash of CTC_r
    component hash_CTC = hash64(); 
    hash_CTC.in <== enc.CT; 
    signal h_CTC_r <== hash_CTC.out;
    COM_r === h_CTC_r;

    // enc sk
    component enc_sk = sk_enc();
    enc_sk.MK_0 <== MK_0_payer;
    enc_sk.MK_1 <== MK_1_payer;
    enc_sk.nonce <== nonce_payer;
    enc_sk.IV <== IV_payer;
    enc_sk.sk[0] <== MK_0_payee;
    enc_sk.sk[1] <== MK_1_payee;
    enc_sk.sk[2] <== nonce_derive_out;
    enc_sk.sk[3] <== IV_payee;
    CT_sk <== enc_sk.CT;
}
