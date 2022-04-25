//
//  UtilityService.swift
//  UtilityAPI
//
//  Created by Rémi Bardon on 13/01/2022.
//  Copyright © 2022 Monki Projects. All rights reserved.
//

import Vapor
import Fluent
import MonkiMapModel
import Regex

internal struct UtilityService: Service, UtilityServiceProtocol {
	
	let db: Database
	let app: Application
	let eventLoop: EventLoop
	let logger: Logger
	
	func getCoordinatesFromGoogleMapsUrl(_ url: URL) async throws -> Coordinate? {
		if url.absoluteString.hasPrefix("https://www.google.com/maps/search/") {
			return try getCoordinatesFromGoogleMapsUrlType1(url)
		} else {
			return try await getCoordinatesFromGoogleMapsUrlType2(url)
		}
	}
	
	/// <https://www.google.com/maps/search/47.1840384,-1.5613742>
	private func getCoordinatesFromGoogleMapsUrlType1(_ url: URL) throws -> Coordinate? {
		let regex: Regex
		do {
			regex = try coordinatesRegex()
		} catch {
			logger.error("Could not create `Regex`: \(error)")
			throw Abort(.internalServerError, reason: "Could not get coordinates from this URL.")
		}
		
		guard let coordinates = try findCoordinates(in: url.absoluteString, with: regex) else {
			logger.warning("Did not find any coordinate in URL <\(url.absoluteString)>.")
			return nil
		}
		
		return coordinates
	}
	
	/// <https://www.google.com/maps/place/Breil-Barberie/data=!4m2!3m1!1s0x4805ec4690f2f2a7:0xfe8783a220ee8e15>
	private func getCoordinatesFromGoogleMapsUrlType2(_ url: URL) async throws -> Coordinate? {
		let res: ClientResponse
		do {
			res = try await app.client.get(URI(string: url.absoluteString))
		} catch {
			logger.error("Could not load HTML page: \(error)")
			throw Abort(.internalServerError, reason: "Could not load the web page.")
		}
		
		if res.status == .notFound {
			logger.debug("URL <\(url.absoluteString)> did not resolve to a web page.")
			return nil
		} else if res.status == .tooManyRequests {
			let retryAfter = res.headers[.retryAfter].first
			// swiftlint:disable:next line_length
			let message = "Too many requests sent to <google.com/maps>. \(retryAfter.map({ "Asking to retry after \($0)s." }) ?? "No \"Retry-After\" header set.")"
			
			logger.debug(message, metadata: ["url": .stringConvertible(url)])
			
			throw Abort(.tooManyRequests, headers: HTTPHeaders([
				// Retry after 60 seconds by default (no idea if it's enough)
				.retryAfter: retryAfter ?? "60",
			]), reason: message)
		} else if !(200..<300).contains(res.status.code) {
			logger.debug("URL <\(url.absoluteString)> returned status code \(res.status.code).")
			return nil
		}
		
		let html: String
		do {
			html = try res.content.decode(String.self, using: PlaintextDecoder())
		} catch {
			logger.error("Could not decode HTML body: \(error)")
			throw Abort(.internalServerError, reason: "Could not read the web page.")
		}
		
		let regex: Regex
		do {
			regex = try Regex(pattern: "@\(coordinatesRegex().pattern)")
		} catch {
			logger.error("Could not create `Regex`: \(error)")
			throw Abort(.internalServerError, reason: "Could not search for coordinates in the web page.")
		}
		
		return try findCoordinates(in: html, with: regex)
	}
	
	internal func coordinatesRegex() throws -> Regex {
		try Regex(pattern: "(-?\\d+\\.\\d{4,}),(-?\\d+\\.\\d{4,})")
	}
	
	private func findCoordinates(in string: String, with regex: Regex) throws -> Coordinate? {
		guard let match = regex.findFirst(in: string) else {
			logger.warning("Could not find any coordinate.")
			return nil
		}
		
		let coordinateString: (String, String)
		switch (match.group(at: 1), match.group(at: 2)) {
		case let (.some(latitude), .some(longitude)):
			coordinateString = (latitude, longitude)
		default:
			logger.warning("Regex did not store matched groups.")
			return nil
		}
		
		switch (Double(coordinateString.0), Double(coordinateString.1)) {
		case let (.some(latitudeDegrees), .some(longitudeDegrees)):
			return Coordinate(latitude: latitudeDegrees, longitude: longitudeDegrees)
		default:
			logger.warning("Coordinates `\(coordinateString)` could not be decoded to `Double`.")
			return nil
		}
	}
	
}
