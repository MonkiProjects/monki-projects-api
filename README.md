# Monki Prrojects API

![Swift](https://github.com/MonkiProjects/monki-projects-api/workflows/Swift/badge.svg)

## How To Contribute

1. **Clone the repository**

   ```sh
   git clone https://github.com/MonkiProjects/monki-projects-api.git
   ```

2. **Integrate [SwiftLint](https://github.com/realm/SwiftLint) into your Xcode project to get warnings and errors displayed in the issue navigator**

   ```sh
   swift package generate-xcodeproj
   open monki-projects-api.xcodeproj
   ```

   Follow [SwiftLint's instructions](https://github.com/realm/SwiftLint#xcode) to add a new build phase

3. **Run the project**

   Two possibilities:
   - Open [Package.swift](./Package.swift)
   - Open your `monki-projects-api.xcodeproj`, go to `Product > Scheme` and select the `Run` scheme

   From there, you will be able to run the project.
