//
//  MainnetSetup.swift
//  Metamask_demo_for_hsbc
//
//  Created by Mi Leo on 5/21/22.
//

import Foundation
import RxSwift
import EthereumKit
import BigInt
import HdWalletKit

// 以下均为 EthereumKit 初始化通信逻辑，参照了一些官方指导的设计

protocol IAdapter {
    func start()
    func stop()
    func refresh()

    var name: String { get }
    var coin: String { get }

    var lastBlockHeight: Int? { get }
    var syncState: SyncState { get }
    var transactionsSyncState: SyncState { get }
    var balance: Decimal { get }

    var receiveAddress: Address { get }

    var lastBlockHeightObservable: Observable<Void> { get }
    var syncStateObservable: Observable<Void> { get }
    var transactionsSyncStateObservable: Observable<Void> { get }
    var balanceObservable: Observable<Void> { get }
    var transactionsObservable: Observable<Void> { get }

    func sendSingle(to address: Address, amount: Decimal, gasLimit: Int, gasPrice: GasPrice) -> Single<Void>
    func transactionsSingle(from hash: Data?, limit: Int?) -> Single<[TransactionRecord]>
    func transaction(hash: Data, interTransactionIndex: Int) -> TransactionRecord?
    func transactionSingle(hash: Data) -> Single<FullTransaction>

    func estimatedGasLimit(to address: Address, value: Decimal, gasPrice: GasPrice) -> Single<Int>
}

struct TransactionRecord {
    let transactionHash: String
    let transactionHashData: Data
    let timestamp: Int
    let isFailed: Bool

    let from: Address?
    let to: Address?
    let amount: Decimal?
    let input: String?

    let blockHeight: Int?
    let transactionIndex: Int?

    let decoration: String
}


class EthereumAdapter: EthereumBaseAdapter {
    let signer: Signer
    private let decimal = 18

    init(signer: Signer, ethereumKit: Kit) {
        self.signer = signer

        super.init(ethereumKit: ethereumKit)
    }

    override func sendSingle(to: Address, amount: Decimal, gasLimit: Int, gasPrice: GasPrice) -> Single<Void> {
        let amount = BigUInt(amount.roundedString(decimal: decimal))!
        let transactionData = evmKit.transferTransactionData(to: to, value: amount)

        return evmKit.rawTransaction(transactionData: transactionData, gasPrice: gasPrice, gasLimit: gasLimit)
                .flatMap { [weak self] rawTransaction in
                    guard let strongSelf = self else {
                        throw Signer.SendError.weakReferenceError
                    }

                    let signature = try strongSelf.signer.signature(rawTransaction: rawTransaction)

                    return strongSelf.evmKit.sendSingle(rawTransaction: rawTransaction, signature: signature)
                }
                .map { (tx: FullTransaction) in () }
    }

}


class EthereumBaseAdapter: IAdapter {
    let evmKit: Kit
    private let decimal = 18

    init(ethereumKit: Kit) {
        evmKit = ethereumKit
    }

    private func transactionRecord(fullTransaction: FullTransaction) -> TransactionRecord {
        let transaction = fullTransaction.transaction

        var amount: Decimal?

        if let value = transaction.value, let significand = Decimal(string: value.description) {
            amount = Decimal(sign: .plus, exponent: -decimal, significand: significand)
        }


        return TransactionRecord(
                transactionHash: transaction.hash.toHexString(),
                transactionHashData: transaction.hash,
                timestamp: transaction.timestamp,
                isFailed: transaction.isFailed,
                from: transaction.from,
                to: transaction.to,
                amount: amount,
                input: transaction.input.map { $0.toHexString() },
                blockHeight: transaction.blockNumber,
                transactionIndex: transaction.transactionIndex,
                decoration: String(describing: fullTransaction.decoration)
        )
    }

    func start() {
        evmKit.start()
    }

    func stop() {
        evmKit.stop()
    }

    func refresh() {
        evmKit.refresh()
    }

    var name: String {
        "Ethereum"
    }

    var coin: String {
        "ETH"
    }

    var lastBlockHeight: Int? {
        evmKit.lastBlockHeight
    }

    var syncState: SyncState {
        evmKit.syncState
    }

