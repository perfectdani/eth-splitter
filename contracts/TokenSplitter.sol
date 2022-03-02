//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "./libs/SafeMath.sol";
import "./interfaces/IERC20.sol";
import "./Ownable.sol";

contract TokenSplitter is Ownable {

    IERC20 private token;

    address[] private payees;

    event ReceivedEth(address indexed fromAddress, uint256 amount);
    event SplittedEth(uint256 amount, address[] payees);
    event AddedPayees(address[] payees);
    event RemovedPayees(address[] payees);

    using SafeMath for uint256;

    constructor(
        address[] memory _payees,
        address _token
    ) {
        _addPayees(_payees);
        require(_token != address(0), "Zero address: token");
        token = IERC20(_token);
    }

    function getToken() external view returns (address) {
        return address(token);
    }

    function setToken(address _token) external onlyOwner {
        require(_token != address(0), "Zero address: token");
        token = IERC20(_token);
    }

    function addPayees(
        address[] memory _payees
    ) external {
        _addPayees(_payees);
    }

    function removePayees(
        address[] memory _payeeAddresses
    ) external onlyOwner {
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

    function getPayees() public view returns (address[] memory) {
        return payees;
    }

    function _addPayees(
        address[] memory _payees
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

    function split() external {
        _split();
    }

    function getTokenBalance() external view returns (uint256) {
        uint256 balance = _getTokenBalance();
        return balance;
    }

    function _getTokenBalance() internal view returns (uint256) {
        uint256 _balance = token.balanceOf(address(this));
        return _balance;
    }

    function _split() internal onlyOwner {
        uint256 _amount = _getTokenBalance();
        uint256 payeesCount;
        for (uint256 i = 0; i < payees.length; i++) {
            if(payees[i] != address(0)) {
                payeesCount ++;
            }
        }
        for (uint256 i = 0; i < payees.length; i++) {
            if(payees[i] != address(0)) {
                address payee = payees[i];
                uint256 ethAmount = _amount.div(payeesCount);
                token.transfer(payee, ethAmount);
            }
        }
        emit SplittedEth(_amount, payees);
    }
}
