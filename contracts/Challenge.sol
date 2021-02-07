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

    event ChallengeStarted(
      uint256 indexed challengeId, 
      address indexed creator, 
      address indexed beneficiary, 
      uint256 endTimestamp
    );

    event NewChallengerJoined(
      uint256 indexed challengeId,
      address indexed challenger,
      string indexed ipfsHash
    );

    struct Challenge {
      address creator;
      address beneficiary;
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
    uint256 public bestVideoPercentage = 700;

    mapping(string => Video) public videos;
    mapping(address => Challenge) public challengers; //TODO maybe we should change this so we can allow an address to participate in more than one challenges at a time
    mapping(uint256 => Challenge) public challenges;

    function startChallenge(address _beneficiary, address[] calldata _invitedAddresses,
      uint256 _endTimestamp, uint256 _minEntryFee, string calldata _ipfsHash) 
      nonReentrant public payable returns (uint256) {
      require(now < _endTimestamp, "");
      require(msg.value >= _minEntryFee, "startChallenge: You must at least match the minimum entry fee you set!");
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
      //adding invitees to the mapping
      for(uint256 i =0 ; i< _invitedAddresses.length; i++) {
        challenges[challengId].invitedAddresses[_invitedAddresses[i]] = true;
      }

      videos[_ipfsHash] = Video({
        ipfsHash: _ipfsHash,
        creator: _msgSender(),
        challengeId: challengId
      });
      numChallenges = numChallenges.add(1);

      emit ChallengeStarted(challengId, _msgSender(), _beneficiary, _endTimestamp);

      return challengId;

    }

    function participateInChallenge(uint256 _challengeId,
      address[] calldata _invitedAddresses, string calldata _ipfsHash)
      nonReentrant public payable {
        
        Challenge storage challenge = challenges[_challengeId];
        // challege is going on
        // require( challenge.isActive, "Error in challenge.participateInChallenge : Challenge resolved.");
        require(now < challenge.endTimestamp, "challenge.participateInChallenge : challenge resolved.");
        // in case of challenge is not active, 
        if (!challenge.isPublic) {
          require(challenge.invitedAddresses[_msgSender()], "challenge.participateInChallenge : user is not invited");
        }

        //if there's entrance fee
        if(challenge.minEntryFee > 0) {
          require(msg.value >= challenge.minEntryFee, "challenge.participateInChallenge : Must at least pay the entrance fee.");
        }

        challenge.totalFund += msg.value;
        challenge.invitedAddresses[_msgSender()] = true;

        //adding invitees to the mapping
        for(uint256 i =0 ; i< _invitedAddresses.length; i++) {
          challenge.invitedAddresses[_invitedAddresses[i]] = true;
        }
        videos[_ipfsHash] = Video({
        ipfsHash: _ipfsHash,
        creator: _msgSender(),
        challengeId: _challengeId
      });
        // challengers[msg.sender] = challenge; TODO: not sure why
        emit NewChallengerJoined(_challengeId, _msgSender(), _ipfsHash);
    }

    


    

}