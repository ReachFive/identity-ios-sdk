import Foundation

func mkString(start: String, fields: (field: Any?, name: String)...) -> String {
    mkString(start: "\(start)(", sep: ", ", end: ")", fields: fields)
}

//TODO réimplémenter avec mkString(start:sep:end:fields:)
func mkString(start: String, sep: String, end: String, fields: [(field: Any?, name: String)]) -> String {
    let nonNilFields = fields.compactMap { field, name in
        if let field {
            return (field, name)
        } else {
            return nil
        }
    }
    var iter = nonNilFields.makeIterator()
    var s = start
    var first = true
    while let next: (field: Any, name: String) = iter.next() {
        if first {
            first = false
        } else {
            s += sep
        }
        s += "\(next.name): \"\(next.field)\""
    }
    s += end
    return s
}

func mkString(start: String, sep: String, end: String, fields: [String]) -> String {
    var iter = fields.makeIterator()
    var s = start
    var first = true
    while let next: String = iter.next() {
        if first {
            first = false
        } else {
            s += sep
        }
        s += next
    }
    s += end
    return s
}