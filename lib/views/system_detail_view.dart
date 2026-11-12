import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/system_controller.dart';
import '../services/system_service.dart';

class SystemDetailView extends StatefulWidget {
  const SystemDetailView({super.key});
  @override
  State<SystemDetailView> createState() => _SystemDetailViewState();
}

class _SystemDetailViewState extends State<SystemDetailView> {
  final controller = Get.find<SystemController>();
  final auth = Get.find<AuthController>();
  List<SystemEvent> events = [];
  bool loadingEvents = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final id = Get.arguments as String;
    try {
      final e = await controller.fetchEvents(id);
      if (mounted) setState(() { events = e; loadingEvents = false; });
    } catch (_) {
      if (mounted) setState(() => loadingEvents = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final id = Get.arguments as String;
    return Scaffold(
      appBar: AppBar(title: Obx(() {
        final s = controller.findById(id);
        return Text(s?.name ?? 'System');
      })),
      body: Obx(() {
        final s = controller.findById(id);
        if (s == null) return const Center(child: Text('Not found'));
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: (s.isOnline ? Colors.green : Colors.grey).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(children: [
                Icon(s.os == 'Windows' ? Icons.desktop_windows : Icons.dns,
                    size: 48, color: s.isOnline ? Colors.green : Colors.grey),
                const SizedBox(width: 16),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(s.isOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: s.isOnline ? Colors.green : Colors.grey)),
                  const SizedBox(height: 4),
                  Text('${s.ip}  •  ${s.os}'),
                ]),
              ]),
            ),
            const SizedBox(height: 16),
            _card('System Info', [
              _row('Name', s.name),
              _row('IP', s.ip),
              _row('OS', s.os),
              _row('Last Seen', _fmt(s.lastSeen)),
            ]),
            const SizedBox(height: 16),
            if (s.isOnline)
              _card('Resources', [
                _row('CPU', s.cpu),
                _row('RAM', s.ram),
                _row('Uptime', s.uptime),
              ]),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 8),
              child: Text('Recent Events',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            ),
            if (loadingEvents)
              const Center(child: Padding(
                  padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
            else if (events.isEmpty)
              const Padding(padding: EdgeInsets.all(16), child: Text('No events'))
            else
              Card(
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Column(children: events.map((e) {
                  final isOn = e.type == 'power_on';
                  return ListTile(
                    leading: Icon(isOn ? Icons.power : Icons.power_off,
                        color: isOn ? Colors.green : Colors.red, size: 20),
                    title: Text(e.message, style: const TextStyle(fontSize: 14)),
                    trailing: Text(_t(e.timestamp),
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  );
                }).toList()),
              ),
            const SizedBox(height: 80),
          ],
        );
      }),
      floatingActionButton: Obx(() {
        if (!auth.isAdmin) return const SizedBox.shrink();
        final s = controller.findById(id);
        if (s == null) return const SizedBox.shrink();
        final busy = controller.busyIds.contains(s.id);
        return FloatingActionButton.extended(
          onPressed: busy ? null : () => controller.requestTogglePower(s),
          backgroundColor: s.isOnline ? Colors.red : Colors.green,
          icon: busy
              ? const SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Icon(s.isOnline ? Icons.power_settings_new : Icons.play_arrow),
          label: Text(s.isOnline ? 'Shutdown' : 'Power On'),
        );
      }),
    );
  }

  Widget _card(String title, List<Widget> children) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(title,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          Card(
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(children: children),
            ),
          ),
        ],
      );

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ]),
      );

  String _fmt(DateTime? dt) => dt == null
      ? '-'
      : '${dt.year}-${dt.month.toString().padLeft(2, '0')}-'
          '${dt.day.toString().padLeft(2, '0')} ${_t(dt)}';
  String _t(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}';
}


