import { ethers } from "hardhat";

async function main() {
  const network = await hre.network;

  const gatewayContract =
    network.config.chainId == 43113
      ? "0x517f256cc48145c25c27cf453f6f5006e5266543"
      : "0x8EA05371Eb360Eb79c295375CB2cCE9191EFdaD0";

  const CrossERC721 = await ethers.getContractFactory("CrossERC721");
  const crossERC721 = await CrossERC721.deploy(gatewayContract, 1000000);

  await crossERC721.deployed();

  console.log("CrossERC721 deployed to:", crossERC721.address);

  console.log("Sleeping.....");
  await sleep(40000);

  await hre.run("verify:verify", {
    address: crossERC721.address,
    constructorArguments: [gatewayContract, 1000000],
  });
}
function sleep(ms: number) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
