Mac OS VPNC Frontend 0.1

What it does?
-------------

It works as a menulet which allows you to connect/disconnect to your configured VPNs. It also tracks the tunnel interface to check the connection status and display notifications.


Instructions:
-------------

1) Your VPNC path must be /opt/local/sbin/

2) You have to allow your user in sudoers to run vpnc and vpnc-disconnect without asking for password:

username ALL=(ALL) NOPASSWD: /opt/local/sbin/vpnc, /opt/local/sbin/vpnc-disconnect

Don't forget to check it manually by trying to connect and disconnect just using your regular user!

3) Your configuration files must use ".conf" extension.


Disclaimer:
-----------

This is the first time I use Objective-C, so the code definitely could be better.

Also, I'm using a combination of AppleScript and NSUserNotification to have different types of notifications. That sucks, but I couldn't find a better way to do it at the time.


TODO:
-----

* Code documentation
* Error handling  
* Check for valid VPNC configuration files  
* App configuration file  
* Menu:
  * Display notifications on/off
  * checkStatus timer
  * edit VPNC configuration files

..and many many more things

AUTHOR:
-------

Elian Scrosoppi  
elian83@gmail.com

