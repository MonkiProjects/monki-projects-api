# Monki Projects API

![Test workflow badge](https://github.com/MonkiProjects/monki-projects-api/workflows/Test/badge.svg)

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

## Tips

### Fix port `8080` still open after stopping the app

For some reason, stopping the app causes an error preventing port `8080` to be closed, here is a command that kills it (tested on macOS):

```sh
lsof -t -i tcp:8080 | xargs kill
```
