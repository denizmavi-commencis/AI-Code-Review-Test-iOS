//
//  TestHookView.swift
//  Navtest
//
//  Created to test pre-push hook detection of critical issues
//

import SwiftUI

struct TestHookView: View {
    @State private var apiKey: String = "sk-proj-1234567890abcdefghijklmnopqrstuvwxyz" // CRITICAL: Hardcoded API key
    @State private var password: String = "admin_password_123" // CRITICAL: Hardcoded password
    @State private var userData: UserInfo?
    @State private var items: [String]? = nil
    @State private var optionalValue: String? = nil
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Test Hook View")
                .font(.title)
            
            Button("Load Data") {
                loadData()
                processData()
                accessArray()
            }
            
            Button("Save Secrets") {
                saveSecrets()
            }
            
            // CRITICAL: Force unwrap in view body
            if let data = userData {
                Text(data.name!)
            }
        }
        .padding()
    }
    
    private func loadData() {
        // CRITICAL: Force unwrapping that will crash if nil
        let name = userData!.name!
        let email = userData!.email!
        print("User: \(name), Email: \(email)")
        
        // CRITICAL: Force unwrapping optional array
        let firstItem = items![0]
        print("First: \(firstItem)")
    }
    
    private func processData() {
        // CRITICAL: Multiple force unwraps in chain
        let result = optionalValue!.uppercased().lowercased()
        print(result)
        
        // CRITICAL: Dictionary force unwrap
        let dict = ["key": "value"]
        let missing = dict["nonexistent"]!
        print(missing)
        
        // CRITICAL: Type casting force unwrap
        let anyValue: Any = "string"
        let intValue = anyValue as! Int
        print(intValue)
    }
    
    private func accessArray() {
        // CRITICAL: Array out of bounds
        let array = ["a", "b", "c"]
        print(array[10])
        
        // CRITICAL: Force unwrap optional array access
        let item = items![5]
        print(item)
    }
    
    private func saveSecrets() {
        // CRITICAL: Insecure storage of credentials
        UserDefaults.standard.set(apiKey, forKey: "api_key")
        UserDefaults.standard.set(password, forKey: "user_password")
        
        // CRITICAL: Force unwrap UserDefaults
        let savedKey = UserDefaults.standard.string(forKey: "api_key")!
        print("Using API key: \(savedKey)")
        
        // CRITICAL: Thread safety violation - UI update from background
        DispatchQueue.global().async {
            self.userData = UserInfo(name: "Updated", email: "test@example.com")
        }
    }
    
    // CRITICAL: Memory leak - retain cycle
    private func createLeak() {
        let selfRef = self
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            selfRef.loadData() // Strong reference cycle
        }
    }
}

struct UserInfo {
    var name: String?
    var email: String?
}

#Preview {
    TestHookView()
}
