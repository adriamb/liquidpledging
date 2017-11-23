'use strict';

var VaultAbi = require('../build/Vault.sol').VaultAbi;
var VaultByteCode = require('../build/Vault.sol').VaultByteCode;
var generateClass = require('eth-contract-class').default;

module.exports = generateClass(VaultAbi, VaultByteCode);