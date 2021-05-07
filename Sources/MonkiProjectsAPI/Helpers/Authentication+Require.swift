//
//  Authentication+Require.swift
//  MonkiProjectsAPI
//
//  Created by Rémi Bardon on 06/03/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor

extension Request.Authentication {
	
	enum AuthenticationType {
		case basic, bearer
	}
	
	/// Returns an instance of the supplied type. Throws if no
	/// instance of that type has been authenticated or if there
	/// was a problem.
	@discardableResult
	func require<A>(
		_ type: A.Type = A.self,
		with authType: AuthenticationType,
		in request: Request
	) throws -> A where A: Authenticatable {
		guard let object = self.get(A.self) else {
			switch authType {
			case .basic:
				if let basic = request.headers.basicAuthorization {
					throw Abort(.unauthorized, reason: "Invalid credentials for '\(basic.username)'.")
				} else {
					throw Abort(.unauthorized, reason: "Basic authorization required.")
				}
			case .bearer:
				throw Abort(.unauthorized, reason: "Invalid authorization token.")
			}
		}
		return object
	}
	
}
