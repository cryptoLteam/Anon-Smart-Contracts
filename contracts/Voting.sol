// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract Voting is Ownable {

    IERC721 public abstraction;
    IERC721 public wiainitai;
    IERC721 public anon;
    uint256 public powerUnitForAbstraction;
    uint256 public powerUnitForWiainitai;
    uint256 public powerUnitForAnon;

    struct VoteItem {
        bool yesno;
        uint256 power;
    }

    struct VotingInfo {
        uint256 index;
        address creator;
        string topic;
        uint256 start;
        uint256 end;
        uint256 yes;
        uint256 no;
        mapping(address => VoteItem) voting;
    }

    mapping(uint256 => VotingInfo) public votingInfo;
    uint256 public totalVoting;

    event Vote(address indexed voter, uint256 index, bool yesno, uint256 power);
    event Proposal(address indexed creator, uint256 index, string topic, uint256 start, uint256 end);

    constructor(address _abstraction, uint256 _powerUnitForAbstraction, address _wiainitai, uint256 _powerUnitForWiainitai, address _anon, uint256 _powerUnitForAnon) {
        abstraction = IERC721(_abstraction);
        powerUnitForAbstraction = _powerUnitForAbstraction;
        wiainitai = IERC721(_wiainitai);
        powerUnitForWiainitai = _powerUnitForWiainitai;
        anon = IERC721(_anon);
        powerUnitForAnon = _powerUnitForAnon;
    }

    function setAbstraction(address _abstraction, uint256 _powerUnitForAbstraction) external onlyOwner {
        abstraction = IERC721(_abstraction);
        powerUnitForAbstraction = _powerUnitForAbstraction;
    }

    function setWiainitai(address _wiainitai, uint256 _powerUnitForWiainitai) external onlyOwner {
        wiainitai = IERC721(_wiainitai);
        powerUnitForWiainitai = _powerUnitForWiainitai;
    }

    function setAnon(address _anon, uint256 _powerUnitForAnon) external onlyOwner {
        anon = IERC721(_anon);
        powerUnitForAnon = _powerUnitForAnon;
    }

    function makeProposal(string memory _topic, uint256 _start, uint256 _end) external {
        require(abstraction.balanceOf(msg.sender) >= 3, "You havn't rold to make a proposal.");
        require(bytes(_topic).length > 0, "Invalid Topic");
        require(_start > block.timestamp, "Start time must be greater than now.");
        require(_end > _start + 1 hours, "End time must be greater than start time puls 1 hour.");

        uint256 index = totalVoting;
        votingInfo[index].index = index;
        votingInfo[index].creator = msg.sender;
        votingInfo[index].topic = _topic;
        votingInfo[index].start = _start;
        votingInfo[index].end = _end;
        totalVoting += 1;

        emit Proposal(msg.sender, index, _topic, _start, _end);
    }

    function vote(uint256 _index, bool _yesno) external {
        require(totalVoting > _index, "Invalid Index.");
        require(votingInfo[_index].start <= block.timestamp, "Not Started.");
        require(votingInfo[_index].end >= block.timestamp, "Already Ended.");
        require(votingInfo[_index].voting[msg.sender].power == 0, "You already voted.");
        require(votingInfo[_index].creator != msg.sender, "You are a creator.");

        uint256 votingPower = getVotingPower(msg.sender);
        require(votingPower > 0, "You have zero power to vote.");

        if(_yesno) {
            votingInfo[_index].yes = votingInfo[_index].yes + votingPower;
            votingInfo[_index].voting[msg.sender].yesno = true;
            votingInfo[_index].voting[msg.sender].power = votingPower;
        } else {
            votingInfo[_index].yes = votingInfo[_index].no + votingPower;
            votingInfo[_index].voting[msg.sender].yesno = true;
            votingInfo[_index].voting[msg.sender].power = votingPower;
        }

        emit Vote(msg.sender, _index, _yesno, votingPower);
    }

    function getVotingPower(address _user) public view returns(uint256){
        uint256 abstractionBalance = abstraction.balanceOf(_user);
        uint256 wiainitaiBalance = wiainitai.balanceOf(_user);
        uint256 anonBalance = anon.balanceOf(_user);

        return abstractionBalance * powerUnitForAbstraction + wiainitaiBalance * powerUnitForWiainitai + anonBalance + powerUnitForAnon;
    }
}