import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/smart_learning_provider.dart';
import '../../../data/models/study_session_model.dart'; // ← ADD THIS IMPORT

class StudyStreakTrackerScreen extends StatefulWidget {
  const StudyStreakTrackerScreen({super.key});

  @override
  State<StudyStreakTrackerScreen> createState() => _StudyStreakTrackerScreenState();
}

class _StudyStreakTrackerScreenState extends State<StudyStreakTrackerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SmartLearningProvider>().loadStudySessions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Study Streak'), backgroundColor: Colors.green.shade600),
      body: Consumer<SmartLearningProvider>(
        builder: (context, provider, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildStreakCard(provider),
              const SizedBox(height: 24),
              _buildStatsGrid(provider),
              const SizedBox(height: 24),
              const Text('Recent Sessions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...provider.studySessions.take(10).map((session) => _buildSessionCard(session)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStreakCard(SmartLearningProvider provider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.orange.shade400, Colors.red.shade400]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Current Streak', style: TextStyle(color: Colors.white, fontSize: 18)),
              Text('${provider.currentStreak} Days', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
            ],
          ),
          const Icon(Icons.local_fire_department, color: Colors.white, size: 64),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(SmartLearningProvider provider) {
    return Row(
      children: [
        Expanded(child: _statCard('Total Hours', '${provider.totalStudyMinutes ~/ 60}', Icons.timer, Colors.blue)),
        const SizedBox(width: 12),
        Expanded(child: _statCard('Sessions', '${provider.studySessions.length}', Icons.book, Colors.purple)),
      ],
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)]
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildSessionCard(StudySessionModel session) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: Colors.green.shade100, child: Icon(Icons.check, color: Colors.green.shade700)),
        title: Text(session.subject, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${session.durationMinutes} minutes • ${_formatDate(session.startTime)}'),
        trailing: Text('${session.focusScore}%', style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold)),
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}