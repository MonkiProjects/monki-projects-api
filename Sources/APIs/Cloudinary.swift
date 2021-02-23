//
//  Cloudinary.swift
//  APIs
//
//  Created by Rémi Bardon on 24/06/2020.
//  Copyright © 2020 Monki Projects. All rights reserved.
//

import Vapor

public let cloudinary = CloudinaryRoot()

enum Cloudinary {
	
	static func path(for resourceType: ResourceType, type: DeliveryType) -> String {
		return "/\(resourceType.rawValue)/\(type.rawValue)"
	}
	
	enum ResourceType: String {
		case image, video, raw, auto
	}
	
	enum DeliveryType: String {
		case all, upload, `private`, authenticated,
			 facebook, twitter, gravatar, youtube, hulu, vimeo,
			 animoto, worldstarhiphop, dailymotion
	}
	
	enum Preset: String {
		case placemarkImage = "placemark_image"
		case avatar
	}
	
}

public struct CloudinaryRoot: EndpointRoot {
	
	let scheme = "https"
	let host = "res.cloudinary.com"
	
	private let cloudName = Environment.get("CLOUDINARY_CLOUD_NAME") ?? "nil"
	
	public func image(withId id: String) -> Endpoint {
		return Endpoint(
			root: self,
			path: "/\(cloudName)\(Cloudinary.path(for: .image, type: .upload))/f_auto/\(id)"
		)
	}
	
}
