the resest are the same 

### Purchase Request

When a customer want to buy some chunks of a content committed by `(CID, COM)`, it make a `Purchase Request` to Merchant. The request contain `(sk_payer, CID, COM, chunk_windows)`,which tell the merchant that **"I want to by content committed by `(CID, COM)`, and give me the decryption key `sk_payee` safely, by encypted `sk_payee` using `sk_payer`**. 

`chunk_windows` is a list of pairs like `[(2,4), (7, 11), (255, 1023)]`, each pair `(l, r)` indicates that "I want chunk with index from left index `l` to right index `r`". 

When the merchant received the request, it will return a `receipt` to cumstomer: 
- `Receipt`: 
    - `h_sk_payer = poseidon_hash(sk_payer)`: the ciminion secret key of buyers 
    - `h` : the sha256 hash of a preimage 
    - `COM`: the content that the payer wants. 
    - `COM_chunks`: a normal merkle root build on `chunk_windows`, where each pair in `chunk_windows` is a leaf. 
    - `Compensation`: the amount of compensation of this payment
    - `timestamp`: payment deadline for payer. 
    - `sig`: payee's signature of elements above

### Proof of Content Itegrity 
After the merchant return the `receipt`, Merchant will check the receipt and decide where execute the following steps or abandon this purchase. If cusomter decide goes on this payment, it will notify merchant to deliver the coresbonding `CTCs`, `{CID_i}` and two ordered Merkle multiproofs in `chunk_windows` to customer as the proof of content itergrity (`PoCI`), then customer will verify if two ordered merkle multiproofs are valid. 

### Proof of Fraud 

Once the merchant send the proof of delivery `PoD` on chain, the customer can decrypt `CT_sk_payee` using its own key `sk_payer`, get `sk_payee`. Then the  customer could decrypt the  `CTCs`, get `PTC's`. Then ther cusomter check if `hash(PTC_i') = CID_i' == CID_i`, if not, submit a proof of fraud. 

The proof of fraud `PoF` consist of `[CID_r', CID_r, COM_r, pi]`, the `pi` in `PoF` prove that: 
- `COM_r == poseidon_hash(CTC_r)` and 
- `Dec(sk_payer, CT_sk_payee) == sk_payee` and 
- `h_sk_payer == poseidon_hash(sk_payer)` and 
- `Dec(sk_payee, CTC_r) == PTC_r'` and 
- `h_sk_payee == poseidon_hash(sk_payee)` and 
- `CID_r' == poseidon_hash(PTC_r')`

Besides `PoF`, customer also includes two merkle paths which claim both `CID_r` and `COM_r` are leaves of `CID` and COM. 

`PoF` also includes a merkle path which claim the `r` is in the `COM_chunk`. detail: 
- `r``
- the pair `(l_r, r_r) where l_r<= r <=r_r` which includes `r`
- the merkle path 
Then the `Judge` will check if all above claims by: 
- verify two ordered merkle path 
- verify a normal merkle path for `COM_chunk`
- verify `PoF`
- check if `CID_r' == CID_r`