//
//  PlacemarkPropertyRepositoryProtocol.swift
//  PlacemarksAPI
//
//  Created by Rémi Bardon on 17/04/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor
import MonkiMapModel

public protocol PlacemarkPropertyRepositoryProtocol {
	
	func unsafeGet(
		kind: Placemark.Property.Kind.ID,
		humanId: Placemark.Property.ID
	) -> EventLoopFuture<PlacemarkModel.Property?>
	
	func get(
		kind: Placemark.Property.Kind.ID,
		humanId: Placemark.Property.ID
	) -> EventLoopFuture<PlacemarkModel.Property>
	
	func getAll(kind: Placemark.Property.Kind.ID) -> EventLoopFuture<[PlacemarkModel.Property]>
	
	func getAll(
		dict: [Placemark.Property.Kind.ID: [Placemark.Property.ID]]
	) -> EventLoopFuture<[PlacemarkModel.Property]>
	
}
