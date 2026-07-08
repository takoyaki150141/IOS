import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/storage_service.dart';
import 'services/tracked_items_provider.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.instance.init();
  runApp(const BoothWatchApp());
}

class BoothWatchApp extends StatelessWidget {
  const BoothWatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TrackedItemsProvider(),
      child: MaterialApp(
        title: 'BoothWatch',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: const Color(0xFFFF6699), // Boothカラーに寄せたピンク系
          scaffoldBackgroundColor: const Color(0xFFFAFAFA),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
