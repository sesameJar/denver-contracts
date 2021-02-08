// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/GSN/Context.sol"; 
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

/**
 * @title The Challenge contract
 * @author The Cool Devs 
 * @dev a contract facilitating the video relay challenge
 */
contract ChallengePlatform is
    ReentrancyGuard,
    Context
{
    using SafeMath for uint256;

    event NewChallengeStarted(
      uint256 indexed challengeId, 
      address indexed creator, 
      address indexed beneficiary, 
      uint256 endTimestamp
    );

    event NewChallengerJumpedIn(
      uint256 indexed challengeId,
      address indexed challenger,
      string ipfsHash
    );

    event ChallengeResolved(
      uint256 indexed challengeId,
      address indexed winner,
      string ipfsHash,
      uint256 totalFund
    );

    event FundsSplitted(
      address indexed beneficiary,
      address indexed creator,
      address indexed winner,
      uint256 totalFund
    );

    struct Challenge {
      address payable creator;
      address payable beneficiary;
      mapping(address => bool)  invitedAddresses;
      bool isPublic;
      uint256 endTimestamp;
      uint256 minEntryFee;
      uint256 totalFund;
    }

    struct Video {
      string ipfsHash;
      address creator;
      uint256 challengeId;
    }

    uint256 public numChallenges = 0;
    uint256 public creatorPercentage = 300;
    uint256 public beneficiaryPercentage = 9000;
    uint256 public winnerPercentage = 700;// maybe we can drop this
    uint256 constant ONE_HUNDRED_SCALED = 10000;

    mapping(string => Video) public videos;
    mapping(uint256 => Challenge) public challenges;

    function startChallenge(address payable _beneficiary, address[] calldata _invitedAddresses,
      uint256 _endTimestamp, uint256 _minEntryFee, string calldata _ipfsHash) 
      nonReentrant public payable returns (uint256) {
      require(now < _endTimestamp, "Challenge.startChallenge: endTimestamp must be bigger than current timestamp.");
      require(msg.value >= _minEntryFee, "Challenge.startChallenge: You must at least match the minimum entry fee you set!");
      uint256 challengId = numChallenges + 1;

      // Challenge storage challenge = challenges[challengId];

      challenges[challengId] = Challenge({
        creator: _msgSender(),
        beneficiary: _beneficiary,
        isPublic: _invitedAddresses.length == 0,
        endTimestamp: _endTimestamp,
        minEntryFee: _minEntryFee,
        totalFund: msg.value
      });

      // adding invitees to the mapping
      for(uint256 i =0 ; i< _invitedAddresses.length; i++) {
        challenges[challengId].invitedAddresses[_invitedAddresses[i]] = true;
      }

      videos[_ipfsHash] = Video({
        ipfsHash: _ipfsHash,
        creator: _msgSender(),
        challengeId: challengId
      });
      numChallenges = numChallenges.add(1);

      emit NewChallengeStarted(challengId, _msgSender(), _beneficiary, _endTimestamp);

      return challengId;

    }

    function jumpIn(uint256 _challengeId,
      address[] calldata _invitedAddresses, string calldata _ipfsHash)
      nonReentrant public payable {
        
        Challenge storage challenge = challenges[_challengeId];

        // challenge hasn't ended
        require(now < challenge.endTimestamp, "Challenge.jumpIn: Challenge ended.");

        if (!challenge.isPublic) {
          require(challenge.invitedAddresses[_msgSender()], "Challenge.jumpIn: You need a challenger's invitation.");
        }

        // if there's an entry fee
        if(challenge.minEntryFee > 0) {
          require(msg.value >= challenge.minEntryFee, "Challenge.jumpIn: Please match the minimum entry fee.");
        }

        challenge.totalFund = challenge.totalFund.add(msg.value);
        challenge.invitedAddresses[_msgSender()] = true;

        // adding invitees to the mapping
        for(uint256 i =0 ; i< _invitedAddresses.length; i++) {
          challenge.invitedAddresses[_invitedAddresses[i]] = true;
        }
        videos[_ipfsHash] = Video({
          ipfsHash: _ipfsHash,
          creator: _msgSender(),
          challengeId: _challengeId
        });

        emit NewChallengerJumpedIn(_challengeId, _msgSender(), _ipfsHash);
    }

    function resolveChallenge(uint256 _challengeId, address payable _winner)payable  public  {
      Challenge storage challenge = challenges[_challengeId];

      // check if challenge exists
      require(challenge.creator != address(0), "Challenge.resolveChallenge : challenge does not exists");

      // check if endTimestamp has reached
      require(now > challenge.endTimestamp, "Challenge.resolveChallenge : challenge is still going on.");
      require(challenge.totalFund > 0, "Challenge.resolveChallenge : Challenge either resolve or raised zero fund.");
      //TODO : send a chinlink get req to get highest like 
      uint256 totalFund = challenge.totalFund;

      //commented code explaination : originally used to like this but the only way to prevent 
      // resolveing a challenge more than once is to check totalBalance. 
      // if(totalFund > 0) {
      //   challenge.totalFund = 0;
      //   _splitFundsInChallenge(challenge.beneficiary, challenge.creator, _winner, totalFund);
      // } 
      challenge.totalFund = 0;
      _splitFundsInChallenge(challenge.beneficiary, challenge.creator, _winner, totalFund);
      // TODO: REPLACE IPFS_HASH WITH HARDCODED TEXT BELOW
      emit ChallengeResolved(_challengeId, _winner, "TEST", totalFund);
    }

    function _splitFundsInChallenge(address payable _beneficiary,
      address payable _creator, address payable _winner, uint256 _totalFund ) private  {
        // Calculate Beneficiary's share
        uint256 beneficiaryShare = _totalFund.div(ONE_HUNDRED_SCALED).mul(beneficiaryPercentage);
        (bool beneficiaryReceipt, ) = _beneficiary.call{value : beneficiaryShare}("");
        require(beneficiaryReceipt, "Challenge._splitFundsInChallenge : Failed to send beneficiary's share.");

        // Calculate creator's share
        uint256 creatorShare = _totalFund.div(ONE_HUNDRED_SCALED).mul(creatorPercentage);
        (bool creatorReceipt, ) = _creator.call{value : creatorShare}("");
        require(creatorReceipt, "Challenge._splitFundsInChallenge : Failed to send creator's share.");

        // Calculate winner's share
        uint256 winnerShare = _totalFund.sub(beneficiaryShare).sub(creatorShare);
        (bool winnerReceipt, ) = _winner.call{value : winnerShare}("");
        require(winnerReceipt, "Challenge._splitFundsInChallenge : Failed to send highestLike's share.");

        emit FundsSplitted(_creator, _winner, _beneficiary, _totalFund);
      }

}