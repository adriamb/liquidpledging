
//File: node_modules/giveth-common-contracts/contracts/Owned.sol
pragma solidity ^0.4.15;


/// @title Owned
/// @author Adrià Massanet <adria@codecontext.io>
/// @notice The Owned contract has an owner address, and provides basic 
///  authorization control functions, this simplifies & the implementation of
///  user permissions; this contract has three work flows for a change in
///  ownership, the first requires the new owner to validate that they have the
///  ability to accept ownership, the second allows the ownership to be
///  directly transfered without requiring acceptance, and the third allows for
///  the ownership to be removed to allow for decentralization 
contract Owned {

    address public owner;
    address public newOwnerCandidate;

    event OwnershipRequested(address indexed by, address indexed to);
    event OwnershipTransferred(address indexed from, address indexed to);
    event OwnershipRemoved();

    /// @dev The constructor sets the `msg.sender` as the`owner` of the contract
    function Owned() public {
        owner = msg.sender;
    }

    /// @dev `owner` is the only address that can call a function with this
    /// modifier
    modifier onlyOwner() {
        require (msg.sender == owner);
        _;
    }
    
    /// @dev In this 1st option for ownership transfer `proposeOwnership()` must
    ///  be called first by the current `owner` then `acceptOwnership()` must be
    ///  called by the `newOwnerCandidate`
    /// @notice `onlyOwner` Proposes to transfer control of the contract to a
    ///  new owner
    /// @param _newOwnerCandidate The address being proposed as the new owner
    function proposeOwnership(address _newOwnerCandidate) public onlyOwner {
        newOwnerCandidate = _newOwnerCandidate;
        OwnershipRequested(msg.sender, newOwnerCandidate);
    }

    /// @notice Can only be called by the `newOwnerCandidate`, accepts the
    ///  transfer of ownership
    function acceptOwnership() public {
        require(msg.sender == newOwnerCandidate);

        address oldOwner = owner;
        owner = newOwnerCandidate;
        newOwnerCandidate = 0x0;

        OwnershipTransferred(oldOwner, owner);
    }

    /// @dev In this 2nd option for ownership transfer `changeOwnership()` can
    ///  be called and it will immediately assign ownership to the `newOwner`
    /// @notice `owner` can step down and assign some other address to this role
    /// @param _newOwner The address of the new owner
    function changeOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != 0x0);

        address oldOwner = owner;
        owner = _newOwner;
        newOwnerCandidate = 0x0;

        OwnershipTransferred(oldOwner, owner);
    }

    /// @dev In this 3rd option for ownership transfer `removeOwnership()` can
    ///  be called and it will immediately assign ownership to the 0x0 address;
    ///  it requires a 0xdece be input as a parameter to prevent accidental use
    /// @notice Decentralizes the contract, this operation cannot be undone 
    /// @param _dac `0xdac` has to be entered for this function to work
    function removeOwnership(address _dac) public onlyOwner {
        require(_dac == 0xdac);
        owner = 0x0;
        newOwnerCandidate = 0x0;
        OwnershipRemoved();     
    }
} 

//File: node_modules/giveth-common-contracts/contracts/ERC20.sol
pragma solidity ^0.4.15;


/**
 * @title ERC20
 * @dev A standard interface for tokens.
 * @dev https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
 */
