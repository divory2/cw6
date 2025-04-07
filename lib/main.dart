import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void main() async {
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
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const List<String> dropdownmenuList = ['','high', 'medium', 'low'];
  static const List<String> dropdownCompletionmenuList = ['','incomplete', 'complete'];

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _error;

  String? _filterPriority;
  String? _filterCompletionStatus;
  String _sortOrder = 'none';

  Map<String, bool> selectedTaskList = {};
  List<String> checked = [];
  List<String> unchecked = [];

  @override
  void initState() {
    super.initState();
    _auth.authStateChanges().listen((User? user) {
      if (user == null) {
        _signInMenu();
      }
    });
  }

  void _signIn() async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  void _register() async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      _signIn(); // Auto sign-in after registration
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  void _signInMenu() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Sign in'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_error != null) Text(_error!, style: TextStyle(color: Colors.red)),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(labelText: 'Email'),
                  ),
                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(labelText: 'Password'),
                    obscureText: true,
                  ),
                  ElevatedButton(onPressed: _signIn, child: Text("Sign In")),
                  TextButton(onPressed: _register, child: Text("Register"))
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _selectedTask(bool? status, String name, String id) {
    selectedTaskList[name] = status ?? false;
    setState(() {
      if (status == true) {
        unchecked.remove(name);
        if (!checked.contains(name)) checked.add(name);
      } else {
        checked.remove(name);
        if (!unchecked.contains(name)) unchecked.add(name);
      }
    });
    _firestore.collection('checkList').doc(id).update({
      'completionstatus': status ?? false,
    });
  }

  void _deleteItem(String id) {
    _firestore.collection('checkList').doc(id).delete();
  }

  void _addItem() {
    showDialog(
      context: context,
      builder: (context) {
        String dropDownMenuValue = dropdownmenuList.first;
        TextEditingController nameController = TextEditingController();
        TextEditingController dateController = TextEditingController();
        int priorityValue = 0;

        return AlertDialog(
          title: Text('Add Task'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameController, decoration: InputDecoration(labelText: 'Task Name')),
                  TextField(
                    controller: dateController,
                    decoration: InputDecoration(labelText: "Due Date"),
                    readOnly: true,
                    onTap: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (pickedDate != null) {
                        String formattedDate = DateFormat('dd-MM-yyyy').format(pickedDate);
                        setState(() {
                          dateController.text = formattedDate;
                        });
                      }
                    },
                  ),
                  DropdownButton<String>(
                    value: dropDownMenuValue,
                    items: dropdownmenuList.map((String value) {
                      return DropdownMenuItem<String>(value: value, child: Text(value));
                    }).toList(),
                    onChanged: (String? value) {
                      setState(() {
                        dropDownMenuValue = value!;
                        priorityValue = value == 'high'
                            ? 3
                            : value == 'medium'
                                ? 2
                                : 1;
                      });
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
            TextButton(
              onPressed: () {
                var parsedDate = DateFormat('dd-MM-yyyy').parse(dateController.text);
                parsedDate = DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
                _firestore.collection('checkList').add({
                  'name': nameController.text,
                  'priority': dropDownMenuValue,
                  'dueDate': parsedDate,
                  'priority_value': priorityValue,
                  'completionstatus': false,
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
    // Implement if needed.
  }

  @override
  Widget build(BuildContext context) {
    Query<Map<String, dynamic>> query = _firestore.collection('checkList');

    if (_filterPriority != null && _filterPriority!.isNotEmpty) {
      query = query.where('priority', isEqualTo: _filterPriority);
    }

    if (_filterCompletionStatus != null && _filterCompletionStatus!.isNotEmpty) {
      bool completionStatus = _filterCompletionStatus == 'complete';
      query = query.where('completionstatus', isEqualTo: completionStatus);
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          PopupMenuButton<String>(
            onSelected: (String value) => setState(() => _sortOrder = value),
            itemBuilder: (context) => [
              PopupMenuItem(value: "", child: Text("")),
              PopupMenuItem(value: "High to Low", child: Text("High to Low")),
              PopupMenuItem(value: "Low to High", child: Text("Low to High")),
              PopupMenuItem(value: "Due Date To Earliest", child: Text("Due Date To Earliest")),
              PopupMenuItem(value: "Due Date To Latest", child: Text("Due Date To Latest")),
              PopupMenuItem(value: "Incomplet To Completed", child: Text("Incomplete to Completed")),
              PopupMenuItem(value: "Complet To Incompleted", child: Text("Completed to Incomplete")),
            ],
          ),
          Row(
            children: [
              DropdownButton<String>(
                hint: Text("Filter by priority"),
                value: _filterPriority?.isNotEmpty == true ? _filterPriority : null,
                items: dropdownmenuList.map((value) {
                  return DropdownMenuItem<String>(value: value, child: Text(value));
                }).toList(),
                onChanged: (value) => setState(() => _filterPriority = value),
              ),
              SizedBox(width: 10),
              DropdownButton<String>(
                hint: Text("Filter by status"),
                value: _filterCompletionStatus?.isNotEmpty == true ? _filterCompletionStatus : null,
                items: dropdownCompletionmenuList.map((value) {
                  return DropdownMenuItem<String>(value: value, child: Text(value));
                }).toList(),
                onChanged: (value) => setState(() => _filterCompletionStatus = value),
              ),
            ],
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: query.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return Center(child: CircularProgressIndicator());

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                  return Center(child: Text('No inventory items.'));

                var docs = snapshot.data!.docs;

                selectedTaskList = {
                  for (var doc in docs)
                    (doc.data() as Map<String, dynamic>)['name']: (doc.data() as Map<String, dynamic>)['completionstatus'] ?? false
                };

                switch (_sortOrder) {
                  case "High to Low":
                    docs.sort((a, b) => (b['priority_value'] ?? 0).compareTo(a['priority_value'] ?? 0));
                    break;
                  case "Low to High":
                    docs.sort((a, b) => (a['priority_value'] ?? 0).compareTo(b['priority_value'] ?? 0));
                    break;
                  case "Due Date To Earliest":
                    docs.sort((a, b) => (a['dueDate'] as Timestamp).compareTo(b['dueDate'] as Timestamp));
                    break;
                  case "Due Date To Latest":
                    docs.sort((a, b) => (b['dueDate'] as Timestamp).compareTo(a['dueDate'] as Timestamp));
                    break;
                  case "Incomplet To Completed":
                    docs.sort((a, b) => (a['completionstatus'] ? 1 : 0).compareTo(b['completionstatus'] ? 1 : 0));
                    break;
                  case "Complet To Incompleted":
                    docs.sort((a, b) => (b['completionstatus'] ? 1 : 0).compareTo(a['completionstatus'] ? 1 : 0));
                    break;
                    case "":
                    break;
                }

                return ListView(
                  children: docs.map((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    String taskName = data['name'];
                    return ListTile(
                      leading: Checkbox(
                        value: selectedTaskList[taskName],
                        onChanged: (value) => _selectedTask(value, taskName, doc.id),
                      ),
                      title: Text(taskName),
                      subtitle: Text('Priority: ${data['priority']}'),
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
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addItem,
        tooltip: 'Add Task',
        child: Icon(Icons.add),
      ),
    );
  }
}
