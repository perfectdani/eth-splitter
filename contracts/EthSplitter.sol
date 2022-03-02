//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./libs/SafeMath.sol";
import "./Ownable.sol";

contract EthSplitter is Ownable {

    address payable[] public payees;

    event ReceivedEth(address indexed fromAddress, uint256 amount);
    event SplittedEth(uint256 amount, address payable[] payees);
    event AddedPayees(address payable[] payees);
    event RemovedPayees(address payable[] payees);

    using SafeMath for uint256;

    constructor(
        address payable[] memory _payees
    ) {
        _addPayees(_payees);
    }

    function addPayees(
        address payable[] memory _payees
    ) external payable {
        _addPayees(_payees);
    }

    function removePayees(
        address payable[] memory _payeeAddresses
    ) external payable onlyOwner {
        for (uint256 i = 0; i < payees.length; i++) {
            for (uint256 j = 0; j < _payeeAddresses.length; j++) {
                if(payees[i] == _payeeAddresses[j]) {
                    delete payees[i];
                }
            }
        }
        emit RemovedPayees(_payeeAddresses);
    }

    function getPayeesCount() public view returns (uint256) {
        uint256 payeesCount = payees.length;
        return payeesCount;
    }

    function getPayees() public view returns (address payable[] memory) {
        return payees;
    }

    function _addPayees(
        address payable[] memory _payees
    ) internal onlyOwner {
        for (uint256 i = 0; i < _payees.length; i++) {
            bool isExist = _checkPayee(_payees[i]);
            if(!isExist) {
                payees.push(_payees[i]);
            }
        }
        emit AddedPayees(_payees);
    }

    function _checkPayee(
        address _payee
    ) internal view returns (bool) {
        for (uint256 i = 0; i < payees.length; i++) {
            if(payees[i] == _payee) {
                return true;
            }
        }
        return false;
    }

    receive() external payable {
        emit ReceivedEth(msg.sender, msg.value);
        require(msg.value > 0, "Fund value 0 is not allowed");
        _split(msg.value);
    }

    function split(
        uint256 _amount
    ) external {
        _split(_amount);
    }

    function _split(uint256 _amount) internal {
        uint256 payeesCount;
        for (uint256 i = 0; i < payees.length; i++) {
            if(payees[i] != address(0)) {
                payeesCount ++;
            }
        }
        for (uint256 i = 0; i < payees.length; i++) {
            if(payees[i] != address(0)) {
                address payable payee = payees[i];
                uint256 ethAmount = _amount.div(payeesCount);
                payee.call{ value: ethAmount };
            }
        }
        emit SplittedEth(_amount, payees);
    }
}
