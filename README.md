# unified_local_data

Engine-agnostic local storage for Flutter: one API over Hive, Isar or your own engine, with typed objects, queries, reactive streams and transactions.

| Package | What it is | pub.dev |
|---|---|---|
| [`unified_local_data`](packages/unified_local_data) | The API, the factory and the Hive engine. Runs on every Flutter platform, the web included. | [![pub](https://img.shields.io/pub/v/unified_local_data)](https://pub.dev/packages/unified_local_data) |
| [`unified_local_data_isar`](packages/unified_local_data_isar) | The Isar engine. Every platform but the web. | [![pub](https://img.shields.io/pub/v/unified_local_data_isar)](https://pub.dev/packages/unified_local_data_isar) |

Start with the [`unified_local_data` README](packages/unified_local_data/README.md).

## Development

Each package is its own Flutter package; run commands inside its folder.

```bash
cd packages/unified_local_data
flutter pub get
flutter analyze
flutter test
```

`packages/unified_local_data_isar` builds against the `unified_local_data` in this repository through its `pubspec_overrides.yaml`, which isn't published.

Publish `unified_local_data` before a `unified_local_data_isar` release that needs its new version.

## License

MIT. See [LICENSE](LICENSE).
