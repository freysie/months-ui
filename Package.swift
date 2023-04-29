// swift-tools-version: 5.5
import PackageDescription

let package = Package(
  name: "MonthsUI",
  platforms: [
    // v15 needed for `formatted` for title
    // TODO: try to get it down to v14
    .iOS(.v15)
  ],
  products: [
    .library(name: "MonthsUI", targets: ["MonthsUI"])
  ],
  targets: [
    .target(name: "MonthsUI", dependencies: [])
  ]
)
