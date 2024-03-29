//
//  ItemDetailView.swift
//  Yonda
//
//  Created by Ethan Lipnik on 6/11/21.
//

import SwiftUI
import Moji
import SwiftSoup
import WebView

struct ItemDetailView: View {
    let item: Moji.Item
    
    @Binding var selectedItem: Moji.Item?
    @Environment(\.openURL) var openURL
    var nspace: Namespace.ID
    @State var contents: [ContentItem<AnyView>] = []
    @State var shouldShowCornerRadius = true
    
    var body: some View {
        content
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
        .background(Color("Primary"))
        .clipShape(RoundedRectangle(cornerRadius: shouldShowCornerRadius ? 30 : 0, style: .continuous))
        .matchedGeometryEffect(id: (item.link?.absoluteString ?? item.title ?? UUID().uuidString) + "-background", in: nspace)
        .ignoresSafeArea()
        .overlay(
            Button {
            shouldShowCornerRadius = true
            withAnimation(.spring()) {
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
        }
                .opacity(shouldShowCornerRadius ? 0 : 1),
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
                                        let text = Text(try element.text() + "\n")
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
                                            .padding(.bottom)
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
                                            .padding(.bottom)
                                        return ContentItem(content: AnyView(view))
                                    case "a", "h2":
                                        let attr = try element.attr("href")
                                        if let url = URL(string: attr) {
                                            return ContentItem(content: AnyView(Button(try element.text(), action: {
                                                openURL(url)
                                            })))
                                        } else {
                                            return ContentItem(content: AnyView(Text(try element.text())
                                                                                    .font(.title2.bold())
                                                                                    .padding(.top)
                                                                                    .frame(maxWidth: .infinity, alignment: .leading)))
                                        }
                                    case "iframe", "div":
#if os(macOS)
                                        let view = HStack {
                                            iFrameView(html: try? element.html(), url: URL(string: (try? element.select("iframe").first?.attr("src")) ?? ""))
                                                .frame(width: 300, height: 168.75, alignment: .leading)
                                            Spacer()
                                        }
                                        return ContentItem(content: AnyView(view))
#else
                                        return ContentItem(content: AnyView(iFrameView(html: try? element.html(), url: URL(string: (try? element.select("iframe").first?.attr("src")) ?? ""))
                                                                                .aspectRatio(16/9, contentMode: .fit)
                                                                                .frame(maxWidth: .infinity, alignment: .leading)))
#endif
                                    case "figure":
                                        guard let img = element.children().first?.children().first else { return nil }
                                        let attr = try img.attr("src")
                                        guard let url = URL(string: attr) else { return nil }
                                        if url.pathExtension != "gif" {
                                            return ContentItem(content: AnyView(
                                                AsyncImage(url: url) { phase in
                                                switch phase {
                                                case .empty:
                                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                        .fill(Color("Secondary"))
                                                        .aspectRatio(16/9, contentMode: .fit)
                                                        .shadow(radius: 10)
                                                        .onAppear {
                                                            print(url)
                                                        }
                                                case .success(let image):
                                                    image
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fit)
                                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                                        .shadow(radius: 10)
                                                case .failure:
                                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                        .fill(Color.red)
                                                        .shadow(color: Color.red, radius: 10)
                                                        .onAppear {
                                                            print(url)
                                                        }
                                                @unknown default:
                                                    // Since the AsyncImagePhase enum isn't frozen,
                                                    // we need to add this currently unused fallback
                                                    // to handle any new cases that might be added
                                                    // in the future:
                                                    EmptyView()
                                                }
                                            }
                                            ))
                                        } else {
                                            let view = VStack {
                                                iFrameView(html: nil, url: url)
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                                Link(url.absoluteString, destination: url)
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                            }
                                                .padding(.bottom)
                                            return ContentItem(content: AnyView(view))
                                        }
                                    default:
                                        print(try element.html(), element.tagName())
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
    
    var content: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack {
                    Text(item.title ?? "")
                        .font(.title.bold())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .matchedGeometryEffect(id: (item.link?.absoluteString ?? item.title ?? UUID().uuidString) + "-title", in: nspace)
                    Text(item.description ?? "")
                        .foregroundColor(Color.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .matchedGeometryEffect(id: (item.link?.absoluteString ?? item.title ?? UUID().uuidString) + "-description", in: nspace)
                    if let date = item.pubDate {
                        Text(date, style: .date)
                            .foregroundColor(Color("TertiaryLabel"))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .matchedGeometryEffect(id: (item.link?.absoluteString ?? item.title ?? UUID().uuidString) + "-date", in: nspace)
                    }
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
            .padding(.vertical, 70)
        }
        .onAppear {
            withAnimation {
                shouldShowCornerRadius = false
            }
        }
    }
    
    struct ContentItem<Content: View>: Identifiable {
        let content: Content
        var id: UUID { UUID() }
    }
    
    struct iFrameView: View {
        var html: String? = nil
        var url: URL? = nil
        @StateObject var webViewStore = WebViewStore()
        
        var body: some View {
            WebView(webView: webViewStore.webView)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .shadow(radius: 10)
                .onAppear {
                    if let url = url {
                        webViewStore.webView.load(URLRequest(url: url))
                    } else if let html = html {
                        webViewStore.webView.loadHTMLString(html, baseURL: nil)
                    }
#if !os(macOS)
                    webViewStore.webView.scrollView.isScrollEnabled = false
#endif
                }
        }
    }
}

struct ItemDetailView_Previews: PreviewProvider {
    static var previews: some View {
        ItemDetailView(item: .init(title: "This is a title", description: "This is a cool description about the title"), selectedItem: .constant(nil), nspace: Namespace().wrappedValue)
    }
}
