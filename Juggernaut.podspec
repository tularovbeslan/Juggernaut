
Pod::Spec.new do |s|
  s.name             = 'Juggernaut'
  s.version          = '2.1.0'
  s.summary          = 'Download manager - Juggernaut'

  s.description      = <<-DESC
												Download large files even in background, download multiple files, resume interrupted downloads.
                       DESC

  s.homepage         = 'https://github.com/tularovbeslan/Juggernaut'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'tularovbeslan@gmail.com' => 'tularovbeslan@gmail.com' }
  s.source           = { :git => 'https://github.com/tularovbeslan/Juggernaut.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/JiromTomson'
  s.swift_version = '5'
  s.ios.deployment_target = '10.0'

  s.source_files = 'Juggernaut/Classes/**/*'
  s.frameworks = 'UIKit'
end
