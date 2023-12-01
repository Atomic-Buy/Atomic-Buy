/// Test the merkle tree functions
const F1Field = require("ffjavascript").F1Field;
const Scalar = require("ffjavascript").Scalar;
exports.p = Scalar.fromString("21888242871839275222246405745257275088548364400416034343698204186575808495617");
const Fr = new F1Field(exports.p);
const chai = require("chai");
const merkle = require("../scripts/merkle.js");
const rand = require('../scripts/ciminion_key.js').randomScalar;

describe("merkle tree test", function () {
    ///before test, generate a list of hashes (bigint in string format) in Fr 
    const hashList = [];
    let root = "";
    let root1   = "";
    before(async () => {
        for (let i = 0; i < 64; i++) {
            hashList.push(rand(Fr).toString());
            
        }
        root1 = merkle.MerkleRoot(hashList);
    });
    /// Test 1: test the merkle root function, run twice to if if the result is the same
    it("should return the merkle root", async () => {
        const root2 = merkle.MerkleRoot(hashList);
        chai.assert.equal(root1, root2);
        console.log(root1);
        root = root1; 
    });

    /// Test 2: generate the merkle path of 0-th, 5-th, 64-th leaf, check if the merkle path is correct
    it("should pass the merkle path verification", async () => {
        const path_0 = merkle.MerklePath(hashList, 0);
        chai.assert.isTrue(merkle.MerklePathVerify(hashList[0],"0", path_0, root));
        const path_5 = merkle.MerklePath(hashList, 5);
        const path_63 = merkle.MerklePath(hashList, 63);
        // verify those paths using function MerklePathVerify
        chai.assert.isTrue(merkle.MerklePathVerify(hashList[5], "5", path_5, root));
        chai.assert.isTrue(merkle.MerklePathVerify(hashList[63], "63", path_63, root));
    });

    /// Test 3: test the proof of position of the merkle path
    it("should not pass the proof of position", async () => {
        const path_23 = merkle.MerklePath(hashList, 23);
        console.log(path_23);
        chai.assert.isTrue(merkle.MerklePathVerify(hashList[23],"23", path_23, root));
        chai.assert.isFalse(merkle.MerklePathVerify(hashList[23],"64", path_23, root));
    });
}); 
