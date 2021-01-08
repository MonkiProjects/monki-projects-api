//
//  User+Migration.swift
//  App
//
//  Created by Rémi Bardon on 07/01/2021.
//  Copyright © 2020 Monki Projects. All rights reserved.
//

import Fluent

extension User {
	
	enum Migrations {
		
		static var all: [Migration] {
			return [CreateUser()]
				+ Token.Migrations.all
		}
		
	}
	
}
