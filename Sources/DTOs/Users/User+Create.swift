//
//  User+Create.swift
//  DTOs
//
//  Created by Rémi Bardon on 07/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor
import Models
import MonkiProjectsModel

extension User.Create: Content, Validatable {
	
	public static func validations(_ validations: inout Validations) {
		validations.add("email", as: String.self, is: .email)
		validations.add("username", as: String.self, is: .count(3...32))
		let allowedChars = CharacterSet.lowercaseLetters	// [a-z]
			.union(.decimalDigits)							// [0-9]
			.union(.init(charactersIn: "._"))				// [._]
		validations.add("username", as: String.self, is: .characterSet(allowedChars))
		validations.add("displayName", as: String.self, is: .count(3...32))
		validations.add("password", as: String.self, is: .count(8...))
	}
	
}
