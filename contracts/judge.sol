// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract Judge {
    IERC20 public dToken;
    address public judgeAddress;
    uint256 public min_deposit = 10; 
    uint256 public challengeDepositAmount = 10;
    struct Store {
        string creatorName;
        address owner;
        uint256 depositAmount;
        uint256 potentialPunishment;
        string state;
        uint256 closeTime;
    }

    struct Content {
        bytes32 COM;
        uint256 price;
        uint256 compensationAmount;
        uint256 finedAmount;
        uint256 storeIndex;
        uint256 warranty;
        string state;
    }

    struct Case {
        uint256 id;
        bytes32 h_sk_payee;
        bytes32 h_sk_payer;
        bytes32 COM_r;
        uint256 storeId;
        uint256 compensationAmount;
        uint256 fineAmount;
        uint256 timeoutHeight;
        uint256 compensationHeight;
    }

    Store[] public storeList;
    Content[] public contentList;
    Case[] public caseList;
    uint256 public nextCaseNumber = 0;


    mapping(uint256 => uint256[]) public storeToContents;
    // k = sha256(COM, h) v = bool 
    mapping(bytes32 => bool) public caseRecorder;

    constructor(address _dTokenAddress) {
        dToken = IERC20(_dTokenAddress);
        judgeAddress = msg.sender;
    }

    function createStore(string memory creatorName) external returns (uint256 storeIndex) {
        require(dToken.transferFrom(msg.sender, address(this), min_deposit), "dToken transfer failed");

        Store memory newStore = Store({
            creatorName: creatorName,
            owner: msg.sender,
            depositAmount: 10 ether, // Example deposit amount
            potentialPunishment: 0,
            state: "open",
            closeTime: 0
        });

        storeIndex = storeList.length;
        storeList.push(newStore);
        return storeIndex;
    }

    function closeStore(uint256 storeIndex) external {
        Store storage store = storeList[storeIndex];
        require(store.owner == msg.sender, "Only the owner can close the store");
        require(keccak256(bytes(store.state)) == keccak256(bytes("open")), "Store must be open");

        uint256[] storage contents = storeToContents[storeIndex];
        for (uint256 i = 0; i < contents.length; i++) {
            contentList[contents[i]].state = "removed";
        }

        store.state = "to be closed";
        store.closeTime = block.number + 100; // Example buffer period
    }

    function withdrawStore(uint256 storeIndex) external {
        Store storage store = storeList[storeIndex];
        require(store.owner == msg.sender, "Only the owner can withdraw from the store");
        require(block.number > store.closeTime, "Buffer period has not ended");
        require(keccak256(bytes(store.state)) == keccak256(bytes("to be closed")), "Store must be ready to close");

        store.state = "closed";
        uint256 remainingDeposit = store.depositAmount - store.potentialPunishment;
        if (remainingDeposit > 0) {
            require(dToken.transfer(msg.sender, remainingDeposit), "dToken transfer failed");
        }
    }

    function createContent(
        uint256 storeIndex,
        bytes32 COM,
        uint256 price,
        uint256 compensationAmount,
        uint256 fineAmount,
        uint256 warranty
    ) external returns (uint256 contentIndex) {
        Store storage store = storeList[storeIndex];
        require(store.owner == msg.sender, "Only the owner can create content");
        require(compensationAmount + fineAmount <= store.depositAmount - store.potentialPunishment, "Insufficient deposit");

        // Validate COM format and warranty range, omitted for brevity

        Content memory newContent = Content({
            COM: COM,
            price: price,
            compensationAmount: compensationAmount,
            finedAmount: fineAmount,
            storeIndex: storeIndex,
            warranty: warranty,
            state: "onsale"
        });

        contentIndex = contentList.length;
        contentList.push(newContent);
        storeToContents[storeIndex].push(contentIndex);
        return contentIndex;
    }

    function sueStore(
        uint256 storeIndex,
        uint256 contentIndex,
        bytes32 COM_r,
        bytes32[] calldata merklePath,
        bytes32 h_sk_payer,
        bytes32 h,
        bytes32 COM,
        uint256 timestamp,
        bytes calldata sig,
        bytes32 preimage
    ) external returns (uint256 caseId) {
        require(dToken.transferFrom(msg.sender, address(this), challengeDepositAmount), "Challenge deposit failed");

        Store storage store = storeList[storeIndex];
        require(keccak256(bytes(store.state)) != keccak256(bytes("closed")), "Store is closed");

        Content storage content = contentList[contentIndex];
        require(content.COM == COM, "Content commitment mismatch");
        require(timestamp + content.warranty < block.number, "Warranty period has expired");
        require(h == sha256(abi.encodePacked(preimage)), "Invalid preimage");

        // Validate the signature and merkle path
        verifyMerkle(COM_r, merklePath, COM);


        caseId = nextCaseNumber++;
        Case memory newCase = Case({
            id: caseId,
            h_sk_payee: h_sk_payer, // Assuming h_sk_payee is a typo and should be h_sk_payer
            h_sk_payer: h_sk_payer,
            COM_r: COM_r,
            storeId: storeIndex,
            compensationAmount: content.compensationAmount,
            fineAmount: content.finedAmount,
            timeoutHeight: block.number + 100, // Example timeout height
            compensationHeight: 0 // To be set when the case is defended or times out
        });

        caseList.push(newCase);
        caseRecorder[h] = true;
        store.potentialPunishment += content.finedAmount;
        return caseId;
    }

    function defendCase(uint256 caseId, bool isValidProof) external {
        // In a real-world scenario, you would replace `isValidProof` with actual proof verification
        require(isValidProof, "Proof of defense is not valid");

        Case storage caseItem = caseList[caseId];
        Store storage store = storeList[caseItem.storeId];
        require(store.owner == msg.sender, "Only the store owner can defend the case");

        if (isValidProof) {
            store.depositAmount -= caseItem.fineAmount;
            dToken.transfer(judgeAddress, caseItem.fineAmount); // Transfer fine to Judge

            // Close the case
            delete caseList[caseId];
        } else {
            // Set the compensation deadline
            caseItem.compensationHeight = block.number + 100; // Example compensation deadline
            store.depositAmount -= caseItem.fineAmount;
            dToken.transfer(judgeAddress, caseItem.fineAmount * 10 / 100); // Assuming x% is 10%
            // Burn the rest of the fined deposit, omitted for brevity
        }
    }

    function getCompensation(uint256 caseId) external {
        Case storage caseItem = caseList[caseId];
        require(caseItem.compensationHeight > block.number, "Compensation period has expired");
        require(caseRecorder[caseItem.h_sk_payee], "Case not recorded");

        // Assuming the suer's address is somehow verified or recorded, omitted for brevity
        dToken.transfer(msg.sender, challengeDepositAmount + caseItem.compensationAmount);
        delete caseList[caseId];
    }
}

function verifyMerkle( bytes32 leaf, bytes32[] calldata path, bytes32 root){
    bytes32 computedHash = leaf;
    for (uint256 i = 0; i < path.length; i++) {
        bytes32 proofElement = path[i];

        if (computedHash < proofElement) {
            // Hash(current computed hash + current element of the proof)
            computedHash = sha256(abi.encodePacked(computedHash, proofElement));
        } else {
            // Hash(current element of the proof + current computed hash)
            computedHash = sha256(abi.encodePacked(proofElement, computedHash));
        }
    }

    // Check if the computed hash (root) is equal to the provided root
    assert(computedHash == root);
}
