import 'package:uuid/uuid.dart';

const Uuid _uuid = Uuid();

/// A primary key for a row this device is about to create.
///
/// Every id column in the schema is `uuid`, so anything the client invents has
/// to be a real UUID: Postgres rejects `manual-1788...` or `<capture>-0` with
/// a type error, and the insert fails with nothing on screen to explain it.
String newId() => _uuid.v4();
