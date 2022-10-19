## Java-Android-Magisk-Burp-Objection-Root-Emulator-Easy (JAMBOREE)

Want to pentest or run Android apps in minutes ? Sick of BlueStacks or NOX malware/adware ? Not a single binary in this script and it's open source and downloads are direct from proper sources. There is lots of great powershell tricks (not great code) in this script. I worked hard on thing's like:

- Making it portable as possible

- Setting up and downloading extremely fast environment for Android, Java and Python

- Converting ssl certs to Android without openssl using certutil.exe only

I would like to make it even easier to use but I don't want to spend more time developing it if nobody is going to use it! Please let me know if you like it and open bugs/suggestions/feature request etc!


### Requirements:

- Local admin just to install:

HAXM Intel driver ( https://github.com/intel/haxm )

OR 

AMD ( https://github.com/google/android-emulator-hypervisor-driver-for-amd-processors )

### Usage:

Put ps1 file in a folder WITH NO SPACES ( WIP for true portability for now path must stay the same )  
Rightclick Run with PowerShell

Button click order is easy as... 1,2,3,4,5,4,6,4,7 ;) 

( Watch the Video Tutorial below it's a 3-5 min process. You only have to setup once. After that it's start burp then start AVD ) 

## Burp/Android Emulator (Video Tutorial )



[![IMAGE ALT TEXT HERE](https://img.youtube.com/vi/G1Iv-OoacpQ/0.jpg)](https://youtu.be/G1Iv-OoacpQ)

 

![image](https://user-images.githubusercontent.com/4307863/194215435-7d775b8d-441f-452c-9b91-1932d88dcfe8.png)



## Status of Automation Script

|Core|Status|
|--|--|
|Google Play|✔️|
|Java|✔️|
|Android 11 API 30|✔️|
|Magisk|✔️|
|Burp|✔️|
|Objection|✔️|
|Root|✔️|
|Python|✔️|
|Frida|✔️|
|Certs|✔️|

 
## Credit
https://github.com/Rogdham/python-xz/issues/4 for xz extraction in Python!!!

https://github.com/newbit1/rootAVD RootAVD

## References/Unsorted:

https://www.droidwin.com/how-to-hide-root-from-apps-via-magisk-denylist/

https://github.com/Fox2Code/FoxMagiskModuleManager/releases

https://forum.xda-developers.com/attachments/magiskhidepropsconf-v6-1-2-zip.5453567/

https://github.com/whalehub/custom-certificate-authorities

https://github.com/NickstaDB/patch-apk/archive/refs/heads/master.zip

https://payatu.com/blog/amit/android_pentesting_lab

https://medium.com/@pranavggang/ssl-pinning-bypass-with-frida-framework-6fb71ca43e33

https://joshspicer.com/ssl-pinning-android

https://www.youtube.com/watch?v=JR4gDRYzY2c

https://forum.xda-developers.com/t/script-rootavd-root-your-android-studio-virtual-device-emulator-with-magisk-android-12-linux-darwin-macos-win-google-play-store-apis.4218123/page-9

https://www.studytonight.com/post/intercept-android-app-traffic-in-burp-suite-from-root-to-hack-ultimate-guide

https://markuta.com/magisk-root-detection-banking-apps/

### CERT Install
https://www.youtube.com/watch?v=Ml2GIRNIstI

https://www.youtube.com/watch?v=KL1jUvNSL94

https://www.youtube.com/watch?v=Jg4hyZfFTdc

https://systemweakness.com/how-to-install-burp-suite-certificate-on-an-android-emulator-bb2972ba188c

### PINNING

https://book.hacktricks.xyz/mobile-pentesting/android-app-pentesting

### NOTES

https://gist.github.com/Pulimet/5013acf2cd5b28e55036c82c91bd56d8


