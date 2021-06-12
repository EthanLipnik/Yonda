//
//  NewSourceView.swift
//  Yonda
//
//  Created by Ethan Lipnik on 6/9/21.
//

import SwiftUI
import Moji

struct NewSourceView: View {
    let completion: (URL?) -> Void
    @State var source = ""
    @State var shouldShowDetails = false
    @State var rssFeed: Moji.RSS? = nil
    @Environment(\.openURL) var openURL
    @State var alreadyExists = false
    @State var failedToFindSource = false
    
    @FetchRequest(
        sortDescriptors: [],
        animation: .default)
    private var sources: FetchedResults<Source>
    
    var body: some View {
        VStack {
            Text("Add a source")
                .font(.title)
            TextField("Source", text: $source, onCommit: add)
                .textFieldStyle(.roundedBorder)
                .onChange(of: source) { _ in
                    withAnimation(.easeInOut) {
                        shouldShowDetails = false
                        rssFeed = nil
                        alreadyExists = false
                        failedToFindSource = false
                    }
                }
            if let rssFeed = rssFeed, shouldShowDetails {
                VStack(alignment: .leading, spacing: 10) {
                    Text(rssFeed.title ?? "Unknown title")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(rssFeed.description ?? "Unknown description")
                        .font(.subheadline)
                    Label("\(rssFeed.items.count) items", systemImage: "rectangle.grid.1x2.fill")
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color("Secondary")))
                .frame(maxWidth: .infinity, alignment: .leading)
                .contextMenu {
                    if let language = rssFeed.language {
                        Label(language.uppercased(), systemImage: "flag")
                    }
                    Divider()
                    if let link = rssFeed.link {
                        Button {
                            openURL(link)
                        } label: {
                            Label(link.rootDomain ?? link.absoluteString, systemImage: "globe")
                        }
                    }
                }
            } else if shouldShowDetails {
                ProgressView()
            }
            HStack {
                Button(role: .cancel) {
                    completion(nil)
                } label: {
                    Text("Cancel")
                }
                .keyboardShortcut(.cancelAction)
                Spacer()
                if alreadyExists {
                    Text("Source is already added")
                        .foregroundColor(Color.red)
                } else if failedToFindSource {
                    Text("Failed to resolve source")
                        .foregroundColor(Color.red)
                }
                Button(action: add) {
                    Text(shouldShowDetails ? "Add" : "Find")
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.bordered)
                .disabled(source.isEmpty)
            }
        }
        .padding()
#if !os(macOS)
        .background(RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .fill(Material.thin)
                        .shadow(radius: 30)
        )
#endif
    }
    
    func add() {
        if shouldShowDetails {
            if !sources.contains(where: { $0.url == source || $0.title == rssFeed?.title }) {
                completion(URL(string: source))
            } else {
                withAnimation(.easeInOut) {
                    alreadyExists = true
                }
            }
        } else if let url = URL(string: source) {
            withAnimation(.easeInOut) {
                shouldShowDetails = true
            }
            
            async {
                do {
                    let feed = try await Moji.decode(from: URLRequest(url: url))
                    if feed.title?.isEmpty ?? true || feed.title == nil {
                        throw URLError(.badServerResponse)
                    }
                    withAnimation(.easeInOut) {
                        rssFeed = feed
                        failedToFindSource = false
                    }
                } catch {
                    print(error)
                    withAnimation(.easeInOut) {
                        shouldShowDetails = false
                        failedToFindSource = true
                    }
                }
            }
        }
    }
}

struct NewSourceView_Previews: PreviewProvider {
    static var previews: some View {
        NewSourceView() { url in
            print(url?.absoluteString ?? "No url")
        }
    }
}
