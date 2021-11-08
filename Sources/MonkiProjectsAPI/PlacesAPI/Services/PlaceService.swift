//
//  PlaceService.swift
//  PlacesAPI
//
//  Created by Rémi Bardon on 17/04/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor
import Fluent
import MonkiMapModel

internal struct PlaceService: Service, PlaceServiceProtocol {
	
	let db: Database
	let app: Application
	let eventLoop: EventLoop
	let logger: Logger
	
	func listPlaces(
		state: Place.State,
		pageRequest: PageRequest,
		requesterId: (() throws -> UserModel.IDValue)? = nil
	) async throws -> Page<PlaceModel> {
		switch state {
		case .unknown:
			throw Abort(.badRequest, reason: "Fetching places in 'unknown' state is impossible.")
		case .draft, .local, .private:
			guard let userId = try requesterId?() else {
				throw Abort(
					.forbidden,
					reason: "You must be authenticated to list your draft, local or private places."
				)
			}
			return try await self.make(self.app.placeRepository)
				.getAllPaged(state: state, creator: userId, pageRequest)
		case .submitted, .published, .rejected:
			return try await self.make(self.app.placeRepository)
				.getAllPaged(state: state, creator: nil, pageRequest)
		}
	}
	
	func createPlace(
		_ create: Place.Create,
		creatorId: UserModel.IDValue
	) async throws -> PlaceModel {
		// FIXME: Put this in a [transaction](https://docs.vapor.codes/4.0/fluent/transaction/)
		// TODO: Check for near spots (e.g. < 20m)
		
		// Find place kind in database
		let kind = try await self.make(self.app.placeKindRepository)
			.get(humanId: create.kind.rawValue)
		
		// Create & store place
		let place = try PlaceModel(
			name: create.name,
			latitude: create.latitude,
			longitude: create.longitude,
			kindId: kind.requireID(),
			state: .private,
			creatorId: creatorId
		)
		try await place.create(on: self.db)
		
		let details = try PlaceModel.Details(
			placeId: place.requireID(),
			caption: create.caption,
			images: create.images.map(\.absoluteString)
		)
		
		// Create & store place details
		try await details.create(on: self.db)
		try await self.make(self.app.placeDetailsService)
			.addProperties(create.properties, to: details)
		
		// Trigger jobs (will not wait for completion, just trigger them)
		try await self.triggerSatelliteViewLoading(for: place)
		try await self.triggerLocationReverseGeocoding(for: place)
		
		return place
	}
	
	func deletePlace(
		_ placeId: PlaceModel.IDValue,
		requesterId: UserModel.IDValue
	) async throws {
		// Perform validations
		let userCanDeletePlace = try await self.make(self.app.authorizationService)
			.user(requesterId, can: .delete, place: placeId)
		guard userCanDeletePlace else {
			throw Abort(.forbidden, reason: "You cannot delete someone else's place!")
		}
		
		// Delete details
		try await self.make(self.app.placeDetailsRepository)
			.delete(for: placeId, force: false)
		
		// Delete place
		try await self.make(self.app.placeRepository)
			.get(placeId)
			.delete(on: self.db)
	}
	
	func triggerSatelliteViewLoading(for place: PlaceModel) async throws {
		guard Environment.get("ENABLE_JOBS") == "true" else {
			logger.info("Skipping place satellite view loading")
			return
		}
		
		try await self.app.queues.queue(.places, logger: self.logger, on: self.eventLoop)
			.dispatch(
				PlaceSatelliteViewJob.self,
				.init(
					placeId: try place.requireID(),
					latitude: place.latitude,
					longitude: place.longitude
				)
			)
	}
	
	func triggerLocationReverseGeocoding(for place: PlaceModel) async throws {
		guard Environment.get("ENABLE_JOBS") == "true" else {
			logger.info("Skipping place location reverse geocoding")
			return
		}
		
		try await self.app.queues.queue(.places, logger: self.logger, on: self.eventLoop)
			.dispatch(
				PlaceLocationJob.self,
				.init(
					placeId: try place.requireID(),
					latitude: place.latitude,
					longitude: place.longitude
				)
			)
	}
	
}
