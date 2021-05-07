//
//  PlacemarkService.swift
//  App
//
//  Created by Rémi Bardon on 17/04/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor
import Fluent
import MonkiMapModel

internal struct PlacemarkService: PlacemarkServiceProtocol {
	
	let db: Database
	let app: Application
	let eventLoop: EventLoop
	let logger: Logger
	
	func listPlacemarks(
		state: Placemark.State,
		pageRequest: PageRequest,
		userId: (() throws -> UserModel.IDValue)? = nil
	) -> EventLoopFuture<Page<PlacemarkModel>> {
		do {
			switch state {
			case .unknown:
				throw Abort(.badRequest, reason: "Fetching placemarks in 'unknown' state is impossible.")
			case .draft, .local, .private:
				guard let userId = try userId?() else {
					throw Abort(
						.forbidden,
						reason: "You must be authenticated to list your draft, local or private placemarks."
					)
				}
				return self.app.placemarkRepository(for: self.db)
					.getAllPaged(state: state, creator: userId, pageRequest)
			case .submitted, .published, .rejected:
				return self.app.placemarkRepository(for: self.db)
					.getAllPaged(state: state, creator: nil, pageRequest)
			}
		} catch {
			return self.eventLoop.makeFailedFuture(error)
		}
	}
	
	func createPlacemark(
		_ create: Placemark.Create,
		by userId: UserModel.IDValue
	) -> EventLoopFuture<PlacemarkModel> {
		// TODO: Check for near spots (e.g. < 20m)
		
		// Find placemark kind in database
		let placemarkKindFuture = self.app.placemarkKindRepository(for: self.db).get(humanId: create.kind.rawValue)
		
		func placemarkModel(_ kind: PlacemarkModel.Kind) throws -> PlacemarkModel {
			try PlacemarkModel(
				name: create.name,
				latitude: create.latitude,
				longitude: create.longitude,
				kindId: kind.requireID(),
				state: .private,
				creatorId: userId
			)
		}
		
		// Create & store placemark
		let placemarkFuture = placemarkKindFuture
			.flatMapThrowing(placemarkModel)
			.passthroughAfter { $0.create(on: self.db) }
		
		func placemarkDetails(_ placemark: PlacemarkModel) throws -> PlacemarkModel.Details {
			try PlacemarkModel.Details(
				placemarkId: placemark.requireID(),
				caption: create.caption,
				images: create.images.map { $0.absoluteString }
			)
		}
		
		// Create & store placemark details
		let detailedPlacemarkFuture = placemarkFuture
			.passthroughAfter { placemark in
				self.eventLoop.makeSucceededFuture(placemark)
					.flatMapThrowing(placemarkDetails)
					.passthroughAfter { $0.create(on: self.db) }
					.flatMap { details in
						self.app.placemarkDetailsService(
							database: self.db,
							application: self.app,
							eventLoop: self.eventLoop,
							logger: self.logger
						)
						.addProperties(create.properties, to: details)
					}
			}
		
		// FIXME: Put this in a [transaction](https://docs.vapor.codes/4.0/fluent/transaction/)
		return detailedPlacemarkFuture
			// Trigger jobs (will not wait for completion, just trigger them)
			.passthroughAfter { placemark in
				EventLoopFuture.andAllSucceed([
					self.triggerSatelliteViewLoading(for: placemark),
					self.triggerLocationReverseGeocoding(for: placemark),
				], on: self.eventLoop)
			}
	}
	
	func deletePlacemark(
		_ placemarkId: PlacemarkModel.IDValue,
		userId: UserModel.IDValue
	) -> EventLoopFuture<Void> {
		let placemarkFuture = self.app.placemarkRepository(for: self.db).get(placemarkId)
		
		// Do additional validations
		let guardAuthorizedFuture = placemarkFuture.guard({ placemark in
			placemark.$creator.id == userId
		}, else: Abort(.forbidden, reason: "You cannot delete someone else's placemark!"))
		
		let deleteDetailsFuture = guardAuthorizedFuture
			.passthroughAfter { _ in
				self.app.placemarkDetailsRepository(for: self.db).delete(for: placemarkId, force: false)
			}
		
		return deleteDetailsFuture
			.flatMap { $0.delete(on: self.db) }
	}
	
	func triggerSatelliteViewLoading(for placemark: PlacemarkModel) -> EventLoopFuture<Void> {
		do {
			return self.app.queues.queue(.placemarks, logger: self.logger, on: self.eventLoop)
				.dispatch(
					PlacemarkSatelliteViewJob.self,
					.init(
						placemarkId: try placemark.requireID(),
						latitude: placemark.latitude,
						longitude: placemark.longitude
					)
				)
		} catch {
			return self.eventLoop.makeFailedFuture(error)
		}
	}
	
	func triggerLocationReverseGeocoding(for placemark: PlacemarkModel) -> EventLoopFuture<Void> {
		do {
			return self.app.queues.queue(.placemarks, logger: self.logger, on: self.eventLoop)
				.dispatch(
					PlacemarkLocationJob.self,
					.init(
						placemarkId: try placemark.requireID(),
						latitude: placemark.latitude,
						longitude: placemark.longitude
					)
				)
		} catch {
			return self.eventLoop.makeFailedFuture(error)
		}
	}
	
}
