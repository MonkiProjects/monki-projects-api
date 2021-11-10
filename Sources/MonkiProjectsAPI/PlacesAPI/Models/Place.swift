//
//  Place.swift
//  PlacesAPI
//
//  Created by Rémi Bardon on 09/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent
import Vapor
import MonkiMapModel

public final class PlaceModel: Model {
	
	public typealias Visibility = Place.Visibility
	
	public static let schema = "places"
	
	@ID(custom: .id, generatedBy: .random)
	public var id: Place.ID?
	
	@Field(key: "name")
	public var name: String
	
	@Field(key: "latitude")
	public var latitude: Double
	
	@Field(key: "longitude")
	public var longitude: Double
	
	@Parent(key: "kind_id")
	public var kind: Kind
	
	@Field(key: "visibility")
	public var visibility: Visibility
	
	@Field(key: "is_draft")
	public var isDraft: Bool
	
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
		visibility: Visibility = .private,
		isDraft: Bool = true,
		creatorId: UserModel.IDValue
	) {
		self.id = id
		self.name = name
		self.latitude = latitude
		self.longitude = longitude
		self.$kind.id = kindId
		self.visibility = visibility
		self.isDraft = isDraft
		self.$creator.id = creatorId
	}
	
}
