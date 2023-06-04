## Java Android Magisk Burp Objection Root Emulator Easy (JAMBOREE)
 
Get a working portable Python/Git/Java environment on Windows in **SECONDS** without having local administrator, regardless of your broken Python environment. Our open-source script downloads directly from proper sources without any binaries. While the code may not be perfect, it includes many useful PowerShell tricks.

* Run Android apps and pentest without the adware and malware of BlueStacks or NOX. 
* Run BloodHound Active Directory auditing tool
* AUTOMATIC1111  Stable Diffusion web UI A browser interface based on Gradio library for Stable Diffusion
* AutoGPT  ( Setup for Pay as you go gpt3-turbo https://platform.openai.com/account/usage ) 

### How it works:

* Temporarily resets your windows $PATH environment variable to fix any issues with existing python/java installation
* Build a working Python environment in seconds using a tiny 16 meg nuget.org Python binary and portable PortableGit. Our solution doesn't require a package manager like Anaconda.

I would like to make it even easier to use but I don't want to spend more time developing it if nobody is going to use it! Please let me know if you like it and open bugs/suggestions/feature request etc! you can contact me at ( https://rmccurdy.com ) !

![image](https://user-images.githubusercontent.com/4307863/236506844-b2f3583e-496e-4775-81e6-2e4f2d558988.png)



### Requirements:

- Local admin just to install Android AVD Driver:

HAXM Intel driver ( https://github.com/intel/haxm )

OR 

AMD ( https://github.com/google/android-emulator-hypervisor-driver-for-amd-processors )

### Usage:

Put ps1 file in a folder WITH NO SPACES ( WIP for true portability for now path must stay the same )  
Rightclick Run with PowerShell

OR

From command prompt (NO SPACES IN THE PATH)

    powershell -ExecutionPolicy Bypass -Command "[scriptblock]::Create((Invoke-WebRequest "https://raw.githubusercontent.com/freeload101/Java-Android-Magisk-Burp-Objection-Root-Emulator-Easy/main/JAMBOREE.ps1").Content).Invoke();"

 

More infomation on bypass Root Detection and SafeNet
https://www.droidwin.com/how-to-hide-root-from-apps-via-magisk-denylist/

( Watch the Video Tutorial below it's a 3-5 min process. You only have to setup once. After that it's start burp then start AVD ) 



    
## Burp/Android Emulator (Video Tutorial )

https://youtu.be/G1Iv-OoacpQ

[![name](https://user-images.githubusercontent.com/4307863/225742029-c7090555-049f-422d-bb61-59852bc35cda.png)](https://youtu.be/G1Iv-OoacpQ)

## Burp Proxy/ZAP Proxy
![image](https://user-images.githubusercontent.com/4307863/210654556-88cc1eab-a7d3-448d-891d-1c4c3e9fd14c.png)

## Burp Crawl Config

Included `%USERPROFILE%\AppData\Roaming\BurpSuite\ConfigLibrary_JAMBOREE_Crawl_Level_01.json` the "Headed" Browser is no longer supported 


## Example Objection / Frida

![image](https://user-images.githubusercontent.com/4307863/219110723-5b3e98b9-4d87-4eed-b855-a8a7b0ba0c0c.png)


## Status of Automation Script

|Core|Status|
|--|--|
|AUTOMATIC1111|✔️|
|AutoGPT|✔️|
|Bloodhound|✔️|
|Brida, Burp to Frida bridge|❌|
|SaftyNet+ Bypass|❌|
|Burp Suite Pro / CloudFlare UserAgent Workaround-ish|✔️|
|ZAP Using Burp|✔️|
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


# Bloodhound-Portable Bloodhound Portable 
Six Degrees of Domain Admin

![image](https://user-images.githubusercontent.com/4307863/221010307-94951724-ea8b-497f-a7ed-754510838e67.png)
![image](https://user-images.githubusercontent.com/4307863/229207944-83c876c3-7c25-4826-ba85-1dd030c68cfc.png)

## Useful cypher queries and links

[The BloodHound 4.3 Release Get Global Admin More Often.mp4](https://rmccurdy.com/.scripts/videos/The%20BloodHound%204.3%20Release%20Get%20Global%20Admin%20More%20Often.mp4) 20230418

https://www.google.com/search?q=%22shortestPath%22+%22bloodhound%22+site:github.com

https://github.com/drak3hft7/Cheat-Sheet---Active-Directory

https://gist.github.com/jeffmcjunkin/7b4a67bb7dd0cfbfbd83768f3aa6eb12

https://hausec.com/2019/09/09/bloodhound-cypher-cheatsheet/

https://github.com/BloodHoundAD/BloodHound/wiki/Cypher-Query-Gallery

https://risky.biz/soapbox74/

## Slack
https://bloodhoundhq.slack.com ( not sure how to get invite )


[BloodHound](https://github.com/BloodHoundAD/BloodHound) Portable for Windows (You can run this without local admin. No Administrator required)

[ Presentation ](https://docs.google.com/presentation/d/1aN7CgzeFko6hmkjJMQuQTXg6Ev-v-zsRUhXDd9z7R5Y)

## Usage

1) Download the .ps1 script
2) Click the SharpHound button as a normal domain user Alternatively you can use [Runas.exe](https://bloodhound.readthedocs.io/en/latest/data-collection/sharphound.html?highlight=netonly#running-sharphound-from-a-non-domain-joined-system) inside of a VM under domain user context with ```runas /netonly /user:"US.COMPANY.DOMAIN.COM\UESERNAME@COMPANY.COM" cmd``` or try ```/user:"DOMAIN\USERNAME"``` to run SharpHound.exe 
4) Click Neo4j to start the database
5) Change the default Neo4j password. Wait for Neo4j You must change password at http://localhost:7474
6) Click Bloodhound button to start bloodhound
7) Import the .zip of JSON files from the output of ```SharpHound.exe -s --CollectionMethods All --prettyprint true```

Parse Sharphound Output [Pretty_Bloodhound.py](https://github.com/freeload101/Python/blob/master/Pretty_Bloodhound.py) ( not needed they fixed it )

** You may need to whitelist or disable Bloodhound/Sharphound in your Endpoint Security Software ( Or just obfucate it if your lucky... Resource Hacker or echo '' >> Sharphound.exe etc  ...  ) **

** Last tested Bloodhound 4.1.0 **


![image](https://user-images.githubusercontent.com/4307863/153485618-6bf743af-b5a9-4f88-b0ab-0ad24fed4556.png)

Credit: 
https://bloodhound.readthedocs.io/en/latest/_images/SharpHoundCheatSheet.png

![image](https://user-images.githubusercontent.com/4307863/156181140-951cc25d-d6f7-4385-8520-9980869a7ee2.png)


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


