//
//  PrefixedUUID+RandomGeneratable.swift
//  MonkiProjectsAPI
//
//  Created by Rémi Bardon on 03/07/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent
import PrefixedUUID

extension PrefixedUUID: RandomGeneratable {
	
	public static func generateRandom() -> PrefixedUUID<Prefix> { Self() }
	
}
