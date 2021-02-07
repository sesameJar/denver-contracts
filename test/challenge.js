const {BN, constants, expectEvent, expectRevert, ether, balance} = require('@openzeppelin/test-helpers');

const ChallengePlatform = artifacts.require("ChallengePlatform");

contract('ChallengePlatform', ([challenger1, challender2, creator1, creator2, beneficiary, invitee, ...restOfAccounts]) => {

    const CHALLENGE_1 = new BN('1');
    const CHALLENGE_2 = new BN('2');
    const ONE_ETH = ether(new BN('1'));

    it('setup', async () => {
        const challengeContract = await ChallengePlatform.deployed()
    
        assert.equal(challengeContract.bestVideoPercentage(), 700, "BEST VIDEO PLATFORM IS NOT EQUAL TO 7%");

  });
});