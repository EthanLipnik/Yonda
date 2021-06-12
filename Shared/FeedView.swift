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
    var nspace: Namespace.ID
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [.init(.adaptive(minimum: 300))], spacing: 0) {
                ForEach(feed.items, id: \.title) { item in
                    ItemView(item: item, selectedItem: $selectedItem, nspace: nspace)
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
        @Binding var selectedItem: Moji.Item?
        var nspace: Namespace.ID
        @State var date: Date? = nil
        
        var body: some View {
            Button {
                withAnimation(.spring()) {
                    selectedItem = item
                }
            } label: {
                VStack(alignment: .leading) {
                    Text(item.title ?? "")
                        .font(.title.bold())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .matchedGeometryEffect(id: (item.link?.absoluteString ?? item.title ?? UUID().uuidString) + "-title", in: nspace)
                    Text(item.description ?? "")
                        .foregroundColor(Color.secondary)
                        .matchedGeometryEffect(id: (item.link?.absoluteString ?? item.title ?? UUID().uuidString) + "-description", in: nspace)
                    if let date = item.pubDate {
                        Text(date, style: .date)
                            .foregroundColor(Color("TertiaryLabel"))
                            .matchedGeometryEffect(id: (item.link?.absoluteString ?? item.title ?? UUID().uuidString) + "-date", in: nspace)
                    }
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 30, style: .continuous)
                            #if !os(macOS)
                                .fill(Color("Primary"))
                                .shadow(radius: 20)
                            #else
                                .fill(Color("Secondary"))
                            #endif
                                .matchedGeometryEffect(id: (item.link?.absoluteString ?? item.title ?? UUID().uuidString) + "-background", in: nspace)
                )
                .padding()
            }
            .buttonStyle(.plain)
        }
    }
}

//struct ChannelView_Previews: PreviewProvider {
//    static var previews: some View {
//        FeedView()
//    }
//}
