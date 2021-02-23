//
//  Locale+Ext.swift
//  Helpers
//
//  Created by Rémi Bardon on 29/09/2020.
//  Copyright © 2020 Monki Projects. All rights reserved.
//

import Foundation

public extension Locale {
	
	static var en: Locale { .init(identifier: "en") }
	static var fr: Locale { .init(identifier: "fr") }
	
	static var supported: [Locale] { [.en, .fr] }
	
}
