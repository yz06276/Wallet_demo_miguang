//
//  TransactionRow.swift
//  Metamask_demo_for_hsbc
//
//  Created by Mi Leo on 5/21/22.
//

import Foundation
import SwiftUI


struct TransactionRow: View {
    
    @EnvironmentObject var transaction: OOTransaction

    var body: some View {
        
        VStack(alignment: .leading, spacing: 20) {
            
            Text(transaction.time).font(.system(size: 12))
            HStack {
                transaction.icon.resizable().frame(width: 40, height: 40, alignment: .center)
                VStack(alignment: .leading, spacing: 10){
                    Text(transaction.name)
                    Text(transaction.isFailed ? "失败" : "已确认").foregroundColor(transaction.isFailed ? .red : .green).font(.system(size: 14))
                }
                Spacer()
                Text(transaction.value)
            }
        }
        
    }
}


struct TxValue {
    let name: String = "智能合约交互"
    let icon: Image = Image("Swap")
    let time: String
    let value: String
    let isFailed: Bool
}


struct TransactionRow_Previews: PreviewProvider {
    static var previews: some View {
        TransactionRow().environmentObject(MainnetDataProvider.shared.ooTx)
    }
}
