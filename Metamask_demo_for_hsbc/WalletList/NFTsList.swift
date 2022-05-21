//
//  NFTsList.swift
//  Metamask_demo_for_hsbc
//
//  Created by Mi Leo on 5/21/22.
//

import Foundation
import SwiftUI

struct NFTsList: View {
    
    var wallets: [WalletInfo] = [
        WalletInfo(name: "ETH", icon: Image("ETH"), balance: "123321.1234", unit: "ETH"),
        WalletInfo(name: "BTC", icon: Image("BTC"), balance: "3211.12312", unit: "BTC"),
        
    ]
    
    var body: some View {
        
        List(wallets, id: \.name) { wallet in
            NavigationLink(destination: Wallet()) {
                NFTRow(wallet: wallet)
            }
        }.listStyle(.plain)
    }
    
}


struct NFTsList_Previews: PreviewProvider {
    static var previews: some View {
        NFTsList()
    }
}
