import 'dart:collection';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async{
WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(InventoryApp());
}

class InventoryApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inventory Management App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: InventoryHomePage(title: 'Inventory Home Page'),
    );
  }
}

class InventoryHomePage extends StatefulWidget {
  final String title;
  
  InventoryHomePage({Key? key, required this.title}) : super(key: key);

  @override
  _InventoryHomePageState createState() => _InventoryHomePageState();
}

class _InventoryHomePageState extends State<InventoryHomePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const List<String> dropdownmenuList = <String> ['high','medium','low'];

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: StreamBuilder(
        stream: _firestore.collection('checkList').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No inventory items available.'));
          }
          return ListView(
            children: snapshot.data!.docs.map((doc) {
              var data = doc.data() as Map<String, dynamic>;
              return ListTile(
                title: Text(data['name'] ?? 'Unnamed Item'),
                subtitle: Text('priority: ${data['priority'] ?? 0}'),
                trailing: IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () => _deleteItem(doc.id),
                ),
                onTap: () => _editItem(doc.id, data),
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addItem,
        tooltip: 'Add Item',
        child: Icon(Icons.add),
      ),
    );
  }

  void _addItem() {
    showDialog(
      context: context,
      builder: (context) {
         
        String dropDownMenuValue = dropdownmenuList.first;
        TextEditingController nameController = TextEditingController();
        TextEditingController quantityController = TextEditingController();
        int priority_value = 0;
        return AlertDialog(
          title: Text('Add Inventory Item'),
          content: StatefulBuilder(
            builder: (context, setState)  {
                 return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: InputDecoration(labelText: 'Item Name')),
              TextField(controller: quantityController, decoration: InputDecoration(labelText: 'Priority'), keyboardType: TextInputType.number),
              DropdownButton<String>(
                value: dropDownMenuValue,
                items: dropdownmenuList.map<DropdownMenuItem<String>>((String value){
                      return DropdownMenuItem<String>(value: value, child:
                      Text(value));
                }).toList(),

                
               
                onChanged: (String? value) { 
                  setState(() {
                    dropDownMenuValue = value!;
                    if(dropDownMenuValue == "high"){
                      priority_value = 3;
                    }
                    else if (dropDownMenuValue == "medium"){
                      priority_value = 2;
                    }
                    else{
                      priority_value = 1;
                    }
                  });

                 },
                
                
                ),
            ],
          );
            }
           
          
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _firestore.collection('inventory').add({
                  'name': nameController.text,
                  //'priority': int.tryParse(quantityController.text) ?? 0,
                  'priority': dropDownMenuValue,
                  'priority_value': priority_value
                });
                Navigator.pop(context);
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _editItem(String id, Map<String, dynamic> data) {
    TextEditingController nameController = TextEditingController(text: data['name']);
    TextEditingController quantityController = TextEditingController(text: data['priority'].toString());
    int priority_value = 0;
    String dropDownMenuValue = dropdownmenuList.first;
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Inventory Item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: InputDecoration(labelText: 'Item Name')),
              TextField(controller: quantityController, decoration: InputDecoration(labelText: 'Priority'), keyboardType: TextInputType.number),
              DropdownButton<String>(
                value: dropDownMenuValue,
                items: dropdownmenuList.map<DropdownMenuItem<String>>((String value){
                      return DropdownMenuItem<String>(value: value, child:
                      Text(value));
                }).toList(),

                
               
                onChanged: (String? value) { 
                  setState(() {
                    dropDownMenuValue = value!;
                    if(dropDownMenuValue == "high"){
                      priority_value = 3;
                    }
                    else if (dropDownMenuValue == "medium"){
                      priority_value = 2;
                    }
                    else{
                      priority_value = 1;
                    }
                  });

                 },
                
                
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _firestore.collection('checkList').doc(id).update({
                  'name': nameController.text,
                 // 'quantity': int.tryParse(quantityController.text) ?? 0,
                  'priority': dropDownMenuValue,
                  'priority_value': priority_value
                });
                Navigator.pop(context);
              },
              child: Text('Update'),
            ),
          ],
        );
      },
    );
  }

  void _deleteItem(String id) {
    _firestore.collection('checkList').doc(id).delete();
  }
}
