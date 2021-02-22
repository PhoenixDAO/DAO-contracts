pragma solidity ^0.6.0;
import "@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
contract DaoStakeContract is OwnableUpgradeSafe, PausableUpgradeSafe {
    // Library for safely handling uint256
    using SafeMath for uint256;
    uint256 ONE_DAY;
    uint256 public stakeDays;
    uint256 public maxStakedQuantity;
    address public phnxContractAddress;
    uint256 public ratio;
    mapping(address => uint256) public stakerBalance;
    mapping(uint256 => StakerData) public stakerData;
    struct StakerData {
        uint256 altQuantity;
        uint256 initiationTimestamp;
        uint256 durationTimestamp;
        uint256 rewardAmount;
        address staker;
    }
    event StakeCompleted(
        uint256 altQuantity,
        uint256 initiationTimestamp,
        uint256 durationTimestamp,
        uint256 rewardAmount,
        address staker,
        address phnxContractAddress,
        address portalAddress
    );
    event Unstake(
        address staker,
        address stakedToken,
        address portalAddress,
        uint256 altQuantity,
        uint256 durationTimestamp
    ); // When ERC20s are withdrawn
    event BaseInterestUpdated(uint256 _newRate, uint256 _oldRate);
    ////////////////
    // Initializer
    ////////////////
    function initialize() external initializer {
        OwnableUpgradeSafe.__Ownable_init();
        PausableUpgradeSafe.__Pausable_init();
        ratio = 684931506849315;
        phnxContractAddress = 0xfe1b6ABc39E46cEc54d275efB4b29B33be176c2A;
        maxStakedQuantity = 10000000000000000000000;
        stakeDays = 365;
        ONE_DAY = 24 * 60 * 60;
    }
    /* @dev stake function which enable the user to stake PHNX Tokens.
     *  @param _altQuantity, PHNX amount to be staked.
     *  @param _days, how many days PHNX tokens are staked for (in days)
     */
    function stakeALT(uint256 _altQuantity, uint256 _days)
        public
        whenNotPaused
        returns (uint256 rewardAmount)
    {
        require(_days <= stakeDays && _days > 0, "Invalid Days"); // To check days
        require(
            _altQuantity <= maxStakedQuantity && _altQuantity > 0,
            "Invalid PHNX quantity"
        ); // To verify PHNX quantity
        IERC20(phnxContractAddress).transferFrom(
            msg.sender,
            address(this),
            _altQuantity
        );
        rewardAmount = _calculateReward(_altQuantity, ratio, _days);
        uint256 _timestamp = block.timestamp;
        if (stakerData[_timestamp].staker != address(0)) {
            _timestamp = _timestamp.add(1);
        }
        stakerData[_timestamp] = StakerData(
            _altQuantity,
            _timestamp,
            _days.mul(ONE_DAY),
            rewardAmount,
            msg.sender
        );
        stakerBalance[msg.sender] = stakerBalance[msg.sender].add(_altQuantity);
        IERC20(phnxContractAddress).transfer(msg.sender, rewardAmount);
        emit StakeCompleted(
            _altQuantity,
            _timestamp,
            _days.mul(ONE_DAY),
            rewardAmount,
            msg.sender,
            phnxContractAddress,
            address(this)
        );
    }
    /* @dev unStake function which enable the user to withdraw his PHNX Tokens.
     *  @param _expiredTimestamps, time when PHNX tokens are unlocked.
     *  @param _amount, amount to be withdrawn by the user.
     */
    function unstakeALT(uint256[] calldata _expiredTimestamps, uint256 _amount)
        external
        whenNotPaused
        returns (uint256)
    {
        require(_amount > 0, "Amount should be greater than 0");
        uint256 withdrawAmount = 0;
        for (uint256 i = 0; i < _expiredTimestamps.length; i = i.add(1)) {
            require(
                stakerData[_expiredTimestamps[i]].durationTimestamp != 0,
                "Nothing staked"
            );
            require(
                _expiredTimestamps[i].add(
                    stakerData[_expiredTimestamps[i]].durationTimestamp
                ) <= block.timestamp
            );
            
            if (_amount >= stakerData[_expiredTimestamps[i]].altQuantity) {
                _amount = _amount.sub(
                    stakerData[_expiredTimestamps[i]].altQuantity
                );
                withdrawAmount = withdrawAmount.add(
                    stakerData[_expiredTimestamps[i]].altQuantity
                );
                emit Unstake(
                    msg.sender,
                    phnxContractAddress,
                    address(this),
                    stakerData[_expiredTimestamps[i]].altQuantity,
                    _expiredTimestamps[i]
                );
                stakerData[_expiredTimestamps[i]].altQuantity = 0;
            } else if (
                (_amount < stakerData[_expiredTimestamps[i]].altQuantity) &&
                _amount > 0
            ) {
                stakerData[_expiredTimestamps[i]]
                    .altQuantity = stakerData[_expiredTimestamps[i]]
                    .altQuantity
                    .sub(_amount);
                withdrawAmount = withdrawAmount.add(_amount);
                emit Unstake(
                    msg.sender,
                    phnxContractAddress,
                    address(this),
                    _amount,
                    _expiredTimestamps[i]
                );
                break;
            }
        }
        require(withdrawAmount != 0, "Not Transferred");
       
        stakerBalance[msg.sender] = stakerBalance[msg.sender].sub(
            withdrawAmount
        );
        IERC20(phnxContractAddress).transfer(msg.sender, withdrawAmount);
        return withdrawAmount;
    }
    /* @dev to calculate reward Amount
     *  @param _altQuantity , amount of ALT tokens staked.
     *@param _baseInterest rate
     */
    function _calculateReward(
        uint256 _altQuantity,
        uint256 _ratio,
        uint256 _days
    ) internal pure returns (uint256 rewardAmount) {
        rewardAmount = (_altQuantity.mul(_ratio).mul(_days)).div(
            1000000000000000000
        );
    }
    /* @dev to set base interest rate. Can only be called by owner
     *  @param _rate, interest rate (in wei)
     */
    function updateRatio(uint256 _rate) public onlyOwner whenNotPaused {
        ratio = _rate;
    }
    function updateTime(uint256 _time) public onlyOwner whenNotPaused {
        ONE_DAY = _time;
    }
    function updateQuantity(uint256 _quantity) public onlyOwner whenNotPaused {
        maxStakedQuantity = _quantity;
    }
    /* @dev function to update stakeDays.
     *@param _stakeDays, updated Days .
     */
    function updatestakeDays(uint256 _stakeDays) public onlyOwner {
        stakeDays = _stakeDays;
    }
    /* @dev Funtion to withdraw all PHNX from contract incase of emergency, can only be called by owner.*/
    function withdrawTokens() public onlyOwner {
        IERC20(phnxContractAddress).transfer(
            owner(),
            IERC20(phnxContractAddress).balanceOf(address(this))
        );
    }
    /* @dev function to update Phoenix contract address.
     *@param _address, new address of the contract.
     */
    function setPheonixContractAddress(address _address) public onlyOwner {
        phnxContractAddress = _address;
    }
    /* @dev function which restricts the user from stakng PHNX tokens. */
    function pause() public onlyOwner {
        _pause();
    }
    /* @dev function which disables the Pause function. */
    function unPause() public onlyOwner {
        _unpause();
    }
}

