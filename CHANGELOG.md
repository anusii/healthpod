# Health Pod Change Log

Noted here are the high level changes for the app.  Each update
includes a short user-oriented description.

You can run the app in your browser from the
[**web**](https://healthpod.solidcommunity.au) or else download and
install locally the latest version from the [Solid
Community](https://solidcommunity.au) or directly: for **Android** as
[apk](https://solidcommunity.au/installers/healthpod.apk); for
**GNU/Linux** as
[deb](https://solidcommunity.au/installers/healthpod_amd64.deb) or
[zip](https://solidcommunity.au/installers/healthpod-linux.zip);
for **macOS** as
[zip](https://solidcommunity.au/installers/healthpod-macos.zip);
for **Windows**
[zip](https://solidcommunity.au/installers/healthpod-windows.zip)
or
[exe](https://solidcommunity.au/installers/healthpod-windows-inno.exe).

Contributions are welcome. Visit
[github](https://github.com/anusii/healthpod) to submit an issue or,
even better, fork the repository yourself, update the code, and submit
a Pull Request. Coding documentation is
[available](https://solidcommunity.au/docs/healthpod).

We make this project available for free so if you appreciate the app
then please show some ❤️ and tap on the star at
[GitHub](https://github.com/anusii/healthpod) to support our work.

## 1.0 Migrating to new more secure secret key handling

+ Cancel an ANALYSIS while it runs, stopping the analyser too [1.0.16 20260901 tonypioneer]
+ Keep every ANALYSIS in the Pod, listed to view or delete [1.0.15 20260829 gjw]
+ Fix deleting data points on the DATA page [1.0.14 20260829 tonypioneer]
+ Add button to view previous ANALYSIS [1.0.13 20260829 gjw]
+ Add option to remove permissions to ANALYSIS [1.0.12 20260829 tonypioneer]
+ HEALTH PROFILE with BMI and waist/hip ratio [1.0.11 20260815 gjw]
+ View all blood pressure observations [1.0.10 20260814 gjw]
+ OIDC update for chrome/web [1.0.9 20260711 tonypioneer]
+ Update solidui/solidpod dependencies [1.0.8 20260703 gjw]
+ Restore app to where it left off [1.0.7 20260630 gjw]
+ Allow past appointments to be editted to add notes [1.0.6 20260630 gjw]
+ ANDROID deployment setup [1.0.5 20260630 gjw]
+ Clean and bug fix appointment handling [1.0.4 20260629 gjw]
+ Remove settings - webid now handled by solidui [1.0.3 20260629 gjw]
+ Remove attempt to auto login with ChromeDriver [1.0.2 20260629 gjw]
+ Migrate clientid to github [1.0.1 20260629 gjw]
+ Migrate to solid_auth v1 series [1.0.0 20260613 gjw]

## 0.2 Test and Make Robust

+ Fix widget overflow when viewing appointments [0.2.9 20260123 tonypioneer]
+ Update to riverpod v3 [0.2.8 20260123 tonypioneer]
+ Solidpod read/wirte pod API updates [0.2.7 20260112 tonypioneer]
+ Migrate to flutter_markdown_plus [0.2.6 20251124 gjw]
+ Dark mode fix for DATA PATHOLOGY listing [0.2.5 20251123 tonypioneer]
+ Re-engineer logout/login for status bar [0.2.4 20251013 tonypioneer]
+ Review and get snap build working [0.2.3 20251013 gjw]
+ Cleanup the README. Test snap build. [0.2.2 20251012 gjw]
+ Lychee checks and template updates [0.2.1 20250929 gjw]
+ Begin new series to test and make robust [0.2.0 20250918 gjw]

## 0.1 First stable release with SolidScaffold

+ LINT: Remove unused code and split long files [0.1.23 20250918 tonypioneer]
+ Get installer builds working [0.1.22 20250917 gjw]
+ Migrate to solidscaffold [0.1.21 20250917 tonypioneer]
+ Update solidpod dependency for CSS v7.1.7 [0.1.20 20250815 gjw]
+ Fix support csv import for blood pressure [0.1.19 20250809 atangster]
+ Bug fix exception when delting on chrome/web [0.1.18 20250809 atangster]
+ Bug fix CSV import of blood pressure [0.1.17 20250808 gjw]
+ Various bug fixes and code cleanup [0.1.16 20250808 gjw]
+ CARD: Flutter breaking change fixed [0.1.15 20250626 gjw]
+ MEDICATION: import/export [0.1.14 20250508 atangster]
+ DIARY: Collapse into tabs rather then separate tab [0.1.13 20250508 kev]
+ DIARY: import/export [0.1.12 20250508 kev]
+ DIARY: Updated calendar functionality [0.1.11 20250503 kev]
+ MEDICATIONS: NEW, VIEW, TABLE support [0.1.10 20250501 atangster]
+ HOME: Update to lateset VersionWidget() [0.1.9 20250429 kev]
+ BLOOD PRESSURE: Simplified popup in VISUAL [0.1.8 20250425 atangster]
+ HOME: Rename tabs [0.1.7 20250424 gjw]
+ HOME: Allow health plan to be edited [0.1.6 20250424 atangster]
+ BLOOD PRESSURE: Remove feeling [0.1.5 20250424 atangster]
+ FILES: Explain csv/json formats [0.1.4 20250424 atangster]
+ General cleanup [0.1.3 20250424 gjw]
+ Resync [0.1.2 20250423 gjw]
+ HOME: Concept dashboard and vaccinations [0.1.1 20250402 misc]
+ Ready for beta release [0.1.0 20250326 gjw]

## 0.0 Initial beta release

+ Deploy navigator [0.0.9 20250218 kev]
+ Refine and add import order lint [0.0.8 20250207 atangster]
+ Refine SURVEY and FILES features [0.0.7 20250120 atangster]
+ Add footer information and links [0.0.6 20250114 atangster]
+ Configure for android build [0.0.5 20250111 gjw]
+ Generate Windows installer exe [0.0.4 20250110 atangster]
+ Cleanup all remaining lint issues [0.0.3 20250110 atangster]
+ Add CI/CM and Lint checks [0.0.2 20250109 atangster]
