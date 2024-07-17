// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Exchange} from "../src/Exchange.sol";
import {IExchange} from "../src/interfaces/IExchange.sol";
import {ERC1967Utils} from "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Utils.sol";
import "./utils/SigUtils.sol";
import {ExchangeBaseTest} from "./ExchangeBaseTest.sol";
import {MockERC20} from "./contracts/MockERC20.sol";
import "../src/interfaces/IExchange.sol";
import "../src/interfaces/IExchange.sol";
import "../src/interfaces/IExchange.sol";

contract SovereignWithdrawalTest is ExchangeBaseTest {
    function setUp() public override {
        super.setUp();
        vm.deal(wallet1, 10 ether);
        vm.deal(wallet2, 10 ether);
    }

    function test_sovereignWithdrawal_initiate_nativeToken() public {
        setupWallets();
        deposit(wallet1, 2 ether);
        vm.startPrank(wallet1);

        vm.expectEmit(exchangeProxyAddress);
        emit IExchange.WithdrawalRequested(address(wallet1), address(0), 2 ether);
        exchange.sovereignWithdrawal(address(0), 2 ether);

        (address tokenAddress, uint256 amount, uint256 timestamp) = exchange.sovereignWithdrawals(wallet1);
        assertEq(tokenAddress, address(0));
        assertEq(amount, 2 ether);
        assertGt(timestamp, 0);

        vm.stopPrank();
    }

    function test_sovereignWithdrawal_revertIfInsufficientBalance_nativeToken() public {
        setupWallets();
        deposit(wallet1, 3 ether);
        vm.startPrank(wallet1);

        vm.expectRevert("Insufficient balance");
        exchange.sovereignWithdrawal(address(0), 4 ether);

        vm.stopPrank();
    }

    function test_sovereignWithdrawal_revertIfWithdrawalDelayNotMet_nativeToken() public {
        setupWallets();
        deposit(wallet1, 3 ether);
        vm.startPrank(wallet1);

        exchange.sovereignWithdrawal(address(0), 2 ether);

        vm.expectRevert("Withdrawal delay not met");
        exchange.sovereignWithdrawal(address(0), 2 ether);

        vm.stopPrank();
    }

    function test_sovereignWithdrawal_complete_nativeToken() public {
        setupWallets();
        deposit(wallet1, 3 ether);
        vm.startPrank(wallet1);

        exchange.sovereignWithdrawal(address(0), 2 ether);

        // Increase EVM time to pass the delay
        vm.warp(block.timestamp + exchange.sovereignWithdrawalDelay());

        exchange.sovereignWithdrawal(address(0), 2 ether);

        assertEq(wallet1.balance, 9 ether); // initial balance - deposit + withdrawal
        (, uint256 amount,) = exchange.sovereignWithdrawals(wallet1);
        assertEq(amount, 0);

        vm.stopPrank();
    }

    function test_sovereignWithdrawal_revertAfterDelayIfAmountDoesNotMatch_nativeToken() public {
        setupWallets();
        deposit(wallet1, 3 ether);
        vm.startPrank(wallet1);

        exchange.sovereignWithdrawal(address(0), 2 ether);

        // Increase EVM time to pass the delay
        vm.warp(block.timestamp + exchange.sovereignWithdrawalDelay());

        vm.expectRevert("Amount mismatch");
        exchange.sovereignWithdrawal(address(0), 1 ether);

        vm.stopPrank();
    }

    function test_sovereignWithdrawal_revertAfterDelayIfTokenDoesNotMatch_nativeToken() public {
        setupWallets();
        deposit(wallet1, 3 ether);
        vm.startPrank(wallet1);

        exchange.sovereignWithdrawal(address(0), 2 ether);

        // Increase EVM time to pass the delay
        vm.warp(block.timestamp + exchange.sovereignWithdrawalDelay());

        vm.expectRevert("Token mismatch");
        exchange.sovereignWithdrawal(usdcAddress, 1 ether);

        vm.stopPrank();
    }

    function test_sovereignWithdrawal_expiry_nativeToken() public {
        setupWallets();
        deposit(wallet1, 5 ether);
        vm.startPrank(wallet1);

        vm.expectEmit(exchangeProxyAddress);
        emit IExchange.WithdrawalRequested(address(wallet1), address(0), 2 ether);
        exchange.sovereignWithdrawal(address(0), 2 ether);

        // Increase EVM time to pass the expiry period 2x times
        vm.warp(block.timestamp + exchange.sovereignWithdrawalDelay() * 2);

        vm.expectEmit(exchangeProxyAddress);
        emit IExchange.WithdrawalRequested(address(wallet1), address(0), 4 ether);
        // re-initiate is possible due to expiry
        exchange.sovereignWithdrawal(address(0), 4 ether);

        (address tokenAddress, uint256 amount, uint256 timestamp) = exchange.sovereignWithdrawals(wallet1);
        assertEq(tokenAddress, address(0));
        assertEq(amount, 4 ether);
        assertGt(timestamp, 0);

        vm.stopPrank();
    }

    function test_setSovereignWithdrawalDelay() public {
        vm.startPrank(exchange.owner());

        exchange.setSovereignWithdrawalDelay(2 days);
        assertEq(exchange.sovereignWithdrawalDelay(), 2 days);

        vm.stopPrank();
    }

    function test_setSovereignWithdrawalDelay_revertIfNotOwner() public {
        vm.startPrank(wallet1);

        vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, wallet1));
        exchange.setSovereignWithdrawalDelay(2 days);

        vm.stopPrank();
    }

    function test_setSovereignWithdrawalDelay_revertIfInvalidDelay() public {
        vm.startPrank(exchange.owner());

        vm.expectRevert(bytes("Not a valid sovereign withdrawal delay"));
        exchange.setSovereignWithdrawalDelay(0);

        vm.stopPrank();
    }
}