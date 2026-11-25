## 0.2.0

Rewrite of the plugin with an unchanged Dart API and JSON contract.

* NetMonster Core is no longer copied into the plugin. It is fetched at the commit pinned in
  `android/netmonster.properties` (now `27f8803`, previously a copy of `75f5511`).
* Contract tests (Kotlin + Dart, shared fixtures) and an on-device integration test.
* New example app with a permission flow.
* Android: minSdk 24, compileSdk 37, AGP 9.3.1, Kotlin 2.4.20, Gradle 9.5.0. iOS stub removed.
* Native errors are reported as `PlatformException(CELL_INFO_ERROR)` instead of crashing the app.
* Fixed: `SignalCDMA.cdmaEcio` / `evdoEcio` are `double?` (parsing threw for any real value).
* Removed the unused `flare_flutter` dependency.
* Added R8 consumer rules so the JSON keys survive minification.
