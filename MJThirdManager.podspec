#
# Be sure to run `pod lib lint MJThirdManager.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |spec|
  spec.name              = "MJThirdManager"
  spec.version           = '1.0.1'
  spec.swift_versions    = '5.0'
  spec.license           = { :type => 'MIT', :text => <<-LICENSE
                              Copyright 2019
                              LICENSE
                            }
  spec.summary           = "MJThirdManager"
  spec.description       = <<-DESC
                            第三方的集合处理包括分享支付登录
                            DESC
  spec.homepage          = "https://github.com/chenminjie92/MJThirdManager"
  spec.author            = { "chenminjie" => "chenminjie92@126.com" }

  spec.source            = { :git => "https://github.com/chenminjie92/MJThirdManager.git", :tag => "#{spec.version}" }
  spec.platform          = :ios, "10.0"
  spec.static_framework  = true

  spec.source_files      = 'MJThirdManager/**/*.{h,m,swift}'
  spec.dependency        'WeiXinSDK_Swift'
  spec.dependency        'AlipaySDK_NoUTDID_Swift'
  spec.pod_target_xcconfig = { 'VALID_ARCHS' => 'x86_64 armv7 arm64' }
end
