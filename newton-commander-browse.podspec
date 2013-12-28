#
# Be sure to run `pod spec lint NAME.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# To learn more about the attributes see http://docs.cocoapods.org/specification.html
#
Pod::Spec.new do |s|
  s.name         = "newton-commander-browse"
  s.version      = "0.1.0"
  s.summary      = "Worker process used by Newton Commander for each open panel."
  s.description  = <<-DESC
      The child process that runs for each open tab within Newton Commander.
	  
	  When you open a tab in the UI then a browse-worker process is started.
	  
	  When you kill a tab in the UI then a browse-worker process is killed.
	  
	  If a browse-worker process hangs forever then it doesn't affect the parent process (Newton Commander).
      DESC
  s.homepage     = "https://github.com/neoneye/newton-commander-browse"
  s.screenshots  = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license      = 'MIT'
  s.author       = { "Simon Strandgaard" => "simon@opcoders.com" }
  s.source       = { :git => "https://github.com/neoneye/newton-commander-browse.git", :tag => s.version.to_s }

  # s.platform     = :ios, '5.0'
  # s.ios.deployment_target = '5.0'
  # s.osx.deployment_target = '10.7'
  s.requires_arc = true

  s.source_files = 'Classes'
  s.resources = 'Assets'

  s.ios.exclude_files = 'Classes/osx'
  s.osx.exclude_files = 'Classes/ios'
  # s.public_header_files = 'Classes/**/*.h'
  # s.frameworks = 'SomeFramework', 'AnotherFramework'
  # s.dependency 'JSONKit', '~> 1.4'
end
