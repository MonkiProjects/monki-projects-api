//
//  Endpoint.swift
//  App
//
//  Created by Rémi Bardon on 24/06/2020.
//  Copyright © 2020 Monki Projects. All rights reserved.
//

import Vapor

protocol EndpointRoot {
	var scheme: String { get }
	var host: String { get }
}

extension EndpointRoot {
	var root: Endpoint {
		return Endpoint(root: self, path: "")
	}
}

/// Inspired by [Constructing URLs in Swift](https://www.swiftbysundell.com/articles/constructing-urls-in-swift/#endpoints)
struct Endpoint {
	
	private let root: EndpointRoot
	private let path: String
	private let queryItems: [URLQueryItem]
	
	init(root: EndpointRoot, path: String, queryItems: [URLQueryItem] = []) {
		self.root = root
		self.path = path
		self.queryItems = queryItems
	}
	
	var components: URLComponents {
		var components = URLComponents()
		components.scheme = root.scheme
		components.host = root.host
		components.path = path
		if !queryItems.isEmpty {
			components.queryItems = queryItems
		}
		return components
	}
	
	// We still have to keep 'url' as an optional, since we're
	// dealing with dynamic components that could be invalid.
	var url: URL? { components.url }
	var uri: URI? { components.string.map(URI.init(string:)) }
	
	func requireURL() throws -> URL {
		guard let url = url else {
			// Do not show components in abort reason
			// since it could contain secret credentials
			throw Abort(.internalServerError, reason: "Invalid URL")
		}
		return url
	}
	
	func requireURI() throws -> URI {
		guard let uri = uri else {
			// Do not show components in abort reason
			// since it could contain secret credentials
			throw Abort(.internalServerError, reason: "Invalid URI")
		}
		return uri
	}
	
}
