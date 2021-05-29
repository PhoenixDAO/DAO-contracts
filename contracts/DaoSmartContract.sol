pragma solidity ^0.6.0;
import "@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "./utils/MultipleOwners.sol";

contract DaoSmartContract is MulitpleOwners, PausableUpgradeSafe {
    using SafeMath for uint256;

    enum Status { PENDING, UPVOTE, VOTING, ACTIVE, COMPLETED, REJECTED }

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
        string proposalId,
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
        string proposalId,
        uint256 fundsRequested,
        uint256 initiationTimestamp,
        uint256 completionTimestamp,
        uint256 colletralAmount,
        uint256 totalMilestones,
        uint256 status,
        uint256 totalVotes,
        address proposer
    );
    event ProposalStatusUpdated(string proposalId, uint256 previousStatus, uint256 newStatus);

    event ColleteralWithdrawn(string proposalId, uint256 collateralAmount, address proposer);

    function initialize(address _phoenixContractAddress) external initializer {
        OwnableUpgradeSafe.__Ownable_init();
        PausableUpgradeSafe.__Pausable_init();
        phnxContractAddress = _phoenixContractAddress;
    }

    function updateProposal(
        uint256 fundsRequested,
        uint256 endTimestamp,
        uint256 colletralAmount,
        uint256 totalMilestones,
        string calldata proposalId
    ) external whenNotPaused {
        require(proposalList[proposalId].proposer != address(0), "This proposal Does not exist");
        address sender = msg.sender;
        require(proposalList[proposalId].proposer == sender, "Only Owner of propsal can edit this propsal");
        proposalList[proposalId] = Proposal(
            fundsRequested,
            0,
            endTimestamp,
            colletralAmount,
            totalMilestones,
            0,
            0,
            0,
            sender
        );
        emit ProposalEditted(
            proposalId,
            proposalList[proposalId].fundsRequested,
            proposalList[proposalId].initiationTimestamp,
            proposalList[proposalId].completionTimestamp,
            proposalList[proposalId].colletralAmount,
            proposalList[proposalId].totalMilestones,
            proposalList[proposalId].status,
            proposalList[proposalId].totalVotes,
            proposalList[proposalId].proposer
        );
    }

    function submitProposal(
        uint256 fundsRequested,
        uint256 endTimestamp,
        uint256 colletralAmount,
        uint256 totalMilestones,
        string calldata proposalId
    ) external whenNotPaused {
        require(proposalList[proposalId].proposer == address(0), "Proposal already submitted");
        proposalList[proposalId] = Proposal(
            fundsRequested,
            0,
            endTimestamp,
            colletralAmount,
            totalMilestones,
            0,
            0,
            0,
            msg.sender
        );
        emit ProposalSubmitted(
            proposalId,
            proposalList[proposalId].fundsRequested,
            proposalList[proposalId].initiationTimestamp,
            proposalList[proposalId].completionTimestamp,
            proposalList[proposalId].colletralAmount,
            proposalList[proposalId].totalMilestones,
            proposalList[proposalId].status,
            proposalList[proposalId].totalVotes,
            proposalList[proposalId].proposer
        );
    }

    function withdrawCollateral(string calldata proposalId) external whenNotPaused {
        require(proposalList[proposalId].status == uint256(Status.COMPLETED), "Project status not completed");
        IERC20(phnxContractAddress).transfer(
            proposalList[proposalId].proposer,
            proposalList[proposalId].colletralAmount
        );
        collateralAmount = collateralAmount.sub(proposalList[proposalId].colletralAmount);

        emit ColleteralWithdrawn(proposalId, proposalList[proposalId].colletralAmount, msg.sender);
    }

    function updateProposalStatus(string calldata proposalId, uint256 status) external onlyOwners {
        require(proposalList[proposalId].proposer != address(0), "proposal not submitted before");
        uint256 oldStatus = proposalList[proposalId].status;
        if (status == uint256(Status.UPVOTE) && proposalList[proposalId].status == uint256(Status.PENDING)) {
            proposalList[proposalId].status = uint256(Status.UPVOTE);
            IERC20(phnxContractAddress).transferFrom(
                proposalList[proposalId].proposer,
                address(this),
                proposalList[proposalId].colletralAmount
            );
            collateralAmount = collateralAmount.add(proposalList[proposalId].colletralAmount);
        }

        if (status == uint256(Status.VOTING) && proposalList[proposalId].status == uint256(Status.UPVOTE)) {
            proposalList[proposalId].status = uint256(Status.VOTING);
        }
        if (status == uint256(Status.ACTIVE) && proposalList[proposalId].status == uint256(Status.VOTING)) {
            proposalList[proposalId].status = uint256(Status.ACTIVE);
            proposalList[proposalId].initiationTimestamp = block.timestamp;
        }
        if (status == uint256(Status.REJECTED) && proposalList[proposalId].status == uint256(Status.PENDING)) {
            proposalList[proposalId].status = uint256(Status.REJECTED);
        }

        if (status == uint256(Status.COMPLETED) && proposalList[proposalId].status == uint256(Status.ACTIVE)) {
            proposalList[proposalId].status = uint256(Status.COMPLETED);
        }

        require(proposalList[proposalId].status == status, "Status Not updated");
        emit ProposalStatusUpdated(proposalId, oldStatus, proposalList[proposalId].status);
    }

    function pause() external onlyOwners {
        _pause();
    }

    function unPause() external onlyOwners {
        _unpause();
    }
}
