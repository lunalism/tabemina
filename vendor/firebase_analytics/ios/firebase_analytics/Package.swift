// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

// Copyright 2024, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import PackageDescription

let firebaseSdkVersion: Version = "12.14.0"

// TEMPORARY (vendored override): always IDFA-free now, no env-var needed.
// firebase_analytics 12.4.2 still requests the removed `FirebaseAnalyticsWithoutAdIdSupport`
// product; firebase-ios-sdk 12.x replaced it with `FirebaseAnalyticsCore` (the IDFA-free
// variant), which we link unconditionally so no build can ever pull the IDFA-bearing product.
// Remove this vendored override once the plugin adopts FirebaseAnalyticsCore upstream.
let analyticsProduct = "FirebaseAnalyticsCore"

let package = Package(
  name: "firebase_analytics",
  platforms: [
    .iOS("15.0")
  ],
  products: [
    .library(name: "firebase-analytics", targets: ["firebase_analytics"])
  ],
  dependencies: [
    .package(url: "https://github.com/firebase/firebase-ios-sdk", exact: firebaseSdkVersion),
    .package(name: "firebase_core", path: "../firebase_core"),
  ],
  targets: [
    .target(
      name: "firebase_analytics",
      dependencies: [
        .product(name: analyticsProduct, package: "firebase-ios-sdk"),
        .product(name: "firebase-core", package: "firebase_core"),
      ],
      resources: [
        .process("Resources")
      ]
    )
  ]
)
