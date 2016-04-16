import Inquiline
import JSON
import Resource
import Nest

func jsonResponse(dictionary: JSONEncodeable) -> Response {
	return Response(.Ok, contentType: "application/json", headers: [], content: dictionary.JSONValue.serialize(DefaultJSONSerializer()))
}

func jsonResponse(json: JSON) -> Response {
	return Response(.Ok, contentType: "application/json", headers: [], content: json.serialize(DefaultJSONSerializer()))
}

func collectionResponse<T: Resource>(resources: [T]) -> Response {
	return jsonResponse(["data" : resources.map { $0.dictionaryValue }])
}

extension PayloadType {
	/// Collects every single byte in the payload until returns nil
	mutating func collect() -> [UInt8] {
		var buffer: [UInt8] = []

		while true {
			if let bytes = next() {
				buffer += bytes
			} else {
				break
			}
		}

		return buffer
	}
}

