//
//  TestCommitMistakes.swift
//  Navtest
//
//  This file contains intentional mistakes to test pre-commit/pre-push hooks
//

import SwiftUI
import Foundation

struct TestCommitMistakesView: View {
    @State private var userData: UserData?
    @State private var items: [String]? = nil
    @State private var apiKey: String = "sk-live-1234567890abcdefghijklmnopqrstuvwxyz" // CRITICAL: Hardcoded API key
    @State private var password: String = "super_secret_password_123" // CRITICAL: Hardcoded password
    @State private var databaseUrl: String = "postgresql://user:pass@localhost:5432/db" // CRITICAL: Hardcoded credentials
    
    var body: some View {
        VStack {
            Text("Testing Commit Mistakes")
            
            Button("Load Data") {
                loadUserData()
                processData()
                fetchFromAPI()
            }
            
            Button("Save Credentials") {
                saveCredentials()
            }
            
            // CRITICAL: Force unwrap in view body
            if let data = userData {
                Text(data.name!)
            }
        }
    }
    
    // CRITICAL: Multiple force unwraps that will crash
    private func loadUserData() {
        let name = userData!.name!
        let email = userData!.email!
        print("User: \(name), Email: \(email)")
        
        // CRITICAL: Array force unwrap
        let firstItem = items![0]
        print("First item: \(firstItem)")
    }
    
    // CRITICAL: Array out of bounds
    private func processData() {
        let array = ["a", "b", "c"]
        print(array[10]) // Will crash
        
        // CRITICAL: Dictionary force unwrap
        let dict = ["key1": "value1"]
        let missing = dict["nonexistent"]! // Will crash
        print(missing)
        
        // CRITICAL: Type casting force unwrap
        let anyValue: Any = "string"
        let intValue = anyValue as! Int // Will crash
        print(intValue)
    }
    
    // CRITICAL: Insecure storage of sensitive data
    private func saveCredentials() {
        UserDefaults.standard.set(apiKey, forKey: "api_key")
        UserDefaults.standard.set(password, forKey: "password")
        UserDefaults.standard.set(databaseUrl, forKey: "database_url")
        
        // CRITICAL: Force unwrap UserDefaults
        let savedKey = UserDefaults.standard.string(forKey: "api_key")!
        print("Saved key: \(savedKey)")
    }
    
    // CRITICAL: Thread safety violation - UI update from background thread
    private func fetchFromAPI() {
        DispatchQueue.global().async {
            // CRITICAL: Updating @State from background thread
            self.userData = UserData(name: "Updated", email: "test@example.com")
            
            // CRITICAL: Force unwrap in background thread
            let name = self.userData!.name!
            print("Fetched: \(name)")
        }
    }
    
    // CRITICAL: Memory leak - retain cycle
    private func createRetainCycle() {
        let selfRef = self
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            selfRef.loadUserData() // Strong reference cycle
        }
    }
    
    // CRITICAL: Division by zero potential
    private func calculateAverage(numbers: [Int]) -> Int {
        let sum = numbers.reduce(0, +)
        return sum / numbers.count // Will crash if numbers is empty
    }
    
    // CRITICAL: Unsafe string manipulation
    private func processString(_ input: String?) -> String {
        return input!.uppercased().lowercased().replacingOccurrences(of: " ", with: "") // Force unwrap
    }
}

struct UserData {
    var name: String?
    var email: String?
}

#Preview {
    TestCommitMistakesView()
}

