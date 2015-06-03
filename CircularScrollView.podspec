#
# Be sure to run `pod lib lint CircularScrollView.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "CircularScrollView"
  s.version          = "0.1.0"
  s.summary          = "Endless circular scroll view control for iOS"
  s.description      = <<-DESC
                       This control allows you to create a circular endless control to show UIViewController subclass. It can works both in paginated and non paginated mode.
                       DESC
  s.homepage         = "https://github.com/malcommac/CircularScrollView"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "daniele margutti" => "me@danielemargutti.com" }
  s.source           = { :git => "https://github.com/malcommac/CircularScrollView.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/danielemargutti'

  s.platform     = :ios, '8.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes/**/*'
  s.resource_bundles = {
    'CircularScrollView' => ['Pod/Assets/*.png']
  }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
