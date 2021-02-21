//
//  Jobs.swift
//  App
//
//  Created by Rémi Bardon on 21/02/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor
import Queues

enum Jobs {
	
	static func addAll(to app: Application) {
		app.queues.add(PlacemarkSatelliteViewJob())
		app.queues.add(PlacemarkLocationJob())
	}
	
}
