// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "hardhat/console.sol";

contract StakingContract is OwnableUpgradeable, ReentrancyGuardUpgradeable {

    IERC20 public rtoken;
    mapping(address => uint256) public rewardTokenPerDay;
    mapping(address => bool) public allowedToStake;

    struct UserInfo {
        uint256[] tokenIds;
        uint256 startTime;
    }

    mapping(address => mapping(address => UserInfo)) public userInfo;

    event Stake(address indexed user, uint256 amount);
    event UnStake(address indexed user, uint256 amount);

    function initialize() public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
    }

    function setRewardTokenAddress(address _rewardTokenAddress) public onlyOwner {
        rtoken = IERC20(_rewardTokenAddress);
    }

    function allowCollectionToStake(address _collection, bool _allow) public onlyOwner {
        allowedToStake[_collection] = _allow;
        if(!_allow) rewardTokenPerDay[_collection] = 0;
    }

    function setRewardTokenPerDay(address _collection, uint256 _rewardTokenPerDay) public onlyOwner {
        rewardTokenPerDay[_collection] = _rewardTokenPerDay;
    }

    function approve(address tokenAddress, address spender, uint256 amount) public onlyOwner returns (bool) {
      IERC20(tokenAddress).approve(spender, amount);
      return true;
    }

    function pendingReward(address _collection, address _user) public view returns (uint256) {
        UserInfo memory _userInfo = userInfo[_collection][_user];
        return _userInfo.tokenIds.length * (block.timestamp - _userInfo.startTime) / 1 days * rewardTokenPerDay[_collection];
    }

    function stake(address _collection, uint256[] memory tokenIds) public nonReentrant {
        require(allowedToStake[_collection], "Not allowed to stake for this collection");
        uint256 _pendingRewards = pendingReward(_collection, msg.sender);
        if(_pendingRewards > 0) {
            rtoken.transfer(msg.sender, _pendingRewards);
        }
        userInfo[_collection][msg.sender].startTime = block.timestamp;

        for(uint256 i = 0; i < tokenIds.length; i++) {
            IERC721(_collection).transferFrom(address(msg.sender), address(this), tokenIds[i]);
            userInfo[_collection][msg.sender].tokenIds.push(tokenIds[i]);
            emit Stake(msg.sender, 1);
        }
    }

    function unStake(address _collection, uint256[] memory tokenIds) public nonReentrant {
        uint256 _pendingRewards = pendingReward(_collection, msg.sender);
        if(_pendingRewards > 0) {
            rtoken.transfer(msg.sender, _pendingRewards);
        }
        userInfo[_collection][msg.sender].startTime = block.timestamp;

        for(uint256 i = 0; i < tokenIds.length; i++) {
            require(removeItem(_collection, msg.sender, tokenIds[i]), "Not your NFT id.");
            IERC721(_collection).transferFrom(address(this), msg.sender, tokenIds[i]);
            emit UnStake(msg.sender, 1);
        }
    }

    function claimRewards(address _collection) public nonReentrant {
        uint256 _pendingRewards = pendingReward(_collection, msg.sender);
        if(_pendingRewards > 0) {
            rtoken.transfer(msg.sender, _pendingRewards);
            userInfo[_collection][msg.sender].startTime = block.timestamp;
        }
    }

    function stakeAll(address[] memory _collection, uint256[][] memory tokenIds) public {
        for(uint256 i = 0; i < _collection.length; i++) {
            stake(_collection[i], tokenIds[i]);
        }
    }

    function unStakeAll(address[] memory _collection, uint256[][] memory tokenIds) public {
        for(uint256 i = 0; i < _collection.length; i++) {
            unStake(_collection[i], tokenIds[i]);
        }
    }

    function claimRewardsAll(address[] memory _collection) public {
        for(uint256 i = 0; i < _collection.length; i++) {
            claimRewards(_collection[i]);
        }
    }

    function removeItem(address _collection, address _user, uint256 tokenId) private returns(bool){    
        UserInfo storage _userInfo = userInfo[_collection][_user];    
        for (uint256 i = 0; i < _userInfo.tokenIds.length; i++) {
            if (_userInfo.tokenIds[i] == tokenId) {
                _userInfo.tokenIds[i] = _userInfo.tokenIds[_userInfo.tokenIds.length - 1];
                _userInfo.tokenIds.pop();
                return true;
            }
        }
        return false;
    }

    function getStakingInfo(address _collection, address _user) public view returns(uint256[] memory, uint256) {
        return (
            userInfo[_collection][_user].tokenIds,
            pendingReward(_collection, _user)
        );
    }
}