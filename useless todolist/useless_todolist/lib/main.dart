import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

void main() {
  runApp(const TodoApp());
}

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Useless Todo App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const TodoListScreen(),
    );
  }
}

class TodoListScreen extends StatefulWidget {
  const TodoListScreen({super.key});

  @override
  _TodoListScreenState createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  final List<TodoItem> _todoItems = [];
  final TextEditingController _taskController = TextEditingController();
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  DateTime? _selectedDateTime;
  bool _debugMode = false;
  bool _isLoading = true; // Loading state

  @override
  void initState() {
    super.initState();
    // Simulate a loading delay of 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      setState(() {
        _isLoading = false; // Set loading to false after delay
      });
    });
  }

  void _addTodoItem() {
    if (_taskController.text.isNotEmpty && _selectedDateTime != null) {
      final newTodo = TodoItem(_taskController.text, _selectedDateTime!, false);
      setState(() {
        _todoItems.add(newTodo);
        _listKey.currentState?.insertItem(_todoItems.length - 1);
      });
      _scheduleUnblur(newTodo);
      _taskController.clear();
      _selectedDateTime = null;
    }
  }

  void _scheduleUnblur(TodoItem todo) {
    final now = DateTime.now();
    final difference = todo.reminderTime.difference(now).abs() + const Duration(hours: 24);
    Timer(difference, () {
      setState(() {
        todo.isUnblurred = true;
      });
    });
  }

  void _removeTodoItem(int index) {
    final removedItem = _todoItems[index];
    setState(() {
      _todoItems.removeAt(index);
      _listKey.currentState?.removeItem(
        index,
        (context, animation) => _buildAnimatedTile(removedItem, animation),
      );
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

  Widget _buildAnimatedTile(TodoItem item, Animation<double> animation) {
    return SizeTransition(
      sizeFactor: animation,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
 decoration: BoxDecoration(
          color: Colors.lightBlueAccent.shade100,
          borderRadius: BorderRadius.circular(15.0),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
          title: Text(
            _getDisplayTitle(item),
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
          ),
          subtitle: Text(
            _getVagueTimeDescription(),
            style: const TextStyle(color: Colors.black54),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _removeTodoItem(_todoItems.indexOf(item)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Useless Todo App'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: _toggleDebugMode,
            tooltip: _debugMode ? 'Disable Debug Mode' : 'Enable Debug Mode',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // Show loading indicator
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _taskController,
                    decoration: const InputDecoration(labelText: 'Enter task'),
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
                  child: const Text('Add Task'),
                ),
                Expanded(
                  child: AnimatedList(
                    key: _listKey,
                    initialItemCount: _todoItems.length,
                    itemBuilder: (context, index, animation) {
                      return _buildAnimatedTile(_todoItems[index], animation);
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
  bool isUnblurred;

  TodoItem(this.task, this.reminderTime, this.isUnblurred);
}