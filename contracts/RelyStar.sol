// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/GSN/Context.sol"; 
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

/**
 * @title The Challenge contract
 * @author The Cool Devs (Lijia, Emma, Ben, Mehrad)
 * @dev a contract facilitating the video relay challenge
 */
contract RelayStar is
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
      bool isPublic;
      bool isActive;
      uint256 totalFund;
      uint256 minEntryFee;
      uint256 endTimestamp;
      address payable creator;
      address payable beneficiary;
      mapping(address => bool)  invitedAddresses;
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

        
        require(now < _endTimestamp, "RelayStar.startChallenge: endTimestamp must be bigger than current timestamp.");
        require(msg.value >= _minEntryFee, "RelayStar.startChallenge: You must at least match the minimum entry fee you set!");
        uint256 challengeId = numChallenges + 1;

        require(challenges[challengeId].creator == address(0), "RelayStar.startChallenge: Challenge already exists.");

        challenges[challengeId] = Challenge({
          creator: _msgSender(),
          beneficiary: _beneficiary,
          isPublic: _invitedAddresses.length == 0,
          endTimestamp: _endTimestamp,
          minEntryFee: _minEntryFee,
          totalFund: msg.value,
          isActive : true
        });

        // adding invitees to the mapping
        for(uint256 i =0 ; i< _invitedAddresses.length; i++) {
          challenges[challengeId].invitedAddresses[_invitedAddresses[i]] = true;
        }

        videos[_ipfsHash] = Video({
          ipfsHash: _ipfsHash,
          creator: _msgSender(),
          challengeId: challengeId
        });
        numChallenges = numChallenges.add(1);

        emit NewChallengeStarted(challengeId, _msgSender(), _beneficiary, _endTimestamp);

        return challengeId;

    }

    function jumpIn(uint256 _challengeId,
      address[] calldata _invitedAddresses, string calldata _ipfsHash)
      nonReentrant public payable {
        
        Challenge storage challenge = challenges[_challengeId];

        // check if challenge hasn't ended
        require(now < challenge.endTimestamp, "RelayStar.jumpIn: Challenge ended.");

        if (!challenge.isPublic) {
          // if msg.sender is invited
          require(challenge.invitedAddresses[_msgSender()], "RelayStar.jumpIn: You need a challenger's invitation.");
        }

        // if there's an entry fee
        if(challenge.minEntryFee > 0) {
          require(msg.value >= challenge.minEntryFee, "RelayStar.jumpIn: Please match the minimum entry fee.");
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
      require(challenge.creator != address(0), "RelayStar.resolveChallenge : challenge does not exists");

      // check if endTimestamp has reached
      require(now > challenge.endTimestamp && challenge.isActive, "RelayStar.resolveChallenge : challenge is still going on.");
      //TODO : send a chinlink get req to get highest like 
      uint256 totalFund = challenge.totalFund;

      //commented code explaination : originally used to like this but the only way to prevent 
      // resolveing a challenge more than once is to check totalBalance. 
      if(totalFund > 0) {
        challenge.totalFund = 0;
        _splitFundsInChallenge(challenge.beneficiary, challenge.creator, _winner, totalFund);
      }
      challenge.isActive = false;

      // TODO: REPLACE IPFS_HASH WITH HARDCODED TEXT BELOW
      emit ChallengeResolved(_challengeId, _winner, "TEST", totalFund);
    }

    function _splitFundsInChallenge(address payable _beneficiary,
      address payable _creator, address payable _winner, uint256 _totalFund ) private  {
        // Calculate Beneficiary's share
        uint256 beneficiaryShare = _totalFund.div(ONE_HUNDRED_SCALED).mul(beneficiaryPercentage);
        (bool beneficiaryReceipt, ) = _beneficiary.call{value : beneficiaryShare}("");
        require(beneficiaryReceipt, "RelayStar._splitFundsInChallenge : Failed to send beneficiary's share.");

        // Calculate creator's share
        uint256 creatorShare = _totalFund.div(ONE_HUNDRED_SCALED).mul(creatorPercentage);
        (bool creatorReceipt, ) = _creator.call{value : creatorShare}("");
        require(creatorReceipt, "RelayStar._splitFundsInChallenge : Failed to send creator's share.");

        // Calculate winner's share
        uint256 winnerShare = _totalFund.sub(beneficiaryShare).sub(creatorShare);
        (bool winnerReceipt, ) = _winner.call{value : winnerShare}("");
        require(winnerReceipt, "RelayStar._splitFundsInChallenge : Failed to send highestLike's share.");

        emit FundsSplitted(_creator, _winner, _beneficiary, _totalFund);
      }

}