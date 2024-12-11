import 'package:location_platform_interface/location_platform_interface.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static Database? _database;

  // Get the database
  Future<Database> get database async {
    if (_database != null) return _database!;

    // If database doesn't exist, create it
    _database = await _initDatabase();
    return _database!;
  }

  // Initialize the database
  Future<Database> _initDatabase() async {
    // Get the path to the database file
    String path = join(await getDatabasesPath(), 'locations.db');

    // Open the database (if it doesn't exist, it will be created)
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Create tables here, for example:
        await db.execute('''
          CREATE TABLE packages(
            id INTEGER PRIMARY KEY,
            package_name TEXT,
            latitude REAL,
            longitude REAL,
            radius REAL,
            description TEXT,
            image_url TEXT
          )
        ''');
      },
    );
  }

  // Example function to fetch location packages (customize based on your actual schema)
  Future<List<Map<String, dynamic>>> fetchLocationPackages(LocationData userLocation) async {
    final db = await database;

    // Replace the query with the actual query to get location packages
    var result = await db.query('packages'); // Replace 'packages' with the actual table name
    return result;
  }
}
