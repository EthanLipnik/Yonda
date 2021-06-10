//
//  NewSourceView.swift
//  Yonda
//
//  Created by Ethan Lipnik on 6/9/21.
//

import SwiftUI

struct NewSourceView: View {
    let completion: (URL?) -> Void
    @State var source = ""
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack {
            Text("Add a source")
                .font(.title)
            TextField("Source", text: $source, onCommit:  {
                presentationMode.wrappedValue.dismiss()
                completion(URL(string: source))
            })
            Spacer()
            HStack {
                Button(role: .cancel) {
                    presentationMode.wrappedValue.dismiss()
                    completion(nil)
                } label: {
                    Text("Cancel")
                }.keyboardShortcut(.cancelAction)
                Spacer()
                Button {
                    presentationMode.wrappedValue.dismiss()
                    completion(URL(string: source))
                } label: {
                    Text("Add")
                }.keyboardShortcut(.defaultAction)
            }
        }.padding()
    }
}

struct NewSourceView_Previews: PreviewProvider {
    static var previews: some View {
        NewSourceView() { url in
            print(url?.absoluteString ?? "No url")
        }
    }
}
