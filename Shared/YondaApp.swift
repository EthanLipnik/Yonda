//
//  YondaApp.swift
//  Shared
//
//  Created by Ethan Lipnik on 6/9/21.
//

import SwiftUI
import Moji

@main
struct YondaApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .onOpenURL { url in
                    if let scheme = url.scheme, scheme == "feed" {
                        let urlStr = String(url.absoluteString
                            .dropFirst()
                            .dropFirst()
                            .dropFirst()
                            .dropFirst()
                            .dropFirst())
                        
                        async {
                            let newItem = Source(context: persistenceController.container.viewContext)
                            newItem.url = urlStr
                            
                            do {
                                let rss = try await Moji.decode(from: URLRequest(url: URL(string: urlStr)!))
                                newItem.title = rss.title
                                
                                try persistenceController.container.viewContext.save()
                                NotificationCenter.default.post(Notification.UpdateSourcesNotification)
                            } catch {
                                // Replace this implementation with code to handle the error appropriately.
                                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                                let nsError = error as NSError
                                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
                            }
                        }
                    }
                }
        }
        .commands {
            SidebarCommands()
        }
    }
}

extension Notification {
    static let UpdateSourcesNotification = Notification(name: Notification.Name(rawValue: "UpdateSourcesNotification"))
}
