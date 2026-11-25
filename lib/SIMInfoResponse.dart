class SIMInfoResponse {
  List<SimInfoList>? simInfoList;

  SIMInfoResponse({this.simInfoList});

  SIMInfoResponse.fromJson(Map<String, dynamic> json) {
    if (json['simInfoList'] != null) {
      simInfoList = [];
      json['simInfoList'].forEach((v) {
        simInfoList!.add(SimInfoList.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (simInfoList != null) {
      data['simInfoList'] = simInfoList!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class SimInfoList {
  String? carrierName;
  String? displayName;
  int? mcc;
  int? mnc;
  String? subscriptionInfoNumber;
  int? subscriptionId;
  bool? isDefaultDataSubscription;
  String? countryIso;
  String? networkCountryIso;
  bool? roaming;

  SimInfoList({
    this.carrierName,
    this.displayName,
    this.mcc,
    this.mnc,
    this.subscriptionInfoNumber,
    this.subscriptionId,
    this.isDefaultDataSubscription,
    this.countryIso,
    this.networkCountryIso,
    this.roaming,
  });

  SimInfoList.fromJson(Map<String, dynamic> json) {
    carrierName = json['carrierName'];
    displayName = json['displayName'];
    mcc = json['mcc'];
    mnc = json['mnc'];
    subscriptionInfoNumber = json['subscriptionInfoNumber'];
    subscriptionId = json['subscriptionId'];
    isDefaultDataSubscription = json['isDefaultDataSubscription'];
    countryIso = json['countryIso'];
    networkCountryIso = json['networkCountryIso'];
    roaming = json['roaming'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['carrierName'] = carrierName;
    data['displayName'] = displayName;
    data['mcc'] = mcc;
    data['mnc'] = mnc;
    data['subscriptionInfoNumber'] = subscriptionInfoNumber;
    data['subscriptionId'] = subscriptionId;
    data['isDefaultDataSubscription'] = isDefaultDataSubscription;
    data['countryIso'] = countryIso;
    data['networkCountryIso'] = networkCountryIso;
    data['roaming'] = roaming;
    return data;
  }
}
