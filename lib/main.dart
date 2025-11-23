import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:glass_estate/presentation/screens/home_screen.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:glass_estate/data/models/apartment_model.dart';
import 'package:glass_estate/data/models/geocoding_cache_model.dart';
import 'package:glass_estate/data/models/point_of_interest_model.dart';
import 'package:glass_estate/presentation/providers/apartment_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open(
    [ApartmentModelSchema, PointOfInterestModelSchema, GeocodingCacheModelSchema],
    directory: dir.path,
  );

  runApp(ProviderScope(
    overrides: [
      isarProvider.overrideWithValue(isar),
    ],
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GlassEstate',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
