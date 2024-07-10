import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'splash_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ToDo List',
      theme: ThemeData.light().copyWith(
        primaryColor: Colors.lightBlueAccent,
        scaffoldBackgroundColor: Colors.white,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(),
        '/home': (context) => ToDoList(),
      },
    );
  }
}

class ToDoList extends StatefulWidget {
  @override
  _ToDoListState createState() => _ToDoListState();
}

class _ToDoListState extends State<ToDoList> {
  final List<Map<String, dynamic>> _toDoItems = [];
  final List<Map<String, dynamic>> _completedItems = [];
  final TextEditingController _textController = TextEditingController();
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
  DateTime _selectedDateTime = DateTime.now();
  bool _showCompleted = false;

  @override
  void initState() {
    super.initState();
    _loadToDoItems();
  }

  Future<void> _loadToDoItems() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _toDoItems.addAll(json
          .decode(prefs.getString('toDoItems') ?? '[]')
          .map((item) => Map<String, dynamic>.from(item))
          .toList());
      _completedItems.addAll(json
          .decode(prefs.getString('completedItems') ?? '[]')
          .map((item) => Map<String, dynamic>.from(item))
          .toList());
    });
  }

  Future<void> _saveToDoItems() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('toDoItems', json.encode(_toDoItems));
    prefs.setString('completedItems', json.encode(_completedItems));
  }

  void _addToDoItem(String task, DateTime dateTime) {
    if (task.isNotEmpty && dateTime != null) {
      setState(() {
        _toDoItems.add({
          'task': task,
          'dateTime': dateTime,
        });
      });
      _saveToDoItems();
      Navigator.pop(context);
      _textController.clear();
    }
  }

  void _completeToDoItem(int index) {
    setState(() {
      Map<String, dynamic> completedTask = _toDoItems.removeAt(index);
      _completedItems.add(completedTask);
    });
    _saveToDoItems();
  }

  void _removeToDoItem(int index) {
    setState(() {
      _toDoItems.removeAt(index);
    });
    _saveToDoItems();
  }

  void _removeCompletedItem(int index) {
    setState(() {
      _completedItems.removeAt(index);
    });
    _saveToDoItems();
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );
      if (pickedTime != null) {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  void _showCompletedItems() {
    setState(() {
      _showCompleted = true;
    });
  }

  void _showAddToDoDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Tambah Tugas Baru'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: _textController,
                decoration: InputDecoration(
                  hintText: 'Masukkan tugas baru',
                ),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => _selectDateTime(context),
                child: Text('Atur Tanggal dan Waktu'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Batal'),
              onPressed: () {
                Navigator.of(context).pop();
                _textController.clear();
              },
            ),
            ElevatedButton(
              child: Text('Tambah'),
              onPressed: () {
                _addToDoItem(_textController.text, _selectedDateTime);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildToDoItem(
      Map<String, dynamic> item, int index, bool isCompleted) {
    return ListTile(
      title: Text(
        item['task'],
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          decoration:
              isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
        ),
      ),
      subtitle: Text(
        isCompleted
            ? 'Completed: ${_dateFormat.format(item['dateTime'])}'
            : 'Reminder: ${_dateFormat.format(item['dateTime'])}',
        style: TextStyle(color: isCompleted ? Colors.green : Colors.teal),
      ),
      trailing: isCompleted
          ? IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () => _removeCompletedItem(index),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.check_circle_outline, color: Colors.green),
                  onPressed: () => _completeToDoItem(index),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeToDoItem(index),
                ),
              ],
            ),
    );
  }

  Widget _buildToDoList() {
    return ListView.builder(
      itemCount: _toDoItems.length,
      itemBuilder: (context, index) {
        return _buildToDoItem(_toDoItems[index], index, false);
      },
    );
  }

  Widget _buildCompletedList() {
    return _showCompleted
        ? ListView.builder(
            itemCount: _completedItems.length,
            itemBuilder: (context, index) {
              return _buildToDoItem(_completedItems[index], index, true);
            },
          )
        : SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ToDo List'),
        leading: Image.asset(
          'assets/logo.png',
          width: 40,
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              ElevatedButton(
                onPressed: _showAddToDoDialog,
                child: Text('Tambah Tugas'),
              ),
              SizedBox(height: 20),
              Expanded(
                child: _buildToDoList(),
              ),
              SizedBox(height: 20),
              GestureDetector(
                onTap: _showCompletedItems,
                child: Text(
                  'Lihat Tugas Selesai:',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              Expanded(
                child: _buildCompletedList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
