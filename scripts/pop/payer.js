const fs = require('fs');
const request = require('request');
const path = require('path');
const keygen = require('../ciminion_key.js');

const REST_HOST = 'localhost:8082'
const LND_PATH = '/home/vielo/.polar/networks/3/volumes/lnd/bob/'
const MACAROON_PATH = path.join(LND_PATH, 'data/chain/bitcoin/regtest/admin.macaroon')


class PopPayer {
    constructor(sk_path) {
        // save the root path to save the sk 
        this.sk_path = sk_path;
    }

    // 实现generate_offer_request方法
    generate_offer_request(content_commitment) {
        // generate a set of keys 
        const keypair = new keygen.ciminionKeyGen();
        let sk = keypair.export_sk();
        // build the request
        let request = {
            MAC: content_commitment,
            MK_0: sk.MK_0,
            MK_1: sk.MK_1,
            IV: sk.IV,
            nonce: sk.nonce
        }
        return request;

    }

    // 实现pay_invoice方法
    pay_invoice(invoice) {
        // using LND rest api to pay the invoice
        
    }

    // 实现get_preimage方法
    get_preimage() {
        // 方法的具体实现
        console.log('Getting preimage...');
        // 你的逻辑代码
    }

    // 实现build_poc方法
    build_pop() {
        // 方法的具体实现
        console.log('Building proof of concept...');
        // 你的逻辑代码
    }
}

// 创建PocPayer的实例
const poc_payer = new PopPayer();

// 调用实例的方法
poc_payer.generate_offer_request();
poc_payer.pay_invoice();
poc_payer.get_preimage();
poc_payer.build_poc();
