const Web3 = require("web3");
const web3 = new Web3();

/// build a merkle tree and return the merkle root
// input: an array of finie field elements COM_r in Fr in string format.
// output: the merkle root in Fr, in string.
// each leaf i = keccak256(input[i], i). input[i] should be converted to uint256 before hashing.
// the keccak256 from the web3 library is used here.
function MerkleRoot(COMs) {
    // caculate the leaves leaf_i = keccak256(input[i], i)
    let leaves = [];
    for (let i = 0; i < COMs.length; i++) {
        let temp = web3.utils.soliditySha3(
            { t: "uint256", value: COMs[i] },
            { t: "uint256", value: i }
        );
        leaves.push(temp);
    }
    // caculate the merkle root
    let root = leaves;
    // compare two child, smaller one on the left, larger one on the right
    // if the number of leaves is odd, duplicate the last leaf
    while (root.length > 1) {
        // make the number of leaves even
        if (root.length % 2 == 1) {
            root.push(root[root.length - 1]);
        }
        let temp = [];
        for (let i = 0; i < root.length; i = i + 2) {
            // smaller one on left
            let left = root[i];
            // larger one on right
            let right = root[i + 1];
            if (left > right) {
                // swap
                let temp = left;
                left = right;
                right = temp;
            }
            let hash = web3.utils.soliditySha3(
                { t: "uint256", value: left },
                { t: "uint256", value: right }
            );
            temp.push(hash);
        }
        root = temp;
    }
    return root[0];
}

/// verify merkle root
function MerkleRootVerify(COMr, root) {
    return root == MerkleRoot(COMr);
}
/// return the merkle path of r-th leaf and the root of COMs
function MerklePath(COMs, r) {
    let index = r;
    // caculate the leaves leaf_i = keccak256(input[i], i)
    let leaves = [];
    for (let i = 0; i < COMs.length; i++) {
        let temp = web3.utils.soliditySha3(
            { t: "uint256", value: COMs[i] },
            { t: "uint256", value: i }
        );
        leaves.push(temp);
    }
    let path = [];
    let root = leaves;
    while (root.length > 1) {
        // make the number of leaves even
        if (root.length % 2 == 1) {
            root.push(root[root.length - 1]);
        }
        let temp = [];
        for (let i = 0; i < root.length; i = i + 2) {
            // smaller one on left
            let left = root[i];
            // larger one on right
            let right = root[i + 1];
            if (left > right) {
                // swap
                let temp = left;
                left = right;
                right = temp;
            }
            let hash = web3.utils.soliditySha3(
                { t: "uint256", value: left },
                { t: "uint256", value: right }
            );
            temp.push(hash);
            // if index == i, add root[i+1] to the path
        }
        // if index is even, push root[index+1] to the path
        // else push root[index-1] to the path
        if (index % 2 == 0) {
            path.push(root[index + 1]);
        } else {
            path.push(root[index - 1]);
        }
        root = temp;
        index = index >> 1;
    }
    return path, root;
}

/// Verify Merkle path 
function MerklePathVerify(COMr,r, path, root) {
    // caculate leaf_r first 
    let leaf_r = web3.utils.soliditySha3(
        { t: "uint256", value: COMr },
        { t: "uint256", value: r }
    );
    // caculate the root from the path
    let root_from_path = leaf_r;
    for (let i = 0; i < path.length; i++) {
        let left = root_from_path;
        let right = path[i];
        if (left > right) {
            // swap
            let temp = left;
            left = right;
            right = temp;
        }
        root_from_path = web3.utils.soliditySha3(
            { t: "uint256", value: left },
            { t: "uint256", value: right }
        );
    }
    // compare with the given root 
    return root_from_path == root;
}

module.exports = {
    MerkleRoot,
    MerkleRootVerify,
    MerklePath,
    MerklePathVerify,
}