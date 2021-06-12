//
//  HomeView.swift
//  Yonda
//
//  Created by Ethan Lipnik on 6/11/21.
//

import SwiftUI
import Moji

struct HomeView: View {
    let feeds: [Moji.RSS]
    
    @Binding var selectedItem: Moji.Item?
    var nspace: Namespace.ID
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [.init(.adaptive(minimum: 300))], spacing: 0) {
                ForEach(feeds.flatMap({ $0.items }).sorted(by: { ($0.pubDate ?? Date()).compare($1.pubDate ?? Date()) == .orderedDescending }), id: \.title) { item in
                    FeedView.ItemView(item: item, selectedItem: $selectedItem, nspace: nspace)
                        .id((item.title ?? "") + (item.description ?? "") + "\(item.hashValue)")
                }
            }.padding()
        }
        .frame(minWidth: 300)
        .background(Color("Background"))
        .navigationTitle("Home")
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(feeds: [], selectedItem: .constant(nil), nspace: Namespace().wrappedValue)
    }
}
