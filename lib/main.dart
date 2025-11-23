import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:glass_estate/presentation/screens/home_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:glass_estate/data/models/apartment_model.dart';
import 'package:glass_estate/data/models/geocoding_cache_model.dart';
import 'package:glass_estate/data/models/point_of_interest_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Hive.initFlutter();
  
  Hive.registerAdapter(ApartmentModelAdapter());
  Hive.registerAdapter(GeocodingCacheModelAdapter());
  Hive.registerAdapter(PointOfInterestModelAdapter());

  await Hive.openBox<ApartmentModel>('apartments');
  await Hive.openBox<GeocodingCacheModel>('geocoding_cache');
  await Hive.openBox<PointOfInterestModel>('pois');

  runApp(const ProviderScope(
    child: MyApp(),
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
