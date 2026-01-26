import 'package:cloud_firestore/cloud_firestore.dart';

class AdminRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// 🚀 SCALABILITY: Update up to 500 items in one atomic operation
  Future<void> bulkUpdateResources(List<String> ids, Map<String, dynamic> data) async {
    final WriteBatch batch = _db.batch();
    for (String id in ids) {
      final ref = _db.collection('resources').doc(id);
      batch.update(ref, {...data, 'updatedAt': FieldValue.serverTimestamp()});
    }
    await batch.commit();
  }

  /// 📜 AUDIT TRAIL: Logs every admin action for system transparency
  Future<void> logSystemAction(String adminId, String action) async {
    await _db.collection('system_logs').add({
      'adminId': adminId,
      'action': action,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}