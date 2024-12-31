//
//  ContentView.swift
//  NotificationContentExtension
//
//  Created by Himshikhar Gayan on 13/08/24.
//

import SwiftUI
import PushEngage

@available(iOSApplicationExtension 13.0, *)
struct ContentView: View {
    
    var payLoadInfo: CustomUIModel
    
    var body: some View {
        VStack(alignment: .center,spacing: 10) {
            HStack(alignment: .center) {
                Text("PushEngage Notification")
                    .foregroundColor(.black)
                    .bold()
                Image("image")
                    .resizable()
                    .padding()
                    .frame(width: 20, height: 20, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
            }
            Image(uiImage: payLoadInfo.image ?? UIImage())
                .resizable()
                .frame(width: 300, height: 300,
                       alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
            Text(payLoadInfo.title)
                .foregroundColor(.black)
                .fontWeight(.medium)
                .padding(.all, 10)
            Text(payLoadInfo.body)
                .foregroundColor(.black)
                .fontWeight(.regular)
                .padding(.all, 10)
        }.background(Color.white)
    }
    
}

