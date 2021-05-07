//
//  PlacemarkServiceProtocol.swift
//  PlacemarksAPI
//
//  Created by Rémi Bardon on 07/05/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent
import MonkiMapModel

public protocol PlacemarkServiceProtocol {
	
	func listPlacemarks(
		state: Placemark.State,
		pageRequest: PageRequest,
		userId: (() throws -> UserModel.IDValue)?
	) -> EventLoopFuture<Page<PlacemarkModel>>
	
	func createPlacemark(
		_ create: Placemark.Create,
		by userId: UserModel.IDValue
	) -> EventLoopFuture<PlacemarkModel>
	
	func deletePlacemark(
		_ placemarkId: PlacemarkModel.IDValue,
		userId: UserModel.IDValue
	) -> EventLoopFuture<Void>
	
	func triggerSatelliteViewLoading(for placemark: PlacemarkModel) -> EventLoopFuture<Void>
	
	func triggerLocationReverseGeocoding(for placemark: PlacemarkModel) -> EventLoopFuture<Void>
	
}
