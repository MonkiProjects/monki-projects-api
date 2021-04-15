// swift-tools-version:5.3
import PackageDescription

let package = Package(
	name: "monki-projects-api",
	defaultLocalization: "en",
	platforms: [
		.macOS(.v10_15),
	],
	dependencies: [
		// 💧 A server-side Swift web framework.
		.package(url: "https://github.com/vapor/vapor.git", from: "4.0.0"),
		.package(url: "https://github.com/vapor/fluent.git", from: "4.0.0"),
		.package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.0.0"),
		.package(url: "https://github.com/vapor/fluent-sqlite-driver.git", from: "4.0.0"),
		.package(url: "https://github.com/vapor/queues-redis-driver.git", from: "1.0.0"),
		.package(
			name: "monki-map-model",
			url: "https://github.com/MonkiProjects/monki-map-model-swift.git",
			.branch("main")
		),
		.package(url: "https://github.com/GEOSwift/GEOSwift.git", from: "8.0.0")
	],
	targets: [
		.target(
			name: "App",
			dependencies: [
				.product(name: "Vapor", package: "vapor"),
				.product(name: "Fluent", package: "fluent"),
				.product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
				.product(name: "QueuesRedisDriver", package: "queues-redis-driver"),
				.product(name: "MonkiMapModel", package: "monki-map-model"),
				.target(name: "Migrations"),
				.target(name: "DTOs"),
				.target(name: "Jobs"),
				.product(name: "GEOSwift", package: "GEOSwift"),
			],
			swiftSettings: [
				// Enable better optimizations when building in Release configuration. Despite the use of
				// the `.unsafeFlags` construct required by SwiftPM, this flag is recommended for Release
				// builds. See <https://github.com/swift-server/guides#building-for-production> for details.
				.unsafeFlags(["-cross-module-optimization"], .when(configuration: .release)),
			]
		),
		.target(name: "Run", dependencies: [.target(name: "App")]),
		.testTarget(
			name: "AppTests",
			dependencies: [
				.target(name: "App"),
				.product(name: "XCTVapor", package: "vapor"),
				.product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver"),
			]
		),
		.target(
			name: "Helpers",
			dependencies: [
				.product(name: "Vapor", package: "vapor"),
				.product(name: "Fluent", package: "fluent"),
				.product(name: "MonkiMapModel", package: "monki-map-model"),
			]
		),
		.target(
			name: "APIs",
			dependencies: [
				.product(name: "Vapor", package: "vapor"),
			]
		),
		.target(
			name: "Models",
			dependencies: [
				.product(name: "Vapor", package: "vapor"),
				.product(name: "Fluent", package: "fluent"),
				.product(name: "MonkiMapModel", package: "monki-map-model"),
				.target(name: "APIs"),
				.target(name: "Helpers"),
			]
		),
		.target(
			name: "Migrations",
			dependencies: [
				.product(name: "Vapor", package: "vapor"),
				.product(name: "Fluent", package: "fluent"),
				.product(name: "MonkiMapModel", package: "monki-map-model"),
				.target(name: "Models"),
			]
		),
		.target(
			name: "DTOs",
			dependencies: [
				.product(name: "Vapor", package: "vapor"),
				.product(name: "Fluent", package: "fluent"),
				.product(name: "MonkiMapModel", package: "monki-map-model"),
				.target(name: "Models"),
				.product(name: "GEOSwift", package: "GEOSwift"),
			]
		),
		.target(
			name: "Jobs",
			dependencies: [
				.product(name: "Fluent", package: "fluent"),
				.product(name: "Vapor", package: "vapor"),
				.product(name: "MonkiMapModel", package: "monki-map-model"),
				.target(name: "APIs"),
				.target(name: "Models"),
			]
		),
	]
)
