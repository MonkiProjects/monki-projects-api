//
//  Jobs+All.swift
//  MonkiProjectsAPI
//
//  Created by Rémi Bardon on 21/02/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor
import Queues

public enum Jobs {
	
	public static func addAll(to app: Application) {
		app.queues.add(PlaceSatelliteViewJob())
		app.queues.add(PlaceLocationJob())
	}
	
}
