// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {
  // const AnonToken = await ethers.getContractFactory("AnonToken");
  // token = await AnonToken.deploy("ANON", "$ANON", 260000000000);
  // await token.deployed();
  // console.log("token address: ", token.address)

  // const Abstractionbyanon = await ethers.getContractFactory("Abstractionbyanon");
  // abstraction = await Abstractionbyanon.deploy();
  // await abstraction.deployed();
  // console.log("abstraction address: ", abstraction.address)

  // const Whoiamisnotimportanttheartis = await ethers.getContractFactory("Whoiamisnotimportanttheartis");
  // wiainitai = await Whoiamisnotimportanttheartis.deploy();
  // await wiainitai.deployed();
  // console.log("wiainitai address: ", wiainitai.address)

  // const KOBA = await ethers.getContractFactory("KOBA");
  // koba = await KOBA.deploy(abstraction.address, wiainitai.address);
  // await koba.deployed();
  // console.log("koba address: ", koba.address)

  // const StakingContract = await ethers.getContractFactory("StakingContract");
  // staking = await StakingContract.deploy(
  //         token.address, 
  //         abstraction.address, ethers.utils.parseEther("25"), 
  //         wiainitai.address, ethers.utils.parseEther("5"), 
  //         koba.address, ethers.utils.parseEther("1")
  // );
  // await staking.deployed();
  // console.log("staking address: ", staking.address)

  // await koba.unPause()
  // await abstraction.setPaused()
  // await wiainitai.setPaused()

  
  const ANON = await ethers.getContractFactory("ANON");
  anon = await upgrades.deployProxy(ANON, [], { initializer: 'initialize' } );
  await anon.deployed();
  console.log("anon address: ", anon.address)
  
  await anon.setKobaAddress('0x06c5209a0046e99e9d1BE1FE289f94C1CF91F093')
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
