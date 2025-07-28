import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'http_client.dart';
import 'forecast_notification_service.dart';

class ForecastStorageService {
  static const String baseUrl = 'http://localhost:3000/api';
  final HttpClient _httpClient = HttpClient();
  
  // Local storage for fallback
  static final List<Map<String, dynamic>> _localReports = [];

  // Store investment history report in portfolio
  Future<bool> storeInvestmentReport(Map<String, dynamic> reportData) async {
    try {
      debugPrint('ForecastStorageService: Storing investment report for ${reportData['symbol']}');
      debugPrint('ForecastStorageService: Report data keys: ${reportData.keys.toList()}');
      
      final requestData = {
        'symbol': reportData['symbol'],
        'type': reportData['type'] ?? 'Stocks',
        'investmentAmount': reportData['investmentAmount'] ?? 1000,
        'duration': reportData['duration'] ?? 10,
        'riskLevel': reportData['riskLevel'] ?? 'Medium',
        'historicalData': reportData['historicalData'],
        'metrics': reportData['metrics'],
        'insights': reportData['insights'],
        'generatedAt': DateTime.now().toIso8601String(),
        'reportType': 'investment_history',
      };
      
      debugPrint('ForecastStorageService: Request data keys: ${requestData.keys.toList()}');
      debugPrint('ForecastStorageService: Investment amount: ${requestData['investmentAmount']}');
      debugPrint('ForecastStorageService: Duration: ${requestData['duration']}');
      
      final response = await _httpClient.post('/forecast', requestData);
      
      debugPrint('ForecastStorageService: Response status: ${response['status']}');
      debugPrint('ForecastStorageService: Response keys: ${response.keys.toList()}');

      if (response['status'] == 'success') {
        debugPrint('ForecastStorageService: Successfully stored investment report in backend');
        // Also store locally as backup
        await _storeLocally(reportData);
        // Notify other parts of the app about the new report
        ForecastNotificationService().notifyNewForecast(reportData);
        return true;
      } else {
        debugPrint('ForecastStorageService: Backend failed, storing locally: ${response['message']}');
        // Store locally as fallback
        await _storeLocally(reportData);
        return true; // Return true since we stored locally
      }
    } catch (e) {
      debugPrint('ForecastStorageService: Error storing investment report: $e');
      // Store locally as fallback
      await _storeLocally(reportData);
      return true; // Return true since we stored locally
    }
  }

  // Store report locally as fallback
  Future<void> _storeLocally(Map<String, dynamic> reportData) async {
    try {
      debugPrint('ForecastStorageService: Storing report locally as fallback');
      
      final localReport = {
        ...reportData,
        'generatedAt': DateTime.now().toIso8601String(),
        'reportType': 'investment_history',
        'storedLocally': true,
      };
      
      _localReports.add(localReport);
      
      // Keep only last 50 reports to prevent memory issues
      if (_localReports.length > 50) {
        _localReports.removeAt(0);
      }
      
      debugPrint('ForecastStorageService: Local reports count: ${_localReports.length}');
      
      // Notify other parts of the app about the new report
      ForecastNotificationService().notifyNewForecast(localReport);
    } catch (e) {
      debugPrint('ForecastStorageService: Error storing locally: $e');
    }
  }

  // Get all investment reports from portfolio
  Future<List<Map<String, dynamic>>> getInvestmentReports() async {
    try {
      debugPrint('ForecastStorageService: Fetching investment reports');
      
      // Try to get from backend first
      final response = await _httpClient.get('/forecast');
      
      debugPrint('ForecastStorageService: Backend response status: ${response['status']}');
      debugPrint('ForecastStorageService: Backend response keys: ${response.keys.toList()}');
      
      List<Map<String, dynamic>> reports = [];
      
      if (response['status'] == 'success' && response['data'] != null) {
        debugPrint('ForecastStorageService: Found ${response['data'].length} total forecasts from backend');
        
        // Filter for investment history reports
        final backendReports = List<Map<String, dynamic>>.from(response['data'])
            .where((report) => report['reportType'] == 'investment_history')
            .toList();
        
        debugPrint('ForecastStorageService: Found ${backendReports.length} investment history reports from backend');
        reports.addAll(backendReports);
      }
      
      // Add local reports
      debugPrint('ForecastStorageService: Adding ${_localReports.length} local reports');
      reports.addAll(_localReports);
      
      // Remove duplicates based on symbol and generatedAt
      final uniqueReports = <Map<String, dynamic>>[];
      final seenKeys = <String>{};
      
      for (final report in reports) {
        final key = '${report['symbol']}_${report['generatedAt']}';
        if (!seenKeys.contains(key)) {
          seenKeys.add(key);
          uniqueReports.add(report);
        }
      }
      
      // Sort by generation date (most recent first)
      uniqueReports.sort((a, b) {
        final aDate = DateTime.tryParse(a['generatedAt'] ?? '') ?? DateTime.now();
        final bDate = DateTime.tryParse(b['generatedAt'] ?? '') ?? DateTime.now();
        return bDate.compareTo(aDate);
      });
      
      debugPrint('ForecastStorageService: Returning ${uniqueReports.length} unique reports');
      
      return uniqueReports;
    } catch (e) {
      debugPrint('ForecastStorageService: Error fetching investment reports: $e');
      debugPrint('ForecastStorageService: Returning ${_localReports.length} local reports as fallback');
      return _localReports;
    }
  }

  // Get the most recent investment report
  Future<Map<String, dynamic>?> getMostRecentReport() async {
    try {
      final reports = await getInvestmentReports();
      return reports.isNotEmpty ? reports.first : null;
    } catch (e) {
      debugPrint('Error fetching most recent report: $e');
      return _localReports.isNotEmpty ? _localReports.first : null;
    }
  }

  // Delete a specific report
  Future<bool> deleteReport(String reportId) async {
    try {
      final response = await _httpClient.delete('/forecast/$reportId');
      return response['status'] == 'success';
    } catch (e) {
      debugPrint('Error deleting report: $e');
      return false;
    }
  }

  // Update existing report
  Future<bool> updateReport(String reportId, Map<String, dynamic> reportData) async {
    try {
      final response = await _httpClient.put(
        '/forecast/$reportId',
        reportData,
      );
      return response['status'] == 'success';
    } catch (e) {
      debugPrint('Error updating report: $e');
      return false;
    }
  }
  
  // Clear all local reports (useful for testing)
  void clearLocalReports() {
    _localReports.clear();
    debugPrint('ForecastStorageService: Cleared all local reports');
  }
  
  // Get local reports count (for debugging)
  int get localReportsCount => _localReports.length;
} 