## 1.0.0

* The Isar engine of `unified_local_data`, as its own package. Until `unified_local_data` 2.0.0 it was part of that package.
* `IsarDataSourceConfig.schemas` is optional and typed as `List<CollectionSchema<dynamic>>`.
* Includes the fixes from `unified_local_data` 1.2.1: writes inside `transaction()` join it and roll back together, and `drop()` with no collection works.
* Compiles against any Isar Community 3.x release from 3.4.1 on.
