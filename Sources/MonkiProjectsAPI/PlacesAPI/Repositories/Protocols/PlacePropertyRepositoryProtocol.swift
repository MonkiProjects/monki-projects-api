//
//  PlacePropertyRepositoryProtocol.swift
//  PlacesAPI
//
//  Created by Rémi Bardon on 17/04/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor
import MonkiMapModel

public protocol PlacePropertyRepositoryProtocol {
	
	func unsafeGet(
		kind: Place.Property.Kind.ID,
		humanId: Place.Property.ID
	) async throws -> PlaceModel.Property?
	
	func get(
		kind: Place.Property.Kind.ID,
		humanId: Place.Property.ID
	) async throws -> PlaceModel.Property
	
	func getAll(kind: Place.Property.Kind.ID) async throws -> [PlaceModel.Property]
	
	func getAll(
		dict: [Place.Property.Kind.ID: [Place.Property.ID]]
	) async throws -> [PlaceModel.Property]
	
}
