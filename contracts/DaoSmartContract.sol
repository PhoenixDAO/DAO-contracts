pragma solidity ^0.6.0;
import "@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";

contract DaoSmartContract is OwnableUpgradeSafe, PausableUpgradeSafe {
    using SafeMath for uint256;

    enum Status {PENDING, UPVOTE, VOTING, ACTIVE, COMPLETED, REJECTED}
    // 0 -> pending
    // 1 -> upvote
    // 2 -> voting
    // 3 -> active
    // 4 -> completed
    // 5 -> rejected
    address public phnxContractAddress;
    
    uint256 public collateralAmount;

    mapping(string => Proposal) public proposalList;
    
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
        string _Id,
        uint256 fundsRequested,
        uint256 initiationTimestamp,
        uint256 completionTimestamp,
        uint256 colletralAmount,
        uint256 totalMilestones,
        uint256 status,
        uint256 totalVotes,
        address proposer
    );

    event ProposalEditted(
        string _Id,
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

    event ColleteralWithdrawn(
        string _proposalId,
        uint256 _collateralAmount,
        address _proposer
    );
    // event Voted(
    //     string _proposalId,
    //     uint256 altQuantity,
    //     uint256 _days,
    //     uint256 rewardAmount
    // );
  

    function initialize(address _phoenixContractAddress) external initializer {
        OwnableUpgradeSafe.__Ownable_init();
        PausableUpgradeSafe.__Pausable_init();
        // phnxContractAddress = 0xfe1b6ABc39E46cEc54d275efB4b29B33be176c2A;
        phnxContractAddress = _phoenixContractAddress;
        // phnxStakingContractAddress = 0xe5242650Ed4a1C0bBa33204Efa1ca76772a5544C;
        
    }

    function updateProposal(
        uint256 fundsRequested,
        uint256 endTimestamp,
        uint256 colletralAmount,
        uint256 totalMilestones,
        string calldata _proposalId
    ) external whenNotPaused {
        require(proposalList[_proposalId].proposer != address(0),"This proposal Does not exist");
        address sender = msg.sender;
        require(proposalList[_proposalId].proposer == sender,"Only Owner of propsal can edit this propsal");
        proposalList[_proposalId] = Proposal(
            fundsRequested,
            0,
            endTimestamp,
            colletralAmount,
            totalMilestones,
            0,
            0, //status
            0,
            sender
        );
        emit ProposalEditted(
            _proposalId,
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


    function submitProposal(
        uint256 fundsRequested,
        uint256 endTimestamp,
        uint256 colletralAmount,
        uint256 totalMilestones,
        string calldata _proposalId
    ) external whenNotPaused {
        require(
            proposalList[_proposalId].proposer == address(0),
            "Proposal already submitted"
        );
        proposalList[_proposalId] = Proposal(
            fundsRequested,
            0,
            endTimestamp,
            colletralAmount,
            totalMilestones,
            0,
            0, //status
            0,
            msg.sender
        );
        emit ProposalSubmitted(
            _proposalId,
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

    // function stake(
    //     string calldata _proposalId,
    //     uint256 _altQuantity,
    //     uint256 _days
    // ) public whenNotPaused returns (uint256 rewardAmount) {
    //     require(
    //         votes[msg.sender][_proposalId] == false,
    //         "already staked once for this proposal"
    //     );
    //     rewardAmount = DaoStakeContract(phnxStakingContractAddress).stakeALT(
    //         _altQuantity,
    //         _days
    //     );
    //     votes[msg.sender][_proposalId] = true;
    //     proposalList[_proposalId].totalVotes = proposalList[_proposalId]
    //         .totalVotes
    //         .add(1);
    //     emit Voted(_proposalId, _altQuantity, _days, rewardAmount);
    // }

    function withdrawCollateral(string calldata _proposalId)
        external
        whenNotPaused
    {
        require(
            proposalList[_proposalId].status == uint256(Status.COMPLETED),
            "Project status not completed"
        );
        IERC20(phnxContractAddress).transfer(
            proposalList[_proposalId].proposer,
            proposalList[_proposalId].colletralAmount
        );
        collateralAmount=collateralAmount.sub(proposalList[_proposalId].colletralAmount);
        //rewardAmount=IERC20(phnxContractAddress).balanceOf(address(this)).sub(collateralAmount);
        
        emit ColleteralWithdrawn(
            _proposalId,
            proposalList[_proposalId].colletralAmount,
            msg.sender
        );
    }

    function updateProposalStatus(string calldata _proposalId, uint256 _status)
        external
        onlyOwners
    {
        require(
            proposalList[_proposalId].proposer != address(0),
            "proposal not submitted before"
        );
        uint256 oldStatus = proposalList[_proposalId].status;
        if (
            _status == uint256(Status.UPVOTE) &&
            proposalList[_proposalId].status == uint256(Status.PENDING)
        ) {
            proposalList[_proposalId].status = uint256(Status.UPVOTE);
            IERC20(phnxContractAddress).transferFrom(
                proposalList[_proposalId].proposer,
                address(this),
                proposalList[_proposalId].colletralAmount
            );
            collateralAmount=collateralAmount.add(proposalList[_proposalId].colletralAmount);
            //rewardAmount=address(this).balance.sub(collateralAmount);
            //
        }

        if (
            _status == uint256(Status.VOTING) &&
            proposalList[_proposalId].status == uint256(Status.UPVOTE)
        ) {
            proposalList[_proposalId].status = uint256(Status.VOTING);
        }
        if (
            _status == uint256(Status.ACTIVE) &&
            proposalList[_proposalId].status == uint256(Status.VOTING)
        ) {
            proposalList[_proposalId].status = uint256(Status.ACTIVE);
            proposalList[_proposalId].initiationTimestamp=block.timestamp;
        }
        if (
            _status == uint256(Status.REJECTED) &&
            proposalList[_proposalId].status == uint256(Status.PENDING)
        ) {
            proposalList[_proposalId].status = uint256(Status.REJECTED);
        }

        if (
            _status == uint256(Status.COMPLETED) &&
            proposalList[_proposalId].status == uint256(Status.ACTIVE)
        ) {
            proposalList[_proposalId].status = uint256(Status.COMPLETED);
        }

        require(proposalList[_proposalId].status == _status, "Status updated");
        emit ProposalStatusUpdated(
            _proposalId,
            oldStatus,
            proposalList[_proposalId].status
        );
    }


    function pause() external onlyOwners {
        _pause();
    }

    function unPause() external onlyOwners {
        _unpause();
    }
}


 