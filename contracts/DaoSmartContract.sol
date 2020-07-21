pragma solidity ^0.6.0;
import "@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "./DaoStakeInterface.sol";

contract DaoSmartContract is OwnableUpgradeSafe, PausableUpgradeSafe {
    // Library for safely handling uint256
    using SafeMath for uint256;

    enum Status {PENDING, UPVOTE, VOTING, ACTIVE, COMPLETED, REJECTED}
    address public phnxContractAddress;
    address public phnxStakingContractAddress;
    mapping(string => Proposal) public proposalList;
    mapping(address => mapping(string => bool)) public votes;
    struct Proposal {
        uint256 fundsRequested;
        uint256 initiationTimestamp;
        uint256 completionTimestamp;
        uint256 colletralAmount;
        uint256 totalMilestones;
        uint256 completedMilestones;
        uint256 status;
        uint256 totalVotes;
        address proposer;
    }

    event ProposalSubmitted(
        uint256 fundsRequested,
        uint256 initiationTimestamp,
        uint256 completionTimestamp,
        uint256 colletralAmount,
        uint256 totalMilestones,
        uint256 status,
        uint256 totalVotes,
        address proposer
    );
    event ProposalStatusUpdated(
        string _proposalId,
        uint256 _previousStatus,
        uint256 _newStatus
    );
    event FundsReleased(
        string _proposalId,
        uint256 _amountReleased,
        uint256 _milestoneNumber,
        address _admin
    );
    event CollateralDeposited(
        string _proposalId,
        uint256 _collateralAmount,
        address _proposer
    );
    event ColleteralWithdrawn(
        string _proposalId,
        uint256 _collateralAmount,
        address _proposer
    );
    event Voted(
        string _proposalId,
        uint256 altQuantity,
        uint256 _days,
        uint256 rewardAmount
    );
    event CompletedMilestone(
        string _proposalId,
        uint256 _milestoneNumber,
        uint256 _completedMilestones
    );

    function initialize() external initializer {
        OwnableUpgradeSafe.__Ownable_init();
        PausableUpgradeSafe.__Pausable_init();
        phnxContractAddress = 0xfe1b6ABc39E46cEc54d275efB4b29B33be176c2A;
        phnxStakingContractAddress = 0xe5242650Ed4a1C0bBa33204Efa1ca76772a5544C;
    }

    function submitProposal(
        uint256 fundsRequested,
        uint256 endTimestamp,
        uint256 colletralAmount,
        uint256 totalMilestones,
        string calldata _proposalId
    ) public whenNotPaused {
        require(
            proposalList[_proposalId].proposer == address(0),
            "zero address"
        );
        proposalList[_proposalId] = Proposal(
            fundsRequested,
            block.timestamp,
            endTimestamp,
            colletralAmount,
            totalMilestones,
            0,
            uint256(Status.PENDING),
            0,
            msg.sender
        );
        emit ProposalSubmitted(
            proposalList[_proposalId].fundsRequested,
            proposalList[_proposalId].initiationTimestamp,
            proposalList[_proposalId].completionTimestamp,
            proposalList[_proposalId].colletralAmount,
            proposalList[_proposalId].totalMilestones,
            proposalList[_proposalId].status,
            proposalList[_proposalId].totalVotes,
            proposalList[_proposalId].proposer
        );
    }

    function stake(
        string calldata _proposalId,
        uint256 _altQuantity,
        uint256 _days
    ) public whenNotPaused returns (uint256 rewardAmount) {
        require(
            votes[msg.sender][_proposalId] == false,
            "already staked once for this proposal"
        );
        rewardAmount = DaoStakeContract(phnxStakingContractAddress).stakeALT(
            _altQuantity,
            _days
        );
        votes[msg.sender][_proposalId] = true;
        proposalList[_proposalId].totalVotes = proposalList[_proposalId]
            .totalVotes
            .add(1);
        emit Voted(_proposalId, _altQuantity, _days, rewardAmount);
    }

    function withdrawCollateral(string calldata _proposalId)
        public
        whenNotPaused
    {
        require(
            proposalList[_proposalId].status == uint256(Status.COMPLETED),
            "Project status not completed"
        );
        IERC20(phnxContractAddress).transfer(
            msg.sender,
            proposalList[_proposalId].colletralAmount
        );
        emit ColleteralWithdrawn(
            _proposalId,
            proposalList[_proposalId].colletralAmount,
            msg.sender
        );
    }

    function updateProposalStatus(string calldata _proposalId, uint256 _status)
        public
        onlyOwner
    {
        uint256 oldStatus = proposalList[_proposalId].status;
        if (
            _status == uint256(Status.UPVOTE) &&
            proposalList[_proposalId].status == uint256(Status.PENDING)
        ) {
            proposalList[_proposalId].status == uint256(Status.UPVOTE);
        }

        if (
            _status == uint256(Status.VOTING) &&
            proposalList[_proposalId].status == uint256(Status.UPVOTE)
        ) {
            proposalList[_proposalId].status == uint256(Status.VOTING);
        }
        if (
            _status == uint256(Status.ACTIVE) &&
            proposalList[_proposalId].status == uint256(Status.VOTING)
        ) {
            proposalList[_proposalId].status == uint256(Status.ACTIVE);
        }
        if (
            _status == uint256(Status.REJECTED) &&
            proposalList[_proposalId].status == uint256(Status.PENDING)
        ) {
            proposalList[_proposalId].status == uint256(Status.REJECTED);
        }
        emit ProposalStatusUpdated(
            _proposalId,
            oldStatus,
            proposalList[_proposalId].status
        );
    }

    function issueFunds(
        string calldata _proposalId,
        uint256 _amount,
        uint256 _milestoneNumber
    ) public onlyOwner {
        require(
            proposalList[_proposalId].status == uint256(Status.ACTIVE),
            "status not active"
        );

        require(
            proposalList[_proposalId].completedMilestones !=
                proposalList[_proposalId].totalMilestones,
            "mileStones completed"
        );
        if (proposalList[_proposalId].fundsRequested != 0) {
            IERC20(phnxContractAddress).transfer(
                proposalList[_proposalId].proposer,
                _amount
            );
            proposalList[_proposalId]
                .completedMilestones = proposalList[_proposalId]
                .completedMilestones
                .add(1);
            proposalList[_proposalId].fundsRequested = proposalList[_proposalId]
                .fundsRequested
                .sub(_amount);
        }
        emit CompletedMilestone(
            _proposalId,
            _milestoneNumber,
            proposalList[_proposalId].completedMilestones
        );

        if (proposalList[_proposalId].fundsRequested == 0) {
            uint256 oldStatus = proposalList[_proposalId].status;
            proposalList[_proposalId].status = uint256(Status.COMPLETED);
            emit ProposalStatusUpdated(
                _proposalId,
                oldStatus,
                proposalList[_proposalId].status
            );
        }

        emit FundsReleased(_proposalId, _amount, _milestoneNumber, msg.sender);
    }

    function getBaseInterest() public view returns (uint256) {
        return (
            DaoStakeContract(phnxStakingContractAddress).baseInterestRate()
        );
    }
}
