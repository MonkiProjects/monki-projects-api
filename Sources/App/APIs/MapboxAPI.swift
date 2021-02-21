//
//  MapboxAPI.swift
//  App
//
//  Created by Rémi Bardon on 24/06/2020.
//  Copyright © 2020 Monki Projects. All rights reserved.
//

import Vapor

let mapboxApi = MapboxAPIRoot()

struct MapboxAPIRoot: EndpointRoot {
	
	let scheme = "https"
	let host = "api.mapbox.com"
	
	let accessToken = Environment.get("MAPBOX_ACCESS_TOKEN") ?? "nil"
	
	/// `Endpoint` aiming at [Mapbox Static Images API](https://docs.mapbox.com/api/maps/static-images/)
	///
	/// - Parameters:
	///   - lat: Latitude (-90...90)
	///   - long: Longitude (-180...180)
	///   - zoom: Zoom (0...20)
	///   - bearing: Clockwise bearing (0...359)
	///   - width: Result image width (1...1280)
	///   - height: Result image height (1...1280)
	/// - Returns: An `Endpoint` used for networking
	/// - Warning: Input values are not checked at runtime,
	///            only server response will throw error.
	///
	/// # Notes #
	///   1. Default style is 'Satellite' (no streets)
	///   2. Image is redered at 2x (`@2x`)
	func satelliteImage(
		lat: Double, long: Double,
		zoom: Double = 19, bearing: UInt16 = 0,
		width: UInt16 = 1080, height: UInt16 = 1080
	) -> Endpoint {
		return Endpoint(
			root: self,
			path: "/styles/v1/mapbox/satellite-v9/static/\(long),\(lat),\(zoom),\(bearing)/\(width)x\(height)@2x",
			queryItems: [
				.init(name: "access_token", value: accessToken),
			]
		)
	}
	
	/// `Endpoint` aiming at [Mapbox Geocoding API](https://docs.mapbox.com/api/search/geocoding/)
	///
	/// - Parameters:
	///   - lat: Latitude (-90...90)
	///   - long: Longitude (-180...180)
	/// - Returns: An `Endpoint` used for networking
	/// - Warning: Input values are not checked at runtime,
	///            only server response will throw error.
	///
	/// # Notes #
	///   1. Image is redered at 2x (`@2x`)
	func reverseGeocodeLocation(
		lat: Double, long: Double
	) -> Endpoint {
		return Endpoint(
			root: self,
			path: "/geocoding/v5/mapbox.places/\(long),\(lat).json",
			queryItems: [
				.init(name: "access_token", value: accessToken),
				.init(name: "autocomplete", value: "false"),
				.init(name: "types", value: "place,country"),
				.init(name: "limit", value: "1"),
				.init(name: "language", value: "en"),
			]
		)
	}
	
}
