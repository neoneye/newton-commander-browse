puts "XCompiling NewtonCommanderBrowse's worker process"

system 'xcodebuild -project Project/NewtonCommanderBrowse.xcodeproj -target Demo CONFIGURATION_BUILD_DIR=NewtonCommanderBrowseBinary'

puts "XFinished compiling NewtonCommanderBrowse's worker process"
