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

    uint256 public numChallenges;

    event ChallengeStarted(
      uint256 indexed challengeId, 
      address creator, 
      address beneficiary, 
      uint256 endTimestamp
    );

    struct Challenge {
      uint256 id;
      uint256 endTimestamp;
      address creator;
    }

    function startChallenge(address beneficiary, string videoIPFSHash, bool isPublic, uin256 endTimestamp) public returns (uint256) {

      numChallenges = numChallenges.add(1);
      uint256 challengeId = numChallenges;
      emit ChallengeStarted(challengeId, _msgSender(), beneficiary, endTimestamp)
      return challengeId;

    }

}