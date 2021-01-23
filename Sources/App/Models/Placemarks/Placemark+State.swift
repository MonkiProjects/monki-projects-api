//
//  Placemark+State.swift
//  App
//
//  Created by Rémi Bardon on 09/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor

extension Placemark {
	
	enum State: String, Content {
		case `private`, submitted, published, rejected
	}
	
}
