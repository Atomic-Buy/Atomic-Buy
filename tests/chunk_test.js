const chunkLib = require('../scripts/chunk.js');
const chai = require("chai");
// test the chunk functions 
const testFilePath = '../data/src.jpg';
const fs = require('fs');
const path = require('path');
describe('chunk functions', () => {
    /// divide a file into chunks then build the file from chunks 
    it('should divide a file into chunks then build the file from chunks', () => {
        const inputFilePath = testFilePath;
        chunkLib.divideIntoChunks(inputFilePath);
        const outputFilePath = '../data/output.jpg';
        const chunkFolder = chunkLib.getChunkFolder(inputFilePath);
        chunkLib.rebuildFromFileChunks(outputFilePath, chunkFolder);
        // compare the original file and the rebuilt file
        const originalFile = fs.readFileSync(inputFilePath);
        const rebuiltFile = fs.readFileSync(outputFilePath);
        chai.assert.deepEqual(originalFile, rebuiltFile);
        // rm output file
        fs.unlinkSync(outputFilePath);
    });

    /// convert a chunk to to a big number array then convert it back to a chunk
    it('should convert a chunk to to a big number array then convert it back to a chunk', () => {
        const inputFilePath = testFilePath;
        const chunkFolder = chunkLib.getChunkFolder(inputFilePath);
        // get the first chunk '0.chunk' in the folder
        const chunkPath = path.join(chunkFolder, '0.chunk');
        const bigNumbers = chunkLib.chunkToBigNumberArray(chunkPath);
        const chunk = chunkLib.bigNumberArrayToChunk(bigNumbers);
        const originalChunk = fs.readFileSync(chunkPath);
        chai.assert.deepEqual(chunk, originalChunk);
    });

    /// convert all chunks into big number arrays then write them into json files, then rebuild source file from the json files. 
    it('should convert all chunks into BN arrays in json then rebuild src file from arrays', () => {
        const inputFilePath = testFilePath;
        chunkLib.inputFileToBigNumberArrays(inputFilePath);
        const chunkFolder = chunkLib.getChunkFolder(inputFilePath);
        chunkLib.buildFileFromBigNumberArrays(chunkFolder, '../data/output.jpg');
        // compare the original file and the rebuilt file
        const originalFile = fs.readFileSync(inputFilePath);
        const rebuiltFile = fs.readFileSync('../data/output.jpg');
        chai.assert.deepEqual(originalFile, rebuiltFile);
        // remove the output file
        fs.unlinkSync('../data/output.jpg');
    });
    /// remove all chunks 
    after(() => {
        const inputFilePath = testFilePath;
        const chunkFolder = chunkLib.getChunkFolder(inputFilePath);
        const files = fs.readdirSync(chunkFolder);
        files.forEach((file) => {
            fs.unlinkSync(path.join(chunkFolder, file));
        });
        fs.rmdirSync(chunkFolder);
    });
});