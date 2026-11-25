import 'package:cell_info/models/common/network.dart';

import 'cdma_band.dart';
import 'cdma_signal.dart';

class Cdma {
  int? sid;
  int? nid;
  double? lat;
  double? lon;
  Band? band;
  int? bid;
  SignalCDMA? signalCDMA;
  String? connectionStatus;
  Network? network;
  int? subscriptionId;
  String? type;

  Cdma({
    this.sid,
    this.nid,
    this.lat,
    this.lon,
    this.band,
    this.bid,
    this.signalCDMA,
    this.connectionStatus,
    this.network,
    this.subscriptionId,
    this.type,
  });

  Cdma.fromJson(Map<String, dynamic> json) {
    band = json['band'] != null ? Band.fromJson(json['band']) : null;
    bid = json['bid'];
    sid = json['sid'];
    nid = json['nid'];
    lat = json['lat'];
    lon = json['lon'];
    signalCDMA = json['signalCDMA'] != null
        ? SignalCDMA.fromJson(json['signalCDMA'])
        : null;
    connectionStatus = json['connectionStatus'];
    subscriptionId = json['subscriptionId'];
    network = json['network'] != null
        ? Network.fromJson(json['network'])
        : null;
    type = json['type'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (band != null) {
      data['band'] = band!.toJson();
    }
    data['bid'] = bid;
    data['sid'] = sid;
    data['nid'] = nid;
    data['lat'] = lat;
    data['lon'] = lon;
    data['subscriptionId'] = subscriptionId;
    if (signalCDMA != null) {
      data['signalCDMA'] = signalCDMA!.toJson();
    }
    data['connectionStatus'] = connectionStatus;
    if (network != null) {
      data['network'] = network!.toJson();
    }
    data['type'] = type;
    return data;
  }
}
