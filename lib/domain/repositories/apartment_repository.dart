import 'package:glass_estate/domain/entities/apartment.dart';

abstract class ApartmentRepository {
  Future<List<Apartment>> parseAndSavePdf(String pdfText, {void Function(int current, int total)? onProgress});
  Future<List<Apartment>> getSavedApartments();
  Stream<List<Apartment>> watchApartments();
  Future<void> toggleFavorite(String id);
  Future<void> clearAll();
  Future<void> clearNonFavorites();
}
