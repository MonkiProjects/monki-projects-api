//
//  Endpoint.swift
//  APIs
//
//  Created by Rémi Bardon on 24/06/2020.
//  Copyright © 2020 Monki Projects. All rights reserved.
//

import Vapor

internal protocol EndpointRoot {
	var scheme: String { get }
	var host: String { get }
}

// swiftlint:disable:next file_types_order
extension EndpointRoot {
	var root: Endpoint {
		Endpoint(root: self, path: "")
	}
}

/// Inspired by [Constructing URLs in Swift](https://www.swiftbysundell.com/articles/constructing-urls-in-swift/#endpoints)
public struct Endpoint {
	
	private let root: EndpointRoot
	private let path: String
	private let queryItems: [URLQueryItem]
	
	public var components: URLComponents {
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
	public var url: URL? { components.url }
	public var uri: URI? { components.string.map(URI.init(string:)) }
	
	init(root: EndpointRoot, path: String, queryItems: [URLQueryItem] = []) {
		self.root = root
		self.path = path
		self.queryItems = queryItems
	}
	
	public func requireURL() throws -> URL {
		guard let url = url else {
			// Do not show components in abort reason
			// since it could contain secret credentials
			throw Abort(.internalServerError, reason: "Invalid URL")
		}
		return url
	}
	
	public func requireURI() throws -> URI {
		guard let uri = uri else {
			// Do not show components in abort reason
			// since it could contain secret credentials
			throw Abort(.internalServerError, reason: "Invalid URI")
		}
		return uri
	}
	
}
