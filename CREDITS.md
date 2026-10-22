# Crédits & licences des assets

Le jeu utilise de **vrais modèles 3D riggés + texturés** de **KayKit** (Kay Lousberg)
pour les unités (péon, ouvriers, grunts), avec leur **bibliothèque d'animations**
intégrée (Idle, Walking, Attack, Death…). Le monde (bâtiments, arbres, sol) reste
généré procéduralement avec un cel-shader maison.

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
