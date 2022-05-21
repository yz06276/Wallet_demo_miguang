//
//  TransactionList.swift
//  Metamask_demo_for_hsbc
//
//  Created by Mi Leo on 5/21/22.
//

import Foundation
import SwiftUI

struct TransactionList: View {
    
    var transactions: [OOTransaction] = [
        MainnetDataProvider.shared.ooTx,
        MainnetDataProvider.shared.ooTx,
        MainnetDataProvider.shared.ooTx,
    ]
    
    var body: some View {
        List(transactions, id: \.value) { tx in
            TransactionRow().environmentObject(tx)
        }.listStyle(.plain).navigationTitle("Transaction List")
    }
}


struct TransactionList_Previews: PreviewProvider {
    static var previews: some View {
        TransactionList()
    }
}
