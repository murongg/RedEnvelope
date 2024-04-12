const { ethers } = require("hardhat")
const { assert, expect } = require("chai")

const abi = require('../artifacts/contracts/RedEnvelope.sol/RedEnvelope.json').abi

describe("RedEnvelope", function () {
  let redEnvelopeFactory, redEnvelope, signers, contractWithSigner, receivers, owner
  beforeEach(async function () {
    redEnvelopeFactory = await ethers.getContractFactory("RedEnvelope")
    redEnvelope = await redEnvelopeFactory.deploy()
    signers = await ethers.getSigners();
    receivers = signers.map(signer => signer.address)
    owner = signers[0];
    contractWithSigner = redEnvelope.connect(owner);
  })

  it("create & grab", async function () {
    const value = ethers.parseEther("0.1")
    console.log(value.toString())
    const tx = await contractWithSigner.create(receivers, 0, { value });
    await tx.wait();
    // parse data
    const currentEnvelopeId = await redEnvelope.currentEnvelopeId();
    const envelope = await redEnvelope.getEnvelope(currentEnvelopeId)
    // console.log(envelope)
    const ownerAddress = await envelope[0]
    const addresses = envelope[1]
    const amount = envelope[2]
    assert.equal(ownerAddress, owner.address);
    assert.deepEqual(addresses, receivers);
    assert.equal(amount, value);

    // console.log(currentEnvelopeId)
    const receiver = signers[1]
    console.log('receiver old', await receiver.provider.getBalance(receiver.address))
    const contractWithReceiver = redEnvelope.connect(receiver);
    const grabTx = await contractWithReceiver.grab(currentEnvelopeId);
    await grabTx.wait()
    console.log('amount', ethers.getBigInt(value) / BigInt(receivers.length))
    console.log('receiver new', await receiver.provider.getBalance(receiver.address))

    const record = await redEnvelope.getRecord(currentEnvelopeId)
    console.log(record)

    console.log('owner balance', await ethers.provider.getBalance(owner.address))
    const withdrawOwnerTx = await contractWithSigner.withdrawOwner();
    console.log('owner balance', await ethers.provider.getBalance(owner.address))

    // console.log(grabTx)
    // const balance = await receiver.provider.getBalance(receiver.address);
    // console.log(balance)
  })
})
