const {BN, constants, expectEvent, expectRevert, ether, balance} = require('@openzeppelin/test-helpers');
const {expect} = require('chai');
const ChallengePlatform = artifacts.require("ChallengePlatform");

contract('ChallengePlatform', ([challenger1, challender2, creator1, creator2, beneficiary1, invitee, ...restOfAccounts]) => {

    const CHALLENGE_1 = new BN('1');
    const CHALLENGE_2 = new BN('2');
    const ONE_ETH = ether(new BN('1'));
    beforeEach(async () => {
        this.challenge = await ChallengePlatform.new()
    })

    describe('Creating a new Challenge', () => {
        it('setup', async () => {
        
            // assert.equal(challengeContract.bestVideoPercentage(), 700, "BEST VIDEO PLATFORM IS NOT EQUAL TO 7%");
            expect(await this.challenge.bestVideoPercentage()).to.be.bignumber.equal('700')
        });
        
        it('Video must be added after a new challenge is created',async () => {
            await this.challenge.startChallenge(beneficiary1,[],new BN('99999999999999'), ONE_ETH, "TEST", {
                from: creator1,
                value: ONE_ETH
            })

            const { ipfsHash, creator, challengeId } = await this.challenge.videos("TEST")
            
            expect(creator).to.be.equal(creator1)
            expect(ipfsHash).to.be.equal("TEST")
            expect(challengeId).to.be.bignumber.equal("1")
        })

        it('challenge must be added to the list of challenges', async () => {
             await this.challenge.startChallenge(beneficiary1,[],new BN('99999999999999'), ONE_ETH, "TEST1", {
                from: creator1,
                value: ONE_ETH
            })
            const { challengeId } = await this.challenge.videos("TEST1")
            const { creator, beneficiary, totalFund } = await this.challenge.challenges(challengeId)
            
            expect(creator).to.be.equal(creator1)
            expect(beneficiary).to.be.equal(beneficiary1)
            expect(totalFund).to.be.bignumber.equal(ONE_ETH)

        })
    });

    describe('Jumping in a challenge', () => { 
        beforeEach(async() => {
            await this.challenge.startChallenge(beneficiary1,[],new BN('99999999999999'), ONE_ETH, "TEST1", {
                from: creator1,
                value: ONE_ETH
            })
        })
        it("can't jumpIn if entrance fee is lower than the challge's is", async ()=>{
            await expectRevert(
                this.challenge.participateInChallenge(CHALLENGE_1, [], '123ABC', {from: challender2 }),
                "challenge.participateInChallenge : Must at least pay the entrance fee."
            )  
        })

        it("Video info must be updated on a successful jumpIn", async ()=>{
            const { challengeId } = await this.challenge.videos("TEST1")
            const { creator, beneficiary, totalFund } = await this.challenge.challenges(challengeId)
            
            expect(creator).to.be.equal(creator1)
            expect(beneficiary).to.be.equal(beneficiary1)
            expect(totalFund).to.be.bignumber.equal(ONE_ETH) 
        })
    })
    

});