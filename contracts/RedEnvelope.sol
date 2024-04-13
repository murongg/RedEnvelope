// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IRedEnvelope.sol";

// Uncomment this line to use console.log
// import "hardhat/console.sol";
contract RedEnvelope is IRedEnvelope {
    uint256 public currentEnvelopeId = 0;
    mapping(uint256 => Envelope) public envelopes;
    mapping(uint256 => Record[]) public records;

    uint256 public constant ENVELOPE_LUCKY_MIN = 1 ether / 1000;

    address owner = msg.sender;

    constructor() {
        owner = msg.sender;
    }

    function create(
        address[] memory receivers,
        EnvelopeType envelopeType
    ) public payable returns (uint256) {
        currentEnvelopeId++;
        envelopes[currentEnvelopeId] = Envelope(
            msg.sender,
            receivers,
            msg.value,
            msg.value,
            envelopeType
        );
        emit Create(
            currentEnvelopeId,
            msg.sender,
            receivers,
            msg.value,
            envelopeType
        );
        return currentEnvelopeId;
    }

    function grab(
        uint256 id
    )
        public
        checkEnvelopeIsExist(id)
        checkEnvelopeReceivers(id, msg.sender)
        returns (uint256)
    {
        Envelope memory envelope = envelopes[id];
        require(envelope.balance > 0, "No balance");
        uint256 amount = envelope.envelopeType == EnvelopeType.Average
            ? _grabByAverage(id)
            : _grabByLucky(id);
        require(amount <= envelope.balance, "No balance");
        envelopes[id].balance = envelope.balance - amount;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Failed to send Ether");
        records[id].push(Record(msg.sender, amount));
        emit Receive(envelope.sender, msg.sender, amount);
        return amount;
    }

    function _grabByAverage(uint256 id) private view returns (uint256) {
        Envelope memory envelope = envelopes[id];
        uint256 len = envelope.receivers.length;
        uint256 amount = envelope.amount / len;
        return amount;
    }

    function _grabByLucky(uint256 id) private view returns (uint256) {
        Envelope memory envelope = envelopes[id];
        uint256 recordLen = records[id].length;
        uint256 unAssignLen = envelope.receivers.length - recordLen;
        if (unAssignLen == 0) {
            return 0;
        } else if (unAssignLen == 1) {
            return envelope.balance;
        } else {
            uint256 safeAmount = ENVELOPE_LUCKY_MIN * (unAssignLen - 1);
            uint256 luckyAmount = _getRandomAmount(
                envelope.balance - safeAmount
            );
            return luckyAmount;
        }
    }

    function _getRandomAmount(uint256 _max) private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        msg.sender,
                        ENVELOPE_LUCKY_MIN
                    )
                )
            ) % _max;
    }

    function withdraw(uint256 id) public payable onlyEnvelopeOwner(id) {
        (bool success, ) = envelopes[id].sender.call{
            value: envelopes[id].balance
        }("");
        require(success, "Failed to send Ether");
        emit Withdraw(id, envelopes[id].sender, envelopes[id].balance);
        envelopes[id].balance = 0;
    }

    function withdrawOwner() public payable onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance");
        (bool success, ) = owner.call{value: balance}("");
        require(success, "Failed to send Ether");
        emit WithdrawOwner(balance);
    }

    function getEnvelope(uint256 id) public view returns (Envelope memory) {
        return envelopes[id];
    }

    function getRecord(uint256 id) public view returns (Record[] memory) {
        return records[id];
    }

    modifier checkBalance(uint256 amount, address sender) {
        require(amount <= sender.balance, "Not enough balance");
        _;
    }

    modifier checkEnvelopeIsExist(uint256 id) {
        require(envelopes[id].sender != address(0), "Envelope is not exist");
        _;
    }

    modifier checkEnvelopeReceivers(uint256 id, address receiver) {
        Envelope memory envelope = envelopes[id];
        bool has = false;
        for (uint256 i = 0; i < envelope.receivers.length; i++) {
            if (envelope.receivers[i] == receiver) {
                has = true;
                break;
            } else {
                has = false;
            }
        }
        require(has, "Receiver is not exist");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyEnvelopeOwner(uint256 id) {
        require(msg.sender == envelopes[id].sender);
        _;
    }
}
