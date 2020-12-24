# FireFoxUltimateClear
<#
Firefox ultimate clear 1.0 - by E-D-H

This script will clear firefox ultimately (No ff refresh needed) and only 
places the settings that are defined in an external file: configureFF.txt
These are just a copy of the relevant items from the .js file that stores
all settings (also tweakable by about:config), for example

user_pref("accessibility.force_disabled", 1);
user_pref("app.update.service.enabled", false);
user_pref("browser.discovery.enabled", false);
user_pref("browser.download.animateNotifications", false);
user_pref("browser.download.dir", "D:\\ffdownloads");
user_pref("browser.download.folderList", 2);
user_pref("browser.download.lastDir", "D:\\ffdownloads");
user_pref("browser.download.panel.shown", true);
user_pref("browser.ping-centre.telemetry", false);
user_pref("browser.startup.homepage", "https://www.google.com");

Advice: copy them as text directly from the configured prefs.js file! (Author uses 60 entries...)
#>
