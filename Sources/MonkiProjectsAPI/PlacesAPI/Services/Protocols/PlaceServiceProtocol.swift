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
	) async throws -> Page<PlaceModel>
	
	func createPlace(
		_ create: Place.Create,
		creatorId: UserModel.IDValue
	) async throws -> PlaceModel
	
	func deletePlace(
		_ placeId: PlaceModel.IDValue,
		requesterId: UserModel.IDValue
	) async throws
	
	func triggerSatelliteViewLoading(for place: PlaceModel) async throws
	
	func triggerLocationReverseGeocoding(for place: PlaceModel) async throws
	
}
