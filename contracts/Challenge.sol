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
contract EphimeraMarketplace is
    ReentrancyGuard,
    Context
{
    using SafeMath for uint256;

    event ChallengeStarted(
      uint256 indexed challengeId, 
      address creator, 
      address beneficiary, 
      uint256 endTimestamp
    );

    struct Challenge {
      address creator;
      address beneficiary;
      address[] invitedAddresses;
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
    mapping(uint256 => Video) public videos;
    mapping(address => Challenge) public challengers; //TODO maybe we should change this so we can allow an address to participate in more than one challenges at a time
    mapping(uint256 => Challenge) public challenges;

    function startChallenge(address _beneficiary, address[] _invitedAddresses, uint256 _endTimestamp, uint256 _minEntryFee, string _videoIPFSHash) public returns (uint256) {

      require(msg.value >= _minEntryFee, "startChallenge: You must at least match the minimum entry fee you set!");

      uint256 _challengeId = numChallenges;

      challenges[_challengeId] = Challenge({
        creator: _msgSender(),
        beneficiary: _beneficiary,
        invitedAddresses: _invitedAddresses,
        isPublic: _invitedAddresses.length == 0,
        endTimestamp: _endTimestamp,
        minEntryFee: _minEntryFee,
        totalFund: msg.value,
      });

      videos[_videoIPFSHash] = Video({
        ipfsHash: _videoIPFSHash,
        creator: _msgSender(),
        challengeId: _challengeId;
      });

      emit ChallengeStarted(_challengeId, _msgSender(), _beneficiary, _endTimestamp);

      numChallenges = numChallenges.add(1);
      return challengeId;

    }

}