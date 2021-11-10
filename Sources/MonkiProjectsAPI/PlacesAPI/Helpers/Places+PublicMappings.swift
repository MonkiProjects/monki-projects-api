//
//  Places+PublicMappings.swift
//  PlacesAPI
//
//  Created by Rémi Bardon on 27/02/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor
import Fluent
import MonkiMapModel

extension Array where Element == PlaceModel {
	
	func asPublic(on req: Request) async -> [Place.Public] {
		typealias Result = Place.Public
		return await withTaskGroup(of: Result?.self, returning: [Result].self) { group in
			for place in self {
				group.addTask {
					return try? await place.asPublic(on: req)
				}
			}
			
			return await group.compactMap({ $0 }).reduce(into: [Result]()) { $0.append($1) }
		}
	}
	
}

extension Array where Element == PlaceModel.Property {
	
	func localized(in locale: Locale? = nil) async -> [Place.Property.Localized] {
		typealias Result = Place.Property.Localized
		return await withTaskGroup(of: Result?.self, returning: [Result].self) { group in
			for place in self {
				group.addTask {
					return try? place.localized(in: .en)
				}
			}
			
			return await group.compactMap({ $0 }).reduce(into: [Result]()) { $0.append($1) }
		}
	}
	
}

extension Page where T == PlaceModel {
	
	func asPublic(on req: Request) async throws -> Page<Place.Public> {
		try await self.map { try await $0.asPublic(on: req) }
	}
	
}

extension Array where Element == PlaceModel.Submission.Review {
	
	func asPublic(on req: Request) async -> [Place.Submission.Review.Public] {
		typealias Result = Place.Submission.Review.Public
		return await withTaskGroup(of: Result?.self, returning: [Result].self) { group in
			for place in self {
				group.addTask {
					return try? await place.asPublic(on: req)
				}
			}
			
			return await group.compactMap({ $0 }).reduce(into: [Result]()) { $0.append($1) }
		}
	}
	
}

extension Page where T == PlaceModel.Submission.Review {
	
	func asPublic(on req: Request) async throws -> Page<Place.Submission.Review.Public> {
		try await self.map { try await $0.asPublic(on: req) }
	}
	
}
