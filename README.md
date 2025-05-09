# Health Pod

The Health Pod collects into one private and secure location all of
your health data and medical records. Value is added to the data
through various provided tools, including privacy preserving large
language models. You collect your health data together and then you
can interact with it to review your health. You can also decide if you
want to share that data with anyone else, like you general
practitioner for them to provide their professional advice.

Visit https://healthpod.solidcommunity.au/ to run the app online.

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

+ Obs (A feature to record daily or regular observations like
  blood pressure, physical activity, etc)

+ Activity (A record of activities recording date, start, end, what)

+ Diary (A record of visits to doctors, dentists, pharmacy,
  vaccinations, etc. Each diary entry records: date, what, details,
  provider, professional, total, covered, cost)

+ Docs (A file browser type of thing where the user can arrange their
  PDFs into appropriate folders as they like.)

## Use Cases

+ I am visiting the doctor and I need to check when I last had a
  vaccination

+ A LLM model runs over the whole contents of the Pod to then allow me
  to interact with the data collection.
