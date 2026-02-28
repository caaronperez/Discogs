//
//  Package.swift
//  Discogs
//
//  Created by Cristian Perez on 2/27/26.
//

#if canImport(PackageDescription)
import PackageDescription

let package = Package(
    name: "Discogs",
    platforms: [ .iOS(.v18) ],
    products: [ .library(name: "Discogs", targets: ["Discogs"]) ],
    targets: [
        .target(
            name: "Discogs",
            exclude: [
                "README.md",
                ".swiftlint.yml",
                "Scripts/run-swiftlint.sh",
                "Networking/README-Networking.md",
                "Utilities/README-Utilities.md",
                "ViewModels/README-ViewModels.md",
                "Views/README-Views.md"
            ]
        ),
        .testTarget(
            name: "DiscogsTests",
            dependencies: ["Discogs"],
            exclude: ["README-Tests.md"]
        )
    ]
)
#endif
