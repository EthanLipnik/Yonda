//
//  YondaApp.swift
//  Shared
//
//  Created by Ethan Lipnik on 6/9/21.
//

import SwiftUI

@main
struct YondaApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }.commands {
            SidebarCommands()
        }
    }
}
