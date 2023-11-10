const F1Field = require("ffjavascript").F1Field;
const Scalar = require("ffjavascript").Scalar;
exports.p = Scalar.fromString("21888242871839275222246405745257275088548364400416034343698204186575808495617");
const Fr = new F1Field(exports.p);

class ciminionKeyGen{
    // generate four random numbers in Fp
    constructor(){
        this.mk_0 = Fr.rand();
        this.mk_1 = Fr.rand();
        this.IV = Fr.rand();
        this.nonce = Fr.rand();
    }
    export_sk(){
        let sk = {
            MK_0: this.mk_0.to_string(),
            MK_1: this.mk_1.to_string(),
            IV: this.IV.to_string(),
            nonce: this.nonce.to_string()
        }
        return sk;
    }
    
}