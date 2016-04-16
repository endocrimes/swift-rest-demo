import PackageDescription

let package = Package(
 name: "demo",
 dependencies: [
 	.Package(url: "https://github.com/nestproject/Frank.git", majorVersion: 0, minor: 3),
	.Package(url: "https://github.com/endocrimes/Resource.git", majorVersion: 0, minor: 3)
 ])
