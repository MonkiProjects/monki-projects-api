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
	) -> EventLoopFuture<Page<PlaceModel>> {
		do {
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
				return self.make(self.app.placeRepository)
					.getAllPaged(state: state, creator: userId, pageRequest)
			case .submitted, .published, .rejected:
				return self.make(self.app.placeRepository)
					.getAllPaged(state: state, creator: nil, pageRequest)
			}
		} catch {
			return self.eventLoop.makeFailedFuture(error)
		}
	}
	
	func createPlace(
		_ create: Place.Create,
		creatorId: UserModel.IDValue
	) -> EventLoopFuture<PlaceModel> {
		// TODO: Check for near spots (e.g. < 20m)
		
		// Find place kind in database
		let placeKindFuture = self.make(self.app.placeKindRepository).get(humanId: create.kind.rawValue)
		
		func placeModel(_ kind: PlaceModel.Kind) throws -> PlaceModel {
			try PlaceModel(
				name: create.name,
				latitude: create.latitude,
				longitude: create.longitude,
				kindId: kind.requireID(),
				state: .private,
				creatorId: creatorId
			)
		}
		
		// Create & store place
		let placeFuture = placeKindFuture
			.flatMapThrowing(placeModel)
			.passthroughAfter { $0.create(on: self.db) }
		
		func placeDetails(_ place: PlaceModel) throws -> PlaceModel.Details {
			try PlaceModel.Details(
				placeId: place.requireID(),
				caption: create.caption,
				images: create.images.map { $0.absoluteString }
			)
		}
		
		// Create & store place details
		let detailedPlaceFuture = placeFuture
			.passthroughAfter { place in
				self.eventLoop.makeSucceededFuture(place)
					.flatMapThrowing(placeDetails)
					.passthroughAfter { $0.create(on: self.db) }
					.flatMap { details in
						self.make(self.app.placeDetailsService)
							.addProperties(create.properties, to: details)
					}
			}
		
		// FIXME: Put this in a [transaction](https://docs.vapor.codes/4.0/fluent/transaction/)
		return detailedPlaceFuture
			// Trigger jobs (will not wait for completion, just trigger them)
			.passthroughAfter { place in
				EventLoopFuture.andAllSucceed([
					self.triggerSatelliteViewLoading(for: place),
					self.triggerLocationReverseGeocoding(for: place),
				], on: self.eventLoop)
			}
	}
	
	func deletePlace(
		_ placeId: PlaceModel.IDValue,
		requesterId: UserModel.IDValue
	) -> EventLoopFuture<Void> {
		let validationsFuture = EventLoopFuture.andAllSucceed([
			self.make(self.app.authorizationService)
				.user(requesterId, can: .delete, place: placeId)
				.guard(else: Abort(.forbidden, reason: "You cannot delete someone else's place!")),
		], on: self.eventLoop)
		
		func placeFuture() -> EventLoopFuture<PlaceModel> {
			self.make(self.app.placeRepository).get(placeId)
		}
		
		func deleteDetailsFuture() -> EventLoopFuture<Void> {
			self.make(self.app.placeDetailsRepository).delete(for: placeId, force: false)
		}
		
		return validationsFuture
			.flatMap(deleteDetailsFuture)
			.flatMap(placeFuture)
			.flatMap { $0.delete(on: self.db) }
	}
	
	func triggerSatelliteViewLoading(for place: PlaceModel) -> EventLoopFuture<Void> {
		guard Environment.get("ENABLE_JOBS") == "true" else {
			logger.info("Skipping place satellite view loading")
			return self.eventLoop.makeSucceededVoidFuture()
		}
		
		do {
			return self.app.queues.queue(.places, logger: self.logger, on: self.eventLoop)
				.dispatch(
					PlaceSatelliteViewJob.self,
					.init(
						placeId: try place.requireID(),
						latitude: place.latitude,
						longitude: place.longitude
					)
				)
		} catch {
			return self.eventLoop.makeFailedFuture(error)
		}
	}
	
	func triggerLocationReverseGeocoding(for place: PlaceModel) -> EventLoopFuture<Void> {
		guard Environment.get("ENABLE_JOBS") == "true" else {
			logger.info("Skipping place location reverse geocoding")
			return self.eventLoop.makeSucceededVoidFuture()
		}
		
		do {
			return self.app.queues.queue(.places, logger: self.logger, on: self.eventLoop)
				.dispatch(
					PlaceLocationJob.self,
					.init(
						placeId: try place.requireID(),
						latitude: place.latitude,
						longitude: place.longitude
					)
				)
		} catch {
			return self.eventLoop.makeFailedFuture(error)
		}
	}
	
}
