Pod::Spec.new do |spec|
  spec.name         = "TSAVideoCallSDKHB"
  spec.version      = "0.2.0"
  spec.summary      = "TSAVideoCall SDK for video conference."
  spec.homepage     = "https://github.com/smpb05/TSAVideoCallSDKHB"
  spec.license      = "MIT"
  spec.author             = { "Smartex" => "nurgul.aisariyeva@smartex.kz" } 
  spec.source       = { :git => "https://github.com/smpb05/TSAVideoCallSDKHB.git", :tag => '0.2.0' }
  spec.swift_versions = ['5.0']
  spec.ios.deployment_target = '11.0'
  spec.source_files = 'TSAVideoCallSDKHB/**/*.{swift}'
  spec.static_framework = true
  spec.dependency 'TSAVideoCallSDK', '0.0.9'
  spec.pod_target_xcconfig = {
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64'
  }
  spec.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }

end