    var transactionsSyncState: SyncState {
        evmKit.transactionsSyncState
    }

    var balance: Decimal {
        if let balance = evmKit.accountState?.balance, let significand = Decimal(string: balance.description) {
            return Decimal(sign: .plus, exponent: -decimal, significand: significand)
        }

        return 0
    }

    var receiveAddress: Address {
        evmKit.receiveAddress
    }

    var lastBlockHeightObservable: Observable<Void> {
        evmKit.lastBlockHeightObservable.map { _ in () }
    }

    var syncStateObservable: Observable<Void> {
        evmKit.syncStateObservable.map { _ in () }
    }

    var transactionsSyncStateObservable: Observable<Void> {
        evmKit.transactionsSyncStateObservable.map { _ in () }
    }

    var balanceObservable: Observable<Void> {
        evmKit.accountStateObservable.map { _ in () }
    }

    var transactionsObservable: Observable<Void> {
        evmKit.transactionsObservable(tags: [[]]).map { _ in () }
    }

    func sendSingle(to address: Address, amount: Decimal, gasLimit: Int, gasPrice: GasPrice) -> Single<Void> {
        fatalError("Subclasses must override.")
//        let amount = BigUInt(amount.roundedString(decimal: decimal))!
//        let transactionData = evmKit.transferTransactionData(to: to, value: amount)
//
//        return evmKit.sendSingle(transactionData: transactionData, gasPrice: 50_000_000_000, gasLimit: gasLimit).map { _ in ()}
    }

    func transactionsSingle(from hash: Data?, limit: Int?) -> Single<[TransactionRecord]> {
        evmKit.transactionsSingle(tags: [], fromHash: hash, limit: limit)
                .map { [weak self] in
                    $0.compactMap {
                        self?.transactionRecord(fullTransaction: $0)
                    }
                }
    }

    func transaction(hash: Data, interTransactionIndex: Int) -> TransactionRecord? {
        evmKit.transaction(hash: hash).map { transactionRecord(fullTransaction: $0) }
    }

    func estimatedGasLimit(to address: Address, value: Decimal, gasPrice: GasPrice) -> Single<Int> {
        let value = BigUInt(value.roundedString(decimal: decimal))!

        return evmKit.estimateGas(to: address, amount: value, gasPrice: gasPrice)
    }

    func transactionSingle(hash: Data) -> Single<FullTransaction> {
        evmKit.transactionSingle(hash: hash)
    }

}



 class Manager {
    static let shared = Manager()

    private let keyWords = "mnemonic_words"
    private let keyAddress = "address"

    var signer: EthereumKit.Signer!
    var evmKit: EthereumKit.Kit!

    var ethereumAdapter: IAdapter!

    init() {
        if let words = savedWords {
            initEthereumKit(words: words)
        }
    }

    func login(words: [String]) {
        try! EthereumKit.Kit.clear(exceptFor: ["walletId"])

        save(words: words)
        initEthereumKit(words: words)
    }

    func watch(address: Address) {
        try! EthereumKit.Kit.clear(exceptFor: ["walletId"])

        save(address: address.hex)
        initEthereumKit(address: address)
    }

    func logout() {
        clearWords()

        signer = nil
        evmKit = nil
        ethereumAdapter = nil
    }

    private func initEthereumKit(words: [String]) {
        let configuration = Configuration.shared

        let seed = Mnemonic.seed(mnemonic: words)

        let signer = try! Signer.instance(
                seed: seed,
                chain: configuration.chain
        )
        let evmKit = try! EthereumKit.Kit.instance(
                address: Signer.address(seed: seed, chain: configuration.chain),
                chain: configuration.chain,
                rpcSource: configuration.rpcSource,
                transactionSource: configuration.transactionSource,
                walletId: "walletId",
                minLogLevel: .verbose
        )

        ethereumAdapter = EthereumAdapter(signer: signer, ethereumKit: evmKit)
    
        self.signer = signer
        self.evmKit = evmKit



        evmKit.start()

    }

    private func initEthereumKit(address: Address) {
        let configuration = Configuration.shared

        let evmKit = try! Kit.instance(address: address,
                chain: configuration.chain,
                rpcSource: configuration.rpcSource,
                transactionSource: configuration.transactionSource,
                walletId: "walletId",
                minLogLevel: configuration.minLogLevel
        )
        ethereumAdapter = EthereumBaseAdapter(ethereumKit: evmKit)

  
        self.evmKit = evmKit

    
        evmKit.start()

    }

    private var savedWords: [String]? {
        if let wordsString = UserDefaults.standard.value(forKey: keyWords) as? String {
            return wordsString.split(separator: " ").map(String.init)
        }
        return nil
    }

    private func save(words: [String]) {
        UserDefaults.standard.set(words.joined(separator: " "), forKey: keyWords)
        UserDefaults.standard.synchronize()
    }

    private func save(address: String) {
        UserDefaults.standard.set(address, forKey: keyAddress)
        UserDefaults.standard.synchronize()
    }

    private func clearWords() {
        UserDefaults.standard.removeObject(forKey: keyWords)
        UserDefaults.standard.synchronize()
    }

}


