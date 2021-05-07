//
//  Optional+Usual.swift
//  MonkiProjectsAPI
//
//  Created by Rémi Bardon on 24/02/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Foundation

extension Optional {
	
	public var isNil: Bool { self == nil }
	public var hasValue: Bool { self != nil }
	
}
