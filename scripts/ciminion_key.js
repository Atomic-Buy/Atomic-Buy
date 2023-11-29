const F1Field = require("ffjavascript").F1Field;
const Scalar = require("ffjavascript").Scalar;
exports.p = Scalar.fromString("21888242871839275222246405745257275088548364400416034343698204186575808495617");
const Fr = new F1Field(exports.p);

function GenCiminionKey(){
    // generate four random numbers in Fp
    return {
        MK_0: Fr.rand().to_string(),
        MK_1: Fr.rand().to_string(),
        IV: Fr.rand().to_string(),
        nonce: Fr.rand().to_string()
    }
}

async function GenCiminionKeyJson(outputPath){
    const sk = GenCiminionKey; 
    // write the sk into a json file 
    const fs = require("fs");
    const path = require("path");
    const sk_json = JSON.stringify(sk);
    fs.writeFileSync(path.join(outputPath, "sk.json"), sk_json);
}

async function LoadCIminionKeyJson(inputPath){
    // read the sk from a json file
    const fs = require("fs");
    return JSON.parse(fs.readFileSync(inputPath));
}

module.exports = {
    GenCiminionKey, 
    GenCiminionKeyJson, 
    LoadCIminionKeyJson
}