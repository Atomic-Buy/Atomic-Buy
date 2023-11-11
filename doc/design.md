# Atomic Buy 

Atom Buy: a decentralized paid content distribution service that make the digital content purchase on the Lightning Network atomic and trustless. We propose a purchase scheme which make every digital content accoutable and every digital content purchase atomic and verifable using various cryptography primitives(ZKP, Encryption, Signature...). Then we using blockchain technology protect every purchase and detect the misbehavior.  

## Introduction 

### Problem we want to solve
In the landscape of paid content distribution, both centralized content platforms and independent distribution by content creators present distinct challenges.

The drawbacks of using centralized platforms for paid content sharing — such as academic paper repositories, knowledge paywalls, and sites like OnlyFans — are significant and multifaceted:

- **Trust and Dependency on the Platform**: Content creators (merchants) are forced to place their trust in these platforms, which pose a risk of content leakage. Meanwhile, platforms retain control over the content and users' data, limiting creators' direct relationship with their audience and complicating efforts to move to other distribution methods or platforms.
- **Censorship**: Centralized platforms have the authority to censor content and users, which can be based on a variety of factors, often opaque and outside the control of the content creators and consumers. This can lead to a suppression of freedom of expression and access to information.
- **Fees and Revenue Sharing**: These platforms often take a substantial cut of the creators' earnings, which can greatly reduce the profit margin for the creators. 

In contrast, independent distribution methods that creators might use, like mailing lists or personal websites, have their own set of challenges: **Trust and Verification**: Without the reputation and the protection of a known platform, creators must build trust with their audience from scratch. Consumers might be hesitant to purchase from an unknown source without the assurance of quality and delivery.

### What we wants to build

To address the problems above, we propose a decentralized paid content distribution(DPCD) framework and implementataion a DPCD framework based on EVM, Lightning Network and Nostr. 

## Primitives 


### Ciminion

