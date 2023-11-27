const chunkLib = require('../scripts/chunk.js');
const chai = require("chai");
// test the chunk functions 

describe('chunk functions', () => {
    it('getChunkFolder', () => {
        const inputFilePath = 'tests/test.txt';
        const chunkFolder = chunkLib.getChunkFolder(inputFilePath);
        assert.equal(chunkFolder, 'tests/test');
    });

    it('divideIntoChunks', () => {
        const inputFilePath = 'tests/test.txt';
        const chunks = chunkLib.divideIntoChunks(inputFilePath);
        assert.equal(chunks.length, 1);
    });

    it('divideIntoChunks', () => {
        const inputFilePath = 'tests/test.txt';
        const chunks = chunkLib.divideIntoChunks(inputFilePath);
        assert.equal(chunks.length, 1);
    });

    it('divideIntoChunks', () => {
        const inputFilePath = 'tests/test.txt';
        const chunks = chunkLib.divideIntoChunks(inputFilePath);
        assert.equal(chunks.length, 1);
    });

    it('divideIntoChunks', () => {
        const inputFilePath = 'tests/test.txt';
        const chunks = chunkLib.divideIntoChunks(inputFilePath);
        assert.equal(chunks.length, 1);
    });

    it('divideIntoChunks', () => {
        const inputFilePath = 'tests/test.txt';
        const chunks = chunkLib.divideIntoChunks(inputFilePath);
        assert.equal(chunks.length, 1);
    });

    it('divideIntoChunks', () => {
        const inputFilePath = 'tests/test.txt';
        const chunks = chunkLib.divideIntoChunks(inputFilePath);
        assert.equal(chunks.length, 1);
    });

    it('divideIntoChunks', () => {
        const inputFilePath = 'tests/test.txt';
        const chunks = chunkLib.divideIntoChunks(inputFilePath);
        assert.equal(chunks.length, 1);
    });

    it('divideIntoChunks', () => {
        const inputFilePath = 'tests/test.txt';
        const chunks = chunkLib.divideIntoChunks(inputFilePath);
        assert.equal(chunks.length, 1);
    });
});