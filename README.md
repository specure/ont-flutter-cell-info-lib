# cell_info

Flutter plugin (Android only) that reports the cells a phone sees (GSM, CDMA, WCDMA, TD-SCDMA,
LTE, NR) and its active SIM cards. Cell data comes from
[NetMonster Core](https://github.com/mroczis/netmonster-core), SIM data from the Android SDK.

## Usage

```dart
import 'dart:convert';

import 'package:cell_info/CellResponse.dart';
import 'package:cell_info/SIMInfoResponse.dart';
import 'package:cell_info/cell_info.dart';

final String? cellsJson = await CellInfo.getCellInfo;
if (cellsJson != null) {
  final cells = CellsResponse.fromJson(json.decode(cellsJson));
  print(cells.primaryCellList?.first.lte?.signalLTE?.rsrp);
}

final String? simsJson = await CellInfo.getSIMInfo;
if (simsJson != null) {
  final sims = SIMInfoResponse.fromJson(json.decode(simsJson));
}
```

Both calls return `null` until the app holds **both** runtime permissions:

| Permission             | Why                                   |
|------------------------|---------------------------------------|
| `ACCESS_FINE_LOCATION` | Android treats cell identity as location |
| `READ_PHONE_STATE`     | network type, SIM subscriptions       |

The plugin declares them in its manifest but does not request them; the app has to (the example
uses `permission_handler`). Native failures surface as a `PlatformException` with the code
`CELL_INFO_ERROR`.

Besides `primaryCellList` and `neighboringCellList`, the JSON carries data the Dart models do not
expose: `cellDataList` (a flat record per cell plus device details) and, on primary cells,
`networkType`, `nrAvailable`, `enDcAvailable`, `nrConnected`, `nrConnectionStatus` and
`nrRejectedReason`. Read those from the decoded JSON.

## How NetMonster Core is included

NetMonster Core is **not** copied into this repository. `android/netmonster.properties` pins one
upstream commit:

```properties
repository=https://github.com/mroczis/netmonster-core.git
commit=27f8803c08524aa0295d448122d0873e30dc1835
```

The Gradle task `fetchNetMonsterCore` (in `android/build.gradle.kts`) fetches exactly that commit
with git and compiles the library sources into the plugin. Git verifies the content against the
SHA, and the result is cached in the build directory, so the network is only used after the pin
changes or after `flutter clean`. Building therefore needs `git` on the PATH.

Upstream is fetched from source because it has no per-commit artifacts: JitPack fails to build
its current commits, and Maven Central only has tagged releases.

## Updating NetMonster Core

```sh
tool/update_netmonster.sh            # upstream HEAD, or pass a commit SHA / branch / tag
tool/device_test.sh                  # then confirm on a device or emulator
```

`update_netmonster.sh` rewrites the pin and runs `tool/test.sh`. What the result means:

| Result | Meaning |
|---|---|
| Kotlin fails to compile | Upstream changed an API the plugin uses. Adapt the Kotlin code. |
| A fixture comparison fails | The JSON delivered to Flutter changed. If intended: `tool/test.sh --update-fixtures`, review `git diff test/fixtures`, adapt the Dart models. |
| All green | The Flutter-facing interface is unchanged. |

## Tests

| Where | What it pins |
|---|---|
| `android/src/test/.../CellsResponseContractTest.kt` | Builds NetMonster Core models, runs the plugin's mapping and compares the JSON with `test/fixtures/*.json`. |
| `test/cells_contract_test.dart` | The Dart models parse those same fixtures and understand every key in them. |
| `test/cell_info_test.dart` | Channel names, method names, `null` and error handling of `CellInfo`. |
| `test/sim_info_contract_test.dart` | JSON shape of the SIM info. |
| `example/integration_test/` | Real plugin on a device: `null` without permissions, contract-conforming JSON with them. |

`tool/test.sh` runs everything that needs no device; `tool/device_test.sh [device-id]` runs the
integration test twice (permissions revoked, then granted through adb).

## Example app

```sh
cd example
flutter run
```

It shows the state of both permissions, lets you request them, tells you what the plugin
returned (including the `null` it returns without permissions) and lists SIMs, cells and the raw
JSON. On an emulator the modem is simulated, so expect one LTE cell and no roaming.

## Known quirks kept for compatibility

These are part of the JSON existing apps already consume, so they were preserved and are pinned
by the tests:

- CDMA cells have the outer `type` `"WCDMA"` (the nested `cdma.type` is `"CDMA"`).
- `networkType` is the string `"null"` when no network type was detected for a subscription.
- `bandWCDMA` never contains `downlinkUarfcn` (it is present in `cellDataList`).
- In `cellDataList`, GSM entries lack `mcc`/`mnc`/`iso`, LTE entries lack `pci`, and `ncc`/`bcc`
  are never filled.
- Roaming is reported as `false` on emulators.
- `DetectorLteAdvancedPhysicalChannel` and `DetectorLteAdvancedCellInfo` are not used for network
  type detection because they mixed up LTE and NR on dual SIM devices.

## License

BSD 2-Clause, see [LICENSE](LICENSE). The Dart and Kotlin model classes and the public API derive
from [eslamfaisal/FlutterCellInfo](https://github.com/eslamfaisal/FlutterCellInfo), whose copyright
notice the licence requires to be kept. NetMonster Core is licensed under Apache 2.0 and is
compiled into the plugin, so apps shipping it must honour that licence too.
