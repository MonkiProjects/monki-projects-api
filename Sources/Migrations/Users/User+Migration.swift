//
//  User+Migration.swift
//  Migrations
//
//  Created by Rémi Bardon on 07/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent
import Models

extension UserModel {
	
	public enum Migrations {
		
		public static var all: [Migration] {
			return [CreateUser()]
				+ Token.Migrations.all
		}
		
	}
	
}
