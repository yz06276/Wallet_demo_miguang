//
//  CircleImage.swift
//  Metamask_demo_for_hsbc
//
//  Created by Mi Leo on 5/21/22.
//

import Foundation
import SwiftUI

struct UserInfoView: View {
    
    @EnvironmentObject var account: OOAccount

    let bigCircleRadius: CGFloat = 57
    let smallCircleRadium: CGFloat = 50
    
    
    var body: some View {
        VStack {
            ZStack {
                Color("TintColor")
                    .frame(width: bigCircleRadius, height: bigCircleRadius, alignment: .center)
                    .clipShape(Circle())
                Color.white
                    .frame(width: smallCircleRadium, height: smallCircleRadium, alignment: .center)
                    .clipShape(Circle())
                Image("fox")
                    .resizable()
                    .frame(width: smallCircleRadium, height: smallCircleRadium, alignment: .center)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(.white, lineWidth: 2))
            }
            
            Text(account.userName).font(.system(size: 15, weight: .medium))
            Text("\(account.banlance) ETH").font(.system(size: 20)).foregroundColor(Color("Grey"))
            ZStack{
                Color("BlueBackground")
                Text(account.address).frame(width: 90).font(.system(size: 13))
            }.frame(width: 110, height: 30, alignment: .center).cornerRadius(30)
            
        }
    }
}

struct CircleImage_Previews: PreviewProvider {
    static var previews: some View {
        UserInfoView()
    }
}
