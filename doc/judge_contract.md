# Desigin of the bond contract in judge 

## Objective 

There are two main goal for Judge: 
- work as a hub holding the content commitments. 
- work as a Judge when the content creators fraud customers. 

## Background 
Every user (both merchants and customers) should have a identity keypair in Judge, just like any other blockchain system. `Judge` has two types of token, execution token `eToken` and deposit token `dToken`. `eToken` is used to pay the execution cost of `Judge`(like gas fee in ETH), where `dToken` is used as the security deposit. `eToken` and `dToken` do not have clear difference, we can use one particular token for both `eToken` and `dToken`. Every call to `Judge` should pay some `eToken` as transaction fee. 

## Interface
For data commitment phase, `Judge` provides following interface to merchants:
- **Create a store**: a merchant deposit some `dToken` and open a store. 
- **Commit a content**: a merchant push the content commitment along with the corresbonding data to `Judge`. an content commitment must attached to a store owned by this merchant. 
 
For Challenge phase, `Judge` provides: 
- **Sue a store**: any user can provide challenge evidence `CE` and the store that he wants to sue to the system. `Judge` will verify the evidence, if the evidence is right, it will set a new `case`, and set a timer for the merchant to defend itself. Once the timer timeout, the security deposit will be slashed and the user will be compensated based on preset configuration. 

## Implementation 

### Structures 
`Judge` storage: 
- `Judge` address
- `dToken` address 
- `Store list`: list of stores. 
- `Content list`: list content commitments. 
- `Case list`: list of undergoing cases. 
- `case number`: next case number. from zero. 

`Store`: 
- Creator Name: 
- owner's public key:  
- deposit amount: the security deposit. 
- potential punishiment: potential punishment amount. 
- state: current state of this store: 
    - "perfect": no case for this store
    - "great": `potential punishment <= 0.2 * total deposit`
    - "risky": `0.2 * total deposit < potential punishment <= 0.8 * total deposit`
    - "dangerous":  `potential punishment > 0.8 * total deposit`
    - "broken": `total deposit <= 0`. 

`Content commitments`: 
- `COM`: merkle root this the content. 
- price: content price in sats
- compenstation amount: the compensation that customer could get.
- fined amount: `x%` of the total fined will be transfered to `Judge`, and the rest will be burned. 
- store index in the `store list`. 
- warranty: the time window of this content receive could receive challenge, counted on blocks. 

Each case will be an object in `Judge`. Each case will maintain: 
- case id: a per
- `h_sk_payee`
- `h_sk_payer`
- `COM_r`
- store id
- compensation amount: 
- fine amount: 
- timeout height: the block height deadline for merchant to defend its self. 

`PoD` verification:a bool function take `(h_sk_payee, COM_r, h_sk_payer, CT_sk, proof)` as input. This function is stateless, and this function will store the verifier public data as verifier. 

### Functions
`create Judge`: set `dToken` address and `Judge` address. 

create_store
- Inputs: 
    - a `dToken` transfer from msg sender to `Judge` address. 
    - creator name: 
- Outputs: 
    - store id 
- Workflow: 
    - check transfer 
    - check transfer amount > 10 `dToken` for example
    - new a store object and add to the `store list`
    - return the store index


`create content`: 
- Inputs: 
    - store index 
    - content commitment `COM`
    - price
    - compensation amount
    - fine amount
    - warranty 
- Outputs: 
    - content index
- workflow: 
    - check ownership: msg sender must be the store owner. 
    - check amounts: `compensation amount + fine amount > store.deposit_amount - store.protential_punishment`
    - check `COM` format, must be a sha256 hash 
    - check warranty, must be more than 20 
    - build content 
    - update store mental data 
    - return content index 

`sue store`: 
- Inputs: 
    - store index
    - content index 
    - `COM_r`: a poseidon hash of r-th ciphertext chunk
    - merkle path: merkle path for `COM_r`
    - `PoP`: proof of purchase 
        - `Receipt`
            - `h_sk_payer = poseidon_hash(sk_payer)`: the ciminion secret key of customer 
            - `h` : the sha256 hash of a `preimage` 
            - `COM_r`
            - `timestamp`: payment deadline for the customer, counted on block. 
            - `sig`: merchants's signature of elements above
        - `preimage`: preimage of `h`
- Outputs: 
    - result
    - case id
- workflow: 
    - check signature: check sig is the correct sign from `store_list[store_index]`
    - check membership: computer the merkle result from `(COM_r,merkle_path)`, check if the merkle result equal to `content_list[content_index].COM`
    - check preimage: check if `h = sha256(preimage)`