contract ERC20 {
  
    /// @dev Returns the total token supply
    function totalSupply() public constant returns (uint256 supply);

    /// @dev Returns the account balance of the account with address _owner
    function balanceOf(address _owner) public constant returns (uint256 balance);

    /// @dev Transfers _value number of tokens to address _to
    function transfer(address _to, uint256 _value) public returns (bool success);

    /// @dev Transfers _value number of tokens from address _from to address _to
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    /// @dev Allows _spender to withdraw from the msg.sender's account up to the _value amount
    function approve(address _spender, uint256 _value) public returns (bool success);

    /// @dev Returns the amount which _spender is still allowed to withdraw from _owner
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

//File: node_modules/giveth-common-contracts/contracts/Escapable.sol
pragma solidity ^0.4.15;
/*
    Copyright 2016, Jordi Baylina
    Contributor: Adrià Massanet <adria@codecontext.io>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/





/// @dev `Escapable` is a base level contract built off of the `Owned`
///  contract; it creates an escape hatch function that can be called in an
///  emergency that will allow designated addresses to send any ether or tokens
///  held in the contract to an `escapeHatchDestination` as long as they were
///  not blacklisted
contract Escapable is Owned {
    address public escapeHatchCaller;
    address public escapeHatchDestination;
    mapping (address=>bool) private escapeBlacklist; // Token contract addresses

    /// @notice The Constructor assigns the `escapeHatchDestination` and the
    ///  `escapeHatchCaller`
    /// @param _escapeHatchCaller The address of a trusted account or contract
    ///  to call `escapeHatch()` to send the ether in this contract to the
    ///  `escapeHatchDestination` it would be ideal that `escapeHatchCaller`
    ///  cannot move funds out of `escapeHatchDestination`
    /// @param _escapeHatchDestination The address of a safe location (usu a
    ///  Multisig) to send the ether held in this contract; if a neutral address
    ///  is required, the WHG Multisig is an option:
    ///  0x8Ff920020c8AD673661c8117f2855C384758C572 
    function Escapable(address _escapeHatchCaller, address _escapeHatchDestination) public {
        escapeHatchCaller = _escapeHatchCaller;
        escapeHatchDestination = _escapeHatchDestination;
    }

    /// @dev The addresses preassigned as `escapeHatchCaller` or `owner`
    ///  are the only addresses that can call a function with this modifier
    modifier onlyEscapeHatchCallerOrOwner {
        require ((msg.sender == escapeHatchCaller)||(msg.sender == owner));
        _;
    }

    /// @notice Creates the blacklist of tokens that are not able to be taken
    ///  out of the contract; can only be done at the deployment, and the logic
    ///  to add to the blacklist will be in the constructor of a child contract
    /// @param _token the token contract address that is to be blacklisted 
    function blacklistEscapeToken(address _token) internal {
        escapeBlacklist[_token] = true;
        EscapeHatchBlackistedToken(_token);
    }

    /// @notice Checks to see if `_token` is in the blacklist of tokens
    /// @param _token the token address being queried
    /// @return False if `_token` is in the blacklist and can't be taken out of
    ///  the contract via the `escapeHatch()`
    function isTokenEscapable(address _token) constant public returns (bool) {
        return !escapeBlacklist[_token];
    }

    /// @notice The `escapeHatch()` should only be called as a last resort if a
    /// security issue is uncovered or something unexpected happened
    /// @param _token to transfer, use 0x0 for ether
    function escapeHatch(address _token) public onlyEscapeHatchCallerOrOwner {   
        require(escapeBlacklist[_token]==false);

        uint256 balance;

        /// @dev Logic for ether
        if (_token == 0x0) {
            balance = this.balance;
            escapeHatchDestination.transfer(balance);
            EscapeHatchCalled(_token, balance);
            return;
        }
        /// @dev Logic for tokens
        ERC20 token = ERC20(_token);
        balance = token.balanceOf(this);
        require(token.transfer(escapeHatchDestination, balance));
        EscapeHatchCalled(_token, balance);
    }

    /// @notice Changes the address assigned to call `escapeHatch()`
    /// @param _newEscapeHatchCaller The address of a trusted account or
    ///  contract to call `escapeHatch()` to send the value in this contract to
    ///  the `escapeHatchDestination`; it would be ideal that `escapeHatchCaller`
    ///  cannot move funds out of `escapeHatchDestination`
    function changeHatchEscapeCaller(address _newEscapeHatchCaller) public onlyEscapeHatchCallerOrOwner {
        escapeHatchCaller = _newEscapeHatchCaller;
    }

    event EscapeHatchBlackistedToken(address token);
    event EscapeHatchCalled(address token, uint amount);
}

//File: contracts/LPVault.sol
pragma solidity ^0.4.11;

/// @title LPVault
/// @author Jordi Baylina
/// @notice This contract holds ether securely for liquid pledging systems. For
///  this iteration the funds will come straight from the Giveth Multisig as a
///  safety precaution, but once fully tested and optimized this contract will
///  be a safe place to store funds equipped with optional variable time delays
///  to allow for an optional escape hatch to be implemented



/// @dev `LiquidPledging` is a basic interface to allow the `LPVault` contract
///  to confirm and cancel payments in the `LiquidPledging` contract.
contract LiquidPledging {
    function confirmPayment(uint64 idPledge, uint amount) public;
    function cancelPayment(uint64 idPledge, uint amount) public;
}


/// @dev `LPVault` is a higher level contract built off of the `Escapable`
///  contract that holds funds for the liquid pledging system.
contract LPVault is Escapable {

    LiquidPledging public liquidPledging; // liquidPledging contract's address
    bool public autoPay; // if false, payments will take 2 txs to be completed

    enum PaymentStatus {
        Pending, // means the payment is awaiting confirmation
        Paid,    // means the payment has been sent
        Canceled // means the payment will never be sent
    }
    /// @dev `Payment` is a public structure that describes the details of
    ///  each payment the `ref` param makes it easy to track the movements of
    ///  funds transparently by its connection to other `Payment` structs
    struct Payment {
        PaymentStatus state; //
        bytes32 ref; // an input that references details from other contracts
        address dest; // recipient of the ETH
        uint amount; // amount of ETH (in wei) to be sent
    }

    // @dev An array that contains all the payments for this LPVault
    Payment[] public payments;

    function LPVault(address _escapeHatchCaller, address _escapeHatchDestination)
        Escapable(_escapeHatchCaller, _escapeHatchDestination) public
    {
    }

    /// @dev `liquidPledging` is the only address that can call a function with
    ///  this modifier
    modifier onlyLiquidPledging() {
        require(msg.sender == address(liquidPledging));
        _;
    }

    function () public payable {}

    /// @notice `setLiquidPledging` is used to attach a specific liquid pledging
    ///  instance to this LPvault. Keep in mind this isn't a single pledge but
    ///  instead an entire liquid pledging contract.
    /// @param _newLiquidPledging A full liquid pledging contract
    function setLiquidPledging(address _newLiquidPledging) public onlyOwner {
        require(address(liquidPledging) == 0x0);
        liquidPledging = LiquidPledging(_newLiquidPledging);
    }

    /// @notice `setAutopay` is used to toggle whether the LPvault will
    ///  automatically confirm a payment after the payment has been authorized.
    /// @param _automatic If true payments will confirm automatically
    function setAutopay(bool _automatic) public onlyOwner {
        autoPay = _automatic;
    }

    /// @notice `authorizePayment` is used in order to approve a payment 
    ///  from the liquid pledging contract. Whenever a project or other address
    ///  needs to receive a payment it needs to be authorized with this contract.
    /// @param _ref This parameter is used to reference details about the
    ///  payment from another contract.
    /// @param _dest This is the address that payments will end up being sent to
    /// @param _amount This is the amount that the payment is being authorized
    ///  for.
    function authorizePayment(
        bytes32 _ref,
        address _dest,
        uint _amount
    ) public onlyLiquidPledging returns (uint)
    {
        uint idPayment = payments.length;
        payments.length ++;
        payments[idPayment].state = PaymentStatus.Pending;
        payments[idPayment].ref = _ref;
        payments[idPayment].dest = _dest;
        payments[idPayment].amount = _amount;

        AuthorizePayment(idPayment, _ref, _dest, _amount);

        if (autoPay) {
            doConfirmPayment(idPayment);
        }

        return idPayment;
    }

    /// @notice `confirmPayment` is a basic function used to allow the
    ///  owner of the vault to initiate a payment confirmation. Since 
    ///  `authorizePayment` is the only pay to populate the `payments` array
    ///  this is generally used when `autopay` is `false` after a payment has
    ///  has been authorized.
    /// @param _idPayment Array lookup for the payment.
    function confirmPayment(uint _idPayment) public onlyOwner {
        doConfirmPayment(_idPayment);
    }

    /// @notice `doConfirmPayment` is used to actually initiate a payment
    ///  to the final destination. All of the payment information should be
    ///  set before calling this function.
    /// @param _idPayment Array lookup for the payment.
    function doConfirmPayment(uint _idPayment) internal {
        require(_idPayment < payments.length);
        Payment storage p = payments[_idPayment];
        require(p.state == PaymentStatus.Pending);

        p.state = PaymentStatus.Paid;
        liquidPledging.confirmPayment(uint64(p.ref), p.amount);

        p.dest.transfer(p.amount);  // only ETH denominated in wei

        ConfirmPayment(_idPayment);
    }

    /// @notice `cancelPayment` is used when `autopay` is `false` in order
    ///  to allow the owner to cancel a payment instead of confirming it.
    /// @param _idPayment Array lookup for the payment.
    function cancelPayment(uint _idPayment) public onlyOwner {
        doCancelPayment(_idPayment);
    }

    /// @notice `doCancelPayment` This carries out the task of actually
    ///  canceling a payment instead of confirming it.
    /// @param _idPayment Array lookup for the payment.    
    function doCancelPayment(uint _idPayment) internal {
        require(_idPayment < payments.length);
        Payment storage p = payments[_idPayment];
        require(p.state == PaymentStatus.Pending);

        p.state = PaymentStatus.Canceled;

        liquidPledging.cancelPayment(uint64(p.ref), p.amount);

        CancelPayment(_idPayment);

    }

    /// @notice `multiConfirm` allows for more efficient confirmation of
    ///  multiple payments.
    /// @param _idPayments An array of multiple payment ids
    function multiConfirm(uint[] _idPayments) public onlyOwner {
        for (uint i = 0; i < _idPayments.length; i++) {
            doConfirmPayment(_idPayments[i]);
        }
    }

    /// @notice `multiCancel` allows for more efficient cancellation of
    ///  multiple payments.
    /// @param _idPayments An array of multiple payment ids
    function multiCancel(uint[] _idPayments) public onlyOwner {
        for (uint i = 0; i < _idPayments.length; i++) {
            doCancelPayment(_idPayments[i]);
        }
    }

    /// @notice `nPayments` Basic getter to return the number of payments
    ///  currently held in the system. Since payments are not removed from
    ///  the array this represents all payments over all time.
    function nPayments() constant public returns (uint) {
        return payments.length;
    }

    /// Transfer eth or tokens to the escapeHatchDestination.
    /// Used as a safety mechanism to prevent the vault from holding too much value
    /// before being thoroughly battle-tested.
    /// @param _token to transfer, use 0x0 for ether
    /// @param _amount to transfer
    function escapeFunds(address _token, uint _amount) public onlyOwner {
        /// @dev Logic for ether
        if (_token == 0x0) {
            require(this.balance >= _amount);
            escapeHatchDestination.transfer(_amount);
            EscapeHatchCalled(_token, _amount);
            return;
        }
        /// @dev Logic for tokens
        ERC20 token = ERC20(_token);
        uint balance = token.balanceOf(this);
        require(balance >= _amount);
        require(token.transfer(escapeHatchDestination, _amount));
        EscapeFundsCalled(_token, _amount);
    }

    event ConfirmPayment(uint indexed idPayment);
    event CancelPayment(uint indexed idPayment);
    event AuthorizePayment(uint indexed idPayment, bytes32 indexed ref, address indexed dest, uint amount);
    event EscapeFundsCalled(address _token, uint _amount);
}