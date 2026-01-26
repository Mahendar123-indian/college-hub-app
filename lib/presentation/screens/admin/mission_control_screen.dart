import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart'; // Ensure you added fl_chart to pubspec

class MissionControlScreen extends StatelessWidget {
  const MissionControlScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020417),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildMissionHeader(),
          _buildPriorityQueue(),   // Zone: Urgent tasks
          _buildTrendGrid(),       // Zone: Sparkline analytics
          _buildQuickActions(),    // Zone: Management tools
          _buildLiveAuditLog(),    // Zone: Real-time logs
        ],
      ),
    );
  }

  Widget _buildMissionHeader() {
    return const SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 60, 24, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('MISSION CONTROL', style: TextStyle(color: Colors.blueAccent, letterSpacing: 3, fontSize: 12, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('System Health', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityQueue() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('pending_papers').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SliverToBoxAdapter(child: SizedBox());
        return SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.bolt, color: Colors.redAccent),
                const SizedBox(width: 15),
                Text("${snapshot.data!.docs.length} Uploads Pending", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 14),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTrendGrid() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, mainAxisSpacing: 16, crossAxisSpacing: 16, childAspectRatio: 1.2,
        ),
        delegate: SliverChildListDelegate([
          _buildTrendCard("Active Now", "42", Colors.cyan),
          _buildTrendCard("Today's DL", "128", Colors.purpleAccent),
        ]),
      ),
    );
  }

  Widget _buildTrendCard(String label, String val, Color col) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: col.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)),
          const Spacer(),
          Text(val, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          // Mini Sparkline
          SizedBox(height: 30, child: LineChart(LineChartData(
            gridData: FlGridData(show: false),
            titlesData: FlTitlesData(show: false),
            borderData: FlBorderData(show: false),
            lineBarsData: [LineChartBarData(
              spots: [const FlSpot(0, 1), const FlSpot(1, 1.5), const FlSpot(2, 1.2), const FlSpot(3, 2)],
              isCurved: true, color: col, barWidth: 2, dotData: FlDotData(show: false),
            )],
          ))),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return SliverPadding(
      padding: const EdgeInsets.all(24),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4, mainAxisSpacing: 20, crossAxisSpacing: 20,
        ),
        delegate: SliverChildListDelegate([
          _actionBtn(Icons.people, "Users", Colors.blue),
          _actionBtn(Icons.upload, "File", Colors.orange),
          _actionBtn(Icons.analytics, "Stats", Colors.green),
          _actionBtn(Icons.security, "Guard", Colors.red),
        ]),
      ),
    );
  }

  Widget _actionBtn(IconData i, String l, Color c) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: c.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(i, color: c, size: 24),
        ),
        const SizedBox(height: 8),
        Text(l, style: const TextStyle(color: Colors.white38, fontSize: 10)),
      ],
    );
  }

  Widget _buildLiveAuditLog() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('system_logs').orderBy('timestamp', descending: true).limit(5).snapshots(),
      builder: (context, snapshot) {
        return SliverList(
          delegate: SliverChildBuilderDelegate((context, i) {
            if (!snapshot.hasData) return const SizedBox();
            var log = snapshot.data!.docs[i];
            return Container(
              margin: const EdgeInsets.fromLTRB(24, 0, 24, 10),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(16)),
              child: Text(log['action'], style: const TextStyle(color: Colors.white70, fontSize: 13)),
            );
          }, childCount: snapshot.hasData ? snapshot.data!.docs.length : 0),
        );
      },
    );
  }
}