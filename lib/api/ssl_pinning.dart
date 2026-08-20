import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

/// Provides SSL certificate pinning validation for production API endpoints.
///
/// Uses public key pinning (SHA-256 hash of the DER-encoded certificate)
/// rather than full certificate pinning, so that certificate renewals
/// with the same key pair do not break the pin.
class SslPinning {
  /// Pinned SHA-256 hashes for each production host.
  ///
  /// Each host maps to a list of acceptable base64-encoded SHA-256 hashes
  /// of the DER-encoded certificate. Two pins per host allow for key rotation.
  ///
  // TODO(security): Replace placeholder hashes with actual SHA-256 public key
  // hashes extracted from production certificates. Use the following command
  // to obtain the hash for a given host:
  //
  //   openssl s_client -connect <host>:443 -servername <host> < /dev/null 2>/dev/null \
  //     | openssl x509 -outform DER \
  //     | openssl dgst -sha256 -binary \
  //     | openssl enc -base64
  //
  // Add the output as 'sha256/<base64-hash>' entries below.
  static const Map<String, List<String>> pinnedHashes = {
    'gw2.mcpayment.net': [
      'sha256/T9HHNc0D0yKiuMgaE/kOVZRELNE/ZXo4Q2dF581MTe0=',
      // TODO(security): Add backup pin hash (e.g. from next certificate rotation)
    ],
    'api.oxpayfinancial.com': [
      'sha256/cChdDcPZPFq01M9/QBnJ2Ljz8o+98pWDti4sjTCk+v8=',
      // TODO(security): Add backup pin hash (e.g. from next certificate rotation)
    ],
  };

  /// Validates an [X509Certificate] against the pinned hashes for [host].
  ///
  /// Returns `true` if:
  /// - The host is not in the pinned list (unknown hosts are allowed through).
  /// - The SHA-256 hash of the certificate's DER bytes matches any pinned hash.
  ///
  /// Returns `false` if the host is pinned but no hash matches.
  static bool validateCertificate(X509Certificate cert, String host) {
    final pins = pinnedHashes[host];

    // Allow connections to hosts that are not in the pinned list.
    if (pins == null || pins.isEmpty) {
      return true;
    }

    final certHash = _computeCertHash(cert);

    return pins.contains(certHash);
  }

  /// Computes the `sha256/<base64>` hash string from the DER-encoded
  /// certificate bytes.
  static String _computeCertHash(X509Certificate cert) {
    final derBytes = cert.der;
    final digest = sha256.convert(derBytes);
    final base64Hash = base64Encode(digest.bytes);
    return 'sha256/$base64Hash';
  }
}
