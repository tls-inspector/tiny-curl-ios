# tiny-curl-ios

A script to compile tiny-curl for iOS and iPadOS applications.

# Instructions

It's as simple as:

```
./build-ios.sh <tiny-curl version>
```

Then add the resulting `curl.xcframework` package to your app and you're finished.

# License

This script is licensed under GPLv3.

**Important:** tiny-curl is licensed under GPLv3 which is different than the regular curl.
There are significant legal considerations when using GPL licensed code in your software,
even if you're just linking a library. Do not contact the authors of this package for
questions about the legality of using tiny-curl in your software. Licensed versions of
tiny-curl are [available for purchase](https://curl.se/tiny/) and should work with this
script.
