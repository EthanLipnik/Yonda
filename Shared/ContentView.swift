//
//  ContentView.swift
//  Shared
//
//  Created by Ethan Lipnik on 6/9/21.
//

import SwiftUI
import CoreData
import Moji
import Sebu
import FavIcon

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [],
        predicate: NSPredicate(format: "isPinned == true"),
        animation: .default)
    private var pinnedSources: FetchedResults<Source>
    
    @FetchRequest(
        sortDescriptors: [],
        predicate: NSPredicate(format: "isPinned == false"),
        animation: .default)
    private var unpinnedSources: FetchedResults<Source>
    
    @State var feeds: [Moji.RSS] = []
    @State var selectedFeed: Moji.RSS?
    @State var selectedItem: Moji.Item? = nil
    @State var shouldAddSource = false
    
    var body: some View {
        ZStack {
            NavigationView {
                List {
                    if !feeds.isEmpty {
                        if !pinnedSources.isEmpty {
                            Section("Pinned") {
                                ForEach(pinnedSources) { source in
                                    if let feed = feeds.first(where: { $0.title == source.title }) {
                                        
                                        FeedItem(feed: feed, source: source, updateSources: updateSources(withAnimation:), selectedItem: $selectedItem, selectedFeed: $selectedFeed)
                                            .environment(\.managedObjectContext, viewContext)
                                    }
                                }
                            }
                        }
                        if !unpinnedSources.isEmpty {
                            Section("Feeds") {
                                ForEach(unpinnedSources) { source in
                                    if let feed = feeds.first(where: { $0.title == source.title }) {
                                        FeedItem(feed: feed, source: source, updateSources: updateSources(withAnimation:), selectedItem: $selectedItem, selectedFeed: $selectedFeed)
                                            .environment(\.managedObjectContext, viewContext)
                                    }
                                }
                            }
                        }
                    } else {
                        ProgressView("Loading...", value: Float(feeds.count) / Float(pinnedSources.count + unpinnedSources.count))
                    }
                }
                .listStyle(SidebarListStyle())
                .refreshable {
                    await updateSources(withAnimation: true)
                }
                .frame(minWidth: 200)
                .navigationTitle("Yonda")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            shouldAddSource = true
                        } label: {
                            Label("Add source", systemImage: "plus")
                        }
                    }
                }
            }
            
            //            if let item = selectedItem {
            //                ItemDetailView(item: item)
            //                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            //                    .background(Material.thick)
            //            }
        }
        .sheet(isPresented: $shouldAddSource) {
            NewSourceView() { url in
                if let url = url {
                    addItem(url: url)
                }
            }
        }
        .task {
            await updateSources()
        }
    }
    
    private func updateSources(withAnimation animation: Bool = false) async {
        var newFeeds: [Moji.RSS] = [] {
            didSet {
                withAnimation(animation ? .default : .none) {
                    if newFeeds.count >= pinnedSources.count + unpinnedSources.count {
                        self.feeds = newFeeds
                    }
                }
            }
        }
        do {
            for source in pinnedSources.map({ $0 }) + unpinnedSources.map({ $0 }) {
                if let urlStr = source.url, let url = URL(string: urlStr) {
                    if let cache: Moji.RSS = try? Sebu.get(withName: source.title!) {
                        
                        NSLog("🔵 Got cache for source", source.title ?? "Unknown title")
                        
                        newFeeds.append(cache)
                    } else {
                        let rss = try await Moji.decode(from: URLRequest(url: url))
                        NSLog("🟢 Loaded remote for source", source.title ?? rss.title ?? "Unknown title")
                        
                        try Sebu.save(rss, withName: source.title!, expiration: Calendar.current.date(byAdding: .minute, value: 20, to: Date()))
                        
                        newFeeds.append(rss)
                        
                        source.title = rss.title
                        try viewContext.save()
                    }
                }
            }
        } catch {
            NSLog("🔴 Failed to get sources \(error)")
        }
    }
    
    private func addItem(url: URL) {
        withAnimation {
            let newItem = Source(context: viewContext)
            newItem.url = url.absoluteString
            
            do {
                let rss = try Moji.decode(from: Data(contentsOf: url))
                newItem.title = rss.title!
                
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
            
            async {
                await updateSources(withAnimation: true)
            }
        }
    }
    //
    //    private func deleteItems(offsets: IndexSet) {
    //        withAnimation {
    //            offsets.map { feeds[$0] }.forEach(viewContext.delete)
    //
    //            do {
    //                try viewContext.save()
    //            } catch {
    //                // Replace this implementation with code to handle the error appropriately.
    //                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
    //                let nsError = error as NSError
    //                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
    //            }
    //        }
    //    }
    
    struct FeedItem: View {
        let feed: Moji.RSS
        let source: Source
        let updateSources: (_ withAnimation: Bool) async -> Void
        @Binding var selectedItem: Moji.Item?
        @Binding var selectedFeed: Moji.RSS?
        
        @Environment(\.managedObjectContext) private var viewContext
        
        @State var icon: URL? = nil
        @State var shouldDelete: Bool = false
        
        var body: some View {
            NavigationLink(destination: FeedView(feed: feed, selectedItem: $selectedItem), tag: feed, selection: $selectedFeed) {
                Label {
                    Text(feed.title ?? "Unknown title")
                } icon: {
                    if let icon = icon {
                        AsyncImage(url: icon) { phase in
                            switch phase {
                            case .empty:
                                RoundedRectangle(cornerRadius: 5, style: .continuous)
                                    .fill(Color.secondary)
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .clipShape(RoundedRectangle(cornerRadius: 2))
                                    .transition(.opacity)
                            case .failure:
                                Image(systemName: "newspaper")
                            @unknown default:
                                // Since the AsyncImagePhase enum isn't frozen,
                                // we need to add this currently unused fallback
                                // to handle any new cases that might be added
                                // in the future:
                                EmptyView()
                            }
                        }
                    } else {
                        Image(systemName: "newspaper")
                    }
                }
            }
            .contextMenu {
                Button {
                    source.isPinned.toggle()
                    
                    try? viewContext.save()
                } label: {
                    Label(source.isPinned ? "Unpin" : "Pin", systemImage: source.isPinned ? "pin.slash" : "pin")
                }
                Divider()
                Button(role: .destructive) {
                    shouldDelete.toggle()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
            .alert("Deleting this source will require you to add it again if you want to add it back.", isPresented: $shouldDelete, actions: {
                Button("Delete", role: .destructive) {
                    viewContext.delete(source)
                    
                    try? Sebu.clear(source.title!)
                    do {
                        try viewContext.save()
                        await updateSources(true)
                    } catch {
                        print(error)
                    }
                }
                Button("Cancel", role: .cancel) {
                    shouldDelete.toggle()
                }
            })
            .task {
                do {
                    self.icon = try await feed.getFavicon()
                } catch {
                    print(error)
                }
            }
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
