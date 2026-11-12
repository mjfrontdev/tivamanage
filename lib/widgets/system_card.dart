import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/system_controller.dart';
import '../models/system_model.dart';

class SystemCard extends StatelessWidget {
  final SystemModel system;
  const SystemCard({super.key, required this.system});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SystemController>();
    final auth = Get.find<AuthController>();
    final isOnline = system.isOnline;
    final statusColor = isOnline ? Colors.green : Colors.grey;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Get.toNamed('/system', arguments: system.id),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15), shape: BoxShape.circle),
              child: Icon(
                  system.os == 'Windows' ? Icons.desktop_windows : Icons.dns,
                  color: statusColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(system.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 2),
                  Text('${system.ip}  •  ${system.os}',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                ],
              ),
            ),
            // دکمه power فقط برای admin
            Obx(() {
              if (!auth.isAdmin) return const SizedBox.shrink();
              final busy = controller.busyIds.contains(system.id);
              if (busy) {
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                );
              }
              return IconButton(
                icon: Icon(
                    isOnline ? Icons.power_settings_new : Icons.play_arrow,
                    color: isOnline ? Colors.red : Colors.green),
                onPressed: () => controller.requestTogglePower(system),
              );
            }),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                        color: statusColor, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text(isOnline ? 'Online' : 'Offline',
                    style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

