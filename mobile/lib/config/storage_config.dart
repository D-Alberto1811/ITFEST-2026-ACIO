enum StorageMode {
  server,
  sqlite,
}

/// Change only this line when you want to switch storage.
///
/// StorageMode.server  -> current backend/server auth
/// StorageMode.sqlite  -> local SQLite auth
const StorageMode appStorageMode = StorageMode.sqlite;

bool get isServerMode => appStorageMode == StorageMode.server;
bool get isSqliteMode => appStorageMode == StorageMode.sqlite;