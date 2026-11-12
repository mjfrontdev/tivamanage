import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/system_model.dart';
import '../services/system_service.dart';
import '../services/realtime_service.dart';

class SystemController extends GetxController {
  final SystemService _service = SystemService();
  final RealtimeService _rt = RealtimeService();

  final systems = <SystemModel>[].obs;
  final isLoading = true.obs;
  final lastUpdated = DateTime.now().obs;
  final busyIds = <String>{}.obs;
  final connectionStatus = 'connecting'.obs;

  StreamSubscription? _sysSub;
  StreamSubscription? _statusSub;

  int get onlineCount => systems.where((s) => s.isOnline).length;
  int get offlineCount => systems.where((s) => !s.isOnline).length;

  @override
  void onInit() {
    super.onInit();
    loadSystems();
    _startRealtime();
  }

  @override
  void onClose() {
    _sysSub?.cancel();
    _statusSub?.cancel();
    _rt.dispose();
    super.onClose();
  }

  void _startRealtime() {
    _statusSub = _rt.statusStream.listen((s) => connectionStatus.value = s);
    _sysSub = _rt.systemsStream.listen(_applyIncoming);
    _rt.connect();
  }

  void _applyIncoming(List<dynamic> raw) {
    final incoming = raw
        .map((e) => SystemModel.fromJson(e as Map<String, dynamic>))
        .toList();
    for (final inc in incoming) {
      final old = systems.firstWhereOrNull((s) => s.id == inc.id);
      if (old != null && old.isOnline != inc.isOnline) {
        Get.snackbar(
          inc.isOnline ? '🟢 Back Online' : '🔴 Went Offline',
          inc.name,
          snackPosition: SnackPosition.TOP,
          backgroundColor: inc.isOnline ? Colors.green : Colors.red.shade700,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
          margin: const EdgeInsets.all(12),
        );
      }
    }
    systems.value = incoming;
    lastUpdated.value = DateTime.now();
  }

  Future<void> loadSystems() async {
    isLoading.value = true;
    try {
      systems.value = await _service.fetchSystems();
      lastUpdated.value = DateTime.now();
    } catch (e) {
      if (e.toString().contains('UNAUTHORIZED')) {
        Get.offAllNamed('/login');
      } else {
        Get.snackbar('Backend Offline', 'Could not load systems',
            backgroundColor: Colors.orange, colorText: Colors.white);
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> reload() async => loadSystems();

  SystemModel? findById(String id) {
    try {
      return systems.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<List<SystemEvent>> fetchEvents(String id) => _service.getEvents(id);

  Future<void> requestTogglePower(SystemModel system) async {
    if (busyIds.contains(system.id)) return;

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text(system.isOnline ? 'Shutdown System' : 'Power On System'),
        content: Text(
            system.isOnline
                ? 'Send SHUTDOWN to "${system.name}"?\n\n⚠️ This will really shut down the machine!'
                : 'Send POWER-ON to "${system.name}"?\n\n(Power-on via WoL not implemented yet)'),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: system.isOnline ? Colors.red : Colors.green,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Get.back(result: true),
            child: Text(system.isOnline ? 'Shutdown' : 'Power On'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    busyIds.add(system.id);
    try {
      final updated =
          await _service.powerAction(system.id, system.isOnline ? 'off' : 'on');
      final idx = systems.indexWhere((s) => s.id == system.id);
      if (idx != -1) systems[idx] = updated;
      Get.snackbar(
        'Command Sent',
        system.isOnline
            ? 'Shutdown queued for ${system.name}'
            : 'Power-on queued for ${system.name}',
        backgroundColor: Colors.blue,
        colorText: Colors.white,
      );
    } catch (e) {
      if (e.toString().contains('UNAUTHORIZED')) {
        Get.offAllNamed('/login');
      } else if (e.toString().contains('403')) {
        Get.snackbar('Access Denied', 'Only admin can control power',
            backgroundColor: Colors.red, colorText: Colors.white);
      } else {
        Get.snackbar('Error', 'Operation failed',
            backgroundColor: Colors.red, colorText: Colors.white);
      }
    } finally {
      busyIds.remove(system.id);
    }
  }
}

