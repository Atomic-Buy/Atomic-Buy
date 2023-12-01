const cipherLib = require("../scripts/ciphers.js");
const ciminionKeyLib = require("../scripts/ciminion_key.js");
const chunkLib = require("../scripts/chunk.js");
const fs = require("fs");
const path = require("path");

// new a class for merchant proof of concept 
// the merchant has a ciminion key when newed
// the merchant can encrypt a file into CTCs
// the merchant can decrypt a CTC into PTCs
// the merchant can hash a CTC using poseidon hash function
// the merchant can commit CTCs using 