import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  User? _user;
  UserModel? _userModel;
  bool _isLoading = false;
  
  User? get user => _user;
  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }
  
  void _onAuthStateChanged(User? user) {
    _user = user;
    if (user != null) {
      _loadUserModel();
    } else {
      _userModel = null;
    }
    notifyListeners();
  }
  
  Future<void> _loadUserModel() async {
    if (_user == null) return;
    
    try {
      final doc = await _firestore.collection('users').doc(_user!.uid).get();
      if (doc.exists) {
        _userModel = UserModel.fromMap(doc.data()!);
      }
    } catch (e) {
      print('Error loading user model: $e');
    }
  }

  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return true;
    } catch (e) {
      print('Sign in error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<bool> createUserWithEmailAndPassword(String email, String password, String name) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user != null) {
        final userModel = UserModel(
          uid: credential.user!.uid,
          email: email,
          name: name,
          totalBalance: 0,
          xpLevel: 1,
          streak: 0,
          interests: [],
          riskTolerance: 'Medium',
          createdAt: DateTime.now(),
        );