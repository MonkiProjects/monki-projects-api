//
//  Future+Useful.swift
//  App
//
//  Created by Rémi Bardon on 27/02/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent
import Models
import MonkiMapModel

extension EventLoopFuture where Value == [PlacemarkModel] {
	
	func asPublic(on database: Database) -> EventLoopFuture<[Placemark.Public]> {
		self
			.mapEach {
				$0.asPublic(on: database)
					// Map `Placemark.Public` to `Placemark.Public?` to allow `nil` recover
					.map(Optional.init)
					// Recover errors by mapping to `nil`
					.recover { _ in nil }
			}
			// Skip `nil` values
			.flatMapEachCompact(on: database.eventLoop) { $0 }
	}
	
}
