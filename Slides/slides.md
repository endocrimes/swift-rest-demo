
# REST API's in Swift
###  Danielle Lancashire*⚡︎* @endocrimes

---

# Key Parts
1. HTTP Server (kylef/Currasow)
2. Router (nestproject/Frank)

^
Most web applications contain at least two core components, a HTTP Server and a Router.

---

# Decentralization

![inline](https://avatars3.githubusercontent.com/u/11672187?v=3&s=200)

[https://github.com/*NestProject*](https://github.com/NestProject)

^
The Nest Project provides a set of protocols for allowing different components
from web services to work together.
It's similar to Ruby's Unicorn and Python's GUnicorn.
This is important, as it means you can do things like develop locally
with a simple or debugging server, and deploy to production with something much
more efficient. Or switch to something that supports different HTTP protocols without
affecting your codebase.

---

# Key Parts

1. HTTP Server (kylef/Currasow)

^
Firstly, they have a HTTP server. A HTTP server listens for HTTP requests on a particular port. When someone opens a connection to the port, it will perform some basic parsing of the request to get the method, the URI, the headers, and a response body.
You generally then pass this request to a Router.

---

# Key Parts

1. HTTP Server (kylef/Currasow)
2. Router (nestproject/Frank)

^
You give a router a set of patterns to match, and code to execute when a request matches.
When you pass a request to a router, it will find the most specific matching pattern, and execute the code, passing in any arguments, as well as the rest of the request.
The Router will also often provide a way of responding to a request. In the case of Frank, you return a Response object.

---

# Hello World

```swift
// main.swift
import Frank

func responseWithName(name: String) -> ResponseConvertible {
  return Response(.Ok,
      contentType: "text/html",
      body: "\<html\>\<body\>\<h1\>Hello \(name)!\</h1\>\</body\>\</html\>")
}

// GET /
get { _ in
  return responseWithName("World")
}

// GET /hello/{name}
get("hello", *) { (_, name: String) in
  return responseWithName(name)
}
```

^
Here is a simple Hello World application built with Currasow and Frank.
We setup the routes in main.swift, and return simple HTML responses.
Frank will use Currasow to handle HTTP requests and responses by default.

---

![fit](http://static1.squarespace.com/static/52cafb80e4b0aeb5eedf6291/t/54ecf6cce4b012d8652aa867/1424815822482/)

^

---

## Live Coding

![](https://media.serious.io/bc5d9b10a8bcbc0f/serious.gif)

---

# Ooops...

![](https://bkhemphill.files.wordpress.com/2014/08/tumblr_inline_n06qp9cgvq1sy774p.gif?w=720)

---

# Getting Started

```bash
$ mkdir api
$ touch Package.swift
$ mkdir api
$ touch api/main.swift
$ touch api/helpers.swift
```

^
Swift  doesn't yet automatically have a project bootstrap tool, so we're going
to setup a simple file structure. I won't be showing helpers.swift in this
presentation, as the code is mostly for brevity elsewhere. It will be in the GitHub
repo.

---

# SPM

```swift
// Package.swift
import PackageDescription

let package = Package(
 name: "API",
 dependencies: [
  .Package(url: "https://github.com/nestproject/Frank.git", majorVersion: 0),
  .Package(url: "https://github.com/endocrimes/Resource.git", majorVersion: 0)
 ])
```

^
Now we're going to write a simple Package.swift to import Frank and a resource
modelling library I wrote called Resource to help simplify the responses.

---

# SPM

```bash
$ swift build
```

![](http://www.reactiongifs.us/wp-content/uploads/2013/03/cookie_monster_waiting.gif)

^
Running swift build will download and build the dependencies specified in the Package.swift
This can take a while.

---

# Models!

```swift
// main.swift
import Resource

enum Status: String {
  case Outstanding
  case Completed
}

struct Todo: Resource {
  let identifier: String
  let title: String
  let status: Status

  init(identifier: NSUUID().UUIDString, title: String, status: Status = .Outstanding) {
    self.identifier = identifier
    self.title = title
    self.status = status
  }

  func attributes() -> [String : Any] {
    return [
      "identifier": identifier,
      "title": title,
      "status": status.rawValue
    ]
  }
}

```

^
We're going to define a simple todo type for use in the API, and we're going
to inherit from the Resource protocol. Resource provides some default implementations
of functions to help later on.

---

# Storage

```swift
// main.swift

...

var todos = [
  Todo(identifier: "1234", title: "Write talk for SPADC", status: .Completed),
  Todo(title: "Present talk at SPADC")
]

```

^
We're going to use an in memory array for this demo, rather than setting up a
database.

---

# GET /todos

```swift
// main.swift
import Resource
import Frank

...

get("todos") { _ in
  return collectionResponse(todos)
}

```

---

# GET /todos

```json
[
  {
    "identifier": "1234",
    "title": "Write SPADC Talk",
    "status": "Completed"
  },
  {
    "identifier": "967B102B-EAEB-462F-907E-F193CE2DB463",
    "title": "Present talk at SPADC",
    "status": "Outstanding"
  }
]
```

---

# POST /todos

```swift
// main.swift

post("todos") { req in
  var request = req
  let body = request.body!.collect()
  let parsed = try! JSONParser.parse(body).dictionaryValue!
  let title = parsed["title"]!.stringValue!
  let status = parsed["status"]!.stringValue!
  
  let todo = Todo(title: title, status: Status(rawValue: status))
  todos.append(todo)

  return todo.get(request)
}
```

---

# POST /todos

```json
{
  "identifier": "9B534BBF-C5E0-48F9-9D26-2F2A874BCC16"
  "title": "Hello SPADC!",
  "status": "Outstanding"
}
```

---

# GET /todos/{identifier}

```swift
// main.swift

func todoWithIdentifier(identifier: String) -> Todo? {
  return todos.filter { $0.identifier == identifier } .first
}

get("todos", *) { (request, identifier: String) in 
  guard let todo = todoWithIdentifier(identifier) else {
    return Response(.NotFound, contentType: "application/json", headers: [], content: "{}")
  }

  return todo.get(request)
}

```

---

# GET /todos/1234

```json
{
  "identifier": "1234",
  "title": "Write talk for SPADC",
  "status": "Completed"
}
```

---

# POST /todos/{identifier}/toggle

```swift
// main.swift

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

---

# POST /todos/967B102B-EAEB-462F-907E-F193CE2DB463/toggle

```json
{
  "identifier": "967B102B-EAEB-462F-907E-F193CE2DB463",
  "title": "Give talk at SPADC",
  "status": "Completed"
}
```

---

# Here is where we pretend that everything worked.

![](https://media.giphy.com/media/BQAk13taTaKYw/giphy.gif)

---

# Questions?

```
- https://github.com/endocrimes/swift-rest-demo
- https://twitter.com/endocrimes
- mailto:dani@builds.terrible.systems
```

