import '../entities/certificate.dart';

abstract class CertificateRepository {
  Future<void> saveCertificate(String userId, Certificate certificate);
  
  Future<List<Certificate>> getUserCertificates(String userId);
  
  Stream<List<Certificate>> streamUserCertificates(String userId);
  
  Future<Certificate?> getCertificateById(String userId, String certificateId);
  
  Future<void> updateCertificatePdfUrl(String userId, String certificateId, String pdfUrl);
  
  Future<void> shareCertificate(String userId, String certificateId, List<String> sharedWith);
  
  Future<void> deleteCertificate(String userId, String certificateId);
}
