<p align="center">
 <img src="https://www.reachfive.com/hubfs/5399904/Logo-ReachFive.svg" alt="Reach5 Logo" width="700" height="192"/>
</p>

[![CircleCI](https://circleci.com/gh/ReachFive/identity-ios-sdk/tree/master.svg?style=svg)](https://circleci.com/gh/ReachFive/identity-ios-sdk/tree/master)
[![Download](https://img.shields.io/cocoapods/v/IdentitySdkCore.svg?style=flat) ](https://cocoapods.org/pods/IdentitySdkCore)

# ReachFive Identity iOS SDK

## Cocoapods pods

- [IdentitySdkCore](https://cocoapods.org/pods/IdentitySdkCore)
- [IdentitySdkWebView](https://cocoapods.org/pods/IdentitySdkWebView)
- [IdentitySdkFacebook](https://cocoapods.org/pods/IdentitySdkFacebook)
- [IdentitySdkGoogle](https://cocoapods.org/pods/IdentitySdkGoogle)
- [IdentitySdkWeChat](https://cocoapods.org/pods/IdentitySdkWeChat)

## Installation

Refer to the [public documentation](https://developer.reachfive.com/sdk-ios/index.html) to install the SDKs and to initialize your ReachFive client.

## Demo application

In addition to the libraries, we provide in the `Sandbox` directory a simple iOS application which integrates the ReachFive SDKs.

Install [Cocoapods](https://cocoapods.org).

```sh
sudo gem install cocoapods

cd Sandbox
pod install

open Sandbox.xcworkspace

pod update
```

### Configure the Sandbox

#### Configure your account

On https://developer.apple.com/account, create an Identifier for an App ID.
Choose a `bundle ID`.<br>
To use the full extent of the Sandbox app features, select the `Associated Domains` and `Sign In with Apple` capabilities.

On XCode, connect your account.

In the navigator area, select `Sandbox` at the root, then in the editor area, in `Targets` select `Sandbox` (which should be selected by default) then "Signing & Capabilities".<br>
Fill in your `bundle ID`.
Add the `Associated Domains` and `Sign In with Apple` capabilities. <br>
Configure the associated domains as explained below.

##### Configure the associated domains
In Domains, enter `webcredentials:domain`. <br>
The domain must be the same as in the `SdkConfig`, so for example `webcredentials:integ-sandbox-squad2.reach5.dev`.<br>
If you use a private web server, which is unreachable from the public internet, you can also enable the alternate mode feature by appending `?mode=<alternate mode>`.<br>
So for example `webcredentials:integ-sandbox-squad2.reach5.dev?mode=developer`

cf. https://developer.apple.com/documentation/xcode/supporting-associated-domains

#### Connect to your backend
You also need to set the ReachFive client configuration within the SDK as below:

```
SdkConfig(
  domain: "my-reachfive-url",
  clientId: "my-reachfive-client-id"
)
```


For example:
```
SdkConfig(
    domain: "integ-sandbox-squad2.reach5.dev",
    clientId: "zhU43aRKZtzps551nvOM"
)
```

By default, the URL scheme follows this pattern: `reachfive-${clientId}://callback`.
You can also specify it manually.

#### Configure your backend

The client that you just referenced must be a `First-party client` with `Token Endpoint Authentication Method` at `None`.<br>
You must have the scheme registered in `Allowed Callback URLs`.<br>
You should also enforce PKCE and enable Refresh Tokens.<br>
If you want to use Passkeys, you must have the `Webauthn` feature activated on your account, and add your domain in `Allowed Origins` like this: `https://integ-sandbox-squad2.reach5.dev`.<br>
Note the `https://` here that was not present in the `SdkConfig`.

#### Run Sandbox on a real device
To run your app on a device and not just the simulator (to use Passkeys for example), you need to enable "Developer Mode".<br>
On iPhone, iPad, go to Settings > Privacy & Security > Developer Mode.<br>
On a Mac, run in your terminal:
```shell
swcutil developer-mode -e true
```

## Documentation

You'll find the documentation of the methods exposed on https://developer.reachfive.com/sdk-ios/index.html.

## Changelog

Please refer to [changelog](CHANGELOG.md) to see the descriptions of each release.

## License

MIT © [ReachFive](https://reachfive.co/)
