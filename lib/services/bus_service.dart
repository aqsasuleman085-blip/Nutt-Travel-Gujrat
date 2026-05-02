import 'package:cloud_firestore/cloud_firestore.dart';

import '../admin_side/models/bus_model.dart';

class BusService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<BusModel>> streamBuses() {
    return _firestore
        .collection('buses')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return BusModel.fromMap({'id': doc.id, ...doc.data()});
          }).toList();
        });
  }
}
