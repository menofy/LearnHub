import '../../domain/entities/certificate.dart';
import '../../domain/repositories/certificate_repository.dart';
import '../services/firestore_service.dart';

class CertificateRepositoryImpl implements CertificateRepository {
  CertificateRepositoryImpl({
    FirestoreService? firestoreService,
  }) : _firestoreService = firestoreService ?? FirestoreService.instance;

  final FirestoreService _firestoreService;

  @override
  Future<void> saveCertificate(String userId, Certificate certificate) async {
    await _firestoreService.saveCertificate(userId, certificate.toMap());
  }

  @override
  Future<List<Certificate>> getUserCertificates(String userId) async {
    final certificateMaps = await _firestoreService.getUserCertificates(userId);
    return certificateMaps
        .map((map) => Certificate.fromMap(map))
        .toList();
  }

  @override
  Stream<List<Certificate>> streamUserCertificates(String userId) {
    return _firestoreService
        .streamUserCertificates(userId)
        .map((certificateMaps) {
      return certificateMaps
          .map((map) => Certificate.fromMap(map))
          .toList();
    });
  }

  @override
  Future<Certificate?> getCertificateById(String userId, String certificateId) async {
    final certificateMap = await _firestoreService.getCertificateById(userId, certificateId);
    if (certificateMap == null) return null;
    return Certificate.fromMap(certificateMap);
  }

  @override
  Future<void> updateCertificatePdfUrl(String userId, String certificateId, String pdfUrl) async {
    await _firestoreService.updateCertificatePdfUrl(userId, certificateId, pdfUrl);
  }

  @override
  Future<void> shareCertificate(String userId, String certificateId, List<String> sharedWith) async {
    await _firestoreService.shareCertificate(userId, certificateId, sharedWith);
  }

  @override
  Future<void> deleteCertificate(String userId, String certificateId) async {
    await _firestoreService.deleteCertificate(userId, certificateId);
  }
}
