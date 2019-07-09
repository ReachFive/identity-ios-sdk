require_relative './version'

Pod::Spec.new do |spec|
  spec.name                  = "IdentitySdkCore"
  spec.version               = $VERSION
  spec.summary               = "ReachFive IdentitySdkCore"
  spec.description           = <<-DESC
      ReachFive Identity Sdk Core
  DESC
  spec.homepage              = "https://github.com/ReachFive/identity-ios-sdk"
  spec.license               = { :type => "MIT", :file => "LICENSE" }
  spec.author                = "ReachFive"
  spec.authors               = { "egor" => "egor@reach5.co" }
  spec.swift_versions        = ["5"]
  spec.source                = { :git => "https://github.com/ReachFive/identity-ios-sdk.git", :tag => "#{spec.version}" }
  spec.source_files          = "IdentitySdkCore/IdentitySdkCore/Classes/**/*.*"
  spec.platform              = :ios
  spec.ios.deployment_target = $IOS_DEPLOYMENT_TARGET

  spec.dependency 'Alamofire', '~> 4.8'
  spec.dependency 'AlamofireObjectMapper', '~> 5.2'
  spec.dependency 'CryptoSwift', '~> 1.0.0'
  spec.dependency 'AlamofireNetworkLogger'
end