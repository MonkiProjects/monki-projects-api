//
//  URLQueryCoders+KeyMapping.swift
//  MonkiProjectsAPI
//
//  Created by Rémi Bardon on 21/05/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor

public struct URLEncodedMappedFormDecoder: ContentDecoder, URLQueryDecoder {
	
	let jsonEncoder: JSONEncoder
	let jsonDecoder: JSONDecoder
	
	public init(jsonEncoder: JSONEncoder, jsonDecoder: JSONDecoder) {
		self.jsonEncoder = jsonEncoder
		self.jsonDecoder = jsonDecoder
	}
	
	/// `ContentDecoder` conformance.
	public func decode<D>(_ decodable: D.Type, from body: ByteBuffer, headers: HTTPHeaders) throws -> D
		where D: Decodable {
		let dict = try URLEncodedFormDecoder().decode([String: String].self, from: body, headers: headers)
		return try self.jsonDecoder.decode(decodable, from: self.jsonEncoder.encode(dict))
	}
	
	/// `URLQueryDecoder` conformance.
	public func decode<D>(_ decodable: D.Type, from url: URI) throws -> D where D: Decodable {
		let dict = try URLEncodedFormDecoder().decode([String: String].self, from: url.query ?? "")
		return try self.jsonDecoder.decode(decodable, from: self.jsonEncoder.encode(dict))
	}
	
}
