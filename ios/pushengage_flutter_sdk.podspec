#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint pushengage_flutter_sdk.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'pushengage_flutter_sdk'
  s.version          = '0.0.1'
  s.summary          = 'PushEngage Flutter SDK'
  s.description      = 'Provide the feature for Apple push notification.'
  s.homepage         = 'http://www.pushengage.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { "PushEngage" => "care@pushengage.com" }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.dependency 'PushEngage', '0.0.5'
  s.platform = :ios, '9.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
