import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/squad_model.dart';

class SquadProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<SquadModel> _squads = [];
  SquadModel? _currentSquad;
  bool _isLoading = false;
  
  List<SquadModel> get squads => _squads;
  SquadModel? get currentSquad => _currentSquad;
  bool get isLoading => _isLoading;
  
  Future<void> loadSquads(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final snapshot = await _firestore
          .collection('squads')
          .where('members', arrayContains: userId)
          .get();
      
      _squads = snapshot.docs
          .map((doc) => SquadModel.fromMap(doc.data()))
          .toList();
      
      if (_squads.isNotEmpty) {
        _currentSquad = _squads.first;
      }
    } catch (e) {
      print('Error loading squads: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<bool> createSquad(SquadModel squad) async {
    try {
      await _firestore.collection('squads').add(squad.toMap());
      _squads.add(squad);
      _currentSquad = squad;
      notifyListeners();
      return true;
    } catch (e) {
      print('Error creating squad: $e');
      return false;
    }
  }
  
  Future<bool> joinSquad(String squadId, String userId) async {
    try {
      await _firestore.collection('squads').doc(squadId).update({
        'members': FieldValue.arrayUnion([userId])
      });
      return true;
    } catch (e) {
      print('Error joining squad: $e');
      return false;
    }
  }
}
