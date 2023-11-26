// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./verify.sol"; 
interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}



contract Judge {
    IERC20 public dToken;
    address public judgeAddress;
    uint256 public minDeposit = 10; 
    uint256 public challengeDepositAmount = 10;
    uint256 public storeBufferTime = (1 + 7 + 3 + 3 + 1) * 24 * 60 * 5; // 14 days blocks
    uint256 public minWarranty = 3 * 24 * 60 * 5; // 3 days blocks
    uint256 public maxWarranty = 7 * 24 * 60 * 5; // 7 days blocks
    uint256 public challengeTime = 3 * 24 * 60 * 5; // 3 days blocks
    enum StoreState {
        Open,
        ToBeClosed,
        Closed
    }
    enum ContentState{
        OnSale,
        Removed
    }
    struct Store {
        string creatorName;
        address owner;
        uint256 depositAmount;
        uint256 potentialPunishment;
        StoreState state;
        uint256 closeTime;
    }

    struct Content {
        bytes32 COM;
        uint256 price;
        uint256 compensationAmount;
        uint256 finedAmount;
        uint256 storeIndex;
        uint256 warranty;
        ContentState state;
    }

    struct Case {
        uint256 id;
        bytes32 h_sk_payee;
        bytes32 h_sk_payer;
        bytes32 COM_r;
        uint256 r; 
        uint256 storeId;
        uint256 compensationAmount;
        uint256 fineAmount;
        uint256 timeoutHeight;
        uint256 compensationHeight;
        address suer; 
    }

    Store[] public storeList;
    Content[] public contentList;
    Case[] public caseList;
    uint256 public nextCaseNumber = 0;


    mapping(uint256 => uint256[]) public storeToContents;
    // k = h v = bool 
    mapping(bytes32 => bool) public caseRecorder;

    constructor(address _dTokenAddress) {
        dToken = IERC20(_dTokenAddress);
        judgeAddress = address(this); 
    }

    function createStore(string memory creatorName, uint256 depositAmount) external returns (uint256 storeIndex) {
        require(depositAmount > minDeposit, "Deposit is less than required");
        // get the total transfered dToken amount 
        uint256 allowedAmount = dToken.allowance(msg.sender, judgeAddress );
        require(allowedAmount >= depositAmount, "Not enough tokens approved for transfer");
        // transfer enough dToken to judgeAddress
        require(dToken.transferFrom(msg.sender, judgeAddress, depositAmount), "Token transfer failed");

        Store memory newStore = Store({
            creatorName: creatorName,
            owner: msg.sender,
            depositAmount: depositAmount, // Example deposit amount
            potentialPunishment: 0,
            state: StoreState.Open,
            closeTime: 0
        });

        storeIndex = storeList.length;
        storeList.push(newStore);
        return storeIndex;
    }
    function fundStore(uint256 storeIndex, uint256 amount) external {
        Store storage store = storeList[storeIndex];
        require(store.owner == msg.sender, "Only the owner can fund the store");
        require(store.state == StoreState.Open, "Store must be open");
        // get the total transfered dToken amount 
        uint256 allowedAmount = dToken.allowance(msg.sender, judgeAddress );
        require(allowedAmount >= amount, "Not enough tokens approved for transfer");
        // transfer enough dToken to judgeAddress
        require(dToken.transferFrom(msg.sender, judgeAddress, amount), "Token transfer failed");
        store.depositAmount += amount;
    }

    function closeStore(uint256 storeIndex) external {
        Store storage store = storeList[storeIndex];
        require(store.owner == msg.sender, "Only the owner can close the store");
        require(store.state == StoreState.Open,  "Store must be open");
        // get contents index 
        uint256[] storage contents = storeToContents[storeIndex];
        for (uint256 i = 0; i < contents.length; i++) {
            contentList[contents[i]].state = ContentState.Removed;
        }

        store.state = StoreState.ToBeClosed;
        store.closeTime = block.number + storeBufferTime; // Example buffer period
    }

    function withdrawStore(uint256 storeIndex) external {
        Store storage store = storeList[storeIndex];
        require(store.owner == msg.sender, "Only the owner can withdraw from the store");
        require(block.number > store.closeTime, "Buffer period has not ended");
        require(store.state == StoreState.ToBeClosed, "Store must be ready to close");

        store.state = StoreState.Closed;
        // all case should be settled, so the potentialPunishment should be 0. 
        uint256 remainingDeposit = store.depositAmount;
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
        // ownership check
        require(store.owner == msg.sender, "Only the owner can create content");
        // deposit check
        require(compensationAmount + fineAmount <= store.depositAmount - store.potentialPunishment, "Insufficient deposit");
        // warrenty check 
        require(warranty >= minWarranty && warranty <= maxWarranty, "Invalid warranty period");
        // fineAmount and compenstation amount > 0 
        require(fineAmount > 0 && compensationAmount > 0, "Invalid fine or compensation amount");

        Content memory newContent = Content({
            COM: COM,
            price: price,   // price in satoshis
            compensationAmount: compensationAmount,
            finedAmount: fineAmount,
            storeIndex: storeIndex,
            warranty: warranty,
            state: ContentState.OnSale
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
        uint256 r, 
        bytes memory sig,
        bytes32 preimage
    ) external returns (uint256 caseId) {
        // check store first 
        Store storage store = storeList[storeIndex];
        require(store.state != StoreState.Closed , "Store is closed");
        
        // check if the case has been recorded
        bytes32 caseKey = keccak256(abi.encodePacked(COM, h));
        require(!caseRecorder[caseKey], "Case already recorded");

        // check allowance and transfer 
        uint256 allowedAmount = dToken.allowance(msg.sender, judgeAddress );
        require(allowedAmount >= challengeDepositAmount, "Not enough tokens approved for transfer");
        require(dToken.transferFrom(msg.sender, judgeAddress, challengeDepositAmount), "Token transfer failed");

        // check signature
        require(VerifyLib.verifyReceiptSig(h_sk_payer, h, COM, timestamp, sig, msg.sender), "Invalid signature");
        
        //check content 
        Content storage content = contentList[contentIndex];
        require(content.COM == COM, "Content commitment mismatch");
        require(timestamp + content.warranty < block.number, "Warranty period has expired");
        require(h == sha256(abi.encodePacked(preimage)), "Invalid preimage");

        // Validate merkle path
        require(VerifyLib.verifyMerkle(COM_r,r, merklePath, COM), "Invalid merkle path");

        caseId = nextCaseNumber++;
        Case memory newCase = Case({
            id: caseId,
            h_sk_payee: h_sk_payer, // Assuming h_sk_payee is a typo and should be h_sk_payer
            h_sk_payer: h_sk_payer,
            COM_r: COM_r,
            r: r, 
            storeId: storeIndex,
            compensationAmount: content.compensationAmount,
            fineAmount: content.finedAmount,
            timeoutHeight: block.number + challengeTime, // Example timeout height
            compensationHeight: 0, // To be set when the case is defended or times out
            suer: msg.sender
        });

        caseList.push(newCase);
        caseRecorder[h] = true;
        store.potentialPunishment += content.finedAmount;
        store.potentialPunishment += content.compensationAmount;
        return caseId;
    }

    function defendCase(
        uint256 caseId, 
        uint[2] calldata _pA, 
        uint[2][2] calldata _pB, 
        uint[2] calldata _pC, 
        uint[8] calldata _pubSignals
        ) external {
            // locate case by range the case list, cause the caseID not always match the index of caseList
            Case memory c;
            for (uint256 i = 0; i < caseList.length; i++) {
                if (caseList[i].id == caseId) {
                    c = caseList[i];
                    break;
                }
            }
            // get store 
            Store memory store = storeList[c.storeId];
            // check ownership 
            require(store.owner == msg.sender, "Only the store owner can defend the case");
            // check case state 
            require(c.compensationHeight == 0, "Case has already been defended or timed out");

            bool isValidProof = VerifyLib.verifyPoD(c.h_sk_payer, c.h_sk_payee, c.COM_r, c.r, _pA, _pB, _pC, _pubSignals);
            // In a real-world scenario, you would replace `isValidProof` with actual proof verification
            require(isValidProof, "Proof of defense is not valid");

            
            require(store.owner == msg.sender, "Only the store owner can defend the case");

            if (isValidProof) {
                store.depositAmount -= c.fineAmount;
                dToken.transfer(judgeAddress, c.fineAmount); // Transfer fine to Judge

                // Close the case
                delete caseList[caseId];
            } else {
                // Set the compensation deadline
                c.compensationHeight = block.number + 100; // Example compensation deadline
                store.depositAmount -= c.fineAmount;
                dToken.transfer(judgeAddress, c.fineAmount * 10 / 100); // Assuming x% is 10%
                // Burn the rest of the fined deposit, omitted for brevity
        }
    }

    function getCompensation(uint256 caseId) external {
        Case storage c = caseList[caseId];
        //check ownership 
        require(c.suer == msg.sender, "Only the suer can get compensation");
        require(c.compensationHeight > block.number, "Compensation period has expired");
        require(caseRecorder[c.h_sk_payee], "Case not recorded");

        // Assuming the suer's address is somehow verified or recorded, omitted for brevity
        dToken.transfer(msg.sender, challengeDepositAmount + c.compensationAmount);
        delete caseList[caseId];
    }
    
}




