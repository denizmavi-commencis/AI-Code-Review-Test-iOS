//
//  CriticalIssuesView.swift
//  Navtest
//
//  Created for testing pre-push hook
//

import SwiftUI

struct CriticalIssuesView: View {
    @State private var apiKey: String = "sk_live_1234567890abcdef" // CRITICAL: Hardcoded API key
    @State private var password: String = "admin123" // CRITICAL: Hardcoded password
    @State private var secretToken: String = "secret_token_xyz789" // CRITICAL: Another hardcoded secret
    @State private var userData: UserData?
    @State private var items: [String]? = nil
    @State private var optionalValue: String? = nil
    
    var body: some View {
        VStack {
            Text("Critical Issues Demo")
                .font(.largeTitle)
            
            Button("Load Data") {
                loadUserData()
                processData()
                accessArray()
            }
            
            Button("Save Credentials") {
                saveCredentials()
            }
            
            if let data = userData {
                Text(data.name!)
            }
        }
        .onAppear {
            initializeData()
        }
    }
    
    private func loadUserData() {
        // CRITICAL: Force unwrapping that will crash if nil
        let name = userData!.name!
        let email = userData!.email!
        print("User: \(name), Email: \(email)")
        
        // CRITICAL: Force unwrapping optional array
        let firstItem = items![0]
        print(firstItem)
    }
    
    private func processData() {
        // CRITICAL: Multiple force unwraps in chain
        let result = optionalValue!.uppercased().lowercased().capitalized
        print(result)
        
        // CRITICAL: Force unwrap dictionary access
        let dict = ["key": "value"]
        let value = dict["missing"]!
        print(value)
    }
    
    private func accessArray() {
        // CRITICAL: Array out of bounds - will crash
        let array = ["a", "b", "c"]
        print(array[10])
        
        // CRITICAL: Force unwrap optional array access
        let item = items![5]
        print(item)
    }
    
    private func saveCredentials() {
        // CRITICAL: Storing credentials insecurely
        UserDefaults.standard.set(apiKey, forKey: "api_key")
        UserDefaults.standard.set(password, forKey: "password")
        
        // CRITICAL: Force unwrap UserDefaults
        let savedKey = UserDefaults.standard.string(forKey: "api_key")!
        print("Saved: \(savedKey)")
    }
    
    private func initializeData() {
        // CRITICAL: Force unwrap in initialization
        userData = UserData(name: "Test", email: "test@example.com")
        items = ["item1", "item2"]
    }
    
    // CRITICAL: Memory leak - retain cycle
    private func createRetainCycle() {
        let view = self
        DispatchQueue.main.async {
            view.processData() // Captures self strongly
        }
    }
    
    // CRITICAL: Thread safety violation - accessing UI from background thread
    private func updateUIFromBackground() {
        DispatchQueue.global().async {
            self.userData = UserData(name: "Updated", email: "updated@example.com")
            // Accessing @State from background thread - will crash
        }
    }
}

struct UserData {
    var name: String?
    var email: String?
}

#Preview {
    CriticalIssuesView()
}

