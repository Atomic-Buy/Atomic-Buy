pragma circom 2.0.3; 
include "./lib.circom"; 

/*
Inputs: 
    - sk_payee
    - h_sk_payee
    - r 
    - CTC[r]
intemediate: 
    - ptc_r
Output: 
    - hash(CTC[r])
*/

template PoF64(){
    signal input MK_0_payee; 
    signal input MK_1_payee;
    signal input nonce_payee;
    signal input IV_payee;
    signal input h_sk_payee; 
    signal input r; 
    signal input CTC_r[64]; 
    signal output h_CTC_r; 

    // check sk_payee 
    component payee_check = sk_hash();
    payee_check.MK_0 <== MK_0_payee;
    payee_check.MK_1 <== MK_1_payee;
    payee_check.nonce <== nonce_payee;
    payee_check.h_sk === h_sk_payee;

    // derive 
    component nonce_derive = nonce_derive();
    nonce_derive.pre_nonce <== nonce_payee;
    nonce_derive.r <== r;
    signal nonce_derive_out <== nonce_derive.post_nonce; 

    // dec CTC_r 
    component dec = chunk_dec64(); 
    dec.MK_0 <== MK_0_payee;
    dec.MK_1 <== MK_1_payee;
    dec.nonce <== nonce_derive_out;
    dec.IV <== IV_payee;
    dec.CT <== CTC_r;

    // hash 
    component hash = hash64();
    hash.in <== dec.PT;

    // output
    h_CTC_r <== hash.out;
}