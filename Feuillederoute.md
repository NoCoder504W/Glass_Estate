Étape 0 : Le "Master Prompt" de Contextualisation

Ouvrez une nouvelle session de chat dans VSCode et envoyez ce prompt pour définir les règles du jeu. Ne sautez pas cette étape.

    "Tu es un expert Senior Flutter/Dart spécialisé en Clean Architecture et UI complexe. Nous allons construire une application nommée 'GlassEstate'.

    Le concept : Une app qui parse un PDF d'appartements, extrait les données via Regex, les géocode, et les affiche sur une carte OpenStreetMap interactive. La Tech Stack : Flutter, Dart, Riverpod (State Management), Freezed (Models), flutter_map (Carte), Isar (BDD locale), UI style Glassmorphism. Ton rôle : Tu vas me guider étape par étape. À chaque étape, tu me donneras le code complet des fichiers concernés. N'utilise que des packages stables.

    Garde ce contexte en mémoire pour toute la session. Dis-moi juste 'Prêt' si tu as compris."

Étape 1 : Structure et Dépendances

Une fois qu'il a dit "Prêt", on pose les fondations.

    "Commençons par l'infrastructure.

        Donne-moi le contenu complet du fichier pubspec.yaml avec toutes les dépendances nécessaires (flutter_map, riverpod, hooks_riverpod, freezed_annotation, json_annotation, isar, isar_flutter_libs, path_provider, glass_kit ou équivalent pour l'UI, latlong2). Ajoute les dev_dependencies pour build_runner.

        Décris-moi l'arborescence des dossiers à créer selon la Clean Architecture (lib/core, lib/data, lib/domain, lib/presentation)."

Étape 2 : Modélisation (Domain Layer)

On verrouille les types de données avant de coder la logique.

    "Définissons le modèle de données principal. Crée le fichier lib/domain/entities/apartment.dart. Utilise freezed pour créer une classe immuable Apartment. Elle doit contenir : id (String), bailleur (enum: Social, Prive), type (String ex: F1, F2), region (String), adresse (String), ville (String), cp (String), surface (double), etage (int), loyer (double), hasAscenseur (bool), descriptionParking (String), typeChauffage (String), plafondRef (String), latitude (double?), longitude (double?), isFavorite (bool). Ajoute aussi une méthode fromJson."

(N'oublie pas de lancer dart run build_runner build dans ton terminal après avoir collé le code).

Étape 3 : Le Parser PDF (Data Layer) - CRITIQUE

Ici, l'IA a besoin d'un exemple concret. Ouvre ton PDF, copie le texte brut d'un ou deux appartements et utilise-le dans ce prompt.

    "Passons au parsing. Je vais utiliser un package pour extraire le texte du PDF, mais j'ai besoin de toi pour la logique d'extraction (Regex). Voici un exemple du texte brut que je récupère du PDF : [COLLE ICI UN EXTRAIT DU TEXTE DE TON PDF]

    Écris-moi une classe PdfParsingService dans lib/data/datasources/ qui prend ce texte en entrée et retourne une List<Apartment>. Sois très précis sur les Regex pour capturer les champs correctement."

Étape 4 : Géocoding et Repository

On relie les données à la logique.

    "Crée maintenant le ApartmentRepository. Il doit :

        Appeler le PdfParsingService.

        Pour chaque appartement sans coordonnées, appeler une API de géocoding (simule l'appel API pour l'instant ou utilise geocoding package) pour remplir latitude/longitude.

        Sauvegarder les résultats dans la base de données locale Isar pour éviter de re-parser à chaque fois. Donne-moi le code complet du Repository."

Étape 5 : State Management (Riverpod)

On prépare les données pour l'UI.

    "Crée les providers Riverpod nécessaires. Je veux un StateNotifier ou AsyncNotifier qui gère la liste des appartements. Il doit permettre de charger le PDF, filtrer la liste (par prix, surface) et gérer les favoris. Donne-moi le fichier lib/presentation/providers/apartment_provider.dart."

Étape 6 : UI Glassmorphism (Presentation Layer)

C'est là que le "Luxe" arrive.

    "Passons à l'UI. Le design est 'Premium Glassmorphism'.

        Crée un widget réutilisable GlassContainer (fond flou, bordure blanche semi-transparente, dégradé subtil).

        Crée une ApartmentGlassCard qui utilise ce conteneur pour afficher les infos résumées d'un appartement (Loyer, Ville, Type). Donne-moi le code de ces deux widgets."

Étape 7 : L'écran principal (La Carte)

L'assemblage final.

    "Crée l'écran principal HomeScreen. Il doit afficher une carte FlutterMap en plein écran (utilise un style de tuiles sombres pour aller avec le glassmorphism, ex: CartoDB Dark Matter). Affiche les marqueurs des appartements depuis le provider Riverpod. Au clic sur un marqueur, affiche la ApartmentGlassCard en bas de l'écran par-dessus la carte. Ajoute un bouton flottant 'Glass' pour importer un nouveau PDF."