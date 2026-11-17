import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/plot_model.dart';

class PlotRepository {
  PlotRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<Plot>> getPlots(String ownerId) {
    return _firestore
        .collection('parcels')
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Plot.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  Future<void> addPlot(Plot plot) async {
    await _firestore.collection('parcels').add(plot.toMap());
  }

  Future<void> updatePlot(Plot plot) async {
    await _firestore.collection('parcels').doc(plot.id).update(plot.toMap());
  }

  Future<void> deletePlot(String plotId) async {
    await _firestore.collection('parcels').doc(plotId).delete();
  }
}