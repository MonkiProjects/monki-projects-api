//
//  PlacemarkSubmission+State.swift
//  App
//
//  Created by Rémi Bardon on 10/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor

extension Placemark.Submission {
	
	enum State: String, Content {
		case submitted, accepted, rejected, moderated
	}
	
}
