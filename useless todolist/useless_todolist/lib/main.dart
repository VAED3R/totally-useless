import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:confetti/confetti.dart'; // Import the confetti package

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
  late ConfettiController _confettiController; // Confetti controller

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 1)); // Initialize the controller
    // Simulate a loading delay of 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      setState(() {
        _isLoading = false; // Set loading to false after delay
      });
    });
  }

  @override
  void dispose() {
    _confettiController.dispose(); // Dispose the controller
    super.dispose();
  }

  void _selectDateTimeAndAddTask() async {
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

        String? task = await _showTaskInputDialog();

        if (task != null && task.isNotEmpty) {
          _addTodoItem(task);
        }
      }
    }
  }

  Future<String?> _showTaskInputDialog() {
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Task Title'),
          content: TextField(
            controller: _taskController,
            decoration: const InputDecoration(hintText: 'Task description'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(_taskController.text); // Return the task input
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _addTodoItem(String task) {
    if (_selectedDateTime != null) {
      final newTodo = TodoItem(task, _selectedDateTime!, false);
      setState(() {
        _todoItems.add(newTodo);
        _listKey.currentState?.insertItem(_todoItems.length - 1);
      });
      _scheduleUnblur(newTodo);
      _taskController.clear(); // Clear the text field after adding the task
      _selectedDateTime = null; // Reset selected date/time
    }
  }

  void _scheduleUnblur(TodoItem todo) {
    final now = DateTime.now();
    const difference = Duration(seconds: 5); // Testing
    Timer(difference, () {
      setState(() {
        todo.isUnblurred = true;
        _confettiController.play(); // Play confetti animation when a task is unblurred
      });
    });
  }

  void _removeTodoItem(int index) {
    final removedItem = _todoItems[index];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion?'),
          content: const Text('This might be something super important'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _todoItems.removeAt(index);
                  _listKey.currentState?.removeItem(
                    index,
                    (context, animation) => _buildAnimatedTile(removedItem, animation),
                  );
                });
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  String _getDisplayTitle(TodoItem todo) {
    if (_debugMode || todo.isUnblurred) {
      return todo.task;
    } else {
      return '*' * todo.task.length;
    }
  }

  String _getVagueTimeDescription(TodoItem todo) {
    if (todo.isUnblurred) {
      final sarcasticMessages = [
        "Oops, you just missed this!",
        "Well, that happened!",
        "Guess you're not getting that reminder!",
        "Surprise! It's too late now!",
        "Whoops! Missed the boat on that one!",
        "Too slow! Better luck next time!",
        "Looks like someone wasn't paying attention!",
        "Ah, the irony of timing!",
        "Better luck next time!",
        "Missed it by that much!"
      ];
      final randomIndex = Random().nextInt(sarcasticMessages.length);
      return sarcasticMessages[randomIndex];
    }

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
            _getVagueTimeDescription(item),
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
        title: const Text('BLIND LIST'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: _toggleDebugMode,
            tooltip: _debugMode ? 'Disable Debug Mode' : 'Enable Debug Mode',
          ),
        ],
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator()) // Show loading indicator
              : Column(
                  children: [
                    ElevatedButton(
                      onPressed: _selectDateTimeAndAddTask,
                      child: const Text('Add Reminder'),
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
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive, // Emit in all directions
              emissionFrequency: 0.05, // Higher frequency for more particles
              numberOfParticles: 30, // Number of particles emitted
              gravity: 0.5, // Gravity affecting the confetti
              maxBlastForce: 20, // Maximum blast force
              minBlastForce: 5, // Minimum blast force
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
