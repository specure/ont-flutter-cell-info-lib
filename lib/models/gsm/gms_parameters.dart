import 'package:cell_info/models/common/network.dart';

import 'gsm_band.dart';
import 'gsm_signal.dart';

class Gsm {
  int? subscriptionId;
  int? cid;
  int? lac;
  int? bsic;
  BandGSM? bandGSM;
  SignalGSM? signalGSM;
  String? connectionStatus;
  Network? network;
  String? type;

  Gsm({
    this.subscriptionId,
    this.cid,
    this.lac,
    this.bsic,
    this.bandGSM,
    this.signalGSM,
    this.connectionStatus,
    this.network,
    this.type,
  });

  Gsm.fromJson(Map<String, dynamic> json) {
    bandGSM = json['bandGSM'] != null
        ? BandGSM.fromJson(json['bandGSM'])
        : null;
    signalGSM = json['signalGSM'] != null
        ? SignalGSM.fromJson(json['signalGSM'])
        : null;
    connectionStatus = json['connectionStatus'];
    cid = json['cid'];
    lac = json['lac'];
    bsic = json['bsic'];
    subscriptionId = json['subscriptionId'];
    network = json['network'] != null
        ? Network.fromJson(json['network'])
        : null;
    type = json['type'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (bandGSM != null) {
      data['bandGSM'] = bandGSM!.toJson();
    }
    if (signalGSM != null) {
      data['signalGSM'] = signalGSM!.toJson();
    }
    data['subscriptionId'] = subscriptionId;
    data['cid'] = cid;
    data['lac'] = lac;
    data['bsic'] = bsic;
    data['connectionStatus'] = connectionStatus;
    if (network != null) {
      data['network'] = network!.toJson();
    }
    data['type'] = type;
    return data;
  }
}
