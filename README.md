# newton-commander-browse

The child process that runs for each open tab within Newton Commander.

When you open a tab in the UI then a browse-worker process is started.

When you kill a tab in the UI then a browse-worker process is killed.

If a browse-worker process hangs forever then it doesn't affect the parent process (Newton Commander).

## Usage

To run the example project; clone the repo, and run `pod install` from the Project directory first.

## Requirements

- OSX 10.9 (Mavericks)
- Xcode 5.0.2

## Installation

newton-commander-browse is not yet available through [CocoaPods](http://cocoapods.org).

To install it simply add the following line to your Podfile:

    pod "newton-commander-browse" :git => 'https://github.com/neoneye/newton-commander-browse.git'

## Author

Simon Strandgaard, simon@opcoders.com

## License

newton-commander-browse is available under the MIT license. See the LICENSE file for more info.

