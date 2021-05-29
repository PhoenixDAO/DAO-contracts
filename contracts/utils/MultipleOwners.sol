pragma solidity ^0.6.0;

import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";



contract MulitpleOwners is OwnableUpgradeSafe {

    mapping(address => bool) public isOwner;
    
    event AddedSubOwner(address indexed newOwner);
    event RemovedSubOwner(address indexed newOwner);
    
    modifier onlyOwners(){
        require(isOwner[_msgSender()], "Ownable: caller is not one of many owner");
         _;
    }

    function addOwner(address newOwner) external virtual onlyOwner{
        isOwner[newOwner] = true;
        emit AddedSubOwner(newOwner);
    }

    function removeOwner(address _subOwner) external virtual onlyOwner{
        isOwner[_subOwner] = false;
        emit RemovedSubOwner( _subOwner);
    }

}