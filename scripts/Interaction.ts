import { Contract, ContractFactory } from "ethers";
import DAOContractArtifact from "../artifacts/contracts/DaoSmartContract.sol/DaoSmartContract.json";


import { ethers } from "hardhat";

async function main(): Promise<void> {

  const [signer] = await ethers.getSigners()
  const DAOContract: ContractFactory = new ContractFactory(DAOContractArtifact.abi, DAOContractArtifact.bytecode,signer );

  const DAOContractInstance = DAOContract.attach("0x7415eA5df0870fBcab3027c334e268F50B40ADf5")

// let tx =await DAOContractInstance.updateProposal("60b8c9a4db4cf90023a45ef7",1,{gasPrice: "0x2E90EDD000"});
// console.log(tx)
// await tx.wait(1)

let value = await DAOContractInstance.proposalList("60b8c9a4db4cf90023a45ef7");
console.log("Proposal",value.status.toString());
}


main()
  .then(() => process.exit(0))
  .catch((error: Error) => {
    console.error(error);
    process.exit(1);
  });