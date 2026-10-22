# Crédits & licences des assets

Le jeu utilise de **vrais modèles 3D riggés + texturés** de **KayKit** (Kay Lousberg)
pour les unités (péon, ouvriers, grunts) **et pour le monde** (bâtiments, arbres,
mine d'or), avec leur **bibliothèque d'animations** intégrée (Idle, Walking,
Attack, Death…) et un **cel-shader maison** appliqué à toutes les surfaces.

## Personnages (KayKit, CC0)

| Fichier | Utilisation | Licence |
|---------|-------------|---------|
| `kaykit/Barbarian.glb` | Péon / ouvrier | CC0 1.0 |
| `kaykit/Knight.glb` | Grunt allié (caserne) | CC0 1.0 |
| `kaykit/Skeleton_Warrior.glb` | Grunt ennemi | CC0 1.0 |
| `kaykit/Skeleton_Minion.glb` | (variante ennemie dispo) | CC0 1.0 |
| `kaykit/Rogue_Hooded.glb`, `kaykit/Mage.glb` | (variantes dispo) | CC0 1.0 |

- Personnages : © Kay Lousberg (KayKit), domaine public CC0 1.0.
- Source : https://github.com/KayKit-Game-Assets/KayKit-Character-Pack-Adventures-1.0
  et `KayKit-Character-Pack-Skeletons-1.0`.

## Monde / bâtiments / nature (KayKit, CC0)

| Fichier (sous `assets/models/kaykit_props/`) | Utilisation |
|----------------------------------------------|-------------|
| `buildings_green/*` (castle, home_A, barracks, tower_A, mine…) | Bâtiments du joueur |
| `buildings_red/*` | Bâtiments ennemis |
| `nature/tree_single_A/B`, `nature/rock_single_*` | Arbres à couper, rochers |
| `props/resource_stone`, `props/resource_lumber` | Ressources |

- Monde : © Kay Lousberg (KayKit « Medieval Hexagon Pack »), domaine public CC0 1.0.
- Source : https://github.com/KayKit-Game-Assets/KayKit-Medieval-Hexagon-Pack-1.0

## Modèles de référence (Khronos glTF Sample Models)

| Fichier | Auteur | Licence |
|---------|--------|---------|
| `CesiumMan.glb` | Cesium / Khronos (glTF tutorial) | CC-BY 4.0 |
| `Fox.glb` | PixelMannen (Tomás Laulhé, Quaternius) | CC0 1.0 |

- `Fox.glb` : © Tomás Laulhé, CC0 (domaine public).
- `CesiumMan.glb` : © Cesium, CC-BY 4.0 — « CesiumMan model from the Khronos
  glTF Sample Models, © Cesium, CC-BY 4.0 ».

Source : https://github.com/KhronosGroup/glTF-Sample-Models

## Captures de preuve

`docs/screenshots/` contient des captures hors-écran générées en CI
(voir `tests/capture_showcase.gd` et le hook `PEON_SHOT` dans `main.gd`).
