Pod::Spec.new do |s|
  s.name             = 'Speechly'
  s.version          = '0.1.0'
  s.summary          = 'Swift iOS client for Speechly SLU API.'

  s.homepage         = 'https://github.com/speechly/ios-client'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { :name => 'Speechly' }
  s.source           = { :git => 'https://github.com/speechly/ios-client.git', :tag => s.version.to_s }

  s.ios.deployment_target = '12.0'
  s.swift_version = '5.7'

  s.source_files = 'Sources/Speechly/**', 'Sources/Speechly/*/**'
  s.exclude_files = 'Sources/Speechly/UI/'
  
  s.dependency 'SpeechlyAPI'
  s.dependency 'SwiftNIO', '~> 2.40.0'
  s.dependency 'gRPC-Swift', '~> 1.8.0'
end
