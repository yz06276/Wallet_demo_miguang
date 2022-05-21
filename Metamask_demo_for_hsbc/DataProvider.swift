//
//  DataProvider.swift
//  ksljdfhkjsadhf
//
//  Created by Mi Leo on 5/21/22.
//

import Foundation
import RxSwift
import EthereumKit
import BigInt
import HdWalletKit
import SwiftUI

let wallAddress = "0x2819c144d5946404c0516b6f817a960db37d4929" // 固定的钱包
let transactionHash = "0xbe81eeb75d1dc722a8c86f7c26f8f964f410d5e6175d2a54a4d744472cf73aec" // 交易遍历逻辑复杂，该 Demo 中直接根据 TxHash 查询单个交易

class OOTransaction: ObservableObject { // 用于向 SwiftUI 元素传值的全局交易信息，App 启动后会拉取
    @Published var time: String = ""
    @Published var isFailed: Bool = false
    @Published var value: String = "refreshing..." // 默认的交易金额是 Refreshing 所以显示具体金额时，即代表拉取的结果
    var name: String = "智能合约交互"
    var icon: Image = Image("Swap")
}

class OOAccount: ObservableObject { // 用于向 SwiftUI 元素传值的全局钱包账户信息，App 启动后会拉取，展示余额
    @Published var banlance: String = "refreshing..."
    var userName = "MI GUANG"
    var address = wallAddress
}

class MainnetDataProvider {
    static let shared = MainnetDataProvider()
    private let decimal = 18
    var evmKit: EthereumKit.Kit! // 此处强制解包是安全的
    let words = ["apart", "approve", "black", "comfort", "steel", "spin", "real", "renew", "tone", "primary", "key", "cherry"]
    let manager = Manager.shared
    var ooTx: OOTransaction = OOTransaction()
    var ooAccount: OOAccount = OOAccount()
    
    func getReadableStringFromValue(_ value: BigUInt?) -> String? {
        if let balance = value, let significand = Decimal(string: balance.description) {
            return "\(Decimal(sign: .plus, exponent: -self.decimal, significand: significand))"
        } else {
            return nil
        }
    }
    
    func refresh() {
        // Manager 方法内已实现 ETH Infura Mainnet Websocket 通信所需步骤，在此只需更新钱包地址即可
        Manager.shared.watch(address: try! Address(hex: wallAddress)) //由于地址是保证存在的 hardCode 所以这里使用了强制解包
        Manager.shared.ethereumAdapter.refresh() // 刷新钱包
        guard let ethereumKit = Manager.shared.evmKit else {
            return
        }
        let _ = ethereumKit.lastBlockHeightObservable.subscribe(onNext: { height in print(height) }) // 观察 block 大小可以用来确认 WebSocket 通信正常
        let _ = ethereumKit.syncStateObservable.subscribe(onNext: { state in print(state)
            
            switch state {
            case .synced:
                // 刷新后即可 查询钱包余额
                if let result = self.getReadableStringFromValue(ethereumKit.accountState?.balance) {
                 
                    self.ooAccount.banlance = result
                }
                // 直接根据 txHash 查询特定订单，然后刷新 SwiftUI 的交易列表页
                if let txHash = Data(hex: transactionHash) , let tx = ethereumKit.transaction(hash: txHash) {
                    self.ooTx.time = Date(timeIntervalSince1970: Double(tx.transaction.timestamp)).description(with: Locale(identifier: "ZH-Beijing"))
                    self.ooTx.isFailed = tx.transaction.isFailed
                    if let result = self.getReadableStringFromValue(tx.transaction.value) {
                        self.ooTx.value = result
                    }
                }
            default:
                break
            }
        })

    }

}

