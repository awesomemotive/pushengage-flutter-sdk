import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pushengage_flutter_sdk/helper/pushengage_result.dart';
import 'package:pushengage_flutter_sdk/model/goal.dart';
import 'package:pushengage_flutter_sdk/pushengage_flutter_sdk.dart';

class SendGoalPage extends StatefulWidget {
  const SendGoalPage({super.key});

  @override
  _SendGoalPageState createState() => _SendGoalPageState();
}

class _SendGoalPageState extends State<SendGoalPage> {
  final TextEditingController _goalNameController = TextEditingController();
  final TextEditingController _countController = TextEditingController();
  final TextEditingController _valueController = TextEditingController();

  Future<void> _sendGoal() async {
    final goal = Goal(
      name: _goalNameController.text,
      count: int.tryParse(_countController.text),
      value: double.tryParse(_valueController.text),
    );
    PushEngageResult result = await PushEngage.sendGoal(goal);
    if (result == null) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.isSuccess ? result.data : result.error)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: Text('Send Goal'),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('Enter Goal Name'),
                TextField(
                  controller: _goalNameController,
                  decoration: const InputDecoration(
                    hintText: 'enter name',
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Enter Count'),
                TextField(
                  controller: _countController,
                  decoration: const InputDecoration(
                    hintText: 'enter count',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 16),
                const Text('Enter Value'),
                TextField(
                  controller: _valueController,
                  decoration: const InputDecoration(
                    hintText: 'enter value',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 32),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      _sendGoal();
                      FocusScope.of(context).unfocus();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromARGB(255, 34, 74, 219),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            8), // Set the corner radius to 20
                      ),
                    ),
                    child: const Text(
                      'Send Goal',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
