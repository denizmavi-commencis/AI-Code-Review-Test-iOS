//
//  TestPushHook.swift
//  Navtest
//
//  Created for testing pre-push hook
//

import SwiftUI

struct TestPushHookView: View {
    // CRITICAL: Hardcoded API key and password
    @State private var apiKey: String = "sk-live-1234567890abcdefghijklmnopqrstuvwxyz"
    @State private var secretToken: String = "super_secret_password_12345"
    @State private var databaseUrl: String = "postgresql://user:password@localhost:5432/db"
    
    @State private var optionalValue: String? = nil
    @State private var items: [String]? = nil
    @State private var userData: UserInfo? = nil
    
    var body: some View {
        VStack {
            Text("Test Push Hook")
                .font(.title)
            
            Button("Test Critical Issues") {
                testForceUnwrapping()
                testArrayAccess()
                testDictionaryAccess()
                testTypeCasting()
                testBackgroundThread()
                testRetainCycle()
            }
        }
    }
    
    // CRITICAL: Multiple force unwraps that will crash
    private func testForceUnwrapping() {
        // Force unwrap nil optional
        let value = optionalValue!
        print(value.uppercased())
        
        // Force unwrap in chain
        let result = optionalValue!.uppercased().lowercased().capitalized
        print(result)
        
        // Force unwrap optional property
        let length = optionalValue!.count
        print(length)
    }
    
    // CRITICAL: Array out of bounds access
    private func testArrayAccess() {
        let array = ["a", "b", "c"]
        
        // Access index that doesn't exist
        print(array[10])
        print(array[-1])
        
        // Force unwrap optional array and access invalid index
        let item = items![100]
        print(item)
        
        // Access without bounds check
        let first = array[array.count] // Out of bounds
        print(first)
    }
    
    // CRITICAL: Dictionary force unwrap
    private func testDictionaryAccess() {
        let dict = ["key1": "value1", "key2": "value2"]
        
        // Force unwrap missing key
        let missing = dict["nonexistent"]!
        print(missing)
        
        // Force unwrap in chain
        let value = dict["missing"]!.uppercased()
        print(value)
    }
    
    // CRITICAL: Force type casting
    private func testTypeCasting() {
        let anyValue: Any = "this is a string"
        
        // Force cast to wrong type
        let intValue = anyValue as! Int
        print(intValue)
        
        // Force cast optional
        let stringValue = anyValue as! String?
        print(stringValue!)
    }
    
    // CRITICAL: UI state mutation from background thread
    private func testBackgroundThread() {
        DispatchQueue.global().async {
            // Mutating @State from background thread - will crash
            self.userData = UserInfo(name: "Background", email: "test@example.com")
            self.optionalValue = "set from background"
        }
        
        // Another background thread mutation
        DispatchQueue.global(qos: .utility).async {
            self.apiKey = "modified from background"
        }
    }
    
    // CRITICAL: Retain cycle
    private func testRetainCycle() {
        let selfRef = self
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            // Strong reference cycle
            selfRef.testForceUnwrapping()
            selfRef.testArrayAccess()
        }
        
        // Another retain cycle pattern
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.testDictionaryAccess()
        }
    }
    
    // CRITICAL: Division by zero potential
    private func testDivision() {
        let divisor: Int? = nil
        let dividend = 100
        
        // Force unwrap nil and divide
        let result = dividend / divisor!
        print(result)
    }
    
    // CRITICAL: Unsafe string manipulation
    private func testStringManipulation() {
        let str: String? = nil
        
        // Multiple force unwraps in chain
        let uppercased = str!.uppercased().lowercased().capitalized
        let substring = uppercased.prefix(10)
        print(substring)
    }
}

struct UserInfo {
    let name: String
    let email: String
}

#Preview {
    TestPushHookView()
}
