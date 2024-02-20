# Install Guide

## Prerequisites

Before you begin, ensure you have met the following requirements:

- **Homebrew**: The missing package manager for macOS (or Linux), which you can use to install CocoaPods.
- **CocoaPods**: A dependency manager for Swift and Objective-C Cocoa projects.

## Setup

To get a local copy up and running, follow these simple steps.

### Installing Homebrew

If not already installed on your macOS, open Terminal and run:

`/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`

## Installing CocoaPods

With Homebrew installed, execute the following command to install CocoaPods:

`brew install cocoapods`

### After installing CocoaPods

Go into the project folder and run 

`pod install`

Make sure to open project workspace after.

`open ProjectName.xcworkspace`
