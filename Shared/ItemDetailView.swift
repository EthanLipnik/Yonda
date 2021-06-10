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
    
    var body: some View {
        WebView(webView: webViewStore.webView)
            .navigationTitle(webViewStore.title ?? "")
            .onAppear {
                let html = """
<html>
<head>
<style>
html,
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif, "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol";
    }
</style>
</head>
<body>\(item.encoded ?? "<h1>Failed to get content</h1>")</body>
</html>
"""
                self.webViewStore.webView.loadHTMLString(html, baseURL: nil)
            }
    }
}

//struct ItemDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        ItemDetailView(item: <#Moji.Item#>)
//    }
//}
