pragma circom 2.0.3; 

include "./ciminion/ciminion_mac.circom"; 
include "./ciminion/ciminion_enc.circom";
include "./poseidon_sk.circom";
template MacChecker(){
    signal input MK_0;
    signal input MK_1;
    signal input nonce;
    signal input IV;
    signal input CT[512];
    signal input TAG; 

    signal TAG2; 
    component mac = CiminionMac(256); 
    mac.MK_0 <== MK_0;
    mac.MK_1 <== MK_1;
    mac.nonce <== nonce;
    mac.IV <== IV;
    mac.CT <== CT;
    TAG2 <== mac.TAG;

    TAG === TAG2;

}

template KeyEnc() {
    signal input MK_0;
    signal input MK_1;
    signal input nonce;
    signal input IV;
    signal input PT[4];
    signal output CT[4];

    component enc = CiminionEnc(2);
    enc.MK_0 <== MK_0;
    enc.MK_1 <== MK_1;
    enc.nonce <== nonce;
    enc.IV <== IV;
    enc.PT <== PT;
    CT <== enc.CT;
}

template pod(){
    signal input MK_0_buyer; 
    signal input MK_1_buyer;
    signal input nonce_buyer;
    signal input IV_buyer;
    signal input MK_0_seller; 
    signal input MK_1_seller;
    signal input nonce_seller;
    signal input IV_seller;
    signal input CT1[512]; 
    signal input MAC; 
    signal input hash_buyer; 
    signal output CT2[4]; 
    
    //check if ciphertext is valid 
    component mac = MacChecker();
    mac.MK_0 <== MK_0_seller; 
    mac.MK_1 <== MK_1_seller;
    mac.nonce <== nonce_seller;
    mac.IV <== IV_seller;
    mac.CT <== CT1;
    mac.TAG <== MAC;

    // encrypt the seller keys with the buyer's key
    component enc = KeyEnc();
    enc.MK_0 <== MK_0_buyer;
    enc.MK_1 <== MK_1_buyer;
    enc.nonce <== nonce_buyer;
    enc.IV <== IV_buyer;
    enc.PT[0] <== MK_0_seller;
    enc.PT[1] <== MK_1_seller;
    enc.PT[2] <== nonce_seller;
    enc.PT[3] <== IV_seller;
    CT2 <== enc.CT;
    
    // check hash buyer 
    component hasher = hash_sk(); 
    hasher.MK_0 <== MK_0_buyer;
    hasher.MK_1 <== MK_1_buyer;
    hasher.nonce <== nonce_buyer;
    hasher.IV <== IV_buyer;
    hasher.hash === hash_buyer;

}

component main {public [hash_buyer, MAC]} = pod();
