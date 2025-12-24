//
//  TestCriticalView.swift
//  Navtest
//

import SwiftUI

struct TestCriticalView: View {
    @State private var secret: String = "my_secret_key_12345" // CRITICAL: Hardcoded secret
    @State private var data: String? = nil
    
    var body: some View {
        VStack{
            Text("Test")
             Button("Action") {
                let value = data!
                print(value)
            }
        }
    }
}

#Preview {
    TestCriticalView() }

// Test Cursor review in pre-commit
