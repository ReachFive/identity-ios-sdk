<p align="center">
 <img src="https://www.reachfive.com/hubfs/5399904/Logo-ReachFive.svg" alt="Reach5 Logo" width="700" height="192"/>
</p>

[![CircleCI](https://circleci.com/gh/ReachFive/identity-ios-sdk/tree/master.svg?style=svg)](https://circleci.com/gh/ReachFive/identity-ios-sdk/tree/master)
[![Download](https://img.shields.io/cocoapods/v/IdentitySdkCore.svg?style=flat) ](https://cocoapods.org/pods/IdentitySdkCore)

# ReachFive Identity iOS SDK

## Installation

### Cocoapods

Add the following line to your **Podfile**:


    pod 'IdentitySdkCore'

and other dependencies, for Social Login, as needed:

    pod 'IdentitySdkFacebook'
    pod 'IdentitySdkGoogle'
    pod 'IdentitySdkWeChat'


### Swift Package Manager
Open the following menu item in Xcode:

**File > Add Package Dependencies...**

In the **Search or Enter Package URL** search box enter this URL:

https://github.com/ReachFive/identity-ios-sdk.git

Then, select the dependency rule and press **Add Package**.

Or directly add it to the dependencies value of your Package.swift or the Package list in Xcode


    dependencies: [
        .package(url: "https://github.com/ReachFive/identity-ios-sdk.git", .upToNextMajor(from: "6.3.0"))
    ]

## initialisation
Refer to the [public documentation](https://developer.reachfive.com/sdk-ios/index.html) to install the SDKs and to initialize your ReachFive client.

The basics are:

- Configuration:


    let reachfive: ReachFive = ReachFive(sdkConfig: SdkConfig(domain: "DOMAIN", clientId: "CLIENT_ID"))

- Initialisation:

Call this method (that makes a network call) inside the corresponding method of `UIApplicationDelegate`


    reachfive.application(application, didFinishLaunchingWithOptions: launchOptions)


## Demo application

In addition to the libraries, we provide in the `Sandbox` directory a simple iOS application which integrates the ReachFive SDKs.

To configure this demo application and learn how to use this SDK, refer to [contributing](CONTRIBUTING.md#running-the-demo-application)

## Documentation

You'll find the documentation of the methods exposed on https://developer.reachfive.com/sdk-ios/index.html.

## Changelog

Please refer to [changelog](CHANGELOG.md) to see the descriptions of each release.

## Development

Please refer to [contributing](CONTRIBUTING.md#development)

## License

[MIT](LICENSE) © [ReachFive](https://reachfive.co/)
