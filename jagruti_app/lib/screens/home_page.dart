import 'package:flutter/material.dart';
import '../db/database_helper.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> contacts = [];
  List<Map<String, dynamic>> filteredContacts = [];

  TextEditingController searchController = TextEditingController();
  String selectedPlace = "All";

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  void _loadContacts() async {
    contacts = await DatabaseHelper().getContacts(); // Use the Singleton
    _applyFilters();
  }

  void _applyFilters() {
    String searchText = searchController.text.toLowerCase();
    setState(() {
      filteredContacts = contacts.where((contact) {
        String name = contact['Name']?.toLowerCase() ?? "";
        String surname = contact['Surname']?.toLowerCase() ?? "";
        String place = contact['Place']?.toLowerCase() ?? "";

        bool matchesSearch = name.contains(searchText) || surname.contains(searchText);
        bool matchesPlace = (selectedPlace == "All" || place == selectedPlace.toLowerCase());

        return matchesSearch && matchesPlace;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(
              'Jagruti',
              style: TextStyle(
                fontFamily: 'Century Gothic', // Apply the font
                fontSize: 24, // Adjust as needed
                fontWeight: FontWeight.bold,
                color: const Color.fromARGB(255, 69, 9, 80),  // Optional: bold style
              ),
            ),),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: "Search by Name or Surname",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onChanged: (value) => _applyFilters(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: DropdownButton<String>(
              isExpanded: true,
              value: selectedPlace,
              items: ["All", ...contacts.map((c) => c['Place']?.toString().trim() ?? "Unknown").toSet()]
                  .map<DropdownMenuItem<String>>((String place) {
                return DropdownMenuItem<String>(
                  value: place,
                  child: Text(place),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedPlace = value!;
                  _applyFilters();
                });
              },
            ),
          ),
          Expanded(
            child: filteredContacts.isEmpty
                ? Center(child: Text("No contacts found"))
                : ListView.builder(
                    itemCount: filteredContacts.length,
                    itemBuilder: (context, index) {
                      final contact = filteredContacts[index];

                      String title = (contact['Title'] ?? " ").toString();
                      String surname = (contact['Surname'] ?? "Unknown Name").toString();
                      String name = (contact['Name'] ?? "Unknown Name").toString();
                      String dob = (contact['DOB'] ?? "Unknown Place").toString();
                      String place = (contact['Place'] ?? "Unknown Place").toString();
                      String phone = (contact['Phone'] ?? "No Phone Number").toString();
                      String email = (contact['Email ID'] ?? "No Email").toString();
                      String address = (contact['Address'] ?? "No Email").toString();

                      return Card(
                        elevation: 4,
                        margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: ListTile(
                          title: Text("$title $surname $name"),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(address), // Added email here
                              Text("(M): $phone | (E):$email"),
                              
                            ],
                          ),
                          leading: CircleAvatar(child: Text(name.isNotEmpty ? name[0] : "?")),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}