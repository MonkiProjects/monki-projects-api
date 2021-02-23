//
//  Placemark.swift
//  Models
//
//  Created by Rémi Bardon on 09/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent
import Vapor
import MonkiMapModel

public final class PlacemarkModel: Model {
	
	public typealias State = Placemark.State
	
	public static let schema = "placemarks"
	
	@ID(key: .id)
	public var id: UUID?
	
	@Field(key: "name")
	public var name: String
	
	@Field(key: "latitude")
	public var latitude: Double
	
	@Field(key: "longitude")
	public var longitude: Double
	
	@Parent(key: "kind_id")
	public var kind: Kind
	
	@Field(key: "state")
	public var state: State
	
	@Parent(key: "creator_id")
	public var creator: UserModel
	
	@Timestamp(key: "created_at", on: .create)
	public var createdAt: Date?
	
	@Timestamp(key: "updated_at", on: .update)
	public var updatedAt: Date?
	
	@Timestamp(key: "deleted_at", on: .delete)
	public var deletedAt: Date?
	
	public init() {}
	
	public init(
		id: IDValue? = nil,
		name: String,
		latitude: Double,
		longitude: Double,
		kindId: Kind.IDValue,
		state: State = .private,
		creatorId: UserModel.IDValue
	) {
		self.id = id
		self.name = name
		self.latitude = latitude
		self.longitude = longitude
		self.$kind.id = kindId
		self.state = state
		self.$creator.id = creatorId
	}
	
}
