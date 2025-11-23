# Suivi des Tâches - GlassEstate

## Étape 0 : Contextualisation
- [ ] Définir le rôle et le contexte (Fait implicitement par le prompt système et l'instruction utilisateur)

## Étape 1 : Structure et Dépendances
- [ ] Configurer `pubspec.yaml` avec toutes les dépendances (flutter_map, riverpod, freezed, isar, etc.)
- [ ] Créer l'arborescence des dossiers (Clean Architecture: core, data, domain, presentation)

## Étape 2 : Modélisation (Domain Layer)
- [ ] Créer `lib/domain/entities/apartment.dart` avec Freezed
- [ ] Définir les champs (id, bailleur, type, region, adresse, etc.)
- [ ] Lancer `build_runner`

## Étape 3 : Le Parser PDF (Data Layer)
- [ ] Créer `PdfParsingService` dans `lib/data/datasources/`
- [ ] Implémenter les Regex pour l'extraction des données (nécessite un exemple de texte PDF)

## Étape 4 : Géocoding et Repository
- [ ] Créer `ApartmentRepository`
- [ ] Intégrer le parsing PDF
- [ ] Intégrer le géocoding (simulé ou réel)
- [ ] Intégrer la sauvegarde locale avec Isar

## Étape 5 : State Management (Riverpod)
- [ ] Créer `apartment_provider.dart`
- [ ] Gérer le chargement, le filtrage et les favoris

## Étape 6 : UI Glassmorphism (Presentation Layer)
- [ ] Créer le widget `GlassContainer`
- [ ] Créer le widget `ApartmentGlassCard`

## Étape 7 : L'écran principal (La Carte)
- [ ] Créer `HomeScreen` avec `FlutterMap`
- [ ] Afficher les marqueurs
- [ ] Afficher la `ApartmentGlassCard` au clic
- [ ] Ajouter le bouton d'import PDF
