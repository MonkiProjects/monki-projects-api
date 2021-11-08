//
//  PrefixedUUID+RandomGeneratable.swift
//  MonkiProjectsAPI
//
//  Created by Rémi Bardon on 03/07/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Foundation
import Fluent
import Prefixed

extension Prefixed: RandomGeneratable where Base == UUID {
	
	public static func generateRandom() -> Prefixed<Prefix, UUID> { PrefixedUUID() }
	
}
