const cipherLib = require("../scripts/ciphers.js");
const ciminionKeyLib = require("../scripts/ciminion_key.js");
const chunkLib = require("../scripts/chunk.js");
const merkleLib = require("../scripts/merkle.js");
const rand = require('../scripts/ciminion_key.js').randomScalar;

const fs = require("fs");
const path = require("path");


// new a class for merchant proof of concept 
// the merchant has a ciminion key when newed
// the merchant can encrypt a file into CTCs
// the merchant can decrypt a CTC into PTCs
// the merchant can hash a CTC (COM) using poseidon hash function
// the merchant can commit CTCs using the merkle root of a merkle tree built on COMs 
// the merchant can prove the merkle path of a r-th COM 
class Merchant {
    constructor(skPath, if_new_sk = true) {
        this.skPath = skPath;
        // ge
    }

    // encrypt a PTC into a CTC
    async PTCtoCTC(ptc) {
        const sk = await ciminionKeyLib.LoadCIminionKeyJson(this.skPath);
        const ctc = await cipherLib.PTCtoCTC(ptc, sk);
        return ctc;
    }

    // decrypt a CTC into a PTC
    async CTCtoPTC(ctc) {
        const sk = await ciminionKeyLib.LoadCIminionKeyJson(this.skPath);
        const ptc = await cipherLib.CTCtoPTC(ctc, sk);
        return ptc;
    }

    // hash a CTC into a COM
    async HashCTC(ctc) {
        const hash = await cipherLib.HashCTC(ctc);
        return hash;
    }

    // commit a list of CTCs into a merkle root
    async CommitCTCs(ctcs) {
        const coms = [];
        for (let i = 0; i < ctcs.length; i++) {
            const com = await this.HashCTC(ctcs[i]);
            coms.push(com);
        }
        const root = await merkle.MerkleRoot(coms);
        return root;
    }

    // prove the merkle path of a r-th CTC
    async ProveCTC(ctcs, r) {
        const coms = [];
        for (let i = 0; i < ctcs.length; i++) {
            const com = await this.HashCTC(ctcs[i]);
            coms.push(com);
        }
        const path = await merkle.MerklePath(coms, r);
        return path;
    }
}