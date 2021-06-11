//
//  FeedView.swift
//  Yonda
//
//  Created by Ethan Lipnik on 6/9/21.
//

import SwiftUI
import Moji

struct FeedView: View {
    let feed: Moji.RSS
    
    @Binding var selectedItem: Moji.Item?
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [.init(.adaptive(minimum: 200, maximum: 300))]) {
                ForEach(feed.items ?? [], id: \.title) { item in
                    Button {
                        selectedItem = item
                    } label: {
                        ItemView(item: item)
                    }
                    .buttonStyle(.plain)
                    .id((item.title ?? "") + (item.description ?? "") + "\(item.hashValue)")
                }
            }.padding()
        }
        .frame(minWidth: 300)
        .background(Color("Background"))
        .navigationTitle(feed.title ?? "")
        #if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
    
    struct ItemView: View {
        let item: Moji.Item
        
        var body: some View {
            VStack {
                Text(item.title ?? "")
                    .font(.title.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(item.description ?? "")
                    .foregroundColor(Color.secondary)
                    .lineLimit(2)
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 30, style: .continuous)
                            .fill(Color.blue)
                            .shadow(radius: 20))
            .padding()
        }
    }
}

//struct ChannelView_Previews: PreviewProvider {
//    static var previews: some View {
//        FeedView()
//    }
//}
