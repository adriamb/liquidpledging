'use strict';

var LPVaultAbi = require('../build/LPVault.sol').LPVaultAbi;
var LPVaultByteCode = require('../build/LPVault.sol').LPVaultByteCode;
var generateClass = require('eth-contract-class').default;

module.exports = generateClass(LPVaultAbi, LPVaultByteCode);