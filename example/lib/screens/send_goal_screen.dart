import 'package:flutter/material.dart';
import 'package:pushengage_flutter_sdk/pushengage_flutter_sdk.dart';

import '../demo_theme.dart';
import '../widgets/alert.dart';

/// Builds and sends a [Goal] via `PushEngage.sendGoal`. Mirrors the RN
/// SendGoal screen.
class SendGoalScreen extends StatefulWidget {
  const SendGoalScreen({super.key});

  @override
  State<SendGoalScreen> createState() => _SendGoalScreenState();
}

class _SendGoalScreenState extends State<SendGoalScreen> {
  final TextEditingController _nameCtl = TextEditingController();
  final TextEditingController _countCtl = TextEditingController();
  final TextEditingController _valueCtl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nameCtl.dispose();
    _countCtl.dispose();
    _valueCtl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    final goal = Goal(
      name: _nameCtl.text.trim(),
      count: int.tryParse(_countCtl.text.trim()),
      value: double.tryParse(_valueCtl.text.trim()),
    );
    final res = await PushEngage.sendGoal(goal);
    if (!mounted) return;
    setState(() => _loading = false);
    await showAlert(
      context,
      res.isSuccess ? 'Success' : 'Error',
      res.isSuccess
          ? (res.data ?? 'Goal sent successfully')
          : res.error.toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: DemoColors.header,
        foregroundColor: Colors.white,
        title: const Text('SendGoal',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Enter Goal Name'),
            const SizedBox(height: 6),
            TextField(
              controller: _nameCtl,
              decoration: const InputDecoration(
                  hintText: 'enter name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            const Text('Enter Count'),
            const SizedBox(height: 6),
            TextField(
              controller: _countCtl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  hintText: 'enter count', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            const Text('Enter Value'),
            const SizedBox(height: 6),
            TextField(
              controller: _valueCtl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                  hintText: 'enter value', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: DemoColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
              ),
              onPressed: _loading ? null : _send,
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Send Goal'),
            ),
          ],
        ),
      ),
    );
  }
}
