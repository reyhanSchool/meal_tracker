import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

class MealTrackerPage extends StatefulWidget {
  get initialFoodItems => null;

  @override
  _MealTrackerPageState createState() => _MealTrackerPageState();
}

class _MealTrackerPageState extends State<MealTrackerPage> {
  DatabaseHelper databaseHelper = DatabaseHelper();
  TextEditingController targetCaloriesController = TextEditingController();
  DateTime selectedDate = DateTime.now();
  List<String> availableFoodItems = [];
  List<Map<String, dynamic>> availableFoodItemsDetails = [];
  Set<int> selectedFoodItemIds = {};

  List<String> selectedFoodItems = [];
  List<Map<String, dynamic>> selectedFoodItemsDetails = [];

  @override
  void initState() {
    super.initState();
    _loadAvailableFoodItems();
  }

  Future<void> _loadAvailableFoodItems() async {
    Database db = await databaseHelper.database;
    List<Map<String, dynamic>> foods = await db.query('foods');

    setState(() {
      availableFoodItemsDetails = foods;
      availableFoodItems = foods.map((food) => food['name'] as String).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Meal Tracker'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: targetCaloriesController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Target Calories per Day'),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Text('Selected Date: ${selectedDate.toLocal()}'),
                IconButton(
                  icon: Icon(Icons.calendar_today),
                  onPressed: () => _selectDate(context),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text('Available Food Items:'),
            Expanded(
              child: ListView.builder(
                itemCount: availableFoodItemsDetails.length,
                itemBuilder: (context, index) {
                  Map<String, dynamic> foodItem = availableFoodItemsDetails[index];
                  int foodItemId = foodItem['id'] as int;

                  return ListTile(
                    title: Text(foodItem['name']),
                    // Use Icons.check_circle if the food item is selected, Icons.check_circle_outline otherwise
                    leading: Icon(
                      selectedFoodItemIds.contains(foodItemId)
                          ? Icons.check_circle
                          : Icons.check_circle_outline,
                      color: Colors.blue,
                    ),
                    onTap: () => _toggleFoodItem(foodItemId),
                  );
                },
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Total Calories: ${_calculateTotalCalories()}',
              style: _calculateTotalCalories() > (int.tryParse(targetCaloriesController.text) ?? 0)
                  ? TextStyle(color: Colors.red)
                  : null,
            ),
            if (_calculateTotalCalories() > (int.tryParse(targetCaloriesController.text) ?? 0))
              Text(
                'Calorie Limit Exceeded',
                style: TextStyle(color: Colors.red),
              ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _addToMealPlan(),
              child: Text('Add to Meal Plan'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime picked = (await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    ))!;
    if (picked != null && picked != selectedDate)
      setState(() {
        selectedDate = picked;
      });
  }

  void _selectFoodItem(Map<String, dynamic> foodDetails) {
    setState(() {
      if (selectedFoodItemsDetails.contains(foodDetails)) {
        selectedFoodItemsDetails.remove(foodDetails);
      } else {
        selectedFoodItemsDetails.add(foodDetails);
      }
    });
  }
  int _calculateTotalCalories() {
    int totalCalories = 0;
    for (var foodId in selectedFoodItemIds) {
      // Find the selected food item by its ID
      Map<String, dynamic>? selectedFoodItem = availableFoodItemsDetails.firstWhere(
            (food) => food['id'] == foodId,
        orElse: () => Map<String, dynamic>(),
      );
      totalCalories += selectedFoodItem['calories'] as int;
    }
    return totalCalories;
  }
  void _addToMealPlan() async {
    int targetCalories = int.tryParse(targetCaloriesController.text) ?? 0;

    await databaseHelper.insertMealPlan(selectedDate, selectedFoodItemsDetails);

    print('Meal Plan added to the database:');
    print('Target Calories: $targetCalories');
    print('Selected Date: ${selectedDate.toLocal()}');
    print('Selected Food Items: $selectedFoodItemsDetails');
    print('Total Calories: ${_calculateTotalCalories()}');
  }



// Function to toggle the selection of a food item
  void _toggleFoodItem(int foodItemId) {
    setState(() {
      if (selectedFoodItemIds.contains(foodItemId)) {
        selectedFoodItemIds.remove(foodItemId);
        selectedFoodItemsDetails.removeWhere((item) => item['id'] == foodItemId);
      } else {
        selectedFoodItemIds.add(foodItemId);
        Map<String, dynamic>? selectedFoodItem = availableFoodItemsDetails
            .firstWhere((food) => food['id'] == foodItemId);
        if (selectedFoodItem != null) {
          selectedFoodItemsDetails.add(selectedFoodItem);
        }
      }
    });
  }

}
