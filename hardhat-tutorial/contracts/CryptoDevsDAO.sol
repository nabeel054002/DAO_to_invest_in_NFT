//SPDX License Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * Interface for the FakeNFTMarketplace
 */
interface IFakeNFTMarketplace {
    /// @dev getPrice() returns the price of an NFT from the FakeNFTMarketplace
    /// @return Returns the price in Wei for an NFT
    function getPrice() external view returns (uint256);

    /// @dev available() returns whether or not the given _tokenId has already been purchased
    /// @return Returns a boolean value - true if available, false if not
    function available(uint256 _tokenId) external view returns (bool);

    /// @dev purchase() purchases an NFT from the FakeNFTMarketplace
    /// @param _tokenId - the fake NFT tokenID to purchase
    function purchase(uint256 _tokenId) external payable;
}

/**
 * Minimal interface for CryptoDevsNFT containing only two functions
 * that we are interested in
 */
interface ICryptoDevsNFT {
    /// @dev balanceOf returns the number of NFTs owned by the given address
    /// @param owner - address to fetch number of NFTs for
    /// @return Returns the number of NFTs owned
    function balanceOf(address owner) external view returns (uint256);

    /// @dev tokenOfOwnerByIndex returns a tokenID at given index for owner
    /// @param owner - address to fetch the NFT TokenID for
    /// @param index - index of NFT in owned tokens array to fetch
    /// @return Returns the TokenID of the NFT
    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256);
}

contract CryptoDevsDAO is Ownable{
    struct Proposal {
        // nftTokenId - the tokenID of the NFT to purchase from FakeNFTMarketplace if the proposal passes
        uint256 nftTokenId;
        // deadline - the UNIX timestamp until which this proposal is active. Proposal can be executed after the deadline has been exceeded.
        uint256 deadline;
        // yayVotes - number of yay votes for this proposal
        uint256 yayVotes;
        // nayVotes - number of nay votes for this proposal
        uint256 nayVotes;
        // executed - whether or not this proposal has been executed yet. Cannot be executed before the deadline has been exceeded.
        bool executed;
        // voters - a mapping of CryptoDevsNFT tokenIDs to booleans indicating whether that NFT has already been used to cast a vote or not
        mapping(uint256 => bool) voters;
    }
    // Create a mapping of ID to Proposal
    mapping(uint256 => Proposal) public proposals;
    // Number of proposals that have been created
    uint256 public numProposals;

    ICryptoDevsNFT cryptoDevsNFT;
    IFakeNFTMarketplace nftMarketplace;

    //also accept an ETH deposit from the deployer to fill the DAO ETH treasury.

    constructor (address _CryptoDevsNFT, address _nftMarketplace) payable {
        cryptoDevsNFT = ICryptoDevsNFT(_CryptoDevsNFT);
        nftMarketplace = IFakeNFTMarketplace(_nftMarketplace);
    }// Create a modifier which only allows a function to be
    // called by someone who owns at least 1 CryptoDevsNFT
    modifier nftHolderOnly(){
        require(cryptoDevsNFT.balanceOf(msg.sender)>0,"Not an authorized member of the DAO");
        _;
    }

    modifier activeProposal (uint256 proposalIndex){
        require(proposals[proposalIndex].deadline > block.timestamp, "Deadline for voting has ended");
        _;
        //what about the border cases that no one votes or tie 
        //Note how this modifier takes a parameter!
    }

    modifier inactiveProposalOnly(uint256 proposalIndex){
        require(proposals[proposalIndex].deadline <= block.timestamp, "Deadline not exceeded");
        require(proposals[proposalIndex].executed==false, "proposal has been executed");
        _;
    }
    // Create an enum named Vote containing possible options for a vote
    enum Vote {
        YAY, // YAY = 0
        NAY // NAY = 1
    }

    function createProposal (uint256 _tokenId) external nftHolderOnly returns (uint256){
        require(nftMarketplace.available(_tokenId), "NFT is not available for sale");
        Proposal storage proposal = proposals[numProposals];
        proposal.deadline = block.timestamp + 5 minutes;
        numProposals++;
        return numProposals-1;
    }

    function voteOnProposal (uint256 proposalIndex, Vote vote)external nftHolderOnly activeProposal(proposalIndex){
        Proposal storage proposal = proposals[proposalIndex];
        uint256 voterNFTBalance = cryptoDevsNFT.balanceOf(msg.sender);
        uint256 numVotes = 0;
        for (uint256 i = 0; i < voterNFTBalance; i++){
            uint256 tokenId = cryptoDevsNFT.tokenOfOwnerByIndex(msg.sender, i);
            if (proposal.voters[tokenId]==false){
                numVotes++;
                proposal.voters[tokenId] = true;
            }
        }
        require(numVotes>0, "Already voted");

        if (vote == Vote.YAY){
            proposal.yayVotes+=numVotes;
        } else{
            proposal.nayVotes += numVotes;
        }
    }

    function executeProposal (uint256 proposalIndex) external nftHolderOnly inactiveProposalOnly(proposalIndex){
        Proposal storage proposal = proposals[proposalIndex];
        //If the proposal has more YAY votes then buy nft
        if (proposal.yayVotes > proposal.nayVotes){
            uint256 nftPrice = nftMarketplace.getPrice();
            require(address(this).balance>=nftPrice, "Not enough funds");
            nftMarketplace.purchase{
                value:nftPrice
            }(
                proposal.nftTokenId
            );
        }
        proposal.executed = true;
    }

    /// @dev withdrawEther allows the contract owner (deployer) to withdraw the ETH from the contract
    function withdrawEther() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
        //what does this mean...
    }

    receive () external payable {}
    fallback () external payable {}
    /* we don't want users to call functions just to deposit money, they should be 
    able to tranfer ETH directly from their wallet. For that, let's add these two 
    functions:*/
}