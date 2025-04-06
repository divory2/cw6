import 'dart:collection';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
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
  static const List<String> dropdownmenuList = <String> ['','high','medium','low',];
  static const List<String> dropdownCompletionmenuList = <String> ['','incomplete','complete'];
  Map<String, bool> selectedTaskList = {};
  List <String> checked = [];
  List<String> unchecked=[];
  String? _filterPriority;
  String? _filterCompletionStatus;
  bool? _completionStatusFilter;
  
  void _selectedTask(bool ?status, String name,String id){
   selectedTaskList[name]= status??false;
   setState(() {
     if(status == true){
      if(!checked.contains(name)){
          unchecked.remove(name);
          checked.add(name);
           
      }
      
    }
    else{
      if(!unchecked.contains(name)){
          checked.remove(name);
          unchecked.add(name);
          

      }
    }

   });
   _firestore.collection('checkList').doc(id).update({
                 'completionstatus': status??false
                });
    
  }
  String _sortOrder= 'none';
   String dropDownMenuValue = dropdownmenuList.first;
  @override
  Widget build(BuildContext context) {
    Query<Map<String, dynamic>> query = _firestore.collection('checkList');
     // Apply priority filter if selected
  if (_filterPriority != null && _filterPriority!.isNotEmpty) {
    query = query.where('priority', isEqualTo: _filterPriority);
  }

  // Apply completion status filter if selected
  if (_filterCompletionStatus != null && _filterCompletionStatus!.isNotEmpty) {
    bool completionStatus = _filterCompletionStatus == 'complete';
    query = query.where('completionstatus', isEqualTo: completionStatus);
  }
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        
      ),
     

      body:Column( 
        children: [
          PopupMenuButton(itemBuilder: (context)=> 
          [
            PopupMenuItem(value: "High to Low",child: 
                            Text("High to Low"),),
            PopupMenuItem(value: "Low to High",child: 
                            Text("Low to High"),),
                          PopupMenuItem(value: "Due Date To Earliest",child: 
                            Text("Due Date To Earliest"),),
                          PopupMenuItem(value: "Due Date To Latest",child: 
                            Text("Due Date To Latest"),),
                           PopupMenuItem(value: "Incomplet To Completed",child: 
                            Text("Incomplet To Completed"),),
                          PopupMenuItem(value: "Complet To Incompleted",child: 
                            Text("Complet To Incompleted"),),
            

          ],
          onSelected: (String value) {
            setState(() {
              _sortOrder = value;
            });
          },
          ),
          SizedBox(width: 20,),
           DropdownButton<String>(
                hint: Text("filter by priority"),
                value: _filterPriority,
                items: dropdownmenuList.map<DropdownMenuItem<String>>((String value){
                      return DropdownMenuItem<String>(value: value, child:
                      Text(value));
                }).toList(),

                
               
                onChanged: (String? value) { 
                  setState(() {
                    _filterCompletionStatus = value!;
                    if(value == 'incomplete'){
                      _completionStatusFilter = false;
                    }
                    else if(value =='complete'){
                      _completionStatusFilter = true;
                    }
                    
                  });

                 },
                
                
                ),
                SizedBox(width: 20,),
           DropdownButton<String>(
                hint: Text("filter by completion Status"),
                value: _filterCompletionStatus,
                items: dropdownCompletionmenuList.map<DropdownMenuItem<String>>((String value){
                      return DropdownMenuItem<String>(value: value, child:
                      Text(value));
                }).toList(),

                
               
                onChanged: (String? value) { 
                  setState(() {
                    _filterCompletionStatus = value!;
                    
                  });

                 },
                
                
                ),
           Expanded(
        child:
          StreamBuilder(
        stream: query.snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            var docs = snapshot.data!.docs;
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No inventory items available.'));
          }
          
          selectedTaskList = {
            for (var doc in docs)
              (doc.data() as Map<String, dynamic>)['name']: (doc.data() as Map<String, dynamic>)['completionstatus'] ?? false
          };
          
          if(_sortOrder == "High to Low"){
            
            docs.sort((a, b) {
              int sortedAval = (a.data()as Map<String,dynamic>)['priority_value']??0;
              int sortedBval = (b.data()as Map<String,dynamic>)['priority_value']??0;
              return sortedBval.compareTo(sortedAval);
            },);

          }
          else if(_sortOrder == "Low to High"){
            
            docs.sort((a, b) {
              int sortedAval = (a.data()as Map<String,dynamic>)['priority_value']??0;
              int sortedBval = (b.data()as Map<String,dynamic>)['priority_value']??0;
              return sortedAval.compareTo(sortedBval);
            },);

          }
          else if(_sortOrder == "Due Date To Earliest"){
            docs.sort((a, b) {
              Timestamp sortedAval = (a.data()as Map<String,dynamic>)['dueDate'];
              Timestamp sortedBval = (b.data()as Map<String,dynamic>)['dueDate'];
              DateTime dateA = sortedAval.toDate();
              DateTime dateB = sortedBval.toDate();
              return dateA.compareTo(dateB);
            },);

          }else if(_sortOrder == "Due Date To Latest"){
            docs.sort((a, b) {
              Timestamp sortedAval = (a.data()as Map<String,dynamic>)['dueDate'];
              Timestamp sortedBval = (b.data()as Map<String,dynamic>)['dueDate'];
              DateTime dateA = sortedAval.toDate();
              DateTime dateB = sortedBval.toDate();
              return dateB.compareTo(dateA);
            },);

          }
          else if(_sortOrder == "Incomplet To Completed"){
            docs.sort((a, b) {
              bool sortedAval = (a.data()as Map<String,dynamic>)['completionstatus']??false;
              bool sortedBval = (b.data()as Map<String,dynamic>)['completionstatus']??false;
              return sortedAval.toString().compareTo(sortedBval.toString());
            },);

          }
          else if(_sortOrder == "Complet To Incompleted"){
            docs.sort((a, b) {
              bool sortedAval = (a.data()as Map<String,dynamic>)['completionstatus']??false;
              bool sortedBval = (b.data()as Map<String,dynamic>)['completionstatus']??false;
              return sortedBval.toString().compareTo(sortedAval.toString());
            },);

          }

            
          
          return ListView(
            children: docs.map((doc) {
              var data = doc.data() as Map<String, dynamic>;
              var taskName = data['name'];
              return ListTile(
                leading: Checkbox(value: selectedTaskList[taskName] , onChanged: (bool?value){
                  _selectedTask(value, taskName, doc.id);

                },),
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
      

      ),
      ]

      

      

      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addItem,
        tooltip: 'Add Task',
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
        TextEditingController dateController = TextEditingController();
       // TextEditingController quantityController = TextEditingController();
       
        int priority_value = 0;
        return AlertDialog(
          title: Text('Add Task'),
          content: StatefulBuilder(
            builder: (context, setState)  {
                 return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: InputDecoration(labelText: 'Task Name')),
              //TextField(controller: quantityController, decoration: InputDecoration(labelText: 'Priority'), keyboardType: TextInputType.number),
              TextField(
                  controller: dateController,
                  decoration: InputDecoration(
                                  labelText: "Due Date", ),
                  readOnly: true,
                  onTap: ()async{
                    DateTime? pickedDate = await showDatePicker(
                        context: context, 
                        firstDate: DateTime(2000), 
                        lastDate: DateTime(2101),
                        initialDate: DateTime.now(),
                        );
                        if(pickedDate !=null){
                          String formatedDate = DateFormat('dd-MM-yyyy').format(pickedDate);
                          setState(() {
                               dateController.text = formatedDate;
                              });
                          

                  }

                  },
                  
              ),
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
              var parsedDate = DateFormat('dd-MM-yyyy').parse(dateController.text);
              parsedDate = DateTime(parsedDate.year,parsedDate.month,parsedDate.day);

                _firestore.collection('checkList').add({
                  'name': nameController.text,
                  //'priority': int.tryParse(quantityController.text) ?? 0,
                  'priority': dropDownMenuValue,
                  'dueDate': parsedDate,
                  'priority_value': priority_value,
                  'completionstatus': false
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
    //TextEditingController quantityController = TextEditingController(text: data['priority'].toString());
    int priority_value = 0;
    String dropDownMenuValue = dropdownmenuList.first;
    TextEditingController dateController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: InputDecoration(labelText: 'Task Name')),
              //TextField(controller: quantityController, decoration: InputDecoration(labelText: 'Priority'), keyboardType: TextInputType.number),
              TextField(
                  controller: dateController,
                  decoration: InputDecoration(
                                  labelText: "Due Date", ),
                  readOnly: true,
                  onTap: ()async{
                    DateTime? pickedDate = await showDatePicker(
                        context: context, 
                        firstDate: DateTime(2000), 
                        lastDate: DateTime(2101),
                        initialDate: DateTime.now(),
                        );
                        if(pickedDate !=null){
                          String formatedDate = DateFormat('dd-MM-yyyy').format(pickedDate);
                          setState(() {
                               dateController.text = formatedDate;
                              });
                          

                  }

                  },
                  
              ),
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
                var parsedDate = DateFormat('dd-MM-yyyy').parse(dateController.text);
                parsedDate = DateTime(parsedDate.year,parsedDate.month,parsedDate.day);
                _firestore.collection('checkList').doc(id).update({
                  'name': nameController.text,
                 // 'quantity': int.tryParse(quantityController.text) ?? 0,
                  'dueDate':parsedDate,
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
