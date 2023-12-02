// edit_meal_plan_page.dart
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

class EditMealPlanPage extends StatefulWidget {
  final String date;
  final List<Map<String, dynamic>> initialFoodItems;

  const EditMealPlanPage({
    Key? key,
    required this.date,
    required this.initialFoodItems,
  }) : super(key: key);

  @override
  _EditMealPlanPageState createState() => _EditMealPlanPageState();
}

class _EditMealPlanPageState extends State<EditMealPlanPage> {
  TextEditingController targetCaloriesController = TextEditingController();
  DateTime selectedDate = DateTime.now();
  List<Map<String, dynamic>> selectedFoodItemsDetails = [];
  List<Map<String, dynamic>> availableFoodItemsDetails = [];
  List<String> selectedFoodItems = [];
  late DatabaseHelper databaseHelper;
  Set<int> selectedFoodItemIds = {};

  @override
  void initState() {
    super.initState();
    databaseHelper = DatabaseHelper();
    _loadAvailableFoodItems();
    _loadInitialData();
  }

  Future<void> _loadAvailableFoodItems() async {
    Database db = await databaseHelper.database;
    List<Map<String, dynamic>> foods = await db.query('foods');

    setState(() {
      availableFoodItemsDetails = foods;
    });
  }

  void _loadInitialData() {
    // Load initial data from widget's properties
    targetCaloriesController.text = "Initial Target Calories"; // Replace with actual data

    // Convert the date string to DateTime
    selectedDate = DateTime.parse(widget.date);

    // Load initial food items
    selectedFoodItemsDetails = List.from(widget.initialFoodItems);

    // Extract the selected food item IDs
    selectedFoodItemIds = Set<int>.from(selectedFoodItemsDetails.map((item) => item['id'] as int));

    // If no initial food items are selected, initialize with the available food item IDs
    if (selectedFoodItemsDetails.isEmpty) {
      selectedFoodItemIds = Set<int>.from(availableFoodItemsDetails.map((item) => item['id'] as int));
    }
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Meal Plan'),
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
            ElevatedButton(
              onPressed: () => _deleteMealPlan(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, // Set the background color to red
              ),
              child: Text('Delete Meal Plan'),
            ),

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
              )
            ),
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
              onPressed: () => _saveChanges(),
              child: Text('Save Changes'),
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
  Future<void> _deleteMealPlan() async {
    // Show a confirmation dialog
    bool confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete the entire meal plan for this date?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    // If the user confirms deletion, proceed
    if (confirmDelete == true) {
      // Delete the entire meal plan in the database
      await databaseHelper.deleteMealPlan(widget.date);

      // Optionally, you can navigate back or perform any other actions
      Navigator.pop(context);
    }
  }

  void _toggleFoodItem(int foodItemId) {
    setState(() {
      Map<String, dynamic> selectedFoodItem = availableFoodItemsDetails
          .firstWhere((food) => food['id'] == foodItemId, orElse: () => Map<String, dynamic>.from({}));
      String foodItemName = selectedFoodItem['name'];

      if (selectedFoodItemIds.contains(foodItemId)) {
        // If the food item is already selected, remove it
        selectedFoodItemsDetails.removeWhere((item) => item['name'] == foodItemName);
        selectedFoodItemIds.remove(foodItemId);
        selectedFoodItems.remove(foodItemName);
        print(foodItemName);
      } else {
        // If the food item is not selected, add it
        selectedFoodItemsDetails.add(selectedFoodItem);
        selectedFoodItemIds.add(foodItemId);
        selectedFoodItems.add(foodItemName);
        print(foodItemName);
      }
    });
  }


  int _calculateTotalCalories() {
    int totalCalories = 0;
    for (var food in selectedFoodItemsDetails) {
      totalCalories += food['calories'] as int;
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

  Future<void> _saveChanges() async {
    int targetCalories = int.tryParse(targetCaloriesController.text) ?? 0;

    // Get the currently selected food items
    List<Map<String, dynamic>> currentSelectedFoodItemsDetails = List.from(selectedFoodItemsDetails);

    // Update the meal plan in the database
    await databaseHelper.updateMealPlan(widget.date, targetCalories, currentSelectedFoodItemsDetails);

    // Print or log the updated meal plan details
    print('Meal Plan updated in the database:');
    print('Target Calories: $targetCalories');
    print('Selected Date: ${selectedDate.toLocal()}');
    print('Selected Food Items: $currentSelectedFoodItemsDetails');
    print('Total Calories: ${_calculateTotalCalories()}');
    selectedFoodItems = [];
    // Optionally, you can navigate back to the previous screen or perform any other actions
    Navigator.pop(context); // This will pop the current screen off the navigation stack
  }

}
