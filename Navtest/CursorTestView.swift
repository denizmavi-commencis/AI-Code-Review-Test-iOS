//
//  CursorTestView.swift
//  Navtest
//
//  Test file to trigger Cursor AI warnings
//

import SwiftUI

struct CursorTestView: View {
    @State private var apiKey: String = "sk_live_abc123xyz789" // Hardcoded API key
    @State private var userData: String? = nil
    
    var body: some View {
        VStack {
            Text("Test View")
            Button("Action") {
                let value = userData!
                print(value)
                
                let dict = ["key": "value"]
                let missing = dict["nonexistent"]!
                print(missing)
            }
        }
    }
}

#Preview {
    CursorTestView()
}

