import 'dart:io';
import 'package:flutter/material.dart';
import 'package:learnhub/data/repositories/certificate_repository_impl.dart';
import 'package:learnhub/domain/entities/certificate.dart';
import 'package:learnhub/domain/repositories/certificate_repository.dart';
import 'package:learnhub/core/utils/pdf_certificate_generator.dart';
import 'package:learnhub/core/utils/qr_code_generator.dart';
import 'package:learnhub/core/utils/certificate_sharing_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CertificateProvider extends ChangeNotifier {
  CertificateProvider({
    CertificateRepository? repository,
  }) : _repository = repository ?? CertificateRepositoryImpl();

  final CertificateRepository _repository;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Certificate> _allCertificates = [];
  List<Certificate> _filteredCertificates = [];
  String _filterType = 'All'; // All, Completed, In Progress, Shared
  bool _isLoading = false;
  String? _error;

  List<Certificate> get allCertificates => _allCertificates;
  List<Certificate> get filteredCertificates => _filteredCertificates;
  String get filterType => _filterType;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get totalEarned => _allCertificates
      .where((c) => c.completionPercentage >= 100)
      .length;

  int get inProgress => _allCertificates
      .where((c) => c.completionPercentage < 100)
      .length;

  double get averageScore {
    if (_allCertificates.isEmpty) return 0;
    final total = _allCertificates.fold<double>(
      0,
      (sum, cert) => sum + cert.completionPercentage,
    );
    return total / _allCertificates.length;
  }

  /// Initialize provider and load certificates from Firestore
  Future<void> initialize() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      _error = 'User not authenticated';
      notifyListeners();
      return;
    }

    try {
      _isLoading = true;
      notifyListeners();

      // Listen to real-time updates
      _repository.streamUserCertificates(userId).listen((certificates) {
        _allCertificates = certificates;
        _applyFilter();
        _isLoading = false;
        _error = null;
        notifyListeners();
      });
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Save certificate to Firestore
  Future<void> addCertificate(Certificate certificate) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      _isLoading = true;
      notifyListeners();

      // Save to Firestore
      await _repository.saveCertificate(userId, certificate);

      // Generate PDF and QR code
      await _generateAndSaveCertificatePdf(userId, certificate);

      _isLoading = false;
      _error = null;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
    }
    notifyListeners();
  }

  /// Generate PDF and save it
  Future<void> _generateAndSaveCertificatePdf(
    String userId,
    Certificate certificate,
  ) async {
    try {
      // Generate QR code
      final qrCodeBase64 = await QRCodeGenerator.generateQRCodeBase64(certificate);

      // Generate PDF
      final pdfBytes = await PDFCertificateGenerator.generateCertificatePdf(
        certificate,
        qrCodeImageBase64: qrCodeBase64,
      );

      // Save to local file
      final directory = await getApplicationDocumentsDirectory();
      final pdfPath = '${directory.path}/certificate_${certificate.id}.pdf';
      final file = File(pdfPath);
      await file.writeAsBytes(pdfBytes);

      // Update certificate URL in Firestore
      await _repository.updateCertificatePdfUrl(userId, certificate.id, pdfPath);
    } catch (e) {
      print('Error generating PDF: $e');
    }
  }

  /// Load certificates from Firestore
  Future<void> loadCertificates() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      _isLoading = true;
      notifyListeners();

      final certificates = await _repository.getUserCertificates(userId);
      _allCertificates = certificates;
      _applyFilter();

      _isLoading = false;
      _error = null;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
    }
    notifyListeners();
  }

  /// Download certificate PDF
  Future<String?> downloadCertificate(Certificate certificate) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return null;

    try {
      _isLoading = true;
      notifyListeners();

      final qrCodeBase64 = await QRCodeGenerator.generateQRCodeBase64(certificate);
      final pdfBytes = await PDFCertificateGenerator.generateCertificatePdf(
        certificate,
        qrCodeImageBase64: qrCodeBase64,
      );

      final directory = await getApplicationDocumentsDirectory();
      final pdfPath = '${directory.path}/certificate_${certificate.id}.pdf';
      final file = File(pdfPath);
      await file.writeAsBytes(pdfBytes);

      _isLoading = false;
      return pdfPath;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Share certificate
  Future<void> shareCertificate(Certificate certificate) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      final pdfPath = await downloadCertificate(certificate);
      if (pdfPath != null) {
        await CertificateSharingService.shareCertificate(
          certificate,
          pdfPath: pdfPath,
        );
      }
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
  }

  /// Share to WhatsApp
  Future<void> shareToWhatsApp(Certificate certificate) async {
    try {
      await CertificateSharingService.shareToWhatsApp(certificate);
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
  }

  /// Share to Twitter
  Future<void> shareToTwitter(Certificate certificate) async {
    try {
      await CertificateSharingService.shareToTwitter(certificate);
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
  }

  /// Share to Facebook
  Future<void> shareToFacebook(
    Certificate certificate, {
    required String certificateUrl,
  }) async {
    try {
      await CertificateSharingService.shareToFacebook(
        certificate,
        certificateUrl: certificateUrl,
      );
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
  }

  /// Get QR code data for verification
  String getQRCodeData(Certificate certificate) {
    return QRCodeGenerator.generateQRData(certificate);
  }

  /// Verify QR code
  Map<String, String>? verifyQRCode(String qrData) {
    return QRCodeGenerator.verifyQRData(qrData);
  }

  void setFilterType(String filterType) {
    _filterType = filterType;
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    switch (_filterType) {
      case 'Completed':
        _filteredCertificates = _allCertificates
            .where((c) => c.completionPercentage >= 100)
            .toList();
        break;
      case 'In Progress':
        _filteredCertificates = _allCertificates
            .where((c) => c.completionPercentage < 100)
            .toList();
        break;
      case 'Shared':
        _filteredCertificates = _allCertificates
            .where((c) => c.certificateUrl.isNotEmpty)
            .toList();
        break;
      default:
        _filteredCertificates = _allCertificates;
    }
  }

  Certificate? getCertificateById(String id) {
    try {
      return _allCertificates.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Delete certificate
  Future<void> deleteCertificate(String certificateId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      await _repository.deleteCertificate(userId, certificateId);
      _allCertificates.removeWhere((c) => c.id == certificateId);
      _applyFilter();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
