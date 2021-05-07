//
//  main.swift
//  Run
//
//  Created by Rémi Bardon on 07/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import MonkiProjectsAPI
import Vapor

internal var env = try Environment.detect()
try LoggingSystem.bootstrap(from: &env)
internal let app = Application(env)
defer { app.shutdown() }
try configure(app)
try app.run()
