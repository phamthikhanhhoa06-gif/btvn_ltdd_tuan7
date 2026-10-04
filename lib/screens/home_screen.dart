import 'package:flutter/material.dart';

import 'current_location_screen.dart';
import 'route_finder_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _open(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => screen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bài 07 - Google Maps'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                child: Text('1'),
              ),
              title: const Text('Bài tập 1'),
              subtitle: const Text(
                'Hiển thị bản đồ và đánh dấu vị trí hiện tại',
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _open(
                context,
                const CurrentLocationScreen(),
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.route),
              ),
              title: const Text('Bài tổng hợp'),
              subtitle: const Text(
                'Tìm đường, chọn điểm, tìm địa điểm, '
                'phương tiện và lưu SQLite',
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _open(
                context,
                const RouteFinderScreen(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}