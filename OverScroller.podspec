Pod::Spec.new do |s|
  s.name             = 'OverScroller'
  s.version          = '0.1.0'
  s.summary          = 'A short description of OverScroller.'

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/aelam/OverScroller'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'aelam' => 'wanglun02@gmail.com' }
  s.source           = { :git => 'https://github.com/aelam/OverScroller.git', :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'

  s.source_files = 'OverScroller/Classes/**/*'
  
end
