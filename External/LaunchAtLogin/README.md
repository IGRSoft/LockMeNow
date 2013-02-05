# Excerpt

This Xcode Workspace gives you a nice starting point for Apps that require 'Launch at Login' functionality.

# Introduction

"Launch at Login" was quite simple to implement. It even fits in a single gist: https://gist.github.com/1409312. Sandboxing changed this and made it 'little' more troublesome.

Tim Schroeder wrote [a great article](http://blog.timschroeder.net/2012/07/03/the-launch-at-login-sandbox-project/) about this, which combines very well with Alex Zielenski's [StartAtLoginController GitHub project](https://github.com/alexzielenski/StartAtLoginController) into a Helper Project that'll allow you to easily add "Launch at login" to multiple Apps.

Tim's example uses hardcoded information to launch the main App from the Helper App and toggle Launch at Login. Making it super easy to understand, but less flexible to use in multiple projects. That's where Alex' Controller comes in. It'll allow you to add the Helper Project to your main Project, add a new target, drag it your main app's "Copy Files" build phase and be done with it.

[This stackoverflow post](http://stackoverflow.com/questions/11292058/how-to-add-a-sandboxed-app-to-the-login-items) links to a [demo project](http://ge.tt/6DntY4K/v/0?c) that has most of the code in place, but doesn't use Tim's pretty Workspace method of setting things up. I mixed them together and made this new GitHub project that should help you setup your 'Launch at Login'-enabled project pretty quickly.

# Notice

* This will only work if your .app is in /Applications or ~/Applications, making it harder to debug.
* Running /Applications/[YourApp.app]/Contents/Library/StartupItems/[YourAppHelper.app] will sometimes not launch the main app if 'Launch at Startup' hasn't been activated for your app. So first run the app, check the checkbox and try again.

# License

New BSD License, see `LICENSE` for details.
