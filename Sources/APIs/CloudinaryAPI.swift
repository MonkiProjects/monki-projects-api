//
//  CloudinaryAPI.swift
//  APIs
//
//  Created by Rémi Bardon on 24/06/2020.
//  Copyright © 2020 Monki Projects. All rights reserved.
//

import Vapor

public let cloudinaryApi = CloudinaryAPIRoot()

public struct CloudinaryAPIRoot: EndpointRoot {
	
	let scheme = "https"
	let host = "api.cloudinary.com"
	
	private let cloudName = Environment.get("CLOUDINARY_CLOUD_NAME") ?? "nil"
	
	public func uploadSateliteImage(from url: URL) -> Endpoint {
		/// [Generating authentication signatures](https://cloudinary.com/documentation/upload_images#generating_authentication_signatures)
		
		// Required parameters for authenticated requests
		let requiredParameters: [URLQueryItem] = [
			/// The file to upload. In this case, the `HTTPS` `URL` of an existing file.
			.init(name: "file", value: url.absoluteString),
			/// `API` key
			.init(name: "api_key", value: Environment.get("CLOUDINARY_API_KEY") ?? "<api_key>"),
			// Unix time now
			.init(name: "timestamp", value: "\(Int(Date().timeIntervalSince1970))"),
			// The signature needs to be calculated and added later.
		]
		let optionalParameters: [URLQueryItem] = [
			// The name of an upload preset.
			.init(name: "upload_preset", value: "satellite_image"),
		]
		
		var queryItems: [URLQueryItem] = requiredParameters + optionalParameters
		
		/// 1. Create a string with the parameters used in the POST request to Cloudinary:
		///   - All parameters added to the method call should be included **except**: `file`, `cloud_name`, `resource_type` and your `api_key`.
		let excluded = ["file", "cloud_name", "resource_type", "api_key"]
		var hashQueryItems = queryItems
		hashQueryItems.removeAll(where: { excluded.contains($0.name) })
		///   - Sort all the parameters in alphabetical order.
		hashQueryItems.sort(by: { $0.name < $1.name })
		///   - Separate the _parameter_ names from their values with an `=` and join the parameter/value pairs together with an `&`.
		var hashText = hashQueryItems.map({ "\($0.name)=\($0.value ?? "")" }).joined(separator: "&")
		
		/// 2. Append your `API` secret to the end of the string.
		hashText.append(Environment.get("CLOUDINARY_API_SECRET") ?? "<api_secret>")
		
		/// 3. Create a hexadecimal message digest (hash value) of the string using a `SHA` cryptographic function.
		queryItems.append(.init(name: "signature", value: SHA256.hash(data: Data(hashText.utf8)).hex))
		
		return Endpoint(
			root: self,
			path: "/v1_1/\(cloudName)\(Cloudinary.path(for: .image, type: .upload))",
			queryItems: queryItems
		)
	}
	
	public var uploadAvatar: Endpoint {
		return Endpoint(
			root: self,
			path: "/v1_1/\(cloudName)\(Cloudinary.path(for: .image, type: .upload))/avatars",
			queryItems: [
				.init(name: "upload_preset", value: Cloudinary.Preset.avatar.rawValue),
			]
		)
	}
	
}
