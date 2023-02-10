# Batchfile-PIA-PrivateInternetAccess-PortForward-Checker
Batch file command line script to check Private Internet Access for a port forward change on windows if it does change you can insert custom code to update programs firewalls etc

# Usage :
```"C:\path\pia_port_check.cmd" "PIA_USERNAME" "PIA_PASSWORD" 2^>nul```

# Requirements

PrivateInternetAccess installed thats it once you have installed PIA and logged in this will do the rest

https://www.privateinternetaccess.com/download/windows-vpn#download-windows

# Features

`pia_port_check.cmd` This will check your open port assigned by your vpn if it changes it will run any programs you specify to update the port to the new one if the ip address changes the exact same thing and i added dig.cmd to check if your ip address given to you by the vpn is on any spamhaus blacklists etc highly useful.

### PIA Script Features
Ability to use the batch file to configure PIA VPN settings turning on killswitch, PIA MACE Adblocker and more

`dig.cmd` This is dig on windows identical to dig on linux i built in a example black list check if it returns a 127.x.x.x result against one of spam checking domains your ip is in a blacklist for some reason. This is great for VPN checking if your VPN IP is blacklisted if it is my portforward script will cycle reconnecting you until it gives you a ip not blacklisted ;)

### Other Features scripts optional to use

`openssl.cmd` This script is just a example script for use like linux openssl on windows. I thought id plonk it in here someone will love my work.

`installer.cmd` This script is another example script to automatically download and install software and check if it exists if your managing clusters of vm's or desktops in a office enviorment my god this will save you time. `One file to rule them all, One file to find them, One file to bring them all and inside cyberspace bind them.`

# About

Its a simple cmd script.

I designed and built it to be portable so you can move it from machine to machine in automated fashion on flash drives or what ever you require it will setup and connect the rest.

Fast simple and multiple uses.

If you use Linux and want to use this ofcourse you can use Wine or Mono with this.

If you have a office or network of hundreds of computers this can be put on them all. Protecting your entire network :)
