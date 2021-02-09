const {BN, constants, expectEvent, expectRevert, ether, balance, time} = require('@openzeppelin/test-helpers');
const {expect} = require('chai');
const RelayStarContract = artifacts.require("RelayStar");

contract('ChallengePlatform', ([challenger1, challenger2, creator1, winner, beneficiary1, invitee, ...restOfAccounts]) => {

    const CHALLENGE_1 = new BN('1');
    const CHALLENGE_2 = new BN('2');
    const ZERO_ETH = ether(new BN('0'));
    const ONE_ETH = ether(new BN('1'));
    const ONE = new BN('1');
    const END_TIMESTAMP_1 = new BN('99999999999');
    const IPFSHASH_1 = 'TEST1'
    const IPFSHASH_2 = '123ABC'
    beforeEach(async () => {
        this.relayStar = await RelayStarContract.new()
    })

    describe('Creating a new Challenge', () => {
        beforeEach(async () => {
            const now = await time.latest();
            this.challengeEndTimestamp = now.add(new BN((13 * 24 * 60 * 60).toString()))
        })
        it('Setup', async () => {
            expect(await this.relayStar.winnerPercentage()).to.be.bignumber.equal('700')
        });

        it('Min entry fee is sent if set by the challenge creator', async () => {
            
            await expectRevert(this.relayStar.startChallenge(beneficiary1,[],this.challengeEndTimestamp, ONE_ETH, IPFSHASH_1, {
                    from: creator1,
                    value: ZERO_ETH
                }), 
                "RelayStar.startChallenge: You must at least match the minimum entry fee you set!"
            )
        })
        
        it('Video must be added after a new challenge is created', async () => {
            expect(await this.relayStar.numChallenges()).to.be.bignumber.equal("0");
            await this.relayStar.startChallenge(beneficiary1,[],this.challengeEndTimestamp, ONE_ETH, IPFSHASH_1, {
                from: creator1,
                value: ONE_ETH
            })

            const { ipfsHash, creator, challengeId } = await this.relayStar.videos(IPFSHASH_1)
            
            expect(creator).to.be.equal(creator1)
            expect(ipfsHash).to.be.equal(IPFSHASH_1)
            expect(challengeId).to.be.bignumber.equal("1")
        })

        it('Challenge must be added to the list of challenges', async () => {
            const logs = await this.relayStar.startChallenge(beneficiary1,[],this.challengeEndTimestamp, ONE_ETH, IPFSHASH_1, {
                from: creator1,
                value: ONE_ETH
            })
            await expectEvent(logs, 'NewChallengeStarted', {
                challengeId: CHALLENGE_1,
                creator: creator1,
                beneficiary: beneficiary1,
                endTimestamp: this.challengeEndTimestamp
            })
            const { challengeId } = await this.relayStar.videos(IPFSHASH_1)
            const { creator, beneficiary, totalFund } = await this.relayStar.challenges(challengeId)
            
            expect(creator).to.be.equal(creator1)
            expect(beneficiary).to.be.equal(beneficiary1)
            expect(totalFund).to.be.bignumber.equal(ONE_ETH)

        })
    });

    describe('Jumping in a challenge', () => { 
        beforeEach(async () => {
            const now = await time.latest();
            const challengeEndTimestamp = now.add(new BN((13 * 24 * 60 * 60).toString()))
            const logs = await this.relayStar.startChallenge(beneficiary1, [challenger1], challengeEndTimestamp, ONE_ETH, IPFSHASH_1, {
                from: creator1,
                value: ONE_ETH
            })
            await expectEvent(logs, 'NewChallengeStarted', {
                challengeId: CHALLENGE_1,
                creator: creator1,
                beneficiary: beneficiary1,
                endTimestamp: challengeEndTimestamp
            })
        })


        it("Can't jumpIn if the challenge is not public and you are not invited", async () => {
            await expectRevert(
                this.relayStar.jumpIn(CHALLENGE_1, [], IPFSHASH_2, { from: challenger2, value: ONE_ETH }),
                "RelayStar.jumpIn: You need a challenger's invitation."
            )  
        })

        it("Can't jumpIn without the minimum entry fee", async () => {
            await expectRevert(
                this.relayStar.jumpIn(CHALLENGE_1, [], IPFSHASH_2, { from: challenger1 }),
                "RelayStar.jumpIn: Please match the minimum entry fee."
            )  
        })

        it("Video and challenge info must be updated on a successful jumpIn", async () => {
            const challengeBefore = await this.relayStar.challenges(CHALLENGE_1)
            const {receipt} = await this.relayStar.jumpIn(CHALLENGE_1, [], IPFSHASH_2, { from: challenger1, value: ONE_ETH })
            await expectEvent(receipt, 'NewChallengerJumpedIn', {
                challengeId: CHALLENGE_1,
                challenger: challenger1,
                ipfsHash: IPFSHASH_2
            })
            
            const video = await this.relayStar.videos(IPFSHASH_2)
            expect(video.challengeId).to.be.bignumber.equal(CHALLENGE_1)
            expect(video.creator).to.be.equal(challenger1)
            expect(video.ipfsHash).to.be.equal(IPFSHASH_2)
            const challengeAfter = await this.relayStar.challenges(video.challengeId)
            // challenger creator and beneficiary shouldn't change but total fund should if there is a min entry fee
            expect(challengeAfter.creator).to.be.equal(challengeBefore.creator)
            expect(challengeAfter.beneficiary).to.be.equal(challengeBefore.beneficiary)
            expect(challengeAfter.totalFund).to.be.bignumber.equal(challengeBefore.totalFund.add(ONE_ETH)) 
        })
        // this test is going to change time to the future so it HAS TO BE LATEST!
        it("Can't jumpIn if the challenge has ended", async () => {
            const { endTimestamp } = await this.relayStar.challenges(CHALLENGE_1)
             await time.increaseTo(endTimestamp.add(ONE))

            await expectRevert(
                this.relayStar.jumpIn(CHALLENGE_1, [], IPFSHASH_2, { from: challenger1, value: ONE_ETH }),
                "RelayStar.jumpIn: Challenge ended."
            )
        })
    })

    describe('Resolve a challenge', () => { 
        beforeEach(async () => {
            const now = await time.latest()
            const challengeEndTimestamp = now.add(new BN((19 * 24 * 60 * 60).toString()))
            const logs = await this.relayStar.startChallenge(beneficiary1, [challenger1], challengeEndTimestamp, ONE_ETH, IPFSHASH_1, {
                from: creator1,
                value: ONE_ETH
            })
            await expectEvent(logs, 'NewChallengeStarted', {
                challengeId: CHALLENGE_1,
                creator: creator1,
                beneficiary: beneficiary1,
                endTimestamp: challengeEndTimestamp
            })
        })
         
        it("must fail if challenge hasn't ended", async () => {
             await expectRevert(
                 this.relayStar.resolveChallenge(CHALLENGE_1, winner),
                 "RelayStar.resolveChallenge : challenge is still going on."
            )
        })

        it("must fail if challenge does not exist", async () => {
             await expectRevert(
                 this.relayStar.resolveChallenge(new BN("1000"), winner),
                 "RelayStar.resolveChallenge : challenge does not exists"
            )
        })

        it("total funds are 0 after resolved", async () => {
            const {totalFund, endTimestamp} = await this.relayStar.challenges(CHALLENGE_1)
            await time.increaseTo(endTimestamp.add(ONE));
            const {receipt} = await this.relayStar.resolveChallenge(CHALLENGE_1, winner);
            
            await expectEvent(receipt, "ChallengeResolved", {
                challengeId: CHALLENGE_1,
                winner, 
                ipfsHash: "TEST",
                totalFund
            })
            const challengeAfterResolve = await this.relayStar.challenges(CHALLENGE_1)
            expect(
                challengeAfterResolve.totalFund
            ).to.be.bignumber.equal("0");

        })

        it("winner's balance must be update", async () => {
            // winners share = 100 - (beneficiary's share) - (creator's share)
            const winnerPercentage = new BN("10000")
                .sub(await this.relayStar.creatorPercentage())
                .sub(await this.relayStar.beneficiaryPercentage())
            const winnerBalanceBefore = await balance.current(winner);
            

            const challengeBefore = await this.relayStar.challenges(CHALLENGE_1)
            const winnerShare =  challengeBefore.totalFund
                            .div(new BN("10000"))
                .mul(winnerPercentage)
            await time.increaseTo(challengeBefore.endTimestamp.add(ONE));
            await this.relayStar.resolveChallenge(CHALLENGE_1, winner, { from: creator1 });
    
            expect(await balance.current(winner))
                .to.be.bignumber.equal(
                    winnerBalanceBefore.add(
                       winnerShare
                    )
                )
        });

        it("creator's balance must be update", async () => {
            
            const creatorPercentage = await this.relayStar.creatorPercentage() 
            const creatorBalanceBefore = await balance.current(creator1);
            const challengeBefore = await this.relayStar.challenges(CHALLENGE_1)
            
            const creatorShare = challengeBefore.totalFund
                            .div(new BN("10000"))
                .mul(creatorPercentage)
            await time.increaseTo(challengeBefore.endTimestamp.add(ONE));
            // for simiplicity lest call it from beneficiary otherwise we also need to track tx
            await this.relayStar.resolveChallenge(CHALLENGE_1, winner, { from: beneficiary1 });
    
            expect(await balance.current(creator1))
                .to.be.bignumber.equal(
                    creatorBalanceBefore.add(
                        creatorShare
                    )
                )
        });

        it("beneficiary's balance must be updated", async () => {
            
            const beneficiaryPercentage = await this.relayStar.creatorPercentage() 
            const beneficiaryBalanceBefore = await balance.current(creator1);
            const challengeBefore = await this.relayStar.challenges(CHALLENGE_1)
            
            const beneficiaryShare = challengeBefore.totalFund
                            .div(new BN("10000"))
                .mul(beneficiaryPercentage)
            await time.increaseTo(challengeBefore.endTimestamp.add(ONE));
            // for simiplicity lest call it from beneficiary otherwise we also need to track tx
            await this.relayStar.resolveChallenge(CHALLENGE_1, winner, { from: beneficiary1 });
    
            expect(await balance.current(creator1))
                .to.be.bignumber.equal(
                    beneficiaryBalanceBefore.add(
                        beneficiaryShare
                    )
                )
        });

    })
    

});