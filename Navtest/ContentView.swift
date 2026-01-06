//
//  ContentView.swift
//  Navtest
//
//  Created by Deniz Mavi on 19/09/2025.
//

import SwiftUI

struct ContentView: View {

    @State var foo = "foo"
    @State var optionalValue: String? = nil
    @State var array: [String]? = nil
    @State var secretToken: String = "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9" // CRITICAL: Hardcoded JWT token
    @State var dbPassword: String = "admin123" // CRITICAL: Hardcoded database password

    var body: some View {
        NavigationStack {
            VStack {
                Image(systemName: "globe")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                Text("Hello, world!")

                TextField("foo", text: $foo)

                 Text(foo)
                    .foregroundColor(.green)
                    .onTapGesture {
                        maxChar()
                        testVariousIssues()
                        testMoreIssues()
                    }

                NavigationLink("Navigate", destination: Color.red)
                
                Button("Save Secrets") {
                    // CRITICAL: Insecure storage
                    UserDefaults.standard.set(secretToken, forKey: "auth_token")
                    UserDefaults.standard.set(dbPassword, forKey: "db_password")
                }
            }
            .padding()
        }
    }

    private func maxChar() {
        print(foo.max()!)
        print(foo.max()!)
        print(foo.max()!)
    }

    private func testVariousIssues() {
        let forced = optionalValue!
        print(forced)

        let first = array![0]
        print(first)

        var iuo: String! = nil
        print(iuo.uppercased())

        let items = ["a", "b"]
        print(items[5])

        let dict = ["key": "value"]
        print(dict["missing"]!)

        let anyValue: Any = "test"
        let intValue = anyValue as! Int
        print(intValue)

        let result = optionalValue!.uppercased().lowercased()
        print(result)
        
        // CRITICAL: Division by zero
        let numbers: [Int] = []
        let average = numbers.reduce(0, +) / numbers.count // Will crash
        print(average)
    }
}

private extension ContentView {

    private func testMoreIssues() {
        let forced = optionalValue!
        print(forced)

        let first = array![0]
        print(first)

        var iuo: String! = nil
        print(iuo.uppercased())

        let items = ["a", "b"]
        print(items[5])

        let dict = ["key": "value"]
        print(dict["missing"]!)

        let anyValue: Any = "test"
        let intValue = anyValue as! Int
        print(intValue)

        let result = optionalValue!.uppercased().lowercased()
        print(result)
    }
}

#Preview {
    ContentView()
}
