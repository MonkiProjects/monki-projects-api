//
//  User+Public.swift
//  App
//
//  Created by Rémi Bardon on on 08/06/2020.
//  Copyright © 2020 Monki Projects. All rights reserved.
//

import Vapor

extension User {
	
	struct Public: Content {
		
		let id: UUID
		let username: String
		
	}
	
	func asPublic() throws -> Public {
		return try Public(
			id: self.requireID(),
			username: self.username
		)
	}
	
}
