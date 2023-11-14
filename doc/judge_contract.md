# Design of the Bond Contract in Judge

## Objective

The Judge contract has two main goals:
- To act as a hub holding content commitments.
- To serve as a judge when content creators defraud customers.

## Background

Every user (both merchants and customers) must have an identity keypair in Judge, similar to other blockchain systems. Judge utilizes two types of tokens: the execution token (`eToken`) and the deposit token (`dToken`). `eToken` is used to pay for Judge's execution costs (akin to gas fees in Ethereum), while `dToken` is used as a security deposit. There is no strict distinction between `eToken` and `dToken`; a single token can serve both purposes. Every call to Judge incurs a transaction fee payable in `eToken`.

## Interface

For the data commitment phase, Judge provides the following interfaces to merchants:
- **Create a store**: A merchant deposits some `dToken` and opens a store.
- **Close a store**: The store is closed, and all contents from this store are set to "removed". The security deposit is locked for a buffer period until all potential cases are settled.
- **Withdraw a store**: After the buffer period, the merchant can withdraw the remaining deposit.
- **Upload content**: A merchant uploads the content commitment along with the corresponding data to Judge. A content commitment must be attached to a store owned by the merchant.
- **Remove content**: The content state is set to "removed".

For the challenge phase, Judge provides:
- **Sue a store**: Any user can submit challenge evidence (`CE`) and the store they wish to sue. Judge verifies the evidence, and if valid, initiates a new case and starts a timer for the merchant to defend themselves. If the timer expires, the security deposit is slashed, and the user is compensated according to a preset configuration.
- **Defend a case**: The store owner defends the case using `PoD`.

## Implementation

### Structures

`Judge` contract maintaint the following data strucuture: 
- Judge address
- Store list: A list of stores.
- Case list: A list of ongoing cases.
- Case number: The next case number, starting from zero.
- `store_2_contents map`: A hashmap from store index to a dynamic array of contents (`mapping(uint256 => uint256[])`).
- `case recorder`: A hashmap (`mapping((payment_hash, r) => bool)`).

`Judge` also has some pre-configed parameters, and all time are counted on block numbers: 
- `dToken` address: this define which `dToken` we use in this `Judge`. 
- `minimum deposit` amount: the minimum deposit amount for a new store. 
- `minimim fine amount`: the minimum fine amount for a content. 
- `fine burning rate`: define how many presentage of the fine will be burning. 
- `Offer time`: the upper bound of the time between a purchase offer to the LN payment settle time.
- `Warrenty Min`: minimum warrenty time for a content
- `Warrenty Max`: maxium warrenty time for a content
- `Defense DDL`: the time window for a storer owner to defend itself since the case begin. 
- `Compensation DDL`: the time window for the suer to get the compensation since case case settled. 
- `store exiting buffer time` the deposit locking time for a exiting store. `store exiting buffer time > Offer time + Warrenty Max + Defense DDL + Compensation DDL`

`Store`:
- Creator Name
- Owner's public key
- Deposit amount: The security deposit.
- Potential punishment: The potential punishment amount from all ongoing cases.
- Store state:
    - "open"
    - "to be closed"
    - "closed"
- Close time: The block height when merchants can withdraw the remaining security deposit.

`Content`:
- `COM`: The Merkle root of the content.
- Price: The content price in sats.
- Compensation amount: The compensation that a customer could receive.
- Fined amount: `x%` of the total fine will be transferred to Judge, and the rest will be burned.
- Store index in the `store list`.
- Warranty: The time window in which this content can receive challenges, counted in blocks.
- State: "onsale" or "removed".

Each case is an object in Judge, maintaining:
- Case ID
- `h_sk_payee`
- `h_sk_payer`
- `COM_r`
- Store ID
- Compensation amount
- Fine amount
- Timeout height: The block height deadline for the merchant to defend themselves.
- Compensation height: The deadline for the suer to withdraw compensation, after which the compensation is locked forever.


### Functions

`create Judge`:
- Sets the `dToken` address and Judge address.
- Sets the preset parameters. 

`create store`:
- Inputs:
    - A `dToken` transfer from the message sender to the Judge address.
    - Creator name.
