//
//  NFTRow.swift
//  Metamask_demo_for_hsbc
//
//  Created by Mi Leo on 5/21/22.
//

import Foundation
import SwiftUI


struct NFTRow: View {
    var wallet: WalletInfo
    
    var body: some View {
        HStack {
            wallet.icon.resizable().frame(width: 44, height: 44)
            Text(wallet.balance)
            Text(wallet.unit)
            Spacer()
        }.navigationTitle("Wallet List")
    }
}


struct WalletInfo {
    let name: String
    let icon: Image
    let balance: String
    let unit: String
}


struct NFTRow_Previews: PreviewProvider {
    static var previews: some View {
        NFTRow(wallet: WalletInfo(name: "ETH", icon: Image("ETH"), balance: "123321.1234", unit: "ETH"))
        NFTRow(wallet: WalletInfo(name: "BTC", icon: Image("BTC"), balance: "3211.12312", unit: "BTC"))

    }
}
