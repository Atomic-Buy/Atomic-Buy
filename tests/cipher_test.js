const cipherLib = require("../scripts/ciphers.js");
const ciminionKeyLib = require("../scripts/ciminion_key.js");
const chunkLib = require("../scripts/chunk.js");
const F1Field = require("ffjavascript").F1Field;
const Scalar = require("ffjavascript").Scalar;
exports.p = Scalar.fromString(
    "21888242871839275222246405745257275088548364400416034343698204186575808495617"
);

const Fr = new F1Field(exports.p);
const fs = require("fs");
const path = require("path");
const chai = require("chai");
const testFilePath = "../data/src.jpg";
const skPath_0 = "../data/sk_0.json";
const chunkFolder = "../data/src";
const ctcPath = "../data/src/ct_0.json";
describe("cipher functions", function () {
    this.timeout(1000000);
    /// before test, generate a ciminion key and convert the original file into PTCs
    before(async () => {
        // generate a ciminion key
        await ciminionKeyLib.GenCiminionKeyJson(skPath_0);
        // convert the original file into PTCs
        const inputFilePath = testFilePath;
        // divides the file into PTCs
        chunkLib.inputFileToBigNumberArrays(inputFilePath);
    });

    /// Test 1: encrypt 1 PTC into 1 CTC PTC path "../data/PTC/pt_0.json" CTC path "../data/CTC/ct_0.json", then decrypt the CTC into PTC, check if the decrypted PTC is the same as the original PTC
    it("should encrypt and decrypt one PTC", async () => {
        // load the the PTC 
        const ptcPath = path.join(chunkFolder, "pt_0.json");
        // read json to string array 
        const ptc_json = fs.readFileSync(ptcPath);
        const ptc = JSON.parse(ptc_json);
        // encrypt ptc 
        const sk0 = await ciminionKeyLib.LoadCIminionKeyJson(skPath_0);
        const ctc = await cipherLib.PTCtoCTC(ptc, sk0);
        fs.writeFileSync(ctcPath, JSON.stringify(ctc));
        // decrypt ctc
        const ptc_decrypted = await cipherLib.CTCtoPTC(ctc, sk0);
        // assert ptc_decrypted == ptc
        chai.assert.deepEqual(ptc_decrypted, ptc);
        
    });

    /// Test 2: test the poseidon hash function 
    it ("should hash a CTC", async () => {
        // load the the CTC 
        // read json to string array 
        const ctc_json = fs.readFileSync(ctcPath);
        const ctc = JSON.parse(ctc_json);
        // hash ctc 
        const hash = await cipherLib.HashCTC(ctc);
        console.log(hash);
    }); 

    /// Test 3: encrypt all ptcs to ctcs, then decrypt all ctcs to ptcs, check if the decrypted ptcs are the same as the original ptcs
    it("should encrypt and decrypt all PTCs", async () => {
        // load the the PTCs 
        const ptcPaths = fs.readdirSync(chunkFolder);
        // get all ptc files in ptcPaths, "pt_i.json" in chunkfolder 
        const ptcPaths_filtered = [];
        for (let i = 0; i < ptcPaths.length; i++) {
            if (ptcPaths[i].startsWith("pt_")) {
                ptcPaths_filtered.push(ptcPaths[i]);
            }
        }
        // read json to string array 
        const ptcs = [];
        for (let i = 0; i < ptcPaths_filtered.length; i++) {
            const ptcPath = path.join(chunkFolder, ptcPaths_filtered[i]);
            const ptc_json = fs.readFileSync(ptcPath);
            const ptc = JSON.parse(ptc_json);
            ptcs.push(ptc);
        }
        // encrypt ptcs 
        const sk0 = await ciminionKeyLib.LoadCIminionKeyJson(skPath_0);
        const ctcs = await cipherLib.PTCstoCTCs(ptcs, sk0);
        //console.log(ctcs[0]);
        // decrypt ctcs
        const ptcs_decrypted = await cipherLib.CTCstoPTCs(ctcs, sk0);
        // assert ptcs_decrypted == ptcs
        chai.assert.deepEqual(ptcs_decrypted, ptcs);
        // hash ctcs
        const hashes = await cipherLib.HashCTCs(ctcs);
        console.log(hashes);
    });
    /// after test, remove the ciminion key and all the PTCs, CTCs 
    after(() => {
        // remove every file in chunkfolder, and remove the ct_0.json 
        const files = fs.readdirSync(chunkFolder);
        // range files 
        for (let i = 0; i < files.length; i++) {
            fs.unlinkSync(path.join(chunkFolder, files[i]));
        }
        fs.unlinkSync(chunkFolder); 
        fs.unlinkSync(skPath_0);
    });
});
