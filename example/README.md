# cell_info example

Test bench for the `cell_info` plugin on a real device or an emulator.

```sh
flutter run
```

* **Permissions** card: state of location and phone permission, with a button to request them
  (and a shortcut to the app settings once Android stops asking).
* Status line: what the plugin returned, including the `null` it returns without permissions.
* SIM cards, primary and neighbouring cells, and the raw JSON.

Automated check on a device: `../tool/device_test.sh [device-id]`.

The application id is `com.specure.nettest.cell_info_example`, so it installs next to the original
example app instead of replacing it.