- Outputs:
    - Store ID.
- Workflow:
    - Verify the transfer.
    - Ensure the transfer amount is greater than 10 `dToken`, for example.
    - Create a new store object and add it to the `store list`.
    - Return the store index.

`close store`:
- Workflow:
    - Verify ownership: The message sender must be the store owner.
    - Set all content to "removed".
    - Set the store state to "to be closed".
    - Set the close time, the `close time = current block height + store exiting buffer time`

`withdraw store`:
- Workflow:
    - Verify ownership.
    - Check if the current height is greater than the close time.
    - Set the store to "closed".
    - If there is a remaining security deposit, perform an ERC20 transfer from the Judge address to the store owner.

`create content`:
- Inputs:
    - Store index.
    - Content commitment `COM`.
    - Price.
    - Compensation amount.
    - Fine amount.
    - Warranty.
- Outputs:
    - Content index.
- Workflow:
    - Verify ownership: The message sender must be the store owner.
    - Check amounts: `compensation amount + fine amount` must be greater than `store.deposit_amount - store.potential_punishment`.
    - Validate `COM` format: It must be a SHA-256 hash.
    - Check warranty: It must be within a specified range as we set before. 
    - Create the content.
    - Update store metadata.
    - Return the content index.

`sue store`:
- Inputs:
    - User transfers a `challenge deposit` to Judge.
    - Store index.
    - Content index.
    - `COM_r`: a Poseidon hash of the r-th ciphertext chunk.
    - Merkle path: The Merkle path for `COM_r`.
    - `PoP`: Proof of purchase.
        - `Receipt`:
            - `h_sk_payer = poseidon_hash(sk_payer)`: The customer's commitment secret key.
            - `h`: The SHA-256 hash of a `preimage`.
            - `COM`.
            - `timestamp`: The payment deadline for the customer, counted in blocks.
            - `sig`: Merchant's signature of the elements above.
        - `preimage`: The preimage of `h`.
- Outputs:
    - Case ID.
- Workflow:
    - Check `case recorder`: If `PoP.h and PoP.r` is in the recorder, remove it.
    - Check warranty: Ensure `timestamp + warranty < current height`.
    - Verify `challenge deposit`, check if suer paid enough `challenge deposit`. 
    - Check store status: The store must not be "closed".
    - Validate signature: Check if the signature is correct from `store_list[store_index]`.
    - Check content: Verify if `receipt.COM` equals the `COM` on Judge.
    
    - Verify preimage: Check if `h = sha256(preimage)`.
    - Check membership: Compute the Merkle result from `(COM_r, merkle_path)` and verify if it equals `content_list[content_index].COM`.
    - Initiate a case based on the current context.
    - Add the case's payment hash `h` to the `case recorder`.
    - Set the case timeout height.
    - Update the store's amount.
    - Return the new case ID.

`PoD verify`:A Inner function which only called by `Judge`. This function is stateless and stores the verifier's public parameters as the verifier.
- Inputs: 
    - `h_sk_payee`
    - `h_sk_payer`
    - `COM_r`
    - `r`
    - `CT_sk`
    - `PoD` 
- Ouputs: 
    - Result in bool. 
- Workflow: 
    - verify the zk proof 

`defend case`:
- Inputs:
    - Case ID.
    - `PoD`.
- Outputs:
    - Result.
- Workflow:
    - Verify ownership: Only the store owner can call this function.
    - Locate the case using the case ID.
    - Generate public inputs for verification.
    - Run `PoD verify` to verify the `PoD`.
    - If verification passes:
        - Update the store's deposit amount.
        - Burn the `challenge deposit`.
        - Move the case data to the end of the case list and delete it.
    - If verification fails:
        - Set the compensation deadline.
        - Update the store's deposit amount.
        - Burn a portion of the fined deposit.

`get compensation`:
- Input: Case ID.
- Workflow:
    - Locate the case.
    - Verify ownership.
    - Check the defense timeout.
    - Check the compensation timeout.
    - Transfer (challenge deposit + compensation amount) from Judge to the suer.
    - Delete the case.