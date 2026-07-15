// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Pausable.sol";
contract Flashchip is ERC20, Ownable, Pausable {
    uint256 public maxTxAmount;
    uint256 public sellTaxFee;
    address public taxWallet;
    
    mapping(address => bool) public isBlacklisted;

    constructor(
        address _liquidityWallet, 
        address _airdropWallet, 
        address _reserveWallet
    ) ERC20("Flashchip", "FCP") Ownable(msg.sender) {
        uint256 total = 10000000 * 10 ** decimals();
        
        // Pembagian Tokenomics (Total 10 Juta)
        _mint(msg.sender, (total * 15) / 100);       // 15% Owner (ARIPUDIN)
        _mint(_liquidityWallet, (total * 60) / 100); // 60% Liquidity
        _mint(_airdropWallet, (total * 15) / 100);   // 15% Airdrop
        _mint(_reserveWallet, (total * 10) / 100);   // 10% Reserve
        
        maxTxAmount = 10000 * 10 ** decimals(); 
        sellTaxFee = 10; 
        taxWallet = msg.sender;
    }

    // --- FITUR PENGATUR (SETTER) ---
    function setMaxTxAmount(uint256 _amount) external onlyOwner {
        maxTxAmount = _amount * 10 ** decimals();
    }

    function setTax(uint256 _fee) external onlyOwner {
        require(_fee <= 20, "Tax max 20%");
        sellTaxFee = _fee;
    }

    // --- KEAMANAN ---
    function pause() external onlyOwner { _pause(); }
    function unpause() external onlyOwner { _unpause(); }
    function blacklist(address account, bool status) external onlyOwner { isBlacklisted[account] = status; }

    // --- LOGIKA TRANSAKSI ---
    function _update(address from, address to, uint256 value) internal override whenNotPaused {
        require(!isBlacklisted[from] && !isBlacklisted[to], "Alamat diblokir");

        if (from != owner() && to != owner() && from != address(0)) {
            require(value <= maxTxAmount, "Melebihi batas transaksi");
            
            uint256 tax = (value * sellTaxFee) / 100;
            super._update(from, taxWallet, tax);
            super._update(from, to, value - tax);
        } else {
            super._update(from, to, value);
        }
    }
}