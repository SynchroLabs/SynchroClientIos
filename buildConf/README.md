## User creates signing key and provisioning profile

If the user has an XCode development environment they probably already have signing keys and know how to generate provisioning profiles.

Here are the PhoneGap instructions for generating the signing key and provisioning profile.  These aren’t really relevant to our process below, but just to show an example of how to direct the user to create this stuff if they aren't an iOS developer (even without a Mac).

http://docs.build.phonegap.com/en_US/signing_signing-ios.md.html
___
## Gathering existing signing key and provisioning profile

Assuming you already have a signing key and provisioning profile...

### Export the signing key:

Run 'Keychain Access” on your Mac and find the signing key that corresponds to the provisioning profle that you plan to use (either Development or Distribution, as appropriate).  Select it and choose File->Export, or right click the key and choose “Export”.

In the export dialog, choose to export as .p12 file.  Enter a password (you will need to provide the password later when the signing key is processed).

### Download provisioning profile

Go to https://developer.apple.com/account/ios/profile/

Select the provisioning profile that you’d like to use and download it.  It will be named [shortednedprofilename].mobileprovision and placed in Downloads.

___
## Process the signing key

If you want to inspect the signing key (.p12 file), you can run:

```openssl pkcs12 -in Certificate.p12 -passin pass:ThePassword -clcerts -nokeys```

This will produce a list of certificate attributes (if you just want to verify that it’s the correct signing key).

To install this key, such that it can be used by xcodebuild:

```security import Certificate.p12 -k ~/Library/Keychains/login.keychain -P ThePassword -T /usr/bin/codesign```

For an explanation (particularly of the code signing permission), see:

http://stackoverflow.com/questions/4369119/how-to-install-developer-certificate-private-key-and-provisioning-profile-for-io
___
## Process the provisioning profile

The provisioning profile file is signed.  To inspect the contents of the provisioning profile, run:

```security cms -D -i  [shortednedprofilename].mobileprovision```

To install this profile, such that it can be used by xcodebuild, the file must be placed in:

 ~/Library/MobileDevice/Provisioning Profiles/

And it must be named using the UUID from inside the file, and using the mobileprovision suffix.

Here’s a script that uses grep to extract the UUID: https://gist.github.com/benvium/2568707

You will need that UUID later when specifying the provisioning profile for xcodebuild to use.

If you want to verify that the signing certificate included in the provisioning profile matches the signing certificate from the signing key file, you can extract it and inspect it.  It can be found in <DeveloperCertificates><data>.  It is a base64 encoded x509 certificate.

Here is a good description of everything in the provisioning profile, including the developer certificate:

https://possiblemobile.com/2013/04/what-is-a-provisioning-profile-part-2/

I had to put the base64 in a file, wrap it in the BEGIN and END certificate text, and shorten the lines to 72 chars per line, then I could dump it by running the following:

```openssl x509 -in cert.pem -text```

It would be nice (in the future) to be able to report errors where the signing key did not match the provisioning profile (when our end users provide both files to us when requesting a custom client).
___
## Doing the build!

Once you have the provisioning profile and signing key installed, you can build by doing the following:

Substitute build-specific static files:

* Copy the seed.json and the icon files over their existing counterparts

Create a build.xcconfig file and populate it as below:
```console
USR_BUNDLE_NAME = Synchro Civics
PRODUCT_BUNDLE_IDENTIFIER = io.synchro.civics
PROVISIONING_PROFILE = c19af0ce-8a36-4978-952c-fb9cb1b5b7cf
```

__Note:__ Versions of the xcconfig files for Explorer and Civics are checked in (in this directory) as explorer.xcconfig and civics.xcconfig

Create the archive (xcarchive file) - the xcconfig option value should reference the file you created above:

```xcodebuild archive -scheme SynchroSwift -archivePath build/out.xcarchive -xcconfig build.xcconfig```

Sign the archive and export to .ipa:

```xcodebuild -exportArchive -archivePath build/out.xcarchive -exportPath build -exportOptionsPlist buildConf/store_export.plist```

That should produce a SynchroSwift.ipa that can be uploaded to the App Store via the Application Loader
___
## Notes on -exportOptionsPlist

The -exportOptionsPlist directive and corresponding file are required to build for distribution.  The store_export.plist file referenced above (and checked in in this directory) looks like:

```
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
</dict>
</plist>
```

Documentation for the keys available for use in an exportOptionsPlist file are availble through:

```xcodebuild -h```

Right now, we only need to set the ```method``` key to indicate an app store build.  There is no app-specific data required.  So we can just use the static store_export.plist file.  If we wanted to do Development, Enterprise, or Ad Hoc builds, we could make other static plist files for those.
___
## Future - Determining the "release mode" from the provisioning profile

As stated above, the release mode of the product (Development, Ad Hoc, Enterprise, or App Store) must be specified when creating the archive (and specified in the exportOptionsPlist file), even though all of the information required to determine the release mode is available in the provisioning profile.  In future, it would be nice if we could support all release types and determine them based on the provisioning profile.

To determine the release type, inspect the .mobileprovision file.

    If key ProvisionsAllDevices == true, then this is Enterprise release
    Else If Key ProvisionedDevices exists
        If Entitlemenets\get-task-allow = true, this is Development release
        Else this is Ad Hoc release
    Else this is App Store release

Some code and documentation supporting this is available at: https://github.com/blindsightcorp/BSMobileProvision








