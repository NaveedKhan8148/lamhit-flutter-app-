import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:lamhti_app/API%20Models/PaymentIntentAPIModel.dart';
import 'package:lamhti_app/Utils/Toast.dart';

class BuyerPayoutService {
  Future<PaymentIntentAPIModel?> createPaymentIntent(
    int amountInCents,
    String accountId,
  ) async {
    try {
      final url = Uri.parse(
        "https://lamhti-backend-kn795pm9z-lamhtis-projects.vercel.app/api/createPaymentIntent",
      );

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"amount": amountInCents, "accountId": accountId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return PaymentIntentAPIModel.fromJson(data);
      } else {
        return null;
      }
    } catch (e) {
      debugPrint("Error making purchase: $e");
      Toast.toastMessage("Unable to make purchase", Colors.red);
      return null;
    }
  }

  Future<bool> openPaymentSheet(String clientSecret) async {
    try {
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: "Lamhti",
          style: ThemeMode.light,
          customFlow: false,
        ),
      );
      await Stripe.instance
          .presentPaymentSheet()
          .then((value) {
            Toast.toastMessage("Payment Successful!", Colors.green);
          })
          .onError((error, stackTrace) {
            throw Exception(error);
          });
      return true;
    } on StripeException catch (e) {
      debugPrint("Payment Cancelled: ${e.error.localizedMessage}");

      Toast.toastMessage("Payment Cancelled !", Colors.red);
      return false;
    } catch (e) {
      debugPrint("Error: $e");
      return false;
    }
  }
}
