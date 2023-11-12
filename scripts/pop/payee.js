const fs = require("fs");
const req = require('request');
const path = require("path");
const keygen = require("../ciminion_key.js");
const { assert } = require("console");

const REST_HOST = "localhost:8081";
const LND_PATH = "/home/vielo/.polar/networks/3/volumes/lnd/alice/";
const MACAROON_PATH = path.join(
    LND_PATH,
    "data/chain/bitcoin/regtest/admin.macaroon"
);

/// enum states
const states = {
    pending: "pending",
    paid: "paid",
    failed: "failed",
};
/// wrap all LND calls
class PopReceiver {
    constructor() {
        this.content_com_price = [];
        this.request_list = [];
        /*
        this.request_list = [
            {
                state: states.pending,
                content_commitment: "1",
                price: 100,
                preimage: "1",
                invoice: "1",
                sk_buyer: {
                    MK_0: "1",
                    MK_1: "1",
                    IV: "1",
                    nonce: "1",
                },
            }...
        ];
        */
    }
    /// add content {content_commitment(A big number under P string), price int64} to content_com_price
    add_content(content_commitment, price) {
        this.content_com_price.push({ content_commitment, price });
    }
    /// remove content 
    remove_content(content_commitment) {
        this.content_com_price = this.content_com_price.filter(
            (element) => element.content_commitment != content_commitment
        );
    }
    /// generate random 32 bytes and encode in base64
    gen_preimage() {
        const crypto = require("crypto");
        return crypto.randomFillSync(Buffer.alloc(32));
    }
    handle_offer_request(request) {
        // lookup the if the content commitment is in content_com_price
        let content = this.content_com_price.find(
            (element) => element.content_commitment == request.MAC
        );
        // if not found, return error
        if (content == undefined) {
            return "error";
        }
        // generate pre image(32 bytes), then encoded in base64
        let preimage = this.gen_preimage();
        console.log(preimage.toString("hex"));
        // how many sats to pay
        let value = content.price;
        // see https://lightning.engineering/api-docs/api/lnd/lightning/add-invoice for more details
        let invoice_req = {
            r_preimage: preimage.toString("base64"),
            value: value,
            private: false,
        };
        let options = {
            url: `https://${REST_HOST}/v1/invoices`,
            // Work-around for self-signed certificates.
            rejectUnauthorized: false,
            json: true,
            headers: {
                "Grpc-Metadata-macaroon": fs
                    .readFileSync(MACAROON_PATH)
                    .toString("hex"),
            },
            form: JSON.stringify(invoice_req),
        };
        req.post(options, function (error, response, body) {
            console.log(body);
            let hash = body.r_hash
            // check hash == sha256(preimage)
            let r_hash = require("crypto").createHash("sha256").update(preimage).digest("base64");
            assert(hash == r_hash);
        });
        // lookup this invoice in LND
        

    }
}

let x = new PopReceiver();
x.add_content("1", 100);
x.handle_offer_request({ MAC: "1" });
