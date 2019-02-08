
Pod::Spec.new do |s|
  s.name             = 'Juggernaut'
  s.version          = '1.1.2'
  s.summary          = 'Download manager - Juggernaut'

  s.description      = <<-DESC
												Download large files even in background, download multiple files, resume interrupted downloads.
                       DESC

  s.homepage         = 'https://github.com/tularovbeslan/Juggernaut'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'tularovbeslan@gmail.com' => 'tularovbeslan@gmail.com' }
  s.source           = { :git => 'https://github.com/tularovbeslan/Juggernaut.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/JiromTomson'
  s.swift_version = '4.2'
  s.ios.deployment_target = '10.0'

  s.source_files = 'Classes/**/*'
  
  # s.resource_bundles = {
  #   'Juggernaut' => ['Juggernaut/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
   s.frameworks = 'UIKit', 'MapKit'
end
