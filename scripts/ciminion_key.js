const F1Field = require("ffjavascript").F1Field;
const Scalar = require("ffjavascript").Scalar;
exports.p = Scalar.fromString("21888242871839275222246405745257275088548364400416034343698204186575808495617");
const Fr = new F1Field(exports.p);
const crypto = require('crypto');

function randomScalar(field) {
  let rand;
  do {
    // Generate a random buffer of bytes
    const buf = crypto.randomBytes(32);
    // Convert the buffer to a BigInt
    rand = BigInt('0x' + buf.toString('hex'));
    // Ensure the random number fits within the field (less than p)
    rand = Scalar.mod(rand, field.p);
  } while (rand >= field.p);

  return rand;
}
function GenCiminionKey(){
    // generate four random numbers in Fp
    const sk = {
        MK_0: randomScalar(Fr),
        MK_1: randomScalar(Fr),
        IV: '123',
        nonce: randomScalar(Fr)
        
    }
    // convert the four numbers to string
    for (let key in sk) {
        sk[key] = sk[key].toString();
    }
    return sk; 
}

async function GenCiminionKeyJson(outputPath){
    const sk = GenCiminionKey(); 
    // write the sk into a json file 
    const fs = require("fs");
    const sk_json = JSON.stringify(sk);
    fs.writeFileSync(outputPath, sk_json);
}

async function LoadCIminionKeyJson(inputPath){
    // read the sk from a json file
    const fs = require("fs");
    return JSON.parse(fs.readFileSync(inputPath));
}

module.exports = {
    GenCiminionKey, 
    GenCiminionKeyJson, 
    LoadCIminionKeyJson, 
    randomScalar
}