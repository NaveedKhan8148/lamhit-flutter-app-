class CheckAccountStatusAPIModel {
  bool? _chargesEnabled;
  bool? _payoutsEnabled;
  bool? _detailsSubmitted;

  CheckAccountStatusAPIModel(
      {bool? chargesEnabled, bool? payoutsEnabled, bool? detailsSubmitted}) {
    if (chargesEnabled != null) {
      this._chargesEnabled = chargesEnabled;
    }
    if (payoutsEnabled != null) {
      this._payoutsEnabled = payoutsEnabled;
    }
    if (detailsSubmitted != null) {
      this._detailsSubmitted = detailsSubmitted;
    }
  }

  bool? get chargesEnabled => _chargesEnabled;
  set chargesEnabled(bool? chargesEnabled) => _chargesEnabled = chargesEnabled;
  bool? get payoutsEnabled => _payoutsEnabled;
  set payoutsEnabled(bool? payoutsEnabled) => _payoutsEnabled = payoutsEnabled;
  bool? get detailsSubmitted => _detailsSubmitted;
  set detailsSubmitted(bool? detailsSubmitted) =>
      _detailsSubmitted = detailsSubmitted;

  CheckAccountStatusAPIModel.fromJson(Map<String, dynamic> json) {
    _chargesEnabled = json['charges_enabled'];
    _payoutsEnabled = json['payouts_enabled'];
    _detailsSubmitted = json['details_submitted'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['charges_enabled'] = this._chargesEnabled;
    data['payouts_enabled'] = this._payoutsEnabled;
    data['details_submitted'] = this._detailsSubmitted;
    return data;
  }
}
