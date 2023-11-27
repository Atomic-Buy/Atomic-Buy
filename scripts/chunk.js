const fs = require("fs");
const path = require("path");
const { toBigIntBE, toBufferBE } = require("bigint-buffer");
const { F1Field } = require("ffjavascript");

const CHUNK_SIZE = 30 * 64; // bytes
const FIELD_SIZE = 30; // bytes per big number
const F1Field = require("ffjavascript").F1Field;
const Scalar = require("ffjavascript").Scalar;
exports.p = Scalar.fromString(
    "21888242871839275222246405745257275088548364400416034343698204186575808495617"
);
const Fr = new F1Field(exports.p);
// a function which new a folder name from the input file name
function getChunkFolder(inputFilePath) {
    const inputFileName = path.basename(inputFilePath);
    const inputFileNameWithoutExt = path.parse(inputFileName).name;
    return path.join(path.dirname(inputFilePath), inputFileNameWithoutExt);
}

// Function to divide a file into chunks
function divideIntoChunks(inputFilePath) {
    const chunkFolder = getChunkFolder(inputFilePath);
    const data = fs.readFileSync(inputFilePath);
    const chunks = [];
    let i = 0;

    // Create chunks directory if it doesn't exist
    if (!fs.existsSync(chunkFolder)) {
        fs.mkdirSync(chunkFolder);
    }
    let cnt = 0;
    while (i < data.length) {
        const chunk = data.slice(i, i + CHUNK_SIZE);
        const paddingLength = CHUNK_SIZE - chunk.length;
        // donot padding the chunk if it's not the last chunk
        let paddedChunk;
        if (paddingLength > 0) {
            // padding the "paddingLengh -1" as a sigle byte first, then padding the rest as 0
            paddedChunk = Buffer.concat([
                chunk,
                Buffer.alloc(paddingLength , 0)
            ]);
            // write the padding length to a new file in this folder `chunkFolder` `meta.txt`
            fs.writeFileSync(path.join(chunkFolder, "meta.txt"), paddingLength);
        } else {
            paddedChunk = chunk;
        }

        const chunkFileName = `${cnt}.chunk`;
        const chunkFilePath = path.join(chunkFolder, chunkFileName);
        fs.writeFileSync(chunkFilePath, paddedChunk);
        chunks.push(chunkFilePath);
        i += CHUNK_SIZE;
        cnt += 1;
    }
    // return all the chunk file paths
    return chunks;
}

// Function to rebuild the original file from chunks
function rebuildFromFileChunks(outputFilePath, chunkFolder) {
    const chunks = [];
    // count how many chunks in the folder
    const files = fs.readdirSync(chunkFolder);
    // count the file number in format *.chunk in this folder 
    const chunkNum = files.filter((file) => file.endsWith(".chunk")).length;

    for (let i = 0; i < chunkNum; i++) {
        const chunkFilePath = path.join(chunkFolder, `${i}.chunk`);
        const chunk = fs.readFileSync(chunkFilePath);
        chunks.push(chunk);
    }

    const fileData = Buffer.concat(chunks);
    // read the padding length from `meta.txt`
    const paddingLength = fs.readFileSync(path.join(chunkFolder, "meta.txt"));
    // remove the padding
    const fileDataWithoutPadding = fileData.slice(0, fileData.length - paddingLength);
    fs.writeFileSync(outputFilePath, fileDataWithoutPadding);

}

// Function to convert a chunk to a big number array
function chunkToBigNumberArray(chunkFilePath) {
    const chunk = fs.readFileSync(chunkFilePath);
    const bigNumbers = [];

    for (let i = 0; i < chunk.length; i += FIELD_SIZE) {
        const num = toBigIntBE(chunk.slice(i, i + FIELD_SIZE));
        bigNumbers.push(num);
    }

    return bigNumbers;
}

// Function to convert a big number array to a chunk
function bigNumberArrayToChunk(bigNumbers) {
    const buffers = bigNumbers.map((num) => toBufferBE(num, FIELD_SIZE));
    return Buffer.concat(buffers);
}

// Function to convert an input file into arrays of big numbers
function inputFileToBigNumberArrays(inputFilePath) {
    const chunkFolder = getChunkFolder(inputFilePath);
    const chunkFilePaths = divideIntoChunks(inputFilePath, chunkFolder);
    
    // convert each chunk to big number array
    const bigNumberArrays = chunkFilePaths.map((chunkFilePath) =>
        chunkToBigNumberArray(chunkFilePath)
    );
    // write the big number arrays into json array, one chunk array one file , in format `pt_i.json` 
    for (let i = 0; i < bigNumberArrays.length; i++) {
        fs.writeFileSync(path.join(chunkFolder, `pt_${i}.json`), JSON.stringify(bigNumberArrays[i]));
    }

}

// Function to build a file from arrays of big numbers
function buildFileFromBigNumberArrays(chunkFolder, outputFilePath) {
    // read the big number arrays from json file
    const files = fs.readdirSync(chunkFolder);
    // count the file number in format *.json in this folder
    const chunkNum = files.filter((file) => file.endsWith(".json")).length;
    const bigNumberArrays = [];
    for (let i = 0; i < chunkNum; i++) {
        const chunkFilePath = path.join(chunkFolder, `pt_${i}.json`);
        const chunk = fs.readFileSync(chunkFilePath);
        bigNumberArrays.push(JSON.parse(chunk));
    }
    // convert each big number array to chunk
    const chunks = bigNumberArrays.map((bigNumbers) =>
        bigNumberArrayToChunk(bigNumbers)
    );
    // rebuild the file from chunks
    rebuildFromFileChunks(outputFilePath, chunkFolder);
}

module.exports = {
    divideIntoChunks,
    rebuildFromFileChunks,
    chunkToBigNumberArray,
    bigNumberArrayToChunk,
    inputFileToBigNumberArrays,
    buildFileFromBigNumberArrays,
};
