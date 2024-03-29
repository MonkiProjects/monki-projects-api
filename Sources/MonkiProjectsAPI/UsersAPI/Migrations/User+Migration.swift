//
//  User+Migration.swift
//  UsersAPI
//
//  Created by Rémi Bardon on 07/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent

extension UserModel {
	
	public enum Migrations {
		
		public static var all: [Migration] {
			[CreateUser()]
				+ Token.Migrations.all
		}
		
	}
	
}
