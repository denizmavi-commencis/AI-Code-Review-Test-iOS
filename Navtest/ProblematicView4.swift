//
//  ProblematicView4.swift
//  Navtest
//
//  Created by Deniz Mavi on 18/12/2025.
//

import SwiftUI

struct ProblematicView4: View {

    @State var foo = "foo"
    @State var optionalValue: String? = nil
    @State var array: [String]? = nil

    var body: some View {
        Text("Hello, World!")
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

#Preview {
    ProblematicView4()
}
