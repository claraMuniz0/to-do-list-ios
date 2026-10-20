@testable import MyApp

// Foundation's ObjC runtime also exports a `Category`; inside the test module this alias wins.
typealias Category = MyApp.Category
