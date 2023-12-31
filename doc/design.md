
# Atom Buy: A Decentralized Framework for Trustless and Atomic Content Transactions on the Lightning Network

> **Abstract**: We introduce Atom Buy, a framework designed to facilitate trustless and atomic transactions for digital content purchases over the Lightning Network. Our proposed scheme ensures accountability for all digital content and enables each transaction to be atomic and verifiable through the application of cryptographic primitives such as Zero-Knowledge Proofs (ZKP). Furthermore, we leverage blockchain technology to safeguard each purchase and to monitor and address any instances of misconduct.

## Introduction 

### Problem we want to solve
In the landscape of paid content distribution, both centralized content platforms and independent distribution by content creators present distinct challenges.

The drawbacks of using centralized platforms for paid content sharing — such as academic paper repositories, knowledge paywalls, and sites like OnlyFans — are significant and multifaceted:

- **Trust and Dependency on the Platform**: Content creators (merchants) are forced to place their trust in these platforms, which pose a risk of content leakage. Meanwhile, platforms retain control over the content and users' data, limiting creators' direct relationship with their audience and complicating efforts to move to other distribution methods or platforms.
- **Censorship**: Centralized platforms have the authority to censor content and users, which can be based on a variety of factors, often opaque and outside the control of the content creators and consumers. This can lead to a suppression of freedom of expression and access to information.
- **Fees and Revenue Sharing**: These platforms often take a substantial cut of the creators' earnings, which can greatly reduce the profit margin for the creators. 

In contrast, independent distribution methods that creators might use, like mailing lists or personal websites, have their own set of challenges: **Trust and Verification**: Without the reputation and the protection of a known platform, creators must build trust with their audience from scratch. Consumers might be hesitant to purchase from an unknown source without the assurance of quality and delivery.

### What we aim to build

To tackle the aforementioned issues, we propose a decentralized paid content distribution (DPCD) framework. Our system ensures:

- **Content Pre-commitment**: Every piece of content that merchants wish to sell is pre-committed to a trustless third party. Customers can verify the content before completing the purchase.
- **Atomic Purchase**:The delivery of your digital content is secured by our dependable system once you make the payment. 
- **Guaranteed Compensation**: Should merchant misconduct occur, our system holds the merchants responsible and guarantees that customers receive appropriate compensation.

Leveraging this framework, we can create a range of decentralized counterparts to Web2 services, circumventing the pitfalls of centralization.  Furthermore, the Atomic Buy itself can serve as an incentivization layer within existing content distribution applications such as Nostr, IPFS, and BitTorrent.

## Overview  

![structure](./trans.png)

Atomic Buy is inspired by the scenario of a traditional Web2 e-commerce platform, where merchants are required to deposit funds as a form of security when they wish to open a store on platforms like Amazon or Taobao. If customers feel they have been treated unfairly, they can request the platform to adjudicate any alleged misconduct by the merchant.

In our trustless and decentralized model, the "platform"'s Job is substituted by three components: **content relay network**, **payment network** and **Judge**. 

**Content relay network** will become the comminication layer between merchants and customers, distributing content infomation from merchants to customers. Depending on the usecase, we could use different relay network. For example, to build the decentralized vertsion of Onlyfans, Medium, we could use relay network like Nostr, which provides async routine service for both public and private message in a decentralized manner. If we want build a decentralized academic database, We could use service like Arweave, IPFS as the content storage, and any other message service for private commuication between merchants(content creators) and customers. 

**Payment network** is where users pay some cryptocurrency to the merchants, and generate a veriable proof of purchase "I spent x money for product(content) C". The proof of purchase is the primitives for `Judge` esttle the arguments between merchants and customers. In our implementation, we use Lightning Network as the payment network, as it can easily settle a `PoP` lighting fast without onchain verification. 


**Judge** is a accountable and verifable third party, which is secured by a blockchain L1/L2. `Judge` can be a smart contract deployed on any L1/L2, or be a L3 protected by L1/L2 through rollup methods. Similar to a conventional e-commerce platform, merchants are obliged to place a deposit on `Judge`, which holds them accountable in cases of wrongdoing. And `Judge` can detect and punish those who cheat in a content purchase, which make the purchase trustless for customers. 

## Primitives 


### Ciminion

