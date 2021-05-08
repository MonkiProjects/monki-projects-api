# Monki Projects API

![Test workflow badge](https://github.com/MonkiProjects/monki-projects-api/workflows/Test/badge.svg)

## Overview

All of Monki Projects' [APIs](https://en.wikipedia.org/wiki/API) specifications (including this one's) are available in the [mp-api-specs](https://github.com/MonkiProjects/mp-api-specs) repository.

## Environment variables

| Environment variable    |
| ----------------------- |
| `DATABASE_PORT`         |
| `DATABASE_USERNAME`     |
| `DATABASE_PASSWORD`     |
| `DATABASE_NAME`         |
| `ENABLE_JOBS`           |
| `START_IN_PROCESS_JOBS` |
| `START_SCHEDULED_JOBS`  |

## How To Contribute

### Run the project

1. **Clone the repository**

   ```sh
   git clone https://github.com/MonkiProjects/monki-projects-api.git
   ```

2. **(Recommended) Integrate [SwiftLint](https://github.com/realm/SwiftLint) into your Xcode project to get warnings and errors displayed in the issue navigator**

   ```sh
   swift package generate-xcodeproj
   open monki-projects-api.xcodeproj
   ```

   Follow [SwiftLint's instructions](https://github.com/realm/SwiftLint#xcode) to add a new build phase

3. **Setup PostgreSQL (easy way for macOS)**

   > This is the easiest way for macOS, you can do it differently if you prefer.

   1. Download Postgres.app at [postgresapp.com](https://postgresapp.com) and install it.
   2. Open the sidebar (if it's not already open) by clicking on the button in the bottom-left corner.
   3. Create a new server called "Vapor" in the directory `~/Library/Application Support/Postgres/vapor` (you can put whatever you want at this step).
   4. Click <kbd>Initialize</kbd>
   5. Once your server is running, double-click on the `postgres` database to open it.
   6. Once in the [SQL](https://en.wikipedia.org/wiki/SQL) prompt, run

      ```sql
      CREATE DATABASE vapor_database;
      CREATE USER vapor_username WITH PASSWORD 'vapor_password';
      ```

   7. Close the shell (run `exit` to leave the SQL prompt if needed)
   8. You should see a new database called `vapor_database`

   The config you should have can be found in [configure.swift](./Sources/App/configure.swift), but here is a recap:

   | Environment variable | Value            |
   | -------------------: | :--------------- |
   | `DATABASE_PORT`      | `5432`           |
   | `DATABASE_USERNAME`  | `vapor_username` |
   | `DATABASE_PASSWORD`  | `vapor_password` |
   | `DATABASE_NAME`      | `vapor_database` |

   > If you change these settings, you will need to add environment variables to your scheme's `Run` and `Test` configurations.

4. **Run the project**

   Two possibilities:
   - Open [Package.swift](./Package.swift)
   - Open your `monki-projects-api.xcodeproj`, go to `Product > Scheme` and select the `Run` scheme

   From there, you will be able to run the project.

5. **Stop the app**

   In XCode, hit the <kbd>◾</kbd> button in the top-left corner or hit <kbd><kbd>⌘</kbd>+<kbd>.</kbd></kbd> to stop the app. If you're running the app in a terminal, hit <kbd><kbd>Ctrl</kbd>+<kbd>C</kbd></kbd>.

6. **Stop the PostgreSQL server**

   If you used Postgres.app, just open it and click <kbd>Stop</kbd>. Otherwise, manually stop it.

## Tips

### Fix port `8080` still open after stopping the app

For some reason, stopping the app causes an error preventing port `8080` to be closed, here is a command that kills it (tested on macOS):

```sh
lsof -t -i tcp:8080 | xargs kill
```
