class Band {
  int? channelNumber;
  String? name;
  int? number;

  Band({this.channelNumber, this.name, this.number});

  Band.fromJson(Map<String, dynamic> json) {
    channelNumber = json['channelNumber'];
    name = json['name'];
    number = json['number'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['channelNumber'] = channelNumber;
    data['name'] = name;
    data['number'] = number;
    return data;
  }
}