[Ciminion](https://eprint.iacr.org/2021/267), a zk-friendly symmetric Encryption system. All inputs and outputs are numbers in finite field P(`FFP`). the plaintext number must be even. 
- Encryption: `Enc()`
    - Inputs: 
        - `master key 1`
        - `master key 2`
        - `nonce`
        - `IV`
        - `plaintext[N * 2]`
    - Outputs: 
        - `ciphertext[N*2]`
        - `MAC`: message authetication code 

- Decryption: `Dec()`
    - Inputs: 
        - `master key 1`
        - `master key 2`
        - `nonce`
        - `IV`
        - `CT`: `ciphertext[N * 2]`
    - Outputs: 
        - `PT`: `plaintext[N*2]`
We define a set of secret key `sk = [master key 1, master key 2, nonce, IV]`, and we denote alice's `sk` as `sk_alice`. 

### Hash 
We use two different hash functions in our system: 
- Poseidon hash: a zk-friendly hash function, we use this hash function when we need to prove the ownership of perimages.  
- Sha256: the hash function used in HTLC contracts in the Lightning Network.               
- Keccak256: an evm native gas-efficient hash function.                  

## Terminology 

Important terminology to understand our system. 

### Content Commitment 

Merchants commits digital contents in `Judge`. 

Every payee(merchant) and payer(customer) has its own reusable ECDSA identity key pairs `ek = (esk, epk)`. This is used to verify the identity of payees and payers. Besides payee will generate a new ciminion symmetric encryption key`sk_payee` pair for content commitment. 

For a digital content(as a vector of bytes) `C` we can parse the content to plaintext `PT`(presented by big numbers) in a finite field like BN-254. Then we divides `PT` in to fixed sized `PT` chunks `PTC`.(like 512 numbers per `PTC`). 

![](/doc/file_div.png)

After plaintext division, we generate cominion keys to encrypt each chunk `PTC_i` to ciphertext chunk `CTC_i`. For each `PTC_i`, we will derive a secret key `sk_payee_i` to encrypt this chunk by tunning the nonce of `sk_payee`. `sk_payee_i <= sk_payee` and `sk_i.nonce <= poseidon_hash(sk.nonce, i)`. ciphertext chunk i `CTC_i = Enc(sk_payee_i, PT_i).CT `. 

We define `CID_i` as the identity of content chunk `PTC_i`, where `CID_i =  poseidon_hash(PTC_i)`
Then we build a **ordered merkle tree** from `CID_i` using Keccak256, where leaf i is `Keccak256(CID_i || i)`, generating the merkle root hash `COM`. The merkle path of this tree not only provides the membership proof but also provides the position information for a `CID_i`, binding `(CID_i, i)` together. 

For each `CTC_i`, we define ciphertext chunk commitment `COM_i`, where `COM_i = poseidon_hash(CTC_i)`. We build the `COM` using the same method we used to bulid `CID`. 

Finally we define hybrid ID `HID`, where `HID` is the ordered merkle root of `HID_i`, where `HID_i= poseidon_hash(CID_i, COM_i, i)`. 
![](/doc/enc.png)

Any merchant can commit a content `C` to`Judge` by pushing the (`epk_payee`, `CID`, `COM`, `h_sk = poseidon_hash(sk_payee)`) to it. This send a commitment **"I have a content represented by `CID` encrypted by `sk_payee`**. 


### Purchase Request

When a customer want to buy some content committed by `(CID, COM)`, it make a `Purchase Request` to Merchant. The request contain `(sk_payer, CID, COM)`,which tell the merchant that **"I want to by content committed by `(CID, COM)`, and give me the decryption key `sk_payee` safely, by encypted `sk_payee` using `sk_payer`**. 

When the merchant received the request, it will return a `receipt` to cumstomer: 
- `Receipt`: 
    - `h_sk_payer = poseidon_hash(sk_payer)`: the ciminion secret key of buyers 
    - `h` : the sha256 hash of a preimage 
    - `COM`: the content that the payer wants. 
    - `Compensation`: the amount of compensation of this payment
    - `timestamp`: payment deadline for payer. 
    - `sig`: payee's signature of elements above

Merchant-customer may need several rounds of communication to settle the purchase compensation and price. 

### Proof of Content Itegrity 
After the merchant return the `receipt`, Merchant will check the receipt and decide where execute the following steps or abandon this purchase. If cusomter decide goes on this payment, it will notify merchant to deliver the `CTCs` and all `{CID_i}`to customer as the proof of content itergrity (`PoCI`), then customer will verify: 
- `CID`: if `CID` is the ordered merkle root of `{CID_i}`
- `COM`: if `HID` is the ordered merkle root of `{COM_i}`

### Proof of Purchase

The proof of purchase proves that **"I have paid enough money for content `C`"**.
In lightning network, a payment is settled when the sha256 hash `h` of a preimage revealing to the payer. 

The proof of Purchase `PoP` consists of two following parts: 
- `Receipt`
- `pre-image`: preimage of `h`

`Judge` can verify this prove by verfity that if: `sign_{k_sk_payee}(h_sk_payer, h, timestamp) == sig && sha256(pre-image) == h`. 

### Challenge 

Upon settling the bill, the payer expects the payee to provide the decryption keys (`sk_payee`), which are used to decrypt `CTCs`. Should the payer not receive the correct keys as anticipated, they have the option to appeal to a Judge for resolution, akin to contacting customer service in real-life scenarios. This procedure is referred as a **challenge**.

During the challenge phase, the payer must submit the proof of payment to `Judge`. 

The submission to the Judge conveys the following message: **"I have remitted payment for the content (CID, COM), and I request the seller to provide the decryption keys to me."**

Upon receiving the challenge request from the customer, the Judge is tasked with validating the request by:

- Verifying the proof of payment (`PoP`).

### Proof of Delivery 

Once a payee find someone `challenge` him, he payee must proof it has delivered the content to `Judge`. 


![](/doc/pod.png)
We denoted the claim of delivery as `CoD`, where `CoD(public h_sk_payer, public h_sk_payee, sk_payee, sk_payer, PTC_r) -> CT_sk ` will claim: 
- `poseidon_hash(sk_payee) == h_sk_payee` and 
- `Enc(sk_payer, sk_payee).CT = CT_sk` and 
- `poseidon_hash(sk_payer) == h_sk_payer` 

In human readable word, this claim that **"I will send you `sk_payee`, which is the same key that I committed in `Judge`; The secret key(`sk_payee`) can encrypt the plaintext chunks into ciphertext chunks; We deliver the right key `sk_payee` encrypted by customer key provided before(committed by `h_sk_payer`)."**
The proof of `CoD` is denoted as `PoD`, which is generated using Groth16 in Circom and Snarkjs. 

Judge can verify the `PoD` by querying `h_sk_payer, h_sk_payee` from the the `Judge`. 

### Proof of Fraud 

Once the merchant send the proof of delivery `PoD` on chain, the customer can decrypt `CT_sk_payee` using its own key `sk_payer`, get `sk_payee`. Then the  customer could decrypt `CTCs`, get `PTC's`. Then ther cusomter check if `hash(PTC_i') = CID_i' == CID_i`, if not, submit a proof of fraud. 

The proof of fraud `PoF` consist of `[CID_r', CID_r, COM_r, pi]`, the `pi` in `PoF` prove that: 
- `COM_r == poseidon_hash(CTC_r)` and 
- `Dec(sk_payer, CT_sk_payee) == sk_payee` and 
- `h_sk_payer == poseidon_hash(sk_payer)` and 
- `Dec(sk_payee, CTC_r) == PTC_r'` and 
- `h_sk_payee == poseidon_hash(sk_payee)` and 
- `CID_r' == poseidon_hash(PTC_r')`

Besides `PoF`, customer also includes two merkle paths which claim both `CID_r` and `COM_r` are leaves of `CID` and COM. 
Then the `Judge` will check if all above claims by: 
- verify two ordered merkle path 
- verify `PoF`
- check if `CID_r' == CID_r`

## Workflow 

![workflow](./design.png)


We seperate the whole process into 4 phases: 
- **Phase One**: Content Registration. Merchants must register their content and its price on `Judge`, along with depositing some funds. This holds the merchants accountable. Additionally, merchants are required to create a Proof of Content (PoC) for the content. Subsequently, merchants can distribute the encrypted content and `PoC` on any platform such as Twitter or Nostr. Potential customers can then verify the content's quality and ensure that the ciphertext they receive corresponds with the content committed on Judge.
- **Phase Two**: Payment Settlement. Leveraging the advantages of the Lightning Network (LN), a payment proof PoP ("alice pays x satoshis for content `c` before time `T`") can be established solely between the merchant and customer. Should any issues arise, the customer can present the `PoP` to Judge for resolution.
- **Phase Three**: Content delivery: Once the merchant believe that the bill has been payment, it need to delivery the key that can unlocked the ciphertext ASAP to the customer in any message routine platform. 
- **Phase Four**:  Challenge. The challenge phase ensures that keys are delivered to the customer via Judge. Merchants are required to construct a Proof of Delivery (PoD) to verify the delivery of keys. Failure to provide a `PoD` within the stipulated timeframe results in penalties imposed by Judge on the merchant and compensation awarded to the customer. For the safety of this protocol, the customer has the chance to upload the proof of fraud to `Judge`, if the keys provided by merchant cannot unlock all ciphertexts `CTCs`. 

## Bond Contract in Judge 

The Judge contract has two main goals:
- To act as a hub holding content commitments.
- To serve as a judge when content creators defraud customers.

### Requirements

Every user (both merchants and customers) must have an identity keypair in Judge, similar to other blockchain systems. Judge utilizes two types of tokens: the execution token (`eToken`) and the deposit token (`dToken`). `eToken` is used to pay for Judge's execution costs (akin to gas fees in Ethereum), while `dToken` is used as a security deposit. There is no strict distinction between `eToken` and `dToken`; a single token can serve both purposes. Every call to Judge incurs a transaction fee payable in `eToken`.













