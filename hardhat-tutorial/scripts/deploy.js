const {ethers} = require("hardhat")
const {CRYPTODEVS_NFT_CONTRACT_ADDRESS} = require("../constants")
async function main(){
    const FakeNFTMarketplace = await ethers.getContractFactory("FakeNFTMarketplace")
    const deployedFakeNFTMarketplace = await FakeNFTMarketplace.deploy();
    await deployedFakeNFTMarketplace.deployed()
    const tokenContract = await ethers.getContractFactory("CryptoDevsDAO")
    const deployedTokenContract = await tokenContract.deploy(
        deployedFakeNFTMarketplace.address,
    CRYPTODEVS_NFT_CONTRACT_ADDRESS,
    {
      // This assumes your account has at least 1 ETH in it's account
      // Change this value as you want
      value: ethers.utils.parseEther("0.01"),
    }
    );
    await deployedTokenContract.deployed()
    console.log(deployedFakeNFTMarketplace.address, "addres of nftmarketplace")
    console.log(deployedTokenContract.address, "address of dao")
}

main().then(()=>{
    process.exit(0)
}).catch((err)=>{
    console.error(err)
    process.exit(1)
})
/*
0xbf21b06a09A8D58543bBCd2959283AE9E4846E44 = addres of nftmarketplace
0xB5fc72da94E3A9a82b4Ff7dDd4279D2d35ba0Ea4 = address of dao
*/