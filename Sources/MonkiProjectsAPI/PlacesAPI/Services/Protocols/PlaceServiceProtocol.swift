//
//  PlaceServiceProtocol.swift
//  PlacesAPI
//
//  Created by Rémi Bardon on 07/05/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent
import MonkiMapModel

public protocol PlaceServiceProtocol {
	
	func listPlaces(
		state: Place.State,
		pageRequest: PageRequest,
		requesterId: (() throws -> UserModel.IDValue)?
	) -> EventLoopFuture<Page<PlaceModel>>
	
	func createPlace(
		_ create: Place.Create,
		creatorId: UserModel.IDValue
	) -> EventLoopFuture<PlaceModel>
	
	func deletePlace(
		_ placeId: PlaceModel.IDValue,
		requesterId: UserModel.IDValue
	) -> EventLoopFuture<Void>
	
	func triggerSatelliteViewLoading(for place: PlaceModel) -> EventLoopFuture<Void>
	
	func triggerLocationReverseGeocoding(for place: PlaceModel) -> EventLoopFuture<Void>
	
}
