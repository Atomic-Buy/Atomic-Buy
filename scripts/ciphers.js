const F1Field = require("ffjavascript").F1Field;
const Scalar = require("ffjavascript").Scalar;
exports.p = Scalar.fromString("21888242871839275222246405745257275088548364400416034343698204186575808495617");

const Fr = new F1Field(exports.p);
const wasm_tester = require("../circom_tester/index").wasm;
//const c_tester = require("../circom_tester/index").c;

/// encrypt a plaintext array (64 number in an array) into a ciphertext array in string
// ptc should be an array of numbers in BN254
// sk should be an object with 4 keys: MK_0, MK_1, IV, nonce
async function PTCtoCTC(ptc, sk){
    // load the encrypted circuit
    const chunk_encoder = await wasm_tester("../circuits/enc64.circom"); 
    const input = {PT: ptc, MK_0: sk.MK_0, MK_1: sk.MK_1, IV: sk.IV, nonce: sk.nonce}; 
    const wtns = await chunk_encoder.calculateWitness(input);
    await chunk_encoder.checkConstraints(wtns);
    // get the ciphertext from the wtns 
    const ctc = await chunk_encoder.getOutput(wtns, ["CT[64]"]); 
    // the ctc is an map from CT[i] to string, convert to array of strings with the order of CT[0], CT[1], ..., CT[63]
    const ctc_array = [];
    for (let i = 0; i < 64; i++) {
        ctc_array.push(ctc["CT[" + i + "]"]);
    }
    // convert the array of strings to array of numbers using ffjavascript in the filed Fr
    return ctc_array; 
}

/// decrypt a ciphertext array into a plaintext array in string 
// ctc should be an array of numbers in BN254
// sk should be an object with 4 keys: MK_0, MK_1, IV, nonce, all in string format 
async function CTCtoPTC(ctc, sk){
    // load the decrypted circuit
    const chunk_decoder = await wasm_tester("../circuits/dec64.circom"); 
    const wtns = await chunk_decoder.calculateWitness({CT: ctc, MK_0: sk.MK_0, MK_1: sk.MK_1, IV: sk.IV, nonce: sk.nonce});
    await chunk_decoder.checkConstraints(wtns);
    // get the plaintext from the wtns 
    const ptc = await chunk_decoder.getOutput(wtns, ["PT[64]"]); 
    // the ptc is an map from PT[i] to string, convert to array of strings with the order of PT[0], PT[1], ..., PT[63]
    const ptc_array = [];
    for (let i = 0; i < 64; i++) {
        ptc_array.push(ptc["PT[" + i + "]"]);
    }
    
    return ptc_array;
}

/// caculate the hash of a ciphertext array 
async function HashCTC(ctc){
    // load the hash circuit
    const chunk_hash = await wasm_tester("../circuits/hash64.circom"); 
    const wtns = await chunk_hash.calculateWitness({in: ctc});
    await chunk_hash.checkConstraints(wtns);
    // get the hash from the wtns 
    const hash = chunk_hash.getOutput(wtns, ["out"]); 
    // convert the hash from string to number using ffjavascript in the filed Fr
    return hash; 
}


module.exports = {
    PTCtoCTC,
    CTCtoPTC,
    HashCTC,
};

