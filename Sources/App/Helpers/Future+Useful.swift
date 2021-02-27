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
			.mapEachCompact {
				try? $0.asPublic(on: database)
					.map(Optional.init)
					.recover { _ in nil }
			}
			.flatMapEachCompact(on: database.eventLoop) { $0 }
	}
	
}
