//
//  Locale+Ext.swift
//  Helpers
//
//  Created by Rémi Bardon on 29/09/2020.
//  Copyright © 2020 Monki Projects. All rights reserved.
//

import Foundation

extension Locale {
	
	public static var en: Locale { .init(identifier: "en") }
	public static var fr: Locale { .init(identifier: "fr") }
	
	public static var supported: [Locale] { [.en, .fr] }
	
}
