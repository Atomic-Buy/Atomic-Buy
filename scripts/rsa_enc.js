const F1Field = require("ffjavascript").F1Field;
const Scalar = require("ffjavascript").Scalar;
exports.p = Scalar.fromString(
    "21888242871839275222246405745257275088548364400416034343698204186575808495617"
);

const Fr = new F1Field(exports.p);
const wasm_tester = require("../circom_tester/index").wasm;

