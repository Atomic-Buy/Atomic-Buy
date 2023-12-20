pragma circom 2.0.3; 
include "./lib.circom"; 

template PoD(){
    // sk payee
    signal input MK_0_payee; 
    signal input MK_1_payee;
    signal input nonce_payee;
    signal input IV_payee;
    // sk payer
    signal input MK_0_payer; 
    signal input MK_1_payer;
    signal input nonce_payer;
    signal input IV_payer;
    // hash check 
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

    // enc sk
    component enc_sk = sk_enc();
    enc_sk.MK_0 <== MK_0_payer;
    enc_sk.MK_1 <== MK_1_payer;
    enc_sk.nonce <== nonce_payer;
    enc_sk.IV <== IV_payer;
    enc_sk.sk[0] <== MK_0_payee;
    enc_sk.sk[1] <== MK_1_payee;
    enc_sk.sk[2] <== nonce_payee;
    enc_sk.sk[3] <== IV_payee;
    CT_sk <== enc_sk.CT;
}