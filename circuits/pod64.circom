pragma circom 2.0.3; 
include "./lib.circom";

component main {public [h_sk_payee, h_sk_payer, r, COM_r]} = PoD64();