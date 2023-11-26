// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./zk_verify.sol"; 

library VerifyLib {
    function verifyMerkle(
        bytes32 COM_r,
        uint256 r,
        bytes32[] calldata path,
        bytes32 root
    ) internal pure returns (bool) {
        bytes32 computedHash = COM_r;
        // first hash(COM_r || r)
        computedHash = keccak256(abi.encodePacked(computedHash, r));
        for (uint256 i = 0; i < path.length; i++) {
            bytes32 proofElement = path[i];
            // compare size, smaller one in the front
            if (computedHash < proofElement) {
                // hash(current computed hash + current element of the path)
                computedHash = keccak256(
                    abi.encodePacked(computedHash, proofElement)
                );
            } else {
                // hash(current element of the path + current computed hash)
                computedHash = keccak256(
                    abi.encodePacked(proofElement, computedHash)
                );
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }

    function getReceiptHash(
        bytes32 h_sk_payer, 
        bytes32 h, 
        bytes32 COM, 
        uint256 timestamp
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(h_sk_payer, h, COM, timestamp));
    }
    function getEthSignedMessageHash(
        bytes32 _messageHash
    ) public pure returns (bytes32) {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash)
            );
    }

    function verifyReceiptSig(
        bytes32 h_sk_payer, 
        bytes32 h, 
        bytes32 COM, 
        uint256 timestamp,
        bytes memory signature,
        address _signer
    ) public pure returns (bool) {
        bytes32 messageHash = getReceiptHash(h_sk_payer, h, COM, timestamp);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature) == _signer;
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(
        bytes memory sig
    ) public pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }

    // verify PoD 
    function verifyPoD(
        bytes32 h_sk_payer, 
        bytes32 h_sk_payee, 
        bytes32 COM_r, 
        uint256 r,
        uint[2] calldata _pA, 
        uint[2][2] calldata _pB, 
        uint[2] calldata _pC, 
        uint[8] calldata _pubSignals
    ) public view returns (bool) {
        // in _publicSignals: 
        // [0:4) is the ciphertext of circom pod64 
        // 4: COM_r 
        // 5: r
        // 6: h_sk_payer
        // 7: h_sk_payee

        // check public Signals first 
        require(_pubSignals[4] == uint256(COM_r), "COM_r not match");
        require(_pubSignals[5] == r, "r not match");
        require(_pubSignals[6] == uint256(h_sk_payer), "h_sk_payer not match");
        require(_pubSignals[7] == uint256(h_sk_payee), "h_sk_payee not match");

        // check zk proof
        return PoDVerifier.verifyProof(_pA, _pB, _pC, _pubSignals);
    }
}
