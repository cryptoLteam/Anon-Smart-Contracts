// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "hardhat/console.sol";

contract StakingContract is Ownable, ReentrancyGuard {

    IERC20 public rtoken;
    mapping(address => uint256) public rewardTokenPerBlock;
    mapping(address => bool) public allowedToStake;

    struct UserInfo {
        EnumerableSet.UintSet tokenIds;
        uint256 startBlock;
    }

    mapping(address => mapping(address => UserInfo)) userInfo;

    event Stake(address indexed user, uint256 amount);
    event UnStake(address indexed user, uint256 amount);

    constructor(address _rToken) {
        rtoken = IERC20(_rToken);
    }

    function setRewardTokenAddress(address _rewardTokenAddress) public onlyOwner {
        rtoken = IERC20(_rewardTokenAddress);
    }

    function allowCollectionToStake(address _collection, bool _allow) public onlyOwner {
        allowedToStake[_collection] = _allow;
        if(!_allow) rewardTokenPerBlock[_collection] = 0;
    }

    function setRewardTokenPerBlock(address _collection, uint256 _rewardTokenPerBlock) public onlyOwner {
        rewardTokenPerBlock[_collection] = _rewardTokenPerBlock;
    }

    function approve(address tokenAddress, address spender, uint256 amount) public onlyOwner returns (bool) {
      IERC20(tokenAddress).approve(spender, amount);
      return true;
    }

    function pendingReward(address _collection, address _user) public view returns (uint256) {
        UserInfo storage _userInfo = userInfo[_collection][_user];
        return EnumerableSet.length(_userInfo.tokenIds) * (block.number - _userInfo.startBlock) * rewardTokenPerBlock[_collection];
    }

    function stake(address _collection, uint256[] calldata tokenIds) public nonReentrant {
        require(allowedToStake[_collection], "Not allowed to stake for this collection");
        require(tokenIds.length > 0, "tokenIds parameter has zero length.");
        uint256 _pendingRewards = pendingReward(_collection, msg.sender);
        if(_pendingRewards > 0) {
            require(rtoken.transfer(msg.sender, _pendingRewards), "Reward Token Transfer is failed.");
        }
        userInfo[_collection][msg.sender].startBlock = block.number;

        for(uint256 i = 0; i < tokenIds.length; i++) {
            require(IERC721(_collection).ownerOf(tokenIds[i]) == msg.sender, "Not Your NFT.");
            IERC721(_collection).transferFrom(msg.sender, address(this), tokenIds[i]);
            EnumerableSet.add(userInfo[_collection][msg.sender].tokenIds, tokenIds[i]);
        }
        emit Stake(msg.sender, tokenIds.length);
    }

    function unStake(address _collection, uint256[] calldata tokenIds) public nonReentrant {
        require(tokenIds.length > 0, "tokenIds parameter has zero length.");
        uint256 _pendingRewards = pendingReward(_collection, msg.sender);
        if(_pendingRewards > 0) {
            require(rtoken.transfer(msg.sender, _pendingRewards), "Reward Token Transfer is failed.");
        }

        UserInfo storage _userInfo = userInfo[_collection][msg.sender];
        _userInfo.startBlock = block.number;

        for(uint256 i = 0; i < tokenIds.length; i++) {
            require(EnumerableSet.remove(_userInfo.tokenIds, tokenIds[i]), "Not your NFT Id.");
            IERC721(_collection).transferFrom(address(this), msg.sender, tokenIds[i]);
        }
        emit UnStake(msg.sender, tokenIds.length);
    }

    function claimRewards(address _collection) public nonReentrant {
        uint256 _pendingRewards = pendingReward(_collection, msg.sender);
        if(_pendingRewards > 0) {
            require(rtoken.transfer(msg.sender, _pendingRewards), "Reward Token Transfer is failed.");
            userInfo[_collection][msg.sender].startBlock = block.number;
        }
    }

    function stakeAll(address[] memory _collection, uint256[][] calldata tokenIds) public {
        for(uint256 i = 0; i < _collection.length; i++) {
            stake(_collection[i], tokenIds[i]);
        }
    }

    function unStakeAll(address[] memory _collection, uint256[][] calldata tokenIds) public {
        for(uint256 i = 0; i < _collection.length; i++) {
            unStake(_collection[i], tokenIds[i]);
        }
    }

    function claimRewardsAll(address[] calldata _collection) public {
        for(uint256 i = 0; i < _collection.length; i++) {
            claimRewards(_collection[i]);
        }
    }

    function emergencyWithdraw(address _collection) public {
        UserInfo storage _userInfo = userInfo[_collection][msg.sender];
        for(uint256 i = 0; i < EnumerableSet.length(_userInfo.tokenIds); i++) {
            IERC721(_collection).transferFrom(address(this), msg.sender, EnumerableSet.at(_userInfo.tokenIds, i));
        }
        emit UnStake(msg.sender, EnumerableSet.length(_userInfo.tokenIds));
    }

    function getStakingInfo(address _collection, address _user) public view returns(uint256[] memory, uint256) {
        return (
            EnumerableSet.values(userInfo[_collection][msg.sender].tokenIds),
            pendingReward(_collection, _user)
        );
    }
}