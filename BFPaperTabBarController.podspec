Pod::Spec.new do |s|
  s.name         = "BFPaperTabBarController"
  s.version      = "2.2.8"
  s.summary      = "iOS UITabBar inspired by Google's Paper Material Design."
  s.homepage     = "https://github.com/bfeher/BFPaperTabBar"
  s.license      = { :type => 'MIT', :file => 'LICENSE.md' }
  s.author       = { "Bence Feher" => "ben.feher@gmail.com" }
  s.source       = { :git => "https://github.com/bfeher/BFPaperTabBarController.git", :tag => "2.2.8" }
  s.platform     = :ios, '7.0'


  s.source_files = 'Classes/*.{h,m}'
  s.requires_arc = true

end
