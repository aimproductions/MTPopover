#
# Be sure to run `pod lib lint MTPopover.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'MTPopover'
  s.version          = '1.0.0'
  s.summary          = 'A customizable NSPopover alternative for macOS written in Swift.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
A customizable NSPopover alternative for macOS written in Swift based on INPopoverController.
                       DESC

  s.homepage         = 'https://github.com/mylemans/MTPopover'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'BSD', :file => 'LICENSE' }
  s.author           = { 'mylemans' => 'tim@mylemans.com' }
  s.source           = { :git => 'https://github.com/mylemans/MTPopover.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.platform = :osx
  s.osx.deployment_target = "10.13"

  s.source_files = 'MTPopover/Classes/**/*'
  s.requires_arc     = true
  s.swift_version = "5.0"
  # s.resource_bundles = {
  #   'MTPopover' => ['MTPopover/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'Cocoa'
  # s.dependency 'AFNetworking', '~> 2.3'
end
