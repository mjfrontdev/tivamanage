class SystemModel {
  final String id;
  final String name;
  final String ip;
  final String os;
  final bool isOnline;
  final DateTime? lastSeen;
  final String cpu;
  final String ram;
  final String uptime;

  SystemModel({
    required this.id,
    required this.name,
    required this.ip,
    required this.os,
    required this.isOnline,
    this.lastSeen,
    this.cpu = '-',
    this.ram = '-',
    this.uptime = '-',
  });

  factory SystemModel.fromJson(Map<String, dynamic> json) => SystemModel(
        id: json['id'] as String,
        name: json['name'] as String,
        ip: json['ip'] as String,
        os: json['os'] as String,
        isOnline: json['isOnline'] as bool? ?? false,
        lastSeen: json['last_seen'] != null
            ? DateTime.parse(json['last_seen'] as String)
            : null,
        cpu: json['cpu'] as String? ?? '-',
        ram: json['ram'] as String? ?? '-',
        uptime: json['uptime'] as String? ?? '-',
      );

  SystemModel copyWith({bool? isOnline}) => SystemModel(
        id: id, name: name, ip: ip, os: os,
        isOnline: isOnline ?? this.isOnline,
        lastSeen: lastSeen, cpu: cpu, ram: ram, uptime: uptime,
      );
}
