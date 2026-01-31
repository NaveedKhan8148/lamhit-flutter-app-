// import 'dart:developer';

// import 'package:flutter/material.dart';
// import 'package:enough_mail/enough_mail.dart';

// /// ───────── SMTP "config" similar to EmailOTP.setSMTP / .config ─────────
// class SmtpConfig {
//   static String host = 'smtp.gmail.com';
//   static int port = 587;
//   static bool useStartTls = true;
//   static String username = '';
//   static String password = '';
//   static String fromName = 'Lamhti';
//   static String appEmail = '';

//   static Future<void> setSMTP({
//     required String host,
//     required int port,
//     required bool useStartTls,
//     required String username,
//     required String password,
//   }) async {
//     SmtpConfig.host = host;
//     SmtpConfig.port = port;
//     SmtpConfig.useStartTls = useStartTls;
//     SmtpConfig.username = username;
//     SmtpConfig.password = password;
//   }

//   static Future<void> config({
//     required String appEmail,
//     required String appName,
//   }) async {
//     SmtpConfig.appEmail = appEmail;
//     SmtpConfig.fromName = appName;
//   }
// }

// /// ───────── Minimal mail sender (plain-text) ─────────
// class MailSender {
//   static Future<bool> send({
//     required String toEmail,
//     required String subject,
//     required String textBody,
//   }) async {
//     // Guard rails
//     if (SmtpConfig.username.trim().isEmpty ||
//         SmtpConfig.password.trim().isEmpty) {
//       log('[mail] Missing SMTP username/password.');
//       return false;
//     }
//     if (toEmail.trim().isEmpty) {
//       log('[mail] Empty recipient.');
//       return false;
//     }
//     if (subject.trim().isEmpty) {
//       log('[mail] Empty subject.');
//       return false;
//     }
//     if (textBody.trim().isEmpty) {
//       log('[mail] Empty body.');
//       return false;
//     }

//     final client = SmtpClient('gmail-sender');
//     try {
//       await client.connectToServer(
//         SmtpConfig.host,
//         SmtpConfig.port,
//         isSecure: false,
//       );
//       await client.ehlo();

//       if (SmtpConfig.useStartTls) {
//         await client.startTls();
//         await client.ehlo();
//       }

//       // 3) Auth with App Password (no enum needed)
//       await client.authenticate(SmtpConfig.username, SmtpConfig.password);

//       // 4) Build a simple text email
//       final builder =
//           MessageBuilder()
//             ..from = [MailAddress(SmtpConfig.fromName, SmtpConfig.username)]
//             ..to = [MailAddress(null, toEmail)]
//             ..subject = subject
//             ..text = textBody;

//       final mimeMessage = builder.buildMimeMessage();

//       // 5) Send & Quit
//       await client.sendMessage(mimeMessage);
//       await client.quit();
//       return true;
//     } catch (e) {
//       log('[mail] Send failed: $e');
//       try {
//         await client.disconnect();
//       } catch (_) {}
//       return false;
//     }
//   }
// }

// /// ───────── Demo UI: enter email → send fixed message ─────────

import 'dart:developer';
import 'package:enough_mail/enough_mail.dart';

class SmtpConfig {
  static String host = 'smtp.gmail.com';
  static String username = ''; // full gmail address
  static String password = ''; // Gmail App Password
  static String fromName = 'Lamhti';
  static String fromEmail = ''; // same as username (or a verified alias)

  static Future<void> setup({
    required String gmailAddress,
    required String appPassword,
    String displayName = 'Lamhti',
  }) async {
    username = gmailAddress;
    fromEmail = gmailAddress;
    password = appPassword;
    fromName = displayName;
  }
}

class MailSender {
  /// Public API
  static Future<bool> send({
    required String toEmail,
    required String subject,
    required String textBody,
  }) async {
    if (SmtpConfig.username.isEmpty || SmtpConfig.password.isEmpty) {
      log('[mail] Missing Gmail/App Password');
      return false;
    }
    if (toEmail.trim().isEmpty) {
      log('[mail] Empty recipient');
      return false;
    }

    // 1) Try 587 + STARTTLS
    final ok587 = await _sendVia587(
      toEmail: toEmail,
      subject: subject,
      textBody: textBody,
    );
    if (ok587) return true;

    // 2) Fallback to 465 + SSL
    final ok465 = await _sendVia465(
      toEmail: toEmail,
      subject: subject,
      textBody: textBody,
    );
    return ok465;
  }

  static MessageBuilder _build(
    String toEmail,
    String subject,
    String textBody,
  ) {
    final builder =
        MessageBuilder()
          ..from = [MailAddress(SmtpConfig.fromName, SmtpConfig.fromEmail)]
          ..to = [MailAddress(null, toEmail)]
          ..subject = subject
          ..text = textBody;
    return builder;
  }

  static Future<bool> _sendVia587({
    required String toEmail,
    required String subject,
    required String textBody,
  }) async {
    final client = SmtpClient('lamhti-smtp-587');
    try {
      log('[mail] Connecting 587 STARTTLS…');
      await client.connectToServer(
        'smtp.gmail.com',
        587,
        isSecure: false,
        timeout: const Duration(seconds: 15),
      );
      await client.ehlo();
      await client.startTls();
      await client.ehlo();

      await client.authenticate(SmtpConfig.username, SmtpConfig.password);
      final mime = _build(toEmail, subject, textBody).buildMimeMessage();
      await client.sendMessage(mime);
      await client.quit();
      log('[mail] ✅ Sent via 587 STARTTLS');
      return true;
    } catch (e) {
      log('[mail] 587 failed: $e');
      try {
        await client.disconnect();
      } catch (_) {}
      return false;
    }
  }

  static Future<bool> _sendVia465({
    required String toEmail,
    required String subject,
    required String textBody,
  }) async {
    final client = SmtpClient('lamhti-smtp-465');
    try {
      log('[mail] Connecting 465 SSL…');
      await client.connectToServer(
        'smtp.gmail.com',
        465,
        isSecure: true,
        timeout: const Duration(seconds: 15),
      );
      await client.ehlo();

      await client.authenticate(SmtpConfig.username, SmtpConfig.password);
      final mime = _build(toEmail, subject, textBody).buildMimeMessage();
      await client.sendMessage(mime);
      await client.quit();
      log('[mail] ✅ Sent via 465 SSL');
      return true;
    } catch (e) {
      log('[mail] 465 failed: $e');
      try {
        await client.disconnect();
      } catch (_) {}
      return false;
    }
  }
}
