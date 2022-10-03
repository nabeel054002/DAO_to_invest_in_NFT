
require("@nomicfoundation/hardhat-toolbox")
require("dotenv").config({path:"./.env"})


const QUICKNODE_HTTP_URL = process.env.QUICKNODE_HTTP_URL;
const PRIVATE_KEY =  process.env.PRIVATE_KEY;
console.log(process.env)
module.exports = {
  solidity: {
    version: "0.8.0",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks:{
    goerli:{
      url:QUICKNODE_HTTP_URL,
      accounts:[PRIVATE_KEY],
      gas: 2100000,
      gasPrice: 8000000000
    }
  }
}