import 'package:cell_info/models/common/network.dart';
import 'package:cell_info/models/tds_cdma/tds_cdma_signal.dart';
import 'package:cell_info/models/wcdma/wcdma_band.dart';

class Tdscdma {
  int? subscriptionId;
  int? ci;
  int? cid;
  int? lac;
  int? cpid;
  int? rnc;
  String? cgi;
  BandWCDMA? bandTDSCDMA;
  SignalTDSCDMA? signalTDSCDMA;
  String? connectionStatus;
  Network? network;
  String? type;

  Tdscdma({
    this.subscriptionId,
    this.ci,
    this.cid,
    this.lac,
    this.cpid,
    this.rnc,
    this.cgi,
    this.bandTDSCDMA,
    this.signalTDSCDMA,
    this.connectionStatus,
    this.network,
    this.type,
  });

  Tdscdma.fromJson(Map<String, dynamic> json) {
    bandTDSCDMA = json['bandTDSCDMA'] != null
        ? BandWCDMA.fromJson(json['bandTDSCDMA'])
        : null;
    signalTDSCDMA = json['signalTDSCDMA'] != null
        ? SignalTDSCDMA.fromJson(json['signalTDSCDMA'])
        : null;
    connectionStatus = json['connectionStatus'];
    subscriptionId = json['subscriptionId'];
    ci = json['ci'];
    cid = json['cid'];
    lac = json['lac'];
    cpid = json['cpid'];
    rnc = json['rnc'];
    cgi = json['cgi'];
    network = json['network'] != null
        ? Network.fromJson(json['network'])
        : null;
    type = json['type'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (bandTDSCDMA != null) {
      data['bandTDSCDMA'] = bandTDSCDMA!.toJson();
    }
    if (signalTDSCDMA != null) {
      data['signalTDSCDMA'] = signalTDSCDMA!.toJson();
    }
    data['connectionStatus'] = connectionStatus;
    data['subscriptionId'] = subscriptionId;
    data['ci'] = ci;
    data['cid'] = cid;
    data['lac'] = lac;
    data['cpid'] = cpid;
    data['cgi'] = cgi;
    data['rnc'] = rnc;
    if (network != null) {
      data['network'] = network!.toJson();
    }
    data['type'] = type;
    return data;
  }
}
