require_relative './version'

Pod::Spec.new do |spec|
  spec.name                  = "IdentitySdkGoogle"
  spec.version               = $VERSION
  spec.summary               = "ReachFive IdentitySdkGoogle"
  spec.description           = <<-DESC
      ReachFive Identity Sdk Google
  DESC
  spec.homepage              = "https://github.com/ReachFive/identity-ios-sdk"
  spec.license               = { :type => "MIT", :file => "LICENSE" }
  spec.author                = "ReachFive"
  spec.authors               = { "François" => "francois.devemy@reach5.co", "Pierre" => "pierre.bar@reach5.co" }
  spec.swift_versions        = ["5"]
  spec.source                = { :git => "https://github.com/ReachFive/identity-ios-sdk.git", :tag => "#{spec.version}" }
  spec.source_files          = "IdentitySdkGoogle/IdentitySdkGoogle/Classes/**/*.*"
  spec.platform              = :ios
  spec.ios.deployment_target = $IOS_DEPLOYMENT_TARGET

  spec.static_framework = true

  # cf. https://github.com/CocoaPods/CocoaPods/issues/10203
  spec.pod_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64'}
  spec.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64'}

  spec.dependency 'IdentitySdkCore', '~> 6'
  spec.dependency 'GoogleSignIn', '~> 7'
end
