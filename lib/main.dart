import 'package:flutter/material.dart';
import 'edit_plan.dart';
import 'meal_tracker_page.dart';
import 'database_helper.dart'; // Import your database helper class

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(),
    );
  }
}
class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, List<Map<String, dynamic>>> groupedMealPlanItems = {};

  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMealPlanItems();
  }

  Future<void> _loadMealPlanItems() async {
    // Use your DatabaseHelper class to fetch all meal plan items
    DatabaseHelper databaseHelper = DatabaseHelper();
    List<Map<String, dynamic>> mealPlanItems = await databaseHelper.getAllMealPlans();

    print('Fetched Meal Plan Items: $mealPlanItems');

    // Group meal plan items by date
    Map<String, List<Map<String, dynamic>>> groupedItems = groupMealPlanItemsByDate(mealPlanItems);

    setState(() {
      groupedMealPlanItems = groupedItems;
    }); // Trigger a rebuild after fetching data
  }


  Map<String, List<Map<String, dynamic>>> groupMealPlanItemsByDate(
      List<Map<String, dynamic>> mealPlanItems) {
    Map<String, List<Map<String, dynamic>>> groupedItems = {};

    for (var item in mealPlanItems) {
      String date = item['date'];

      if (!groupedItems.containsKey(date)) {
        groupedItems[date] = [];
      }

      groupedItems[date]!.add(item);
    }

    return groupedItems;
  }
  void _searchMealPlans(String query) {
    // Filter meal plans based on the search query
    setState(() {
      if (query.isEmpty) {
        // If the search query is empty, display all meal plans
        _loadMealPlanItems();
      } else {
        // If there's a search query, filter meal plans by date
        groupedMealPlanItems = groupMealPlanItemsByDate(
          groupedMealPlanItems.values.expand((items) => items).toList(),
        ).map((date, items) {
          final filteredItems = items
              .where((item) =>
              item['date'].toLowerCase().contains(query.toLowerCase()))
              .toList();

          return MapEntry(date, filteredItems);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home Page'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () async {
                // Navigate to the MealTrackerPage
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MealTrackerPage()),
                );

                // When returning from MealTrackerPage, refresh the meal plans
                _loadMealPlanItems();
              },
              child: Text('Create a New Meal Plan'),
            ),
            SizedBox(height: 20),
            Padding(
              padding: EdgeInsets.all(10),
              child: TextField(
                controller: searchController,
                onChanged: _searchMealPlans,
                decoration: InputDecoration(
                  labelText: 'Search by Date',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: () {
                      searchController.clear();
                      _searchMealPlans('');
                    },
                  ),
                ),
              ),
            ),
            // Display grouped meal plan items
            Expanded(
              child: ListView(
                children: groupedMealPlanItems.entries.map((entry) {
                  String date = entry.key;
                  List<Map<String, dynamic>> items = entry.value;

                  return Card(
                    margin: EdgeInsets.all(10),
                    child: InkWell(
                      onTap: () {
                        // Navigate to the EditMealPlanPage
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditMealPlanPage(
                              date: date,
                              initialFoodItems: items,
                            ),
                          ),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            title: Text('Meal Plan Date: $date'),
                          ),
                          for (var item in items)
                            ListTile(
                              title: Text('${item['name']}'),
                              subtitle: Text('${item['calories']} calories'),
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }


}
