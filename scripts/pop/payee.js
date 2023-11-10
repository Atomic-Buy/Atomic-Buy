const fs = require('fs');
const request = require('request');
const path = require('path');
const keygen = require('../ciminion_key.js');

const REST_HOST = 'localhost:8081'
const LND_PATH = '/home/vielo/.polar/networks/3/volumes/lnd/alice/'
const MACAROON_PATH = path.join(LND_PATH, 'data/chain/bitcoin/regtest/admin.macaroon')

class PopReceiver{
    constructor(contentWithPrice){
        this.contentWithPrice = contentWithPrice;
        request_list = [ ] 
    }
    handle_offer_request(request){
        // save the request
        this.request_list.push({request: request, state: 'pending'});
        // call LND API, add a new invoice 
        
    }
}