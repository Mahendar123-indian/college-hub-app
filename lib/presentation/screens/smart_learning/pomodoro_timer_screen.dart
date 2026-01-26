import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/smart_learning_provider.dart';

class PomodoroTimerScreen extends StatefulWidget {
  const PomodoroTimerScreen({super.key});

  @override
  State<PomodoroTimerScreen> createState() => _PomodoroTimerScreenState();
}

class _PomodoroTimerScreenState extends State<PomodoroTimerScreen> {
  Timer? _timer;
  int _secondsRemaining = 25 * 60;
  bool _isWorking = true;
  bool _isRunning = false;
  int _cyclesCompleted = 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    setState(() => _isRunning = true);
    context.read<SmartLearningProvider>().startPomodoroSession();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _timerComplete();
        }
      });
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _secondsRemaining = _isWorking ? 25 * 60 : 5 * 60;
    });
  }

  void _timerComplete() {
    _timer?.cancel();
    setState(() {
      if (_isWorking) {
        _cyclesCompleted++;
        context.read<SmartLearningProvider>().completePomodoroSession();
      }
      _isWorking = !_isWorking;
      _secondsRemaining = _isWorking ? 25 * 60 : 5 * 60;
      _isRunning = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isWorking ? 'Break complete! Ready to work' : 'Work session complete! Take a break')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final minutes = _secondsRemaining ~/ 60;
    final seconds = _secondsRemaining % 60;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _isWorking
                ? [Colors.red.shade400, Colors.orange.shade400]
                : [Colors.green.shade400, Colors.teal.shade400],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              AppBar(
                title: const Text('Pomodoro Timer'),
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
              const SizedBox(height: 40),
              Text(_isWorking ? 'FOCUS TIME' : 'BREAK TIME',
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)),
              const SizedBox(height: 20),
              Text('Cycle $_cyclesCompleted / 4', style: const TextStyle(color: Colors.white70, fontSize: 16)),
              const Spacer(),
              Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 30)],
                ),
                child: Center(
                  child: Text(
                    '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 72, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!_isRunning)
                    _buildButton(Icons.play_arrow, 'Start', _startTimer)
                  else
                    _buildButton(Icons.pause, 'Pause', _pauseTimer),
                  const SizedBox(width: 20),
                  _buildButton(Icons.refresh, 'Reset', _resetTimer),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton(IconData icon, String label, VoidCallback onPressed) {
    return Column(
      children: [
        FloatingActionButton(
          onPressed: onPressed,
          backgroundColor: Colors.white,
          child: Icon(icon, color: _isWorking ? Colors.red.shade700 : Colors.green.shade700, size: 32),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
      ],
    );
  }
}