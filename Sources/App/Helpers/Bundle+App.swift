//
//  Bundle+App.swift
//  App
//
//  Created by Rémi Bardon on 13/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Foundation

extension Bundle {
	
	static var app: Bundle {
		#if os(Linux)
		Bundle(for: Self.self)
		#else
		Bundle.module
		#endif
	}
	
}
