BFPaperTabBarController
====================
[![CocoaPods](https://img.shields.io/cocoapods/v/BFPaperTabBarController.svg?style=flat)](https://github.com/bfeher/BFPaperTabBarController)

> Note that this changelog was started very late, at roughly the time between version 2.1.8 and 2.1.9. Non consecutive jumps in changelog mean that there were incremental builds that weren't released as a pod, typically while solving a problem.


2.2.7
---------
* (^) Fixed overline bar getting stuck when set programmatically. [Onur Var](https://github.com/onurvarrrr). (Pull request 8)[https://github.com/bfeher/BFPaperTabBarController/pull/26]


2.2.6
---------
* (^) Dragging to reorder tabs while More->Edit is active now works thanks to [apozdeyev](https://github.com/apozdeyev). (Pull request 7)[https://github.com/bfeher/BFPaperTabBarController/pull/24]

2.2.5
---------
* (-) Removed all BFPaperColors dependecies and code.
* (^) Properties now appear in Interface Builder (IBInspectable)!

2.1.13
---------
* (^) Migrated to CocoaPods 1.0.

2.1.12
---------
* (+) Added feature to display a line on the top of the tab bar, thanks to GitHub user [Onur Var](https://github.com/onurvarrrr)

2.1.11
---------
* (^) Fixed bug where viewDidLoad was being called multiple times for subclasses of BFPaperTabBarController.

2.1.10
---------
* (^) Update pods.

2.1.9
---------
* (+) Added a changelog!  
* (^) Fixed bug where sometimes tapCircle was nil in 'burstTapCircle' thanks to github user [@Maguszin](https://github.com/Maguszin).
