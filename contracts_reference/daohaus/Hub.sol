pragma solidity ^0.4.15;

import "./ResourceProposal.sol";
import "./NonResourceProposal.sol";
import "./deps/Owned.sol";
import "./deps/Logs.sol";

contract Hub is Owned, Logs {
    address[] public members;
    uint256 public availableBalance;
    uint256 public runningBalance;
    uint256 public pvr;

    struct MemberDetails {
        string blockcomId;
        string name;
    }

    address[] public proposals;
    mapping(address => bool) proposalExists;
    mapping(address => MemberDetails) public memberDetails;
    //mapping(string=>address) public numberToAddress;

    mapping(address => uint256) amountsPledgedMapping;
    mapping(address => bool) finishedProposals;
    mapping(address => uint256) balances;

    modifier onlyIfProposal(address proposal) {
        require(proposalExists[proposal]);
        _;
    }

    modifier onlyIfMember() {
        require(amountsPledgedMapping[msg.sender] > 0);
        _;
    }

    function Hub() public {
        pvr = 75;
    }

    function getMemberName(address add) public constant returns (string name) {
        return memberDetails[add].name;
    }

    function getMembers() public constant returns (address[] arr) {
        return members;
    }

    function isMember(address person) public constant returns (bool) {
        return amountsPledgedMapping[person] > 0;
    }

    function register(string blockcomId, string name)
        public
        payable
        sufficientFunds()
        returns (bool)
    {
        /* update hub contract balance */
        availableBalance += msg.value;
        runningBalance += msg.value;

        /* update amountsPledged mapping */
        amountsPledgedMapping[msg.sender] += msg.value;
        memberDetails[msg.sender].blockcomId = blockcomId;
        memberDetails[msg.sender].name = name;

        //numberToAddress[blockcomId] = msg.sender;
        /* update members array */
        //if(memberDetails[msg.sender].blockcomId == "")
        members.push(msg.sender);

        LogMemberRegistered(
            msg.sender,
            name,
            blockcomId,
            msg.value,
            availableBalance,
            runningBalance
        );
        return true;
    }

    function getMembersCount() public constant returns (uint256 count) {
        return members.length;
    }

    function getVotingRightRatio(address member)
        public
        constant
        returns (uint256 ratio)
    {
        return (amountsPledgedMapping[member] * 100) / runningBalance;
    }

    /*function propose(uint ethAmount, string proposalMessage) {
    address proposer = msg.sender;
  }*/

    modifier sufficientFunds() {
        require(msg.value > 0);
        _;
    }

    function getProposalCount()
        public
        constant
        returns (uint256 proposalCount)
    {
        return proposals.length;
    }

    function getProposals() public constant returns (address[] arr) {
        return proposals;
    }

    function createResourceProposal(
        address chairmanAddress,
        uint256 fees,
        uint256 blocks,
        uint256 cost,
        string text
    )
        public
        returns (
            //onlyIfMember
            address proposalContract
        )
    {
        ResourceProposal trustedProposal =
            new ResourceProposal(chairmanAddress, fees, blocks, cost, text);
        require(availableBalance >= fees + cost);
        uint256 ind = proposals.length + 1;
        proposals.push(trustedProposal);
        proposalExists[trustedProposal] = true;
        availableBalance -= fees + cost;
        LogNewProposal(
            ind,
            chairmanAddress,
            fees,
            blocks,
            cost,
            text,
            trustedProposal
        );
        return trustedProposal;
    }

    function createNonResourceProposal(
        uint256 val,
        uint256 blocks,
        string text
    ) public onlyIfMember returns (address proposalContract) {
        NonResourceProposal trustedProposal =
            new NonResourceProposal(blocks, val, text);
        uint256 ind = proposals.length + 1;
        proposals.push(trustedProposal);
        proposalExists[trustedProposal] = true;
        LogNewNRProposal(ind, blocks, val, text, trustedProposal);
        return trustedProposal;
    }

    function executeProposal(
        address[] addrForHub,
        uint8[] votesForHub,
        address chairMan,
        uint256 totFees,
        uint256 deadline
    ) public returns (uint256) {
        require(!finishedProposals[msg.sender]);
        uint256 count = addrForHub.length;
        uint256 pos = 0;
        uint256 total = 0;
        for (uint256 i = 0; i < count; i++) {
            if (isMember(addrForHub[i])) {
                uint256 ratio = getVotingRightRatio(addrForHub[i]);
                if (votesForHub[i] == 1) {
                    pos += ratio;
                }
                total += ratio;
            }
        }

        uint256 cpvr = (pos * 100) / 100;
        if (cpvr >= pvr) {
            finishedProposals[msg.sender] = true;
            LogWithdraw(totFees, chairMan);
            chairMan.transfer(totFees);
            return 1;
        } else if (block.number > deadline) {
            finishedProposals[msg.sender] = true;
        }
        return 2;
    }

    function getPvr() public constant returns (uint256) {
        return pvr;
    }

    function setPvr(uint256 val) private returns (bool) {
        pvr = val;
        return true;
    }

    function executeNRProposal(
        address[] addrForHub,
        uint8[] votesForHub,
        uint256 deadline,
        uint256 val
    ) public returns (uint256) {
        require(!finishedProposals[msg.sender]);
        uint256 count = addrForHub.length;
        uint256 pos = 0;
        uint256 total = 0;
        for (uint256 i = 0; i < count; i++) {
            if (isMember(addrForHub[i])) {
                uint256 ratio = getVotingRightRatio(addrForHub[i]);
                if (votesForHub[i] == 1) {
                    pos += ratio;
                }
                total += ratio;
            }
        }
        uint256 cpvr = (pos * 100) / 100;
        if (cpvr >= pvr) {
            finishedProposals[msg.sender] = true;
            require(setPvr(val));
            //balances[chairMan]+=totFees;
            return 1;
        } else if (block.number > deadline) {
            finishedProposals[msg.sender] = true;
        }

        return 2;
    }

    function withdraw() public returns (bool) {
        // this should be to withdraw proof of stake tokens, once we get them
        // not the proposal amounts - needing refactor
        uint256 amt = balances[msg.sender];
        require(amt > 0);
        balances[msg.sender] = 0;
        LogChairmanWithdraw(amt);
        msg.sender.transfer(amt);
        return true;
    }

    // Pass-through Admin Controls
    function stopProposal(address proposal)
        public
        onlyOwner()
        onlyIfProposal(proposal)
        returns (bool success)
    {
        ResourceProposal trustedProposal = ResourceProposal(proposal);
        return (trustedProposal.runSwitch(false));
    }

    function() public payable {
        /* catch all to update hub contract balance */
        availableBalance += msg.value;
        runningBalance += msg.value;
    }
}
