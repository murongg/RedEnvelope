// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IRedEnvelope {
    struct Envelope {
        address sender;
        address[] receivers;
        uint256 amount;
        uint256 balance;
        EnvelopeType envelopeType;
    }

    struct Record {
        address receiver;
        uint256 amount;
    }

    enum EnvelopeType {
        Average,
        Lucky
    }

    event Receive(address sender, address receiver, uint256 amount);
    event Create(
        uint256 envelopeId,
        address sender,
        address[] receivers,
        uint256 amount,
        EnvelopeType envelopeType
    );
    event Withdraw(uint256 id, address sender, uint256 amount);
    event WithdrawOwner(uint256 amount);

    function create(
        address[] memory receivers,
        EnvelopeType envelopeType
    ) external payable returns (uint256);
    function grab(uint256 id) external returns (uint256);
    function withdraw(uint256 id) external payable;
    function withdrawOwner() external payable;
    function getEnvelope(uint256 id) external view returns (Envelope memory);
    function getRecord(uint256 id) external view returns (Record[] memory);
}
