// swift-tools-version:5.5
import PackageDescription

let package = Package(
	name: "monki-projects-api",
	defaultLocalization: "en",
	platforms: [
		.macOS(.v12),
	],
	dependencies: [
		// 💧 A server-side Swift web framework.
		.package(url: "https://github.com/vapor/vapor.git", from: "4.0.0"),
		.package(url: "https://github.com/vapor/fluent.git", from: "4.0.0"),
		.package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.0.0"),
		.package(url: "https://github.com/vapor/fluent-sqlite-driver.git", from: "4.0.0"),
		.package(url: "https://github.com/vapor/queues-redis-driver.git", from: "1.0.0"),
		.package(
			name: "monki-projects-model",
			url: "https://github.com/MonkiProjects/monki-projects-model-swift.git",
			.upToNextMinor(from: "0.7.8")
		),
		.package(url: "https://github.com/crossroadlabs/Regex", .upToNextMajor(from: "1.2.0")),
	],
	targets: [
		.target(
			name: "MonkiProjectsAPI",
			dependencies: [
				.product(name: "Vapor", package: "vapor"),
				.product(name: "Fluent", package: "fluent"),
				.product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
				.product(name: "QueuesRedisDriver", package: "queues-redis-driver"),
				.product(name: "MonkiProjectsModel", package: "monki-projects-model"),
				.product(name: "MonkiMapModel", package: "monki-projects-model"),
				.product(name: "Regex", package: "Regex"),
			],
			swiftSettings: [
				// Enable better optimizations when building in Release configuration. Despite the use of
				// the `.unsafeFlags` construct required by SwiftPM, this flag is recommended for Release
				// builds. See <https://github.com/swift-server/guides#building-for-production> for details.
				.unsafeFlags(["-cross-module-optimization"], .when(configuration: .release)),
			]
		),
		.executableTarget(name: "Run", dependencies: ["MonkiProjectsAPI"]),
		.testTarget(
			name: "MonkiProjectsAPITests",
			dependencies: [
				.target(name: "MonkiProjectsAPI"),
				.product(name: "XCTVapor", package: "vapor"),
				.product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver"),
			]
		),
	]
)
