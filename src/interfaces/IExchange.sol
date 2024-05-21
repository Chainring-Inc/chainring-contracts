// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IVersion.sol";

interface IExchange is IVersion {
    event Deposit(address indexed from, address token, uint256 amount);
    event Withdrawal(address indexed to, address token, uint256 amount);

    error ErrorDidNotNetToZero(address token);

    enum TransactionType {
        Withdraw,
        WithdrawNative,
        SettleTrade
    }

    enum ErrorCode {
        InvalidSignature,
        InsufficientBalance
    }

    struct Withdraw {
        address sender;
        address token;
        uint256 amount;
        uint64 nonce;
    }

    struct WithdrawWithSignature {
        uint64 sequence;
        Withdraw tx;
        bytes signature;
    }

    struct WithdrawNative {
        address sender;
        uint256 amount;
        uint64 nonce;
    }

    struct WithdrawNativeWithSignature {
        uint64 sequence;
        WithdrawNative tx;
        bytes signature;
    }

    struct Order {
        address sender;
        int256 amount;
        uint256 price;
        uint256 nonce;
    }

    struct OrderWithSignature {
        Order tx;
        bytes signature;
    }

    struct Adjustment {
        uint16 walletIndex;
        uint256 amount;
    }

    struct WalletTradeList {
        bytes32[] tradeHashes;
    }

    struct TokenAdjustmentList {
        address token;
        Adjustment[] increments;
        Adjustment[] decrements;
        uint256 feeAmount;
    }

    struct BatchSettlement {
        address[] walletAddresses;
        WalletTradeList[] walletTradeLists;
        TokenAdjustmentList[] tokenAdjustmentLists;
    }

    struct SettleTrade {
        uint64 sequence;
        address baseToken;
        address quoteToken;
        int256 amount;
        uint256 price;
        uint256 takerFee;
        uint256 makerFee;
        OrderWithSignature takerOrder;
        OrderWithSignature makerOrder;
    }

    struct ExecutionInfo {
        int256 filledAmount;
        uint256 executionPrice;
        uint256 fee;
        int256 baseAdjustment;
        int256 quoteAdjustment;
    }

    event OrderFilled(
        bytes32 indexed digest,
        address indexed sender,
        address baseToken,
        address quoteToken,
        bool isTaker,
        Order order,
        ExecutionInfo executionInfo
    );

    event PrepareTransactionFailed(uint64 sequence, ErrorCode errorCode);

    event SettlementFailed(address _address, bytes32[] tradeHashes, ErrorCode errorCode);

    event SettlementCompleted(address _address, bytes32[] tradeHashes);

    event AmountAdjusted(address indexed sender, address token, uint256 requested, uint256 actual);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function deposit(address _token, uint256 _amount) external;

    receive() external payable;

    function submitWithdrawals(bytes[] calldata withdrawals) external;

    function submitBatch(bytes[] calldata transactions) external;

    function prepareBatch(bytes[] calldata transactions) external;

    function submitSettlementBatch(bytes calldata data) external;

    function prepareSettlementBatch(bytes calldata data) external;

    function rollbackBatch() external;

    function setSubmitter(address _submitter) external;

    function setFeeAccount(address _feeAccount) external;
}
