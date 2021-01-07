//
//  User+Create.swift
//  App
//
//  Created by Rémi Bardon on 07/01/2021.
//  Copyright © 2020 Monki Projects. All rights reserved.
//

import Vapor

extension User {
	
	struct Create: Content {
		let username: String
		let email: String
		let password: String
		let confirmPassword: String
	}
	
}

extension User.Create: Validatable {
	
	static func validations(_ validations: inout Validations) {
		validations.add("username", as: String.self, is: .count(3...32))
		let allowedChars = CharacterSet.lowercaseLetters	// [a-z]
			.union(.decimalDigits)							// [0-9]
			.union(.init(charactersIn: "._"))				// [._]
		validations.add("username", as: String.self, is: .characterSet(allowedChars))
		validations.add("email", as: String.self, is: .email)
		validations.add("password", as: String.self, is: .count(8...))
	}
	
}
