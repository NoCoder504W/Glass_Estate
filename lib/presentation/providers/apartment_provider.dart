import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:glass_estate/data/datasources/geocoding_service.dart';
import 'package:glass_estate/data/datasources/pdf_parsing_service.dart';
import 'package:glass_estate/data/repositories/apartment_repository_impl.dart';
import 'package:glass_estate/domain/entities/apartment.dart';
import 'package:glass_estate/domain/repositories/apartment_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:glass_estate/data/models/apartment_model.dart';
import 'package:glass_estate/data/models/geocoding_cache_model.dart';
import 'package:glass_estate/data/models/point_of_interest_model.dart';

// 1. Hive Box Providers
final apartmentBoxProvider = Provider<Box<ApartmentModel>>((ref) {
  return Hive.box<ApartmentModel>('apartments');
});

final geocodingBoxProvider = Provider<Box<GeocodingCacheModel>>((ref) {
  return Hive.box<GeocodingCacheModel>('geocoding_cache');
});

final poiBoxProvider = Provider<Box<PointOfInterestModel>>((ref) {
  if (!Hive.isBoxOpen('pois')) {
    throw Exception('Box pois is not open');
  }
  return Hive.box<PointOfInterestModel>('pois');
});

// 2. Repository Provider
final apartmentRepositoryProvider = Provider<ApartmentRepository>((ref) {
  final apartmentBox = ref.watch(apartmentBoxProvider);
  final geocodingBox = ref.watch(geocodingBoxProvider);
  return ApartmentRepositoryImpl(PdfParsingService(), GeocodingService(geocodingBox), apartmentBox);
});

// Progress Provider
final importProgressProvider = StateProvider<double?>((ref) => null);
final importStatusMessageProvider = StateProvider<String>((ref) => '');

// 3. State Notifier for Apartments
class ApartmentNotifier extends StateNotifier<AsyncValue<List<Apartment>>> {
  final ApartmentRepository _repository;
  final Ref _ref;

  ApartmentNotifier(this._repository, this._ref) : super(const AsyncValue.loading()) {
    // Listen to Hive changes automatically
    _repository.watchApartments().listen((apartments) {
      state = AsyncValue.data(apartments);
    });
  }

  // No longer needed to call manually, but kept for initial load if needed
  Future<void> loadApartments() async {
    // The stream listener handles updates
  }

  Future<void> importPdf(String text) async {
    try {
      // Do NOT set state to loading here, so the UI stays interactive
      // state = const AsyncValue.loading(); 
      
      _ref.read(importProgressProvider.notifier).state = 0.0;
      _ref.read(importStatusMessageProvider.notifier).state = 'Analyse du PDF...';

      // Run in background (don't await if we want to return immediately, but here we await to clear progress)
      // Actually, since we want "background" feel, we can just let it run.
      // But we need to handle errors.
      
      final newApartments = await _repository.parseAndSavePdf(
        text,
        onProgress: (current, total) {
          final progress = current / total;
          _ref.read(importProgressProvider.notifier).state = progress;
          _ref.read(importStatusMessageProvider.notifier).state = 'Géocodage : $current / $total';
        },
      );
      
      print('--- [DEBUG] Nombre d\'appartements trouvés et sauvegardés : ${newApartments.length} ---');
      
      _ref.read(importProgressProvider.notifier).state = null; // Done
      _ref.read(importStatusMessageProvider.notifier).state = '';
      
      // No need to call loadApartments(), the stream will update
    } catch (e) {
      _ref.read(importProgressProvider.notifier).state = null;
      // Show error in snackbar or similar instead of replacing the whole state
      print('Error importing PDF: $e');
    }
  }

  Future<void> clearAll() async {
    try {
      // state = const AsyncValue.loading(); // Don't block UI
      await _repository.clearAll();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> clearNonFavorites() async {
    try {
      await _repository.clearNonFavorites();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> pickAndExtractPdf() async {
    try {
      print('--- [DEBUG] pickAndExtractPdf: Début de la sélection du fichier ---');
      
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        Uint8List? bytes;

        if (kIsWeb) {
          // On Web, bytes are directly available
          bytes = result.files.single.bytes;
          print('--- [DEBUG] Web: Bytes récupérés directement (${bytes?.length} bytes) ---');
        } else if (result.files.single.path != null) {
          // On Mobile/Desktop, read from path
          print('--- [DEBUG] Fichier sélectionné : ${result.files.single.path} ---');
          final file = File(result.files.single.path!);
          print('--- [DEBUG] Lecture du fichier en bytes... ---');
          bytes = await file.readAsBytes();
        }

        if (bytes != null) {
          // Don't block UI with loading state
          // state = const AsyncValue.loading();
          _ref.read(importStatusMessageProvider.notifier).state = 'Extraction du texte...';
          _ref.read(importProgressProvider.notifier).state = 0.0; // Show progress bar immediately
          
          // Extract text using Syncfusion
          print('--- [DEBUG] Extraction du texte avec Syncfusion... ---');
          final PdfDocument document = PdfDocument(inputBytes: bytes);
          String text = PdfTextExtractor(document).extractText();
          document.dispose();

          // PRINT TO CONSOLE FOR USER
          print('--- [DEBUG] Texte extrait (Aperçu des 500 premiers caractères) ---');
          print(text.length > 500 ? text.substring(0, 500) : text);
          print('--- [DEBUG] Fin extraction texte. Lancement du parsing... ---');
          
          // Continue with parsing
          await importPdf(text);
          print('--- [DEBUG] Parsing et sauvegarde terminés. ---');
        } else {
          print('--- [DEBUG] Erreur: Impossible de lire les bytes du fichier ---');
        }
      } else {
        print('--- [DEBUG] Aucun fichier sélectionné. ---');
      }
    } catch (e) {
      print('Error picking PDF: $e');
      _ref.read(importProgressProvider.notifier).state = null;
      // state = AsyncValue.error(e, st); // Don't crash the UI
    }
  }

  Future<void> toggleFavorite(String id) async {
    try {
      await _repository.toggleFavorite(id);
      // Optimistic update or reload
      await loadApartments();
    } catch (e) {
      // Handle error
    }
  }
}

final apartmentProvider = StateNotifierProvider<ApartmentNotifier, AsyncValue<List<Apartment>>>((ref) {
  final repository = ref.watch(apartmentRepositoryProvider);
  return ApartmentNotifier(repository, ref);
});

// 4. Filter Provider
final filterMinSurfaceProvider = StateProvider<double?>((ref) => null);
final filterMaxLoyerProvider = StateProvider<double?>((ref) => null);
final filterOnlyFavoritesProvider = StateProvider<bool>((ref) => false);
final filterBailleurProvider = StateProvider<Bailleur?>((ref) => null);

final filteredApartmentsProvider = Provider<List<Apartment>>((ref) {
  final apartmentsState = ref.watch(apartmentProvider);
  final minSurface = ref.watch(filterMinSurfaceProvider);
  final maxLoyer = ref.watch(filterMaxLoyerProvider);
  final onlyFavorites = ref.watch(filterOnlyFavoritesProvider);
  final bailleur = ref.watch(filterBailleurProvider);

  return apartmentsState.maybeWhen(
    data: (apartments) {
      return apartments.where((apt) {
        if (minSurface != null && apt.surface < minSurface) return false;
        if (maxLoyer != null && apt.loyer > maxLoyer) return false;
        if (onlyFavorites && !apt.isFavorite) return false;
        if (bailleur != null && apt.bailleur != bailleur) return false;
        return true;
      }).toList();
    },
    orElse: () => [],
  );
});
