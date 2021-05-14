//
//  UserUpdate+Validatable.swift
//  UsersAPI
//
//  Created by Rémi Bardon on 14/05/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor
import MonkiProjectsModel

extension User.Update: Content, Validatable {
	
	public static func validations(_ validations: inout Validations) {
		validations.add("username", as: String.self, is: .count(3...32))
		let allowedChars = CharacterSet.lowercaseLetters	// [a-z]
			.union(.decimalDigits)							// [0-9]
			.union(.init(charactersIn: "._-"))				// [._-]
		validations.add("username", as: String.self, is: .characterSet(allowedChars))
		validations.add("displayName", as: String.self, is: .count(3...32))
	}
	
}
