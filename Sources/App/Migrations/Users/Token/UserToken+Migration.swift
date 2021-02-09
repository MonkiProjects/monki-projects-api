//
//  UserToken+Migration.swift
//  App
//
//  Created by Rémi Bardon on 08/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent

extension UserModel.Token {
	
	enum Migrations {
		
		static var all: [Migration] {
			return [CreateUserToken()]
		}
		
	}
	
}
