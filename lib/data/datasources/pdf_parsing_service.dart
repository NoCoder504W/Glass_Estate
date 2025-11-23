import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/apartment.dart';

class PdfParsingService {
  // final _uuid = const Uuid(); // No longer used for random IDs

  String _generateId(String ville, String adresse, double surface, int etage, double loyer) {
    // Create a deterministic string key
    final key = '${ville.trim().toUpperCase()}_${adresse.trim().toUpperCase()}_${surface.toStringAsFixed(2)}_${etage}_${loyer.toStringAsFixed(2)}';
    // Return an MD5 hash of the key to get a consistent ID string
    return md5.convert(utf8.encode(key)).toString();
  }

  List<Apartment> parse(String text) {
    final List<Apartment> apartments = [];
    
    // Le texte est très déstructuré (colonnes mélangées).
    // Stratégie : On repère les blocs qui commencent par un Code Postal (5 chiffres) suivi d'une Ville en majuscules.
    // C'est le point d'ancrage le plus fiable dans ce format "soupe de mots".
    
    // Regex pour trouver le bloc : CP (5 chiffres) + saut de ligne + VILLE (Majuscules)
    // On capture aussi ce qui suit pour essayer de trouver l'étage, les loyers, etc.
    
    // Analyse du pattern récurrent :
    // [Type de financement: PLS/PLUS]
    // [Parking: Possible en sus / Néant]
    // [CP]
    // [VILLE]
    // [Etage]
    // [Loyer HC]
    // [Loyer CC]
    // [Ascenseur: Oui/Non]
    // [Surface]
    // [Code Ref]
    // [Adresse]
    // [Chauffage]
    
    // On va découper le texte en "lignes" non vides pour itérer plus facilement
    final lines = text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      
      // Détection d'un début de bloc par le Code Postal (ex: 92140)
      if (RegExp(r'^\d{5}$').hasMatch(line)) {
        // Validation supplémentaire : Le CP est suivi par une Ville en MAJUSCULES
        // La Ref (qui est aussi 5 chiffres) est suivie par une Adresse (Mixte)
        bool isLikelyZip = false;
        if (i + 1 < lines.length) {
            final nextLine = lines[i+1];
            // On vérifie si c'est tout en majuscules (et pas juste des chiffres ou symboles)
            // On autorise les espaces et tirets pour "BOULOGNE BILLANCOURT"
            // On exclut "RDC" qui est souvent l'étage juste après
            if (RegExp(r'^[A-Z\s-]+$').hasMatch(nextLine) && 
                RegExp(r'[A-Z]').hasMatch(nextLine) &&
                nextLine != 'RDC') {
                isLikelyZip = true;
            }
        }
        
        if (!isLikelyZip) continue;

        try {
          // On a trouvé un CP, essayons de reconstruire l'appartement autour de cet index
          
          // 1. CP & Ville
          final cp = line;
          String ville = 'Inconnue';
          if (i + 1 < lines.length) {
            ville = lines[i + 1];
            // Parfois la ville est sur deux lignes (BOULOGNE BILLANCOURT)
            if (i + 2 < lines.length && 
                RegExp(r'^[A-Z\s-]+$').hasMatch(lines[i + 2]) && 
                !RegExp(r'^\d').hasMatch(lines[i + 2]) &&
                lines[i + 2] != 'RDC') {
               // Heuristique : si la ligne d'après est aussi en majuscules et n'est pas un chiffre (étage/loyer), c'est la suite de la ville
               ville += ' ${lines[i + 2]}';
            }
          }

          // Recherche contextuelle (vers le haut et le bas)
          
          // 2. Type (F1, F2...)
          // On remonte pour trouver le dernier "Social - Fx -"
          String type = 'Inconnu';
          Bailleur bailleur = Bailleur.social; // Par défaut vu le texte "Bureau du Logement"
          
          for (int j = i; j >= 0; j--) {
            if (lines[j].contains('Social') && lines[j].contains('-')) {
              final typeMatch = RegExp(r'F\d|T\d|Studio').firstMatch(lines[j]);
              if (typeMatch != null) {
                type = typeMatch.group(0)!;
              }
              break; // On prend le dernier en-tête vu
            }
          }
          
          // 3. Etage (souvent juste après la ville)
          // On cherche un chiffre seul ou RDC après la ville
          int etage = 0;
          int searchIndex = i + 1; // Start searching after CP
          // Skip ville lines
          while(searchIndex < lines.length && (lines[searchIndex] == ville || ville.contains(lines[searchIndex]))) {
             searchIndex++;
          }
          
          // Maintenant on cherche l'étage
          if (searchIndex < lines.length) {
             final etageLine = lines[searchIndex];
             if (etageLine == 'RDC') {
               etage = 0;
             } else if (RegExp(r'^\d+$').hasMatch(etageLine)) {
               etage = int.parse(etageLine);
             }
          }

          // 4. Loyers (HC et CC)
          // On cherche les motifs "XXX €" après le CP
          double loyer = 0.0;
          // On scanne les 10 lignes suivantes pour trouver les prix
          for (int k = i; k < i + 15 && k < lines.length; k++) {
             final priceMatch = RegExp(r'(\d+)\s*€').firstMatch(lines[k]);
             if (priceMatch != null) {
                // On assume que le plus grand des deux montants proches est le CC
                // Ou on suit l'ordre : HC puis CC.
                // Dans l'exemple : 654 € (HC) puis 754 € (CC)
                // On prend le dernier trouvé comme Loyer CC si on en trouve deux ?
                // Simplification : on prend la valeur la plus élevée trouvée dans le bloc comme Loyer CC
                double val = double.parse(priceMatch.group(1)!);
                if (val > loyer) loyer = val;
             }
          }

          // 5. Surface
          double surface = 0.0;
          for (int k = i; k < i + 15 && k < lines.length; k++) {
             final surfaceMatch = RegExp(r'(\d+)m²').firstMatch(lines[k]);
             if (surfaceMatch != null) {
                surface = double.parse(surfaceMatch.group(1)!);
                break; 
             }
          }

          // 6. Ascenseur
          bool hasAscenseur = false;
          for (int k = i; k < i + 15 && k < lines.length; k++) {
             if (lines[k] == 'Oui') hasAscenseur = true;
             if (lines[k] == 'Non') hasAscenseur = false;
             // Risqué car "Oui" peut être pour autre chose, mais dans ce format colonne c'est souvent Ascenseur
          }

          // 7. Code Ref (5 chiffres, souvent après la surface)
          String plafondRef = 'N/A';
          for (int k = i; k < i + 15 && k < lines.length; k++) {
             // Un code ref ressemble à 57568 (5 chiffres) mais n'est pas le CP (déjà passé)
             if (RegExp(r'^\d{5}$').hasMatch(lines[k]) && lines[k] != cp) {
                plafondRef = lines[k];
                // Souvent l'adresse est juste après la ref
                break;
             }
          }

          // 8. Adresse
          // L'adresse est souvent après la Ref
          String adresse = 'Adresse non trouvée';
          for (int k = i; k < i + 20 && k < lines.length; k++) {
             if (lines[k] == plafondRef && k + 1 < lines.length) {
                adresse = lines[k+1];
                break;
             }
          }
          
          // 9. Chauffage
          String typeChauffage = 'Individuel';
          for (int k = i; k < i + 20 && k < lines.length; k++) {
             if (lines[k].contains('Collectif') || lines[k].contains('Individuel')) {
                typeChauffage = lines[k];
                break;
             }
          }
          
          // 10. Parking
          // On regarde avant le CP (dans les lignes précédentes)
          String descriptionParking = 'Non spécifié';
          if (i - 1 >= 0 && (lines[i-1].contains('sus') || lines[i-1].contains('Néant'))) {
             descriptionParking = lines[i-1].contains('sus') ? 'Possible en sus' : 'Néant';
          } else if (i - 2 >= 0 && (lines[i-2].contains('sus') || lines[i-2].contains('Néant'))) {
             // Parfois décalé par le type de financement (PLS/PLUS)
             descriptionParking = lines[i-2].contains('sus') ? 'Possible en sus' : 'Néant';
          }

          apartments.add(Apartment(
            id: _generateId(ville, adresse, surface, etage, loyer),
            bailleur: bailleur,
            type: type,
            region: 'Île-de-France', // Déduit des CP 75/92/91
            adresse: adresse,
            ville: ville,
            cp: cp,
            surface: surface,
            etage: etage,
            loyer: loyer,
            hasAscenseur: hasAscenseur,
            descriptionParking: descriptionParking,
            typeChauffage: typeChauffage,
            plafondRef: plafondRef,
          ));
          
        } catch (e) {
          print('Erreur parsing bloc à la ligne $i: $e');
        }
      }
    }

    return apartments;
  }
}
