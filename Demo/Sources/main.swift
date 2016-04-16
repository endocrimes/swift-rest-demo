import Frank
import Resource
import Nest
import Inquiline
import Foundation
import JSON

enum Status: String {
	case Outstanding
	case Completed
}

struct Todo: Resource {
	var identifier: String
	var title: String
	var status: Status

	init(identifier:String =  NSUUID().UUIDString, title: String, status: Status = .Outstanding) {
		self.identifier = identifier
		self.title = title
		self.status = status
	}

	func attributes() -> [String : Any] {
		return [
			"identifier" : identifier,
			"title" : title,
			"status" : status.rawValue
		]
	}
}

var todos = [
	Todo(identifier: "1234", title: "Write talk for SPADC", status: .Completed),
	Todo(title: "Present talk at SPADC")
]

get("todos") { _ in
	return collectionResponse(todos)
}

post("todos") { req in
	var request = req
	let body = request.body!.collect()
	let parsed = try! JSONParser.parse(body).dictionaryValue!
	let title = parsed["title"]!.stringValue!
	let status = parsed["status"]!.stringValue!

	let todo = Todo(title: title, status: Status(rawValue: status)!)
	todos.append(todo)

	return try! todo.get(request)
}

func todoWithIdentifier(identifier: String) -> Todo? {
	return todos.filter { $0.identifier == identifier } .first
}

get("todos", *) { (request, identifier: String) in
	guard let todo = todoWithIdentifier(identifier) else {
		return Response(.NotFound, contentType: "application/json", headers: [], content: "{}")
	}

	return try! todo.get(request)
}

post("todos", *, "toggle") { (request, identifier: String) in
	guard var todo = todoWithIdentifier(identifier) else {
		return Response(.NotFound, contentType: "application/json", headers: [], content: "{}")
	}

	switch todo.status {
	case .Outstanding:
		todo.status = .Completed
	case .Completed:
		todo.status = .Outstanding
	}

	todos = todos.filter({ $0.identifier != identifier }) + [todo]

	return try! todo.get(request)
}

