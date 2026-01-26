import 'package:flutter/material.dart';
import 'dart:async';

class RevisionBoosterScreen extends StatefulWidget {
  final String? subject;
  const RevisionBoosterScreen({super.key, this.subject});

  @override
  State<RevisionBoosterScreen> createState() => _RevisionBoosterScreenState();
}

class _RevisionBoosterScreenState extends State<RevisionBoosterScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<RevisionTopic> _topics = [];
  String _selectedTechnique = 'spaced';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSampleTopics();
  }

  void _loadSampleTopics() {
    _topics.addAll([
      RevisionTopic(
        id: '1',
        subject: 'Physics',
        topic: 'Quantum Mechanics',
        lastRevised: DateTime.now().subtract(const Duration(days: 7)),
        masteryLevel: 0.75,
        revisionCount: 3,
        nextReview: DateTime.now().add(const Duration(days: 1)),
        difficulty: 4,
      ),
      RevisionTopic(
        id: '2',
        subject: 'Mathematics',
        topic: 'Calculus',
        lastRevised: DateTime.now().subtract(const Duration(days: 3)),
        masteryLevel: 0.60,
        revisionCount: 2,
        nextReview: DateTime.now().add(const Duration(days: 4)),
        difficulty: 3,
      ),
      RevisionTopic(
        id: '3',
        subject: 'Chemistry',
        topic: 'Organic Chemistry',
        lastRevised: DateTime.now().subtract(const Duration(days: 1)),
        masteryLevel: 0.85,
        revisionCount: 5,
        nextReview: DateTime.now().add(const Duration(days: 7)),
        difficulty: 5,
      ),
    ]);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.pink.shade400, Colors.pink.shade50],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildTabBar(),
              Expanded(child: _buildContent()),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTopicDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Topic'),
        backgroundColor: Colors.pink.shade600,
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Revision Booster', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                Text('Smart spaced repetition', style: TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.replay, color: Colors.white, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.pink.shade700,
        unselectedLabelColor: Colors.grey,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: Colors.pink.shade50,
        ),
        tabs: const [
          Tab(text: 'Due Now'),
          Tab(text: 'Schedule'),
          Tab(text: 'Techniques'),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildDueTopics(),
        _buildScheduleView(),
        _buildTechniquesView(),
      ],
    );
  }

  Widget _buildDueTopics() {
    final dueTopics = _topics.where((t) => DateTime.now().isAfter(t.nextReview)).toList();

    if (dueTopics.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 100, color: Colors.green.shade300),
            const SizedBox(height: 16),
            const Text('All caught up!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('No revisions due right now', style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: dueTopics.length,
      itemBuilder: (context, index) => _buildTopicCard(dueTopics[index], isDue: true),
    );
  }

  Widget _buildScheduleView() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _topics.length,
      itemBuilder: (context, index) => _buildTopicCard(_topics[index]),
    );
  }

  Widget _buildTechniquesView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Revision Techniques', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _buildTechniqueCard(
            'Spaced Repetition',
            'Review at increasing intervals (1, 3, 7, 14, 30 days)',
            Icons.calendar_today,
            Colors.blue.shade400,
            'spaced',
          ),
          _buildTechniqueCard(
            'Active Recall',
            'Test yourself without looking at notes',
            Icons.quiz,
            Colors.green.shade400,
            'active',
          ),
          _buildTechniqueCard(
            'Feynman Technique',
            'Explain concepts in simple terms',
            Icons.person_outline,
            Colors.orange.shade400,
            'feynman',
          ),
          _buildTechniqueCard(
            'Pomodoro Method',
            '25-minute focused study sessions',
            Icons.timer,
            Colors.red.shade400,
            'pomodoro',
          ),
          const SizedBox(height: 24),
          const Text('Study Tips', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ..._buildTips(),
        ],
      ),
    );
  }

  Widget _buildTopicCard(RevisionTopic topic, {bool isDue = false}) {
    final daysUntil = topic.nextReview.difference(DateTime.now()).inDays;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isDue ? Border.all(color: Colors.orange.shade400, width: 2) : null,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _startRevision(topic),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getSubjectColor(topic.subject).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(_getSubjectIcon(topic.subject), color: _getSubjectColor(topic.subject)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(topic.topic, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text(topic.subject, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                    if (isDue)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('DUE', style: TextStyle(color: Colors.orange.shade700, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.star, size: 16, color: Colors.amber),
                    const SizedBox(width: 4),
                    ...List.generate(5, (i) => Icon(
                      i < topic.difficulty ? Icons.star : Icons.star_border,
                      size: 14,
                      color: Colors.amber,
                    )),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: topic.masteryLevel,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation(_getMasteryColor(topic.masteryLevel)),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Mastery: ${(topic.masteryLevel * 100).toStringAsFixed(0)}%', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                    Text(daysUntil > 0 ? 'Review in $daysUntil days' : 'Review now', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDue ? Colors.orange.shade700 : Colors.grey.shade600)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Revised ${topic.revisionCount} times', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTechniqueCard(String title, String description, IconData icon, Color color, String id) {
    final isSelected = _selectedTechnique == id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isSelected ? Border.all(color: color, width: 2) : null,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => setState(() => _selectedTechnique = id),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(description, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTips() {
    final tips = [
      'Study in short bursts (20-30 min) with breaks',
      'Review before sleeping for better retention',
      'Teach concepts to others to strengthen understanding',
      'Use multiple senses: write, speak, visualize',
      'Practice in different environments',
    ];

    return tips.map((tip) => Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb, color: Colors.amber.shade600, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(tip, style: const TextStyle(fontSize: 14))),
        ],
      ),
    )).toList();
  }

  void _showAddTopicDialog() {
    final subjectController = TextEditingController();
    final topicController = TextEditingController();
    int difficulty = 3;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Add Revision Topic'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: subjectController,
                decoration: InputDecoration(
                  labelText: 'Subject',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: topicController,
                decoration: InputDecoration(
                  labelText: 'Topic',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Difficulty: '),
                  ...List.generate(5, (i) => IconButton(
                    icon: Icon(
                      i < difficulty ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                    ),
                    onPressed: () => setState(() => difficulty = i + 1),
                  )),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink.shade600,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                _topics.add(RevisionTopic(
                  id: DateTime.now().toString(),
                  subject: subjectController.text,
                  topic: topicController.text,
                  lastRevised: DateTime.now(),
                  masteryLevel: 0.0,
                  revisionCount: 0,
                  nextReview: DateTime.now().add(const Duration(days: 1)),
                  difficulty: difficulty,
                ));
                Navigator.pop(context);
                this.setState(() {});
              },
              child: const Text('Add Topic'),
            ),
          ],
        ),
      ),
    );
  }

  void _startRevision(RevisionTopic topic) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              Text(topic.topic, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(topic.subject, style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    _buildRevisionAction('Test Knowledge', Icons.quiz, Colors.blue.shade400, () {}),
                    _buildRevisionAction('Review Notes', Icons.menu_book, Colors.green.shade400, () {}),
                    _buildRevisionAction('Practice Problems', Icons.edit, Colors.orange.shade400, () {}),
                    _buildRevisionAction('Watch Video', Icons.play_circle, Colors.red.shade400, () {}),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        setState(() {
                          final index = _topics.indexWhere((t) => t.id == topic.id);
                          _topics[index] = RevisionTopic(
                            id: topic.id,
                            subject: topic.subject,
                            topic: topic.topic,
                            lastRevised: DateTime.now(),
                            masteryLevel: (topic.masteryLevel + 0.1).clamp(0.0, 1.0),
                            revisionCount: topic.revisionCount + 1,
                            nextReview: DateTime.now().add(Duration(days: (topic.revisionCount + 1) * 3)),
                            difficulty: topic.difficulty,
                          );
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('Mark as Reviewed', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRevisionAction(String title, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 16),
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const Spacer(),
                Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getSubjectColor(String subject) {
    switch (subject) {
      case 'Physics': return Colors.blue.shade600;
      case 'Mathematics': return Colors.green.shade600;
      case 'Chemistry': return Colors.orange.shade600;
      default: return Colors.purple.shade600;
    }
  }

  IconData _getSubjectIcon(String subject) {
    switch (subject) {
      case 'Physics': return Icons.science;
      case 'Mathematics': return Icons.calculate;
      case 'Chemistry': return Icons.biotech;
      default: return Icons.book;
    }
  }

  Color _getMasteryColor(double mastery) {
    if (mastery < 0.3) return Colors.red.shade400;
    if (mastery < 0.6) return Colors.orange.shade400;
    if (mastery < 0.8) return Colors.blue.shade400;
    return Colors.green.shade400;
  }
}

class RevisionTopic {
  final String id;
  final String subject;
  final String topic;
  final DateTime lastRevised;
  final double masteryLevel;
  final int revisionCount;
  final DateTime nextReview;
  final int difficulty;

  RevisionTopic({
    required this.id,
    required this.subject,
    required this.topic,
    required this.lastRevised,
    required this.masteryLevel,
    required this.revisionCount,
    required this.nextReview,
    required this.difficulty,
  });
}