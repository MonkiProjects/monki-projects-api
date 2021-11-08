//
//  Page+AsyncMap.swift
//  MonkiProjectsAPI
//
//  Created by Rémi Bardon on 07/11/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent

extension Page {
	
	/// Maps a page's items to a different type using the supplied closure.
	public func map<U>(_ transform: @escaping (T) async throws -> U) async rethrows -> Page<U>
		where U: Codable {
		let items = try await withThrowingTaskGroup(of: U.self, returning: [U].self) { group in
			for item in self.items {
				group.async {
					return try await transform(item)
				}
			}
			
			return try await group.reduce(into: [U]()) { $0.append($1) }
		}
		
		return .init(items: items, metadata: self.metadata)
	}
	
}
