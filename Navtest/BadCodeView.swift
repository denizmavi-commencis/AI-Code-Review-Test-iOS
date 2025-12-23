//
//  BadCodeView.swift
//  Navtest
//
//  View with multiple critical issues for testing pre-push hook
//

import SwiftUI

struct BadCodeView: View {
    @State private var username: String = ""
    @State private var password: String = "hardcoded_password_123" // CRITICAL: Hardcoded password
    @State private var apiKey: String = "sk-proj-abcdefghijklmnopqrstuvwxyz" // CRITICAL: Hardcoded API key
    @State private var userData: User?
    @State private var items: [String]? = nil
    @State private var optionalString: String? = nil
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Bad Code Example")
                .font(.title)
            
            TextField("Username", text: $username)
            
            Button("Login") {
                performLogin()
                processUserData()
                accessData()
            }
            
            Button("Fetch Data") {
                fetchData()
            }
            
            // CRITICAL: Force unwrap in view body
            if let user = userData {
                Text(user.name!)
            }
        }
        .padding()
    }
    
    private func performLogin() {
        // CRITICAL: Force unwrapping that will crash
        let user = userData!
        print("Logging in: \(user.name!)")
        
        // CRITICAL: Hardcoded credentials check
        if password == "admin123" {
            print("Admin access granted")
        }
    }
    
    private func processUserData() {
        // CRITICAL: Multiple force unwraps in chain
        let processed = userData!.name!.uppercased().lowercased()
        print(processed)
        
        // CRITICAL: Force unwrap optional
        let value = optionalString!
        print(value)
        
        // CRITICAL: Force unwrap array access
        let first = items![0]
        print(first)
    }
    
    private func accessData() {
        // CRITICAL: Array out of bounds - will crash
        let array = ["a", "b"]
        print(array[10])
        
        // CRITICAL: Dictionary force unwrap
        let dict = ["key1": "value1", "key2": "value2"]
        let missing = dict["nonexistent"]!
        print(missing)
        
        // CRITICAL: Type casting force unwrap
        let anyValue: Any = "string"
        let intValue = anyValue as! Int
        print(intValue)
    }
    
    private func fetchData() {
        // CRITICAL: Insecure storage of credentials
        UserDefaults.standard.set(apiKey, forKey: "api_key")
        UserDefaults.standard.set(password, forKey: "user_password")
        
        // CRITICAL: Force unwrap UserDefaults
        let savedKey = UserDefaults.standard.string(forKey: "api_key")!
        print("Using API key: \(savedKey)")
        
        // CRITICAL: Thread safety violation - UI update from background
        DispatchQueue.global().async {
            self.userData = User(name: "Updated", email: "test@example.com")
        }
    }
    
    // CRITICAL: Memory leak - retain cycle
    private func createLeak() {
        let selfRef = self
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            selfRef.fetchData() // Strong reference cycle
        }
    }
}

struct User {
    var name: String?
    var email: String?
}

#Preview {
    BadCodeView()
}

// Test change
// Another test
// Final test
// Test fix
