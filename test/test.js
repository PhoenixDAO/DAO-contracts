let { accounts, contract } = require('@openzeppelin/test-environment');

const { BN, constants, expectEvent, expectRevert } = require('@openzeppelin/test-helpers');
const { expect } = require('chai');
const { ZERO_ADDRESS } = constants;
const admin = accounts[0];
const proposer1 = accounts[1];
const proposer2 = accounts[2];
const DaoSmartContract = contract.fromArtifact('DaoSmartContract');
//initialize values here for proposal submission
const proposalID = ["0", "1", "2", "3"];
const _fundsRequested = new BN(500);
const _endTime = new BN(500);
const _collAmount = new BN(50);
const _milestonesTotal = new BN(4);
//for updating status
const updatedStatus = 2

describe("testin DAO", async () => {
    before(async () => {
        contract = await DaoSmartContract.new({ from: admin });
        await contract.initialize({ from: admin });
    })
    describe("only owner can call", async () => {
        it('can pause', async function () {
            await contract.pause({ from: admin });
            expect(await contract.paused()).to.equal(true);
        });

        it('can unpause', async function () {
            await contract.unPause({ from: admin });
            expect(await contract.paused()).is.equal(false);
        });
        it('cannot pause because not owner', async function () {
            await expectRevert(
                contract.pause
                    ({ from: proposer1 }),
                'Ownable: caller is not the owner'
            );
        });
    })
    describe("submit proposal", function () {
        // console.log(this.contract)
        // Test case

        it("proposal sub", async () => {
            (await contract.submitProposal(_fundsRequested, _endTime, _collAmount, _milestonesTotal, proposalID[0], { from: proposer1 }));
            expect(true).to.equal(true);
            (await contract.submitProposal(_fundsRequested, _endTime, _collAmount, _milestonesTotal, proposalID[1], { from: proposer1 }));
            expect(true).to.equal(true);
        });
        it("is not zero address", async () => {

            expect((await contract.proposalList(proposalID[0])).proposer).to.not.equal(0x0000000000000000000000000000000000000000)
        });
        it("fundsRequested verified", async () => {
            expect((await contract.proposalList(proposalID[0])).fundsRequested).to.be.bignumber.equal(_fundsRequested)
        });
        it("endtimestamp verified", async () => {
            expect((await contract.proposalList(proposalID[0])).completionTimestamp).to.be.bignumber.equal(_endTime)
        });
        it("collateral amount verified", async () => {
            expect((await contract.proposalList(proposalID[0])).colletralAmount).to.be.bignumber.equal(_collAmount)
        });
        it("milestone verified", async () => {
            expect((await contract.proposalList(proposalID[0])).totalMilestones).to.be.bignumber.equal(_milestonesTotal)
        });
        it("status is pending", async () => {
            expect((await contract.proposalList(proposalID[0])).status).to.be.bignumber.equal(new BN(0))
        });
        it("totalvote are 0 initially", async () => {
            expect((await contract.proposalList(proposalID[0])).totalVotes).to.be.bignumber.equal(new BN(0))
        });
    });
    describe("failures", async () => {
        it('cannot submit proposal because dublicate ID', async function () {
            await expectRevert(
                contract.submitProposal(_fundsRequested, _endTime, _collAmount, _milestonesTotal, proposalID[0], { from: proposer1 }),
                "Proposal already submitted");
        });
        it('cannot submit proposal because paused is true', async function () {
            await contract.pause({ from: admin });
            await expectRevert(
                (contract.submitProposal(_fundsRequested, _endTime, _collAmount, _milestonesTotal, proposalID[0], { from: proposer1 }))
                , 'Pausable: paused'
            );
        })
        describe("change status", async () => {
            it("non admin tried to change status", async () => {
                await expectRevert(
                    contract.updateProposalStatus(proposalID[0], updatedStatus, { from: proposer1 }),
                    'Ownable: caller is not the owner'
                );
            });
            it("changed to upvote", async () => {
                await contract.updateProposalStatus(proposalID[0], 1, { from: admin })
                expect((await contract.proposalList(proposalID[0])).status).to.be.bignumber.equal(new BN(1))
            });

            it("changed to voting", async () => {
                await contract.updateProposalStatus(proposalID[0], 2, { from: admin })
                expect((await contract.proposalList(proposalID[0])).status).to.be.bignumber.equal(new BN(2))
            });

            it("changed to active", async () => {
                await contract.updateProposalStatus(proposalID[0], 3, { from: admin })
                expect((await contract.proposalList(proposalID[0])).status).to.be.bignumber.equal(new BN(3))
            });
        })
        describe("check rejected proposal", async () => {
            it("rejected proposal", async () => {
                await contract.updateProposalStatus(proposalID[1], 5, { from: admin })
                expect((await contract.proposalList(proposalID[1])).status).to.be.bignumber.equal(new BN(5))
            })
        })
    })
})