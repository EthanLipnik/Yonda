//
//  ItemDetailView.swift
//  Yonda
//
//  Created by Ethan Lipnik on 6/9/21.
//

import SwiftUI
import WebView
import Moji

struct ItemDetailView: View {
    let item: Moji.Item
    
    @StateObject var webViewStore = WebViewStore()
    @Binding var selectedItem: Moji.Item?
    @Environment(\.openURL) var openURL
    @State var shouldViewAsWebpage = false
    
    var body: some View {
        WebView(webView: webViewStore.webView)
#if !os(macOS)
            .edgesIgnoringSafeArea(.vertical)
            .overlay(
                Group {
                if item.content != nil {
                    Button {
                        webViewStore.webView.loadHTMLString("<div/>", baseURL: nil)
                        withAnimation(.spring()) {
                            shouldViewAsWebpage.toggle()
                        }
                    } label: {
                        Label(shouldViewAsWebpage ? "Reader mode" : "View as webpage", systemImage: shouldViewAsWebpage ? "eyeglasses" : "globe")
                            .font(.headline)
                            .lineLimit(1)
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 30, style: .continuous)
                                    .fill(Material.thick)
                                    .shadow(radius: 30))
                    .padding()
                } else {
                    EmptyView()
                }
            },
                alignment: .bottom
            )
            .overlay(
                GeometryReader { reader in
                Rectangle()
                    .fill(Material.ultraThin)
                    .frame(height: reader.safeAreaInsets.top)
                    .offset(y: -reader.safeAreaInsets.top)
            },
                alignment: .top
            )
#else
            .overlay(
                HStack {
                Button {
                    webViewStore.webView.loadHTMLString("<div/>", baseURL: nil)
                    withAnimation(.spring()) {
                        shouldViewAsWebpage.toggle()
                    }
                } label: {
                    Label(shouldViewAsWebpage ? "Reader mode" : "View as webpage", systemImage: shouldViewAsWebpage ? "eyeglasses" : "globe")
                        .font(.headline)
                        .lineLimit(1)
                }
                Spacer()
                Button("Done") {
                    selectedItem = nil
                }.keyboardShortcut(.cancelAction)
            }
                    .padding()
                    .overlay(Divider(), alignment: .top)
                    .background(Material.thick),
                alignment: .bottom
            )
            .frame(minWidth: 400, minHeight: 600)
#endif
            .navigationTitle(webViewStore.title ?? "")
            .background(Material.thickMaterial)
            .onChange(of: shouldViewAsWebpage, perform: { viewer in
                updateWebView()
            })
            .task(updateWebView)
    }
    
    func updateWebView() {
        DispatchQueue.main.async {
            print(item)
#if !os(macOS)
            self.webViewStore.webView.isOpaque = false
            self.webViewStore.webView.backgroundColor = UIColor.clear
#else
            self.webViewStore.webView.setValue(false, forKey: "drawsBackground")
#endif
            
            if item.content == nil {
                shouldViewAsWebpage = item.content == nil
            }
            
            if item.content != nil && !shouldViewAsWebpage {
                let html = """
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>
html,
body {
font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif, "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol";
color: black;
}
@media (prefers-color-scheme: dark) {
body {
color: white;
}
}
</style>
</head>
<body>\(item.content!)</body>
</html>
"""
                self.webViewStore.webView.loadHTMLString(html, baseURL: nil)
            } else if let link = item.link {
                self.webViewStore.webView.load(URLRequest(url: link))
            } else {
                print(item)
                selectedItem = nil
            }
        }
    }
}

//struct ItemDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        ItemDetailView(item: <#Moji.Item#>)
//    }
//}
