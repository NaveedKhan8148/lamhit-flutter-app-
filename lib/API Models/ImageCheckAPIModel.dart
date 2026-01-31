class ImageCheckAPIModel {
  String? status;
  String? imageHash;
  String? userId;
  Reasons? reasons;
  String? overallReason;

  ImageCheckAPIModel({
    this.status,
    this.imageHash,
    this.userId,
    this.reasons,
    this.overallReason,
  });

  ImageCheckAPIModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    imageHash = json['image_hash'];
    userId = json['userId'];
    reasons =
        json['reasons'] != null ? new Reasons.fromJson(json['reasons']) : null;
    overallReason = json['overall_reason'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this.status;
    data['image_hash'] = this.imageHash;
    data['userId'] = this.userId;
    if (this.reasons != null) {
      data['reasons'] = this.reasons!.toJson();
    }
    data['overall_reason'] = this.overallReason;
    return data;
  }
}

class Reasons {
  String? resolutionCheck;
  String? originalityCheck;
  String? duplicateCheck;

  Reasons({this.resolutionCheck, this.originalityCheck, this.duplicateCheck});

  Reasons.fromJson(Map<String, dynamic> json) {
    resolutionCheck = json['resolution_check'];
    originalityCheck = json['originality_check'];
    duplicateCheck = json['duplicate_check'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['resolution_check'] = this.resolutionCheck;
    data['originality_check'] = this.originalityCheck;
    data['duplicate_check'] = this.duplicateCheck;
    return data;
  }
}
