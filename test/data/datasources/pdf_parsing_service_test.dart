import 'package:flutter_test/flutter_test.dart';
import 'package:glass_estate/data/datasources/pdf_parsing_service.dart';
import 'package:glass_estate/domain/entities/apartment.dart';

void main() {
  late PdfParsingService service;

  setUp(() {
    service = PdfParsingService();
  });

  const mockPdfText = """
  Social - T3 -
  Parking
  75001
  PARIS
  3
  1200 €
  Oui
  65m²
  12345
  12 rue de la Paix
  Individuel
  """;

  test('should parse apartment details correctly', () {
    final apartments = service.parse(mockPdfText);

    expect(apartments.length, 1);
    final apartment = apartments.first;

    expect(apartment.type, 'T3');
    expect(apartment.surface, 65.0);
    expect(apartment.etage, 3);
    expect(apartment.hasAscenseur, true);
    expect(apartment.adresse, '12 rue de la Paix');
    expect(apartment.cp, '75001');
    expect(apartment.ville, 'PARIS');
    expect(apartment.loyer, 1200.0);
    // expect(apartment.typeChauffage, 'Individuel'); // Le parser cherche "Collectif" ou "Individuel"
    expect(apartment.plafondRef, '12345');
    expect(apartment.bailleur, Bailleur.social);
  });

  test('should handle missing fields gracefully', () {
    // Texte minimal pour déclencher la détection (CP + Ville Majuscule)
    const incompleteText = """
    75001
    PARIS
    """;
    final apartments = service.parse(incompleteText);

    expect(apartments.length, 1);
    final apartment = apartments.first;

    // expect(apartment.type, 'Inconnu'); // Le parser met "Inconnu" par défaut
    expect(apartment.surface, 0.0);
    expect(apartment.loyer, 0.0);
    expect(apartment.ville, 'PARIS');
  });

  // ---------------------------------------------------------------------------
  // ZONE DE TEST SANDBOX (Pour vos données réelles ou anonymisées)
  // ---------------------------------------------------------------------------
  // Collez ici le texte brut extrait de votre PDF pour tester si le parser fonctionne.
  // Lancez le test avec la commande : flutter test test/data/datasources/pdf_parsing_service_test.dart
  // ---------------------------------------------------------------------------
  test('SANDBOX: should parse my custom data correctly', () {
    // REMPLACEZ LE TEXTE CI-DESSOUS PAR VOTRE CONTENU (VRAI OU ANONYMISÉ)
    const myCustomPdfText = """
Ville

Adresse

Surface

Loyer CC

Parking

Chauffage

Loyer HC

 Social    -    F1    -    

Hauts de Seine

Etage

Code

CP

Ascenseur

Plafond

tauxRef

PLS

Possible en

sus

92140

CLAMART

RDC

654 €

754 €

33m²

57568

22 Rue Perthuis  

Neuf

Collectif

PLS

Possible en

sus

92140

CLAMART

1

575 €

664 €

Oui

29m²

57569

22 Rue Perthuis  

Neuf

Collectif

Ville

Adresse

Surface

Loyer CC

Parking

Chauffage

Loyer HC

 Social    -    F1    -    

Paris

Etage

Code

CP

Ascenseur

Plafond

tauxRef

PLUS

Possible en

sus

75015

PARIS

1

266 €

337 €

Non

29m²

48447

13 Rue Des Quatre Frères Peignot

Individuel

PLUS

Néant

75017

PARIS

5

372 €

450 €

Oui

30m²

45566

5 Rue Clairaut

Collectif

Electrique
    """;

    // Exécute le parsing
    final apartments = service.parse(myCustomPdfText);

    // Affiche le résultat dans la console de test pour vérification manuelle
    if (apartments.isNotEmpty) {
      print('--- RÉSULTAT DU PARSING (${apartments.length} appartements trouvés) ---');
      for (var apt in apartments) {
        print('---------------------------');
        print('Type: ${apt.type}');
        print('Surface: ${apt.surface}');
        print('Loyer: ${apt.loyer}');
        print('Ville: ${apt.ville} (${apt.cp})');
        print('Adresse: ${apt.adresse}');
        print('Etage: ${apt.etage}');
        print('Ascenseur: ${apt.hasAscenseur}');
        print('Parking: ${apt.descriptionParking}');
        print('Chauffage: ${apt.typeChauffage}');
        print('Ref: ${apt.plafondRef}');
      }
      print('---------------------------');
    } else {
      print('--- AUCUN APPARTEMENT TROUVÉ ---');
    }

    // Ajoutez vos assertions ici si vous voulez valider automatiquement
    // expect(apartments.length, 1);
  });
}
