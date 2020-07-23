let { accounts, contract } = require('@openzeppelin/test-environment');
// let { contractDao, contractPHNX } = contract
// let contractPHNX = contract
const { BN, constants, expectEvent, expectRevert } = require('@openzeppelin/test-helpers');
const { expect } = require('chai');
const { ZERO_ADDRESS } = constants;
const admin = accounts[0];
const proposer1 = accounts[1];
const proposer2 = accounts[2];
let contractDao;
let contractPHNX;

const DaoSmartContract = contract.fromArtifact('DaoSmartContract');
const PHNXToken = contract.fromArtifact('PhoenixDAO')
//initialize values here for proposal submission
const proposalID = ["0", "1", "2", "3"];
const _fundsRequested = new BN("10000000000000000000");
const _issueFunds = new BN("5000000000000000000");
const _endTime = new BN(500);
const _collAmount = new BN("10000000000000000000");
const _milestonesTotal = new BN(2);
//for updating status
const updatedStatus = 2

describe("testin DAO", async () => {
    before(async () => {
        contractDao = await DaoSmartContract.new({ from: admin });
        contractPHNX = await PHNXToken.new({ from: admin });
        // console.log(contract.address);
        await contractDao.initialize(contractPHNX.address, { from: admin });
    })
    it("transfer phnx to DAO", async () => {
        await contractPHNX.transfer(contractDao.address, "10000000000000000000", { from: admin })
        expect(await contractPHNX.balanceOf(contractDao.address)).to.be.bignumber.equal(new BN("10000000000000000000"))
    });
    it("give approval to Daocontract", async () => {
        await contractPHNX.approve(contractDao.address, "10000000000000000000", { from: admin });
        expect(await contractPHNX.allowance(admin, contractDao.address)).to.be.bignumber.equal(new BN("10000000000000000000"))
    })
    describe("only owner can call", async () => {
        it('can pause', async function () {
            await contractDao.pause({ from: admin });
            expect(await contractDao.paused()).to.equal(true);
        });

        it('can unpause', async function () {
            await contractDao.unPause({ from: admin });
            expect(await contractDao.paused()).is.equal(false);
        });
        it('cannot pause because not owner', async function () {
            await expectRevert(
                contractDao.pause
                    ({ from: proposer1 }),
                'Ownable: caller is not the owner'
            );
        });
    })
    describe("submit proposal", function () {
        // console.log(this.contract)
        // Test case

        it("proposal sub", async () => {
            (await contractDao.submitProposal(_fundsRequested, _endTime, _collAmount, _milestonesTotal, proposalID[0], { from: admin }));
            (await contractDao.submitProposal(_fundsRequested, _endTime, _collAmount, _milestonesTotal, proposalID[1], { from: proposer1 }));
            expect(true).to.equal(true);
        });
        it("is not zero address", async () => {

            expect((await contractDao.proposalList(proposalID[0])).proposer).to.not.equal(0x0000000000000000000000000000000000000000)
        });
        it("fundsRequested verified", async () => {
            expect((await contractDao.proposalList(proposalID[0])).fundsRequested).to.be.bignumber.equal(_fundsRequested)
        });
        it("endtimestamp verified", async () => {
            expect((await contractDao.proposalList(proposalID[0])).completionTimestamp).to.be.bignumber.equal(_endTime)
        });
        it("collateral amount verified", async () => {
            expect((await contractDao.proposalList(proposalID[0])).colletralAmount).to.be.bignumber.equal(_collAmount)
        });
        it("milestone verified", async () => {
            expect((await contractDao.proposalList(proposalID[0])).totalMilestones).to.be.bignumber.equal(_milestonesTotal)
        });
        it("status is pending", async () => {
            expect((await contractDao.proposalList(proposalID[0])).status).to.be.bignumber.equal(new BN(0))
        });
        it("totalvote are 0 initially", async () => {
            expect((await contractDao.proposalList(proposalID[0])).totalVotes).to.be.bignumber.equal(new BN(0))
        });
    });
    describe("expecting reverts from all function in this block", async () => {
        it('cannot submit proposal because dublicate ID', async function () {
            await expectRevert(
                contractDao.submitProposal(_fundsRequested, _endTime, _collAmount, _milestonesTotal, proposalID[0], { from: proposer1 }),
                "Proposal already submitted");
        });
        it('cannot submit proposal because paused is true', async function () {
            await contractDao.pause({ from: admin });
            await expectRevert(
                (contractDao.submitProposal(_fundsRequested, _endTime, _collAmount, _milestonesTotal, proposalID[0], { from: proposer1 }))
                , 'Pausable: paused'
            );
        })

    })
    describe("change status", async () => {
        it("non admin tried to change status", async () => {
            await expectRevert(
                contractDao.updateProposalStatus(proposalID[0], updatedStatus, { from: proposer1 }),
                'Ownable: caller is not the owner'
            );
        });
        it("changed to upvote", async () => {
            await contractDao.updateProposalStatus(proposalID[0], 1, { from: admin })
            expect((await contractDao.proposalList(proposalID[0])).status).to.be.bignumber.equal(new BN(1))
        });
        it("changed to voting", async () => {
            await contractDao.updateProposalStatus(proposalID[0], 2, { from: admin })
            expect((await contractDao.proposalList(proposalID[0])).status).to.be.bignumber.equal(new BN(2))
        });

        it("changed to active", async () => {
            await contractDao.updateProposalStatus(proposalID[0], 3, { from: admin })
            expect((await contractDao.proposalList(proposalID[0])).status).to.be.bignumber.equal(new BN(3))
        });
        it("rejected proposal", async () => {
            await contractDao.updateProposalStatus(proposalID[1], 5, { from: admin })
            expect((await contractDao.proposalList(proposalID[1])).status).to.be.bignumber.equal(new BN(5))
        })
    })

    describe("verify issue funds functionality", async () => {

        it("issues funds", async () => {
            for (let i = 0; i < 2; i++) {
                contractDao.issueFunds(proposalID[0], _issueFunds, { from: admin });
            }
            let x = await contractDao.proposalList(proposalID[0]);
            expect(x.status).to.be.bignumber.equal(new BN(4));
        })
        it("should not issue funds after status completed", async () => {
            await expectRevert(
                contractDao.issueFunds(proposalID[0], _issueFunds, { from: admin }), "status not active")
        })
    })
    describe("verify withdraw colletral", async () => {
        it("proposer can withdraw colletral", async () => {
            await contractDao.unPause({ from: admin });
            await contractDao.withdrawCollateral(proposalID[0], { from: proposer1 });
            let x = await contractDao.proposalList(proposalID[0]);
            expect(x.status).to.be.bignumber.equal(new BN(4));
        })
        it("cannot withdraw colletral because status not completed", async () => {
            await expectRevert(
                contractDao.withdrawCollateral(proposalID[1], { from: proposer1 }),"Project status not completed"
            )
        })
    })
})