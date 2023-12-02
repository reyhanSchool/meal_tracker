import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await initDatabase();
    return _database!;
  }

  Future<Database> initDatabase() async {
    final documentsDirectory = await getDatabasesPath();
    final path = join(documentsDirectory, 'meal_tracker_database.db');
    return await openDatabase(path, version: 6, onCreate: _createDatabase, onUpgrade: _onUpgrade);
  }
  Future<void> updateMealPlan(
      String date,
      int targetCalories,
      List<Map<String, dynamic>> selectedFoodItems,
      ) async {
    Database db = await database;

    // Update target calories in the 'meal_plans' table
    await db.update(
      'meal_plans',
      {'target_calories': targetCalories},
      where: 'date = ?',
      whereArgs: [date],
    );

    // Clear existing food items for the specified date
    await db.delete('meal_plans', where: 'date = ?', whereArgs: [date]);

    // Insert updated food items for the specified date
    await insertMealPlan(DateTime.parse(date), selectedFoodItems);
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
    CREATE TABLE foods (
      id INTEGER PRIMARY KEY,
      name TEXT,
      calories INTEGER
    )
  ''');
    await insertInitialFoods(
        db); // Call insertInitialFoods after creating tables

    await db.execute('''
  CREATE TABLE meal_plans (
    id INTEGER PRIMARY KEY,
    date TEXT,
    target_calories INTEGER,
    food_id INTEGER,
    FOREIGN KEY (food_id) REFERENCES foods (id)
  )
''');
  }

  Future<void> deleteMealPlan(String date) async {
    Database db = await database;

    // Delete the entire meal plan for the given date
    await db.delete('meal_plans', where: 'date = ?', whereArgs: [date]);
  }

  Future<void> insertInitialFoods(Database db) async {
    var batch = db.batch();

    // List of foods with their calories and names
    List<Map<String, dynamic>> foods = [
      {'name': 'Apple', 'calories': 52},
      {'name': 'Banana', 'calories': 105},
      {'name': 'Chicken Breast', 'calories': 165},
      {'name': 'Salad', 'calories': 50},
      {'name': 'Pizza Slice', 'calories': 285},
      {'name': 'Broccoli', 'calories': 31},
      {'name': 'Salmon', 'calories': 206},
      {'name': 'Pasta', 'calories': 200},
      {'name': 'Yogurt', 'calories': 150},
      {'name': 'Carrot Sticks', 'calories': 25},
      {'name': 'Almonds', 'calories': 7},
      {'name': 'Chocolate Bar', 'calories': 230},
      {'name': 'Spinach', 'calories': 23},
      {'name': 'Oatmeal', 'calories': 150},
      {'name': 'Orange', 'calories': 62},
      {'name': 'Egg', 'calories': 68},
      {'name': 'Grapes', 'calories': 52},
      {'name': 'Cheese', 'calories': 110},
      {'name': 'Rice', 'calories': 130},
      {'name': 'Tomato', 'calories': 22},
    ];
    for (var food in foods) {
      batch.insert('foods', food);
    }
    await batch.commit();
  }

  Future<void> insertMealPlan(DateTime date, List<Map<String, dynamic>> selectedFoodItems) async {
    Database db = await database;
    var batch = db.batch();

    for (var food in selectedFoodItems) {
      batch.insert('meal_plans', {
        'date': date.toIso8601String(),
        'food_id': food['id'],
      });
    }

    await batch.commit();
  }

  Future<List<Map<String, dynamic>>> getMealPlan(DateTime date) async {
    Database db = await database;

    // Query meal_plans for the specified date
    List<Map<String, dynamic>> mealPlans = await db.rawQuery('''
    SELECT * FROM meal_plans WHERE date = ?
  ''', [date.toIso8601String()]);

    if (mealPlans.isEmpty) {
      // If no meal plans for the specified date, return an empty list
      return [];
    }

    // Extract food_ids from meal plans
    List<int> foodIds = mealPlans.map((mealPlan) => mealPlan['food_id'] as int).toList();

    // Query foods using the extracted food_ids
    return await db.query('foods', where: 'id IN (${foodIds.join(",")})');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Delete existing tables
    await db.execute('DROP TABLE IF EXISTS foods');
    await db.execute('DROP TABLE IF EXISTS meal_plans');

    // Recreate tables and insert initial data
    await _createDatabase(db, newVersion);
  }

  Future<List<Map<String, dynamic>>> getAllMealPlans() async {
    Database db = await database;

    // Join 'meal_plans' with 'foods' to get name and calories
    return await db.rawQuery('''
    SELECT meal_plans.*, foods.name, foods.calories
    FROM meal_plans
    JOIN foods ON meal_plans.food_id = foods.id
  ''');
  }


}
