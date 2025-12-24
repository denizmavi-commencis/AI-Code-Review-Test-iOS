//
//  SwiftLintTestView.swift
//  Navtest
//

import SwiftUI

struct SwiftLintTestView: View {
    var body: some View {
        VStack {
            Text("Test")
            // This line is way too long and should trigger SwiftLint's line_length warning if configured, and also has trailing whitespace at the end        
        }
    }
    
    func testFunction() {
        let x=5
        let y = 6
        var unusedVariable = "test"
        print(x+y)
    }
}

#Preview {
    SwiftLintTestView()
}

// More violations
// Test violation
