'use strict';

var LiquidPledgingAbi = require('../build/LiquidPledging.sol').LiquidPledgingAbi;
var LiquidPledgingCode = require('../build/LiquidPledging.sol').LiquidPledgingByteCode;
var generateClass = require('eth-contract-class').default;

module.exports = generateClass(LiquidPledgingAbi, LiquidPledgingCode);