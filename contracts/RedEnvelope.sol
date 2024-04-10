// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";
contract RedEnvelope {
    struct Envelope {
        address sender;
        address[] receivers;
        uint256 amount;
        uint256 balance;
    }

    struct Record {
        address receiver;
        uint256 amount;
    }

    uint256 public currentEnvelopeId = 0;
    mapping(uint256 => Envelope) public envelopes;
    mapping(uint256 => Record[]) public records;

    address owner = msg.sender;

    event Receive(address sender, address receiver, uint256 amount);
    event Create(
        uint256 envelopeId,
        address sender,
        address[] receivers,
        uint256 amount
    );
    event Withdraw(uint256 id, address sender, uint256 amount);
    event WithdrawOwner(uint256 amount);

    constructor() {
        owner = msg.sender;
    }

    function create(
        address[] memory receivers
    ) public payable returns (uint256) {
        currentEnvelopeId++;
        envelopes[currentEnvelopeId] = Envelope(
            msg.sender,
            receivers,
            msg.value,
            msg.value
        );
        emit Create(currentEnvelopeId, msg.sender, receivers, msg.value);
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
        uint256 len = envelope.receivers.length;
        uint256 amount = envelope.amount / len;
        require(amount <= envelope.balance, "No balance");
        envelopes[id].balance = envelope.balance - amount;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Failed to send Ether");
        records[id].push(Record(msg.sender, amount));
        emit Receive(envelope.sender, msg.sender, amount);
        return amount;
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
