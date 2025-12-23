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