import EthereumKit
import HsToolKit

class Configuration {
    static let shared = Configuration()

    let chain: Chain = .ethereum

    let rpcSource: RpcSource = .ethereumInfuraWebsocket(projectId: "2a1306f1d12f4c109a4d4fb9be46b02e", projectSecret: "fc479a9290b64a84a15fa6544a130218")
//    let rpcSource: RpcSource = .ethereumInfuraHttp(projectId: "2a1306f1d12f4c109a4d4fb9be46b02e", projectSecret: "fc479a9290b64a84a15fa6544a130218")

    let transactionSource: TransactionSource = .ethereumEtherscan(apiKey: "GKNHXT22ED7PRVCKZATFZQD1YI7FK9AAYE")

    let minLogLevel: Logger.Level = .error
    let defaultsWords = "apart approve black  comfort steel spin real renew tone primary key cherry"

    let infuraCredentials: (id: String, secret: String?) = (id: "2a1306f1d12f4c109a4d4fb9be46b02e", secret: "fc479a9290b64a84a15fa6544a130218")

    var erc20Tokens: [Erc20Token] {
        switch chain.id {
        case 1: return [
            Erc20Token(name: "DAI",       coin: "DAI",  contractAddress: try! Address(hex: "0x6b175474e89094c44da98b954eedeac495271d0f"), decimal: 18),
            Erc20Token(name: "USD Coin",  coin: "USDC", contractAddress: try! Address(hex: "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"), decimal: 6),
        ]
        case 56: return [
            Erc20Token(name: "Beefy.Finance", coin: "BIFI",  contractAddress: try! Address(hex: "0xCa3F508B8e4Dd382eE878A314789373D80A5190A"), decimal: 18),
            Erc20Token(name: "PancakeSwap", coin: "CAKE",  contractAddress: try! Address(hex: "0x0e09fabb73bd3ade0a17ecc321fd13a19e81ce82"), decimal: 18),
            Erc20Token(name: "BUSD",        coin: "BUSD",  contractAddress: try! Address(hex: "0xe9e7cea3dedca5984780bafc599bd69add087d56"), decimal: 18),
        ]
        case 3: return [
            //            Erc20Token(name: "GMO coins", coin: "GMOLW", contractAddress: try! Address(hex: "0xbb74a24d83470f64d5f0c01688fbb49a5a251b32"), decimal: 18),
            Erc20Token(name: "DAI",       coin: "DAI",   contractAddress: try! Address(hex: "0xad6d458402f60fd3bd25163575031acdce07538d"), decimal: 18),
            //            Erc20Token(name: "MMM",       coin: "MMM",   contractAddress: try! Address(hex: "0x3e500c5f4de2738f65c90c6cc93b173792127481"), decimal: 8),
            //            Erc20Token(name: "WEENUS",    coin: "WEENUS", contractAddress: try! Address(hex: "0x101848d5c5bbca18e6b4431eedf6b95e9adf82fa"), decimal: 18),
        ]
        case 42: return [
            Erc20Token(name: "DAI",       coin: "DAI",   contractAddress: try! Address(hex: "0x4f96fe3b7a6cf9725f59d353f723c1bdb64ca6aa"), decimal: 18),
        ]
        default: return []
        }
    }

}

public struct Erc20Token {
    let name: String
    let coin: String
    let contractAddress: Address
    let decimal: Int
}
