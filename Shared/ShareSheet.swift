//
//  ShareSheet.swift
//  Canister
//
//  Created by Ethan Lipnik on 12/3/20.
//

import SwiftUI

struct ShareSheet: UIViewControllerRepresentable {
    typealias Callback = (_ activityType: UIActivity.ActivityType?, _ completed: Bool, _ returnedItems: [Any]?, _ error: Error?) -> Void
    
    let activityItems: [Any]
    var callback: Callback? = nil
    
    #if targetEnvironment(macCatalyst)
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let controller = UIDocumentPickerViewController(forExporting: activityItems.compactMap({ $0 as? URL }))
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {
        // Do nothing
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var parent: ShareSheet
        
        init(_ parent: ShareSheet) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            parent.callback?(nil, true, nil, nil)
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.callback?(nil, true, nil, nil)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    #else
    
    var applicationActivities: [UIActivity]? = nil
    var excludedActivityTypes: [UIActivity.ActivityType]? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities)
        controller.excludedActivityTypes = excludedActivityTypes
        controller.completionWithItemsHandler = callback
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // nothing to do here
    }
    #endif
}
