import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/system_controller.dart';
import '../widgets/system_card.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SystemController());
    final auth = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Company Systems'),
        actions: [
          Obx(() {
            final status = controller.connectionStatus.value;
            final color = status == 'connected'
                ? Colors.green
                : status == 'reconnecting'
                    ? Colors.orange
                    : Colors.red;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(children: [
                Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Text(status, style: const TextStyle(fontSize: 11)),
              ]),
            );
          }),
          IconButton(icon: const Icon(Icons.refresh), onPressed: controller.reload),
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle),
            onSelected: (v) {
              if (v == 'logout') auth.showLogoutDialog();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(auth.username.value,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(auth.role.value,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'logout', child: Text('Logout')),
            ],
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.systems.isEmpty) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
              const SizedBox(height: 12),
              const Text('No systems / backend unreachable'),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: controller.reload, child: const Text('Retry')),
            ]),
          );
        }
        return Column(children: [
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _summary('Total', controller.systems.length.toString(), Colors.blue),
                _summary('Online', controller.onlineCount.toString(), Colors.green),
                _summary('Offline', controller.offlineCount.toString(), Colors.grey),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: controller.reload,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: controller.systems.length,
                itemBuilder: (ctx, i) => SystemCard(system: controller.systems[i]),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('Last updated: ${_fmt(controller.lastUpdated.value)}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ),
        ]);
      }),
    );
  }

  Widget _summary(String label, String value, Color color) => Column(children: [
        Text(value,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ]);

  String _fmt(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}:'
      '${dt.second.toString().padLeft(2, '0')}';
}


