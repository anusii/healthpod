# Health Pod &mdash; Collect Your Health Data in your Data Vault

**An ANU Software Innovation Institute demonstrator for your Data Vault**.

*Time-stamp: <Monday 2025-08-25 11:18:41 +1000 Graham Williams>*

*Authors: Ashley Tang, Graham Williams, Zheyuan Xu, Kevin Wang*

*[ANU Software Innovation Institute](https://sii.anu.edu.au)*

*License: GNU GPL V3*

[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)

[![GitHub License](https://img.shields.io/github/license/anusii/healthpod)](https://github.com/anusii/healthpod/blob/dev/LICENSE)
[![Flutter Version](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/anusii/healthpod/master/pubspec.yaml&query=$.version&label=version)](https://github.com/anusii/healthpod/blob/dev/CHANGELOG.md)
[![Last Updated](https://img.shields.io/github/last-commit/anusii/healthpod?label=last%20updated)](https://github.com/anusii/healthpod/commits/dev/)
[![GitHub commit activity (dev)](https://img.shields.io/github/commit-activity/w/anusii/healthpod/dev)](https://github.com/anusii/healthpod/commits/dev/)
[![GitHub Issues](https://img.shields.io/github/issues/anusii/healthpod)](https://github.com/anusii/healthpod/issues)

Run the app online: [**web**](https://healthpod.solidcommunity.au).

Download the latest version:
**GNU/Linux**
[deb](https://solidcommunity.au/installers/healthpod_amd64.deb) or
[zip](https://solidcommunity.au/installers/healthpod-dev-linux.zip);
**Android**
[apk](https://solidcommunity.au/installers/healthpod.apk);
**macOS**
[zip](https://solidcommunity.au/installers/healthpod-dev-macos.zip);
**Windows**
[zip](https://solidcommunity.au/installers/healthpod-dev-windows.zip) or
[inno](https://solidcommunity.au/installers/healthpod-dev-windows-inno.exe).

Coding documentation is available from [solid community
au](https://solidcommunity.au/docs/healthpod)

The Health Pod collects into one private and secure location all of
your health data and medical records. Value is added to the data
through various provided tools, including privacy preserving large
language models. You collect your health data together and then you
can interact with it to review your health. You can also decide if you
want to share that data with anyone else, like you general
practitioner for them to provide their professional advice.

Visit
[https://healthpod.solidcommunity.au/](https://healthpod.solidcommunity.au/)
to run the app online.

See [installers](installers/README.md) for instructions to install on
your device.

Visit the [Solid Community AU Portfolio](https://solidcommunity.au)
for our portfolio of Solid apps developed by the community.

The app is implemented in [Flutter](https://flutter.dev) using our own
[solidpod](https://pub.dev/packages/solidpod) package for Flutter to
manage the Solid Pod interactions, and
[markdown_tooltip](https://pub.dev/packages/markdown_tooltip) to
enhance the user experience, guiding the user through the app, within
app.

## Milestones

- [X] Basic Icon-Based GUI with Solid Pod login
- [X] Profile management with personalized profile photo upload
- [ ] File browse my medical reports
- [ ] Daily entry of Blood Pressure with visualisations
- [ ] Your latest clinic data - appointments and medicines
- [ ] Important medical information, notes and numbers
- [ ] My vaccination history

## Design Goals

The app will work well on a desktop, web browser, a mobile phone or
tablet.

A grid of icons provides access to the functionality.

The grid items include:

- Obs (A feature to record daily or regular observations like
  blood pressure, physical activity, etc)

- Activity (A record of activities recording date, start, end, what)

- Diary (A record of visits to doctors, dentists, pharmacy,
  vaccinations, etc. Each diary entry records: date, what, details,
  provider, professional, total, covered, cost)

- Docs (A file browser type of thing where the user can arrange their
  PDFs into appropriate folders as they like.)

## Use Cases

- I am visiting the doctor and I need to check when I last had a
  vaccination

- A LLM model runs over the whole contents of the Pod to then allow me
  to interact with the data collection.
