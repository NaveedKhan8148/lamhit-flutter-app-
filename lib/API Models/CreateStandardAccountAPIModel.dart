class CreateStandardAccountAPIModel {
  String? _accountId;

  CreateStandardAccountAPIModel({String? accountId}) {
    if (accountId != null) {
      this._accountId = accountId;
    }
  }

  String? get accountId => _accountId;
  set accountId(String? accountId) => _accountId = accountId;

  CreateStandardAccountAPIModel.fromJson(Map<String, dynamic> json) {
    _accountId = json['accountId'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['accountId'] = this._accountId;
    return data;
  }
}
