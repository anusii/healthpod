# HealthPod Installers

Flutter supports multiple platform targets. Flutter based apps can run
native on Android, iOS, Linux, MacOS, and Windows, as well as directly
in a browser from the web. Flutter functionality is essentially
identical across all platforms so the experience across different
platforms will be very similar.

Visit the
[CHANGELOG](https://github.com/anusii/healthpod/blob/dev/CHANGELOG.md)
for the latest updates.

Binaries to download latest version:
[**GNU/Linux**](https://solidcommunity.au/installers/healthpod-dev-linux.zip) -
[**Debian/Ubuntu**](https://solidcommunity.au/installers/healthpod_amd64.deb) -
[**Android**](https://solidcommunity.au/installers/healthpod.apk) -
[**MacOS**](https://solidcommunity.au/installers/healthpod-dev-macos.zip) -
Windows
[**zip**](https://solidcommunity.au/installers/healthpod-dev-windows.zip) or
[**inno**](https://solidcommunity.au/installers/healthpod-dev-windows-inno.exe).

Run in a browser: [**Web**](https://healthpod.solidcommunity.au).

## Prerequisite

There are no specific prerequisites for installing and running
HealthPod.

## Android

You can side load the latest version of the app by downloading the
[installer](https://solidcommunity.au/installers/healthpod.apk) through
your Android device's browser. This will download the app to your
Android device. Then visit the Downloads folder where you can click on
the `healthpod.apk` file. Your browser will ask if you are okay with
installing the app locally.

## Linux

### Deb Install for Debian/Ubuntu

Download and install the deb package:

```bash
wget https://solidcommunity.au/installers/healthpod_amd64.dev -O healthpod_amd64.deb
sudo dpkg --install healthpod_amd64.deb
```

### Zip Install

Download [healthpod-dev-linux.zip](https://solidcommunity.au/installers/healthpod-dev-linux.zip)

To try it out:

```bash
wget https://solidcommunity.au/installers/healthpod-dev-linux.zip -O healthpod-dev-linux.zip
unzip healthpod-dev-linux.zip -d healthpod
./healthpod/healthpod
```

To install for the local user and to make it known to GNOME and KDE,
with a desktop icon for their desktop, begin by downloading the **zip** and
installing that into a local folder:

```bash
unzip healthpod-dev-linux.zip -d ${HOME}/.local/share/healthpod
```

Then set up your local installation (only required once):

```bash
ln -s ${HOME}/.local/share/healthpod/healthpod ${HOME}/.local/bin/
wget https://raw.githubusercontent.com/anusii/healthpod/dev/installers/app.desktop -O ${HOME}/.local/share/applications/healthpod.desktop
sed -i "s/USER/$(whoami)/g" ${HOME}/.local/share/applications/healthpod.desktop
mkdir -p ${HOME}/.local/share/icons/hicolor/256x256/apps/
wget https://github.com/anusii/healthpod/raw/dev/installers/app.png -O ${HOME}/.local/share/icons/hicolor/256x256/apps/healthpod.png
```

To install for any user on the computer:

```bash
sudo unzip healthpod-dev-linux.zip -d /opt/healthpod
sudo ln -s /opt/healthpod/healthpod /usr/local/bin/
wget https://raw.githubusercontent.com/anusii/healthpod/dev/installers/app.desktop -O ${HOME}/usr/local/share/applications/healthpod.desktop
wget https://github.com/anusii/healthpod/raw/dev/installers/app.png -O ${HOME}/use/local/share/icons/healthpod.png
```

Once installed you can run the app from the GNOME desktop through
Alt-F2 and type `healthpod` then Enter.

## MacOS

The zip file
[healthpod-dev-macos.zip](https://solidcommunity.au/installers/healthpod-dev-macos.zip)
can be installed on MacOS. Download the file and open it on your
Mac. Then, holding the Control key click on the app icon to display a
menu. Choose `Open`. Then accept the warning to then run the app. The
app should then run without the warning next time.

## Web -- No Installation Required

No installer is required for a browser based experience of
Healthpod. Simply visit https://healthpod.solidcommunity.au.

Also, your Web browser will provide an option in its menus to install
the app locally, which can add an icon to your home screen to start
the web-based app directly.

## Windows Installer

Download and run the self extracting archive
[healthpod-dev-windows-inno.exe](https://solidcommunity.au/installers/healthpod-dev-windows-inno.exe)
to self install the app on Windows.
