import 'package:cell_info/models/common/network.dart';
import 'package:cell_info/models/wcdma/wcdma_band.dart';
import 'package:cell_info/models/wcdma/wcdma_signal.dart';

class Wcdma {
  int? ci;
  int? cid;
  int? lac;
  int? psc;
  int? rnc;
  String? cgi;
  int? subscriptionId;
  BandWCDMA? bandWCDMA;
  SignalWCDMA? signalWCDMA;
  String? connectionStatus;
  Network? network;
  String? type;

  Wcdma({
    this.ci,
    this.cid,
    this.lac,
    this.psc,
    this.rnc,
    this.cgi,
    this.subscriptionId,
    this.bandWCDMA,
    this.signalWCDMA,
    this.connectionStatus,
    this.network,
    this.type,
  });

  Wcdma.fromJson(Map<String, dynamic> json) {
    bandWCDMA = json['bandWCDMA'] != null
        ? BandWCDMA.fromJson(json['bandWCDMA'])
        : null;
    signalWCDMA = json['signalWCDMA'] != null
        ? SignalWCDMA.fromJson(json['signalWCDMA'])
        : null;
    connectionStatus = json['connectionStatus'];
    subscriptionId = json['subscriptionId'];
    ci = json['ci'];
    cid = json['cid'];
    lac = json['lac'];
    psc = json['psc'];
    rnc = json['rnc'];
    cgi = json['cgi'];
    network = json['network'] != null
        ? Network.fromJson(json['network'])
        : null;
    type = json['type'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (bandWCDMA != null) {
      data['bandWCDMA'] = bandWCDMA!.toJson();
    }
    if (signalWCDMA != null) {
      data['signalWCDMA'] = signalWCDMA!.toJson();
    }
    data['connectionStatus'] = connectionStatus;
    data['subscriptionId'] = subscriptionId;
    data['ci'] = ci;
    data['cid'] = cid;
    data['lac'] = lac;
    data['psc'] = psc;
    data['rnc'] = rnc;
    data['cgi'] = cgi;
    if (network != null) {
      data['network'] = network!.toJson();
    }
    data['type'] = type;
    return data;
  }
}
