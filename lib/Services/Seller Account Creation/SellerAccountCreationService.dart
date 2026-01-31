import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lamhti_app/API%20Models/CheckAccountStatusAPIModel.dart';
import 'package:lamhti_app/API%20Models/CreateStandardAccountAPIModel.dart';
import 'package:lamhti_app/API%20Models/GenerateOnboardingLinkAPIModel.dart';
import 'package:lamhti_app/Utils/Toast.dart';

class SellerAccountCreationService {
  final String baseUrl =
      "https://lamhti-backend-kn795pm9z-lamhtis-projects.vercel.app/api";

  /// ✅ Create Account
  Future<CreateStandardAccountAPIModel?> createAccountId() async {
    try {
      final url = Uri.parse("$baseUrl/createStandardAccount");
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      debugPrint("🔍 createAccountId() response: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return CreateStandardAccountAPIModel.fromJson(data);
      } else {
        debugPrint("❌ Failed to create account. Status: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      debugPrint("❌ Error Creating Account Id: $e");
      return null;
    }
  }

  /// ✅ Generate Onboarding Link
  Future<GenerateOnboardingLinkAPIModel?> generateOnboardingLink(
      String accountId) async {
    try {
      final url = Uri.parse("$baseUrl/generateOnboardingLink");
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"accountId": accountId}),
      );

      debugPrint("🔍 generateOnboardingLink() response: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return GenerateOnboardingLinkAPIModel.fromJson(data);
      } else {
        debugPrint("❌ Failed to generate link. Status: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      debugPrint("❌ Error Generating Onboarding Link: $e");
      Toast.toastMessage("Error Generating Onboarding Link: $e", Colors.red);
      return null;
    }
  }

  /// ✅ Check Onboarding Status
  Future<CheckAccountStatusAPIModel?> checkOnboardingStatus(
      String accountId) async {
    try {
      final url = Uri.parse("$baseUrl/checkAccountStatus");
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"accountId": accountId}),
      );

      debugPrint("🔍 checkOnboardingStatus() response: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return CheckAccountStatusAPIModel.fromJson(data);
      } else {
        debugPrint(
            "❌ Failed to check onboarding status. Status: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      debugPrint("❌ Error Checking Onboarding Account Status: $e");
      Toast.toastMessage("Error Checking Onboarding Account Status: $e", Colors.red);
      return null;
    }
  }
}
