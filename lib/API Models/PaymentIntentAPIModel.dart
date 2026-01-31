class PaymentIntentAPIModel {
  String? _clientSecret;

  PaymentIntentAPIModel({String? clientSecret}) {
    if (clientSecret != null) {
      this._clientSecret = clientSecret;
    }
  }

  String? get clientSecret => _clientSecret;
  set clientSecret(String? clientSecret) => _clientSecret = clientSecret;

  PaymentIntentAPIModel.fromJson(Map<String, dynamic> json) {
    _clientSecret = json['clientSecret'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['clientSecret'] = this._clientSecret;
    return data;
  }
}
