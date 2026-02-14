import ProjectDescription

let project = Project(
    name: "RecordingSDK",
    options: .options(
        automaticSchemesOptions: .disabled
    ),
    settings: .settings(
        base: [
            "DEVELOPMENT_TEAM": "E6GA9X89TN",
        ],
        configurations: [
            .debug(name: "Debug"),
            .release(name: "Release"),
        ]
    ),
    targets: [
        // MARK: - RecordingSDK Framework
        .target(
            name: "RecordingSDK",
            destinations: [.iPhone, .iPad],
            product: .framework,
            bundleId: "com.gabemontague.RecordingSDK",
            deploymentTargets: .iOS("18.0"),
            sources: ["RecordingSDK/**"],
            dependencies: [],
            settings: .settings(
                base: [
                    "CODE_SIGN_STYLE": "Automatic",
                ]
            )
        ),

        // MARK: - RecordingDemo App
        .target(
            name: "RecordingDemo",
            destinations: [.iPhone, .iPad],
            product: .app,
            bundleId: "com.gabemontague.RecordingDemo",
            deploymentTargets: .iOS("18.0"),
            infoPlist: .extendingDefault(with: [
                "UIBackgroundModes": .array([
                    .string("audio"),
                ]),
                "NSMicrophoneUsageDescription": "This app needs microphone access to record audio",
                "UILaunchScreen": .dictionary([:]),
            ]),
            sources: ["RecordingDemo/**"],
            resources: ["RecordingDemo/Assets.xcassets", "RecordingDemo/Preview Content/**"],
            dependencies: [
                .target(name: "RecordingSDK"),
            ],
            settings: .settings(
                base: [
                    "CODE_SIGN_STYLE": "Automatic",
                    "ENABLE_PREVIEWS": "YES",
                ]
            )
        ),

        // MARK: - RecordingSDK Tests
        .target(
            name: "RecordingSDKTests",
            destinations: [.iPhone, .iPad],
            product: .unitTests,
            bundleId: "com.gabemontague.RecordingSDKTests",
            deploymentTargets: .iOS("18.0"),
            sources: ["RecordingSDKTests/**"],
            dependencies: [
                .target(name: "RecordingSDK"),
            ]
        ),

        // MARK: - RecordingDemo UI Tests
        .target(
            name: "RecordingDemoUITests",
            destinations: [.iPhone, .iPad],
            product: .uiTests,
            bundleId: "com.gabemontague.RecordingDemoUITests",
            deploymentTargets: .iOS("18.0"),
            sources: ["RecordingDemoUITests/**"],
            dependencies: [
                .target(name: "RecordingDemo"),
            ]
        ),
    ],
    schemes: [
        .scheme(
            name: "RecordingDemo",
            shared: true,
            buildAction: .buildAction(targets: ["RecordingDemo", "RecordingSDK"]),
            testAction: .targets(["RecordingSDKTests", "RecordingDemoUITests"]),
            runAction: .runAction(configuration: "Debug", executable: "RecordingDemo")
        ),
        .scheme(
            name: "RecordingSDK",
            shared: true,
            buildAction: .buildAction(targets: ["RecordingSDK"]),
            testAction: .targets(["RecordingSDKTests"])
        ),
    ]
)
