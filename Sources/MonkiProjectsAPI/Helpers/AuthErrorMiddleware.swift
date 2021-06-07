//
//  AuthErrorMiddleware.swift
//  MonkiProjectsAPI
//
//  Created by Rémi Bardon on 07/06/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor

/// Comes from [WWW-Authenticate header](https://github.com/vapor/vapor/issues/2337#issuecomment-621010377)
public final class AuthErrorMiddleware: Middleware {
	
	public let type: String
	public let realm: String
	
	private var wwwAuthenticateValue: String {
		if realm.isEmpty {
			return "\(type)"
		}
		
		let escapedRealm = realm.unicodeScalars.reduce(into: "") { $0 += $1.escaped(asASCII: false) }
		return "\(type) realm=\"\(escapedRealm)\", charset=\"UTF-8\""
	}
	
	public init(type: String, realm: String = "") {
		self.type = type
		self.realm = realm
	}
	
	public func respond(to req: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
		next.respond(to: req)
			.map { res in
				if res.status == .unauthorized && !res.headers.contains(name: .wwwAuthenticate) {
					res.headers.replaceOrAdd(name: .wwwAuthenticate, value: self.wwwAuthenticateValue)
				}
				
				return res
			}
			.flatMapErrorThrowing { error in
				guard let abort = error as? AbortError, abort.status == .unauthorized else {
					throw error
				}
				
				req.logger.report(error: error)
				
				var headers: HTTPHeaders = abort.headers
				headers.replaceOrAdd(name: .wwwAuthenticate, value: self.wwwAuthenticateValue)
				
				throw Abort(abort.status, headers: headers, reason: abort.reason)
			}
	}
	
}