[Ciminion](https://eprint.iacr.org/2021/267) Symmetric Encryption system: a zk-friendly Symmetric Encryption system. All inputs and outputs are numbers in finite field P(`FFP`). the plaintext number must be even. 
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
- MAC check: `Mac()`
    - Inputs: 
        - `master key 1`
        - `master key 2`
        - `nonce`
        - `IV`
        - `CT`: `ciphertext[N * 2]`
    - Outputs: 
        - `MAC`

We define a set of secret key `sk = [master key 1, master key 2, nonce, IV]`, and we denote alice's `sk` as `sk_alice`. 

### Poseidon Hash 
A zk-friendly hash function.                                                                                                                                   ### Lightning network                

## Terminology 

Important terminology to understand the system. 

### Judge

`Judge` is a accountable and verifable third party, which is secured by a blockchain L1/L2, or it can be a L1.

### Content Commitment 

For any source digital content(as a vector of bytes) `C` we can parse the content to a vecotor of big number `PT` in `FFP`. 
We define `COM` as the content commitment of `C`, where `COM =  Enc(sk_payee, PT).MAC`. 

Anyone can commit a content to`Judge` by pushing the `COM` to it. 

### Proof of Content 

For content `C` we define a quantity function `Q()` with some parameters `params[...]`, when `Q(C, params) = 0` means the content `c` satisfy some quality that `Q` claimed. For examples, if `C` is a photo, `params` is the result image of some photoshop operations on `C`. `Q(c, params) = 0` claim that the `C` is the orignal image of `params`. 

we define the Claim of Content as a function `CoC(public Params, public Q, sk, PT, public COM) -> CT`, which will  claim: 
- `Q(C, Params) = 0` and 
- `Enc(sk, PT).CT = CT` and 
- `Enc(sk, PT).MAC == COM` 


We can proof this claim using any zk-prove system like Groth16, KZG-Plonk, etc. We denoted the proof of `CoC` as `PoC`, which includes every thing a verifier need to verify this claim, including verifier parameters, public witness and proof. 

Anyone can verify the ciphertext of content `CT` by querying the `COM` from the `Judge` and verifying `POC`. 

### Proof of Purchase
Every payee and payer has its own reusable ECDSA key pairs `k = (esk, epk)`. 
The proof of purchase claim that "I have paid enough money for content `C`".
In lightning network, a payment is finished when a sha256 hash `h`'s preimage revealed to the payer. 

The proof of Purchase `PoP` consists of two following parts: 
- `Receipt`: 
    - `h_payer = poseidon_hash(sk_payer)`: the ciminion secret key of buyers 
    - `h` : the sha256 hash of a preimage 
    - `MAC`: the content's MAC that the payer wants. 
    - `timestamp`: payment deadline for payer. 
    - `sig`: payee's signature of the three elements above
- `pre-image`: preimage of `h`

Anyone can verify this prove by verfity that if: `sign_{k_payee}(h_payer, h, timestamp) == sig && sha256(pre-image) == h`. 


### Proof of Delivery 

Once the payer pay the payee the bill to buy this content, the payer wants the payee to deliver the content to him. If the payer donot receive the content, it can ask a trusted thrid party for help(just like we cal custom service in real world).The payee must proof it has delivered the content to that third party. 

In the prove of Content stage, payee encrypted the content `C` using `sk_payee`, now payee needs to prove that it will deliver the `sk_payee` encrypted by `sk_payer` to payer. 

We denoted the claim of delivery as `CoD`, where `PoD(public h_payer,public COM, sk_payee, sk_payer, CT) -> CT_sk ` will claim: 
- `Mac(sk_payee, CT).MAC == MAC` and 
- `Enc(sk_payer, sk_payee).CT = CT_sk` and 
- `poseidon_hash(sk_payer) == h_payer`

The proof of `CoD` is denoted as `PoD`. 

Anyone can verify the `PoD` by querying `h_payer, COM` from the the `Judge`. 

## Design Abstract 



![structure](./trans.png)

Atomic Buy is inspired by the scenario of a traditional Web2 e-commerce platform, where merchants are required to deposit funds as a form of security when they wish to open a store on platforms like Amazon or Taobao. If customers feel they have been treated unfairly, they can request the platform to adjudicate any alleged misconduct by the merchant.

In our trustless and decentralized model, the "platform"'s Job is substituted by three components: **content relay network**, **payment network** and **Judge**. 

**Content relay network** will become the comminication layer between merchants and customers, distributing content infomation from merchants to customers. Depending on the usecase, we could use different relay network. For example, to build the decentralized vertsion of Onlyfans, Medium, we could use relay network like Nostr, which provides async routine service for both public and private message in a decentralized manner. If we want build a decentralized academic database, We could use service like Arweave, IPFS as the content storage, and any other message service for private commuication between merchants(content creators) and customers. 

**Payment network** is where users pay some cryptocurrency to the merchants, and generate a veriable proof of purchase "I spent x money for product(content) C". The proof of purchase is the primitives for `Judge` settle the arguments between merchants and customers. In our implementation, we use Lightning Network as the payment network, as it can easily settle a `PoP` lighting fast without onchain verification. 


**Judge** is a accountable and verifable third party, which is secured by a blockchain L1/L2, or it can be a L1 itself. Similar to a conventional e-commerce platform, merchants are obliged to place a deposit on `Judge`, which holds them accountable in cases of wrongdoing. And `Judge` can detect and punish those who cheat in a content purchase, which make the purchase trustless for customers. 


## Basic Workflow 

![Abstract of the design of atomic buy](./design.png)


We seperate the whole process into 4 phases: 
- Phase One: Content Registration. Merchants must register their content and its price on `Judge``, along with depositing some funds. This holds the merchants accountable. Additionally, merchants are required to create a Proof of Content (PoC) for the content. Subsequently, merchants can distribute the encrypted content and `PoC` on any platform such as Twitter or Nostr. Potential customers can then verify the content's quality and ensure that the ciphertext they receive corresponds with the content committed on Judge.
- Phase Two: Payment. Leveraging the advantages of the Lightning Network (LN), a payment proof PoP ("alice pays x satoshis for content `c` before time `T`") can be established solely between the merchant and customer. Should any issues arise, the customer can present the `PoP` to Judge for resolution.
- Phase Three: Content delivery: Once the merchant believe that the bill has been payment, it need to delivery the key that can unlocked the ciphertext asap to the customer in any message routine platform. 
- Phase Four:  Challenge. The challenge phase ensures that keys are delivered to the customer via Judge. Merchants are required to construct a Proof of Delivery (PoD) to verify the delivery of keys. Failure to provide a `PoD` within the stipulated timeframe results in penalties imposed by Judge on the merchant and compensation awarded to the customer.









