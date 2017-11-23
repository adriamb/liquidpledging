'use strict';

var LiquidPledgingMockAbi = require('../build/LiquidPledgingMock.sol').LiquidPledgingMockAbi;
var LiquidPledgingMockCode = require('../build/LiquidPledgingMock.sol').LiquidPledgingMockByteCode;
var generateClass = require('eth-contract-class').default;

module.exports = generateClass(LiquidPledgingMockAbi, LiquidPledgingMockCode);