//
//  ContentView.swift
//  Metamask_demo_for_hsbc
//
//  Created by Mi Leo on 5/21/22.
//

import SwiftUI

struct Wallet: View {
    var buttons = ["Receive", "Buy", "Send", "Swap"]
    init() {
        MainnetDataProvider.shared.refresh()
    }
    var body: some View {
        NavigationView{
            VStack(alignment: .center, spacing: 10){
                UserInfoView().environmentObject(MainnetDataProvider.shared.ooAccount)
                HStack(alignment: .center, content: {
                    ForEach(0 ..< buttons.count) {
                        ActionButton(self.buttons[$0])
                    }
                })
                Spacer()
                NavigationLink {
                    NFTsList()
                } label: {
                    Text("Wallet List")
                }
                
                NavigationLink {
                    TransactionList()
                } label: {
                    Text("Transaction List")
                }
            }.navigationTitle("Wallet")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Wallet()
    }
}
