//
//  ActionButton.swift
//  Metamask_demo_for_hsbc
//
//  Created by Mi Leo on 5/21/22.
//

import Foundation
import SwiftUI


struct ActionButton: View {
    var identifier: String
    init(_ name: String) {
        self.identifier = name
    }
    
    var body: some View {
        VStack {
            Image(self.identifier).resizable().frame(width: 36, height: 36, alignment: .center)
            Text(self.identifier).foregroundColor(Color("TintColor")).font(.system(size: 12))
        }.frame(width: 50, height: 63, alignment: .center)
    }
}

struct ActionButton_Previews: PreviewProvider {
    static var previews: some View {
        ActionButton("Swap")
    }
}

