Pod::Spec.new do |s|
  s.name             = 'gt_audio'
  s.version          = '1.0.0'
  s.summary          = 'Unified audio player for Flutter with streaming, offline downloading, background playback, Android Auto, and CarPlay.'
  s.description      = <<-DESC
Unified audio player for Flutter with streaming, offline downloading, queue management, background playback, Android Auto, and CarPlay.
                       DESC
  s.homepage         = 'https://github.com/govindtank/gt_audio'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { 'Govind Tank' => 'govindtank600@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
