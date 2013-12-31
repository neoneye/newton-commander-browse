# newton-commander-browse CHANGELOG

## 0.1.13

When I upgraded to Mavericks I discovered that handshake between parent and child timed out. It took approx 10 seconds to complete a handshake. It was because Bonjour takes 5 seconds to resolve a hostname. This used to be really fast. I had to change the code so it no longer uses Bonjour. Instead it exchanges portNumbers via commandline arguments and via handshake.

I thought that I had to abbandon Distributed Objects entirely and was investigating using ZeroMQ instead. While researching ZeroMQ I found out that I could obtain the port number from a NSSocketPort, so no need for ZeroMQ for now.

## 0.1.0

Initial release.
