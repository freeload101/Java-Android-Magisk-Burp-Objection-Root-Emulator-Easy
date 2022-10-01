# Java-Android-Magisk-Burp-Objection-Root-Emulator-Easy (JAMBOREE)
Java Android Magisk Burp Objection Root Emulator Easy (JAMBOREE)

This is going to be a Windows Installer that will grab and automate most of the process of setting up a Portable Android Emulator!

## Burp/Android Emulator
![image](https://user-images.githubusercontent.com/4307863/191853475-3fe11324-e52b-4b3c-8f72-fdceb27ed337.png)

_"Run ARM apps on the Android Emulator
As part of the Android 11 developer preview we’ve released Android 11 system images, which are capable of executing ARM binaries with significantly improved performance. "_

https://android-developers.googleblog.com/2020/03/run-arm-apps-on-android-emulator.html

## Lame Interface :stuck_out_tongue_closed_eyes:
![image](https://user-images.githubusercontent.com/4307863/192395895-c137dc3d-225e-4aec-a222-c56126a63575.png)


## LuckPatcher
![image](https://user-images.githubusercontent.com/4307863/192104230-fae1cbc8-f2f8-405e-8c3d-bba7a0a5505b.png)

## Status of Automation Script

|Core|Status|
|--|--|
|Java|✔️|
|Android 11 API 30|✔️|
|Magisk|✔️|
|Burp|✔️|
|Objection|✔️|
|Root|✔️|
|Python|✔️|
|Frida|✔️|
|Certs|❌|


|Feature/Idea|Status|
|--|--|
|easy backup button|❌|
|UI Automation https://www.lambdatest.com/blog/best-mobile-app-testing-framework/|❌|
|https://github.com/google/android-emulator-hypervisor-driver-for-amd-processors|❌|
|Kill Task/Wipe Storage|❌|
|Kill all Apps/Root before launch of app|❌|
|Fix Allow All/Perms All Apps|❌|
|Autohide Root/Magisk Before Patch or Frida|❌|
|build.prop (see reddit build.prop)|❌|
|Resize if Image <N (* "${ANDROID_HOME}/emulator/bin64/resize2fs" "${HOME}/.android/avd/${AVD}.avd/system.img" 3072M) |❌|
|Fix Aspect Radio/QR code in Virtual Scene|❌|
|Proxy Switch|❌|
|Logcat All In One Window|❌|
|Detect/Split Apks? https://github.com/NickstaDB/patch-apk|❌|
|Generate New Burp/ZAP certs/openssl .0  .cet .der|❌|
|Proxy Switch|❌|
|Audo add Google Services to DenyList|❌|
|Disable Updates/Google Play|❌|
|Disable Base Apps like Google Music etc|❌|
|Split APK install SAI App from GitHub|❌|
|Brida,Burp to Frida brige|❌|


## Order of Operations
* download android command line installer
* use 7z ps1 script to install licences files
* download all stuff for  Pixel_2_API_30 x86 with PLAY working !
* run rootAVD
* setup magisk
* run google play to add account
* disable play protect (command line ? )
* install magisk manager ? https://github.com/Fox2Code/FoxMagiskModuleManager/releases
* install ?  https://forum.xda-developers.com/attachments/magiskhidepropsconf-v6-1-2-zip.5453567/ 
* https://github.com/whalehub/custom-certificate-authorities
* /data/misc/user/0/cacerts-custom

## Credit/References/Unsorted:

https://www.droidwin.com/how-to-hide-root-from-apps-via-magisk-denylist/
https://github.com/Fox2Code/FoxMagiskModuleManager/releases
https://forum.xda-developers.com/attachments/magiskhidepropsconf-v6-1-2-zip.5453567/
https://github.com/whalehub/custom-certificate-authorities
/data/misc/user/0/cacerts-custom
https://github.com/NickstaDB/patch-apk/archive/refs/heads/master.zip
https://payatu.com/blog/amit/android_pentesting_lab
https://medium.com/@pranavggang/ssl-pinning-bypass-with-frida-framework-6fb71ca43e33
https://joshspicer.com/ssl-pinning-android
https://www.youtube.com/watch?v=JR4gDRYzY2c
https://forum.xda-developers.com/t/script-rootavd-root-your-android-studio-virtual-device-emulator-with-magisk-android-12-linux-darwin-macos-win-google-play-store-apis.4218123/page-9
https://www.studytonight.com/post/intercept-android-app-traffic-in-burp-suite-from-root-to-hack-ultimate-guide
https://markuta.com/magisk-root-detection-banking-apps/

CERT Install
https://www.youtube.com/watch?v=Ml2GIRNIstI
https://www.youtube.com/watch?v=KL1jUvNSL94
https://www.youtube.com/watch?v=Jg4hyZfFTdc
https://systemweakness.com/how-to-install-burp-suite-certificate-on-an-android-emulator-bb2972ba188c

PINNING
https://book.hacktricks.xyz/mobile-pentesting/android-app-pentesting

## NOTES
https://gist.github.com/Pulimet/5013acf2cd5b28e55036c82c91bd56d8


