//
//  ResponseError.swift
//  AppTests
//
//  Created by Rémi Bardon on 23/06/2020.
//  Copyright © 2020 Monki Projects. All rights reserved.
//

import Vapor

internal struct ResponseError: Content {
	
	let reason: String
	
}
