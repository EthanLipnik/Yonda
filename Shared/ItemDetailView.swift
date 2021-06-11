//
//  ItemDetailView.swift
//  Yonda
//
//  Created by Ethan Lipnik on 6/11/21.
//

import SwiftUI
import Moji
import SwiftSoup

struct ItemDetailView: View {
    let item: Moji.Item
    
    @Binding var selectedItem: Moji.Item?
    @Environment(\.openURL) var openURL
    var nspace: Namespace.ID
    @State var contents: [ContentItem<AnyView>] = []
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack {
                    Text(item.title ?? "")
                        .font(.largeTitle.bold())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .matchedGeometryEffect(id: (item.link?.absoluteString ?? item.title ?? UUID().uuidString) + "-title", in: nspace)
                    if let date = item.pubDate {
                        Text(date, style: .date)
                            .foregroundColor(Color.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    Text(item.description ?? "")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .matchedGeometryEffect(id: (item.link?.absoluteString ?? item.title ?? UUID().uuidString) + "-description", in: nspace)
                }
                Divider()
                if !contents.isEmpty {
                    VStack {
                        ForEach(contents) { view in
                            view.content
                        }
                    }.transition(.opacity)
                }
            }
            .padding()
            .padding(.bottom, 70)
        }
#if os(macOS)
        .frame(minWidth: 400, minHeight: 600)
        .overlay(
            HStack {
            if let link = item.link {
                Button {
                    openURL(link)
                } label: {
                    Label("View as webpage", systemImage:"globe")
                        .font(.headline)
                        .lineLimit(1)
                }
            }
            Spacer()
            Button("Done") {
                selectedItem = nil
            }.keyboardShortcut(.cancelAction)
        }
                .padding()
                .background(Material.thin)
                .overlay(Divider(), alignment: .top),
            alignment: .bottom
        )
#else
        .background(Color("Background"))
        .matchedGeometryEffect(id: (item.link?.absoluteString ?? item.title ?? UUID().uuidString) + "-background", in: nspace)
        .overlay(
            Button {
            withAnimation {
                selectedItem = nil
            }
        } label: {
            Image(systemName: "xmark")
        }
                .padding()
                .background(Circle()
                                .fill(Material.thin)
                                .shadow(radius: 10))
                .padding(.leading),
            alignment: .bottomLeading
        )
        .overlay(
            Group {
            if let link = item.link {
                Button {
                    openURL(link)
                } label: {
                    Label("View as webpage", systemImage:"globe")
                        .font(.headline)
                        .lineLimit(1)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 30, style: .continuous)
                                .fill(Material.thin)
                                .shadow(radius: 10))
            } else {
                EmptyView()
            }
        },
            alignment: .bottom
        )
        .overlay(
            GeometryReader { reader in
            Rectangle()
                .fill(Color("Background"))
                .frame(height: reader.safeAreaInsets.top)
                .offset(y: -reader.safeAreaInsets.top)
        },
            alignment: .top
        )
#endif
        .task {
            if let content = item.content {
                do {
                    let doc: Document = try SwiftSoup.parse(content)
                    let text = doc.body()?.children()
                    withAnimation {
                        do {
                            if try text.map({ try $0.text() })?.isEmpty ?? true {
                                if let content = item.content {
                                    contents = [ContentItem(content: AnyView(Text(content).frame(maxWidth: .infinity, alignment: .leading)))]
                                }
                                
                                return
                            }
                            contents = try text?
                                .compactMap({ element -> ContentItem<AnyView>? in
                                    switch element.tagName() {
                                    case "p":
                                        let text = Text(try element.text())
#if os(macOS)
                                            .textSelection(.enabled)
#endif
                                            .font(.body)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        
                                        return ContentItem(content: AnyView(text))
                                    case "pre":
                                        let view = Text(try element
                                                            .children()
                                                            .map({ try $0.text() })
                                                            .joined(separator: "\n"))
#if os(macOS)
                                            .textSelection(.enabled)
                                            .font(.body.monospaced())
#else
                                            .font(.caption.monospaced())
#endif
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding()
                                            .background(RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                            .fill(Color("Secondary")))
                                        return ContentItem(content: AnyView(view))
                                    case "code":
                                        let view = Text(try element.text())
#if os(macOS)
                                            .textSelection(.enabled)
                                            .font(.body.monospaced())
#else
                                            .font(.caption.monospaced())
#endif
                                            .padding()
                                            .background(RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                            .fill(Color("Secondary")))
                                        return ContentItem(content: AnyView(view))
                                    case "a":
                                        print(try element.text())
                                        return nil
                                    default:
                                        return nil
                                    }
                                }) ?? []
                        } catch {
                            print(error)
                        }
                    }
                } catch {
                    print("error")
                }
            }
        }
    }
    
    struct ContentItem<Content: View>: Identifiable {
        let content: Content
        var id: UUID { UUID() }
    }
}

struct ItemDetailView_Previews: PreviewProvider {
    static var previews: some View {
        ItemDetailView(item: .init(title: "This is a title", description: "This is a cool description about the title"), selectedItem: .constant(nil), nspace: Namespace().wrappedValue)
    }
}
