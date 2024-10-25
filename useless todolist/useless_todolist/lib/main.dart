import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

void main() {
  runApp(TodoApp());
}

class TodoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Useless Todo App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: TodoListScreen(),
    );
  }
}

class TodoListScreen extends StatefulWidget {
  @override
  _TodoListScreenState createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  final List<TodoItem> _todoItems = [];
  final TextEditingController _taskController = TextEditingController();
  DateTime? _selectedDateTime;
  bool _debugMode = false; // Debug mode toggle

  void _addTodoItem() {
    if (_taskController.text.isNotEmpty && _selectedDateTime != null) {
      final newTodo = TodoItem(_taskController.text, _selectedDateTime!, false);
      setState(() {
        _todoItems.add(newTodo);
      });
      _scheduleUnblur(newTodo);
      _taskController.clear();
      _selectedDateTime = null;
    }
  }

  void _scheduleUnblur(TodoItem todo) {
    final now = DateTime.now();
    final difference = todo.reminderTime.difference(now).abs() + Duration(hours: 24);
    Timer(difference, () {
      setState(() {
        todo.isUnblurred = true;
      });
    });
  }

  void _removeTodoItem(int index) {
    setState(() {
      _todoItems.removeAt(index);
    });
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (time != null) {
        setState(() {
          _selectedDateTime = DateTime(picked.year, picked.month, picked.day, time.hour, time.minute);
        });
      }
    }
  }

  String _getDisplayTitle(TodoItem todo) {
    if (_debugMode || todo.isUnblurred) {
      return todo.task;
    } else {
      return '*' * todo.task.length;
    }
  }

  String _getVagueTimeDescription() {
    final vagueMessages = [
      "will remind eventually",
      "reminder coming sooner or later",
      "expect a reminder at some point",
      "reminder will arrive... eventually",
      "you'll be reminded in due time",
      "reminder incoming... sometime",
      "rest assured, a reminder is on its way",
      "a reminder will happen... eventually",
      "reminder set for... whenever",
      "reminder planned for a vague time",
    ];
    final randomIndex = Random().nextInt(vagueMessages.length);
    return vagueMessages[randomIndex];
  }

  void _toggleDebugMode() {
    setState(() {
      _debugMode = !_debugMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Useless Todo App'),
        actions: [
          IconButton(
            icon: Icon(Icons.bug_report),
            onPressed: _toggleDebugMode,
            tooltip: _debugMode ? 'Disable Debug Mode' : 'Enable Debug Mode',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _taskController,
              decoration: InputDecoration(labelText: 'Enter task'),
            ),
          ),
          ElevatedButton(
            onPressed: () => _selectDateTime(context),
            child: Text(_selectedDateTime == null
                ? 'Select reminder time'
                : 'Selected: ${_selectedDateTime!.toLocal()}'),
          ),
          ElevatedButton(
            onPressed: _addTodoItem,
            child: Text('Add Task'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _todoItems.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
                  child: Dismissible(
                    key: ValueKey(_todoItems[index]),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) => _removeTodoItem(index),
                    background: Container(
                      alignment: Alignment.centerRight,
                      color: Colors.redAccent,
                      padding: EdgeInsets.symmetric(horizontal: 20.0),
                      child: Icon(Icons.delete, color: Colors.white),
                    ),
                    child: AnimatedScale(
                      scale: 1.0,
                      duration: Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.lightBlueAccent.shade100,
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
                          title: Text(
                            _getDisplayTitle(_todoItems[index]),
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                          subtitle: Text(
                            _getVagueTimeDescription(),
                            style: TextStyle(color: Colors.black54),
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeTodoItem(index),
                          ),
                        ),
                      ),
                    ),
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

class TodoItem {
  final String task;
  final DateTime reminderTime;
  bool isUnblurred; // Track whether the task is unblurred or still hidden

  TodoItem(this.task, this.reminderTime, this.isUnblurred);
}
