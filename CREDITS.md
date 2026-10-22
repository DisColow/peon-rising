# Crédits & licences des assets

Le projet est construit **procéduralement** (meshes + animations générées en code).
Des modèles 3D squelettiques de référence sont inclus dans `assets/models/` pour
valider le pipeline d'import de vrais assets artistes (voir `scripts/skeletal_actor.gd`
et `tests/test_skeletal.gd`).

## Modèles de référence (Khronos glTF Sample Models)

| Fichier | Auteur | Licence |
|---------|--------|---------|
| `CesiumMan.glb` | Cesium / Khronos (glTF tutorial) | CC-BY 4.0 |
| `Fox.glb` | PixelMannen (Tomás Laulhé, Quaternius) | CC0 1.0 |

- `Fox.glb` : © Tomás Laulhé, CC0 (domaine public).
- `CesiumMan.glb` : © Cesium, CC-BY 4.0 — attribution : « CesiumMan model from
  the Khronos glTF Sample Models, © Cesium, CC-BY 4.0 ».

Source : https://github.com/KhronosGroup/glTF-Sample-Models

## Assets recommandés pour le rendu final

Pour atteindre le rendu « cartoon Warcraft » cible, utiliser les packs **CC0** de
Quaternius (quaternius.com) : *Ultimate Fantasy RTS*, *Ultimate Monsters*,
*Universal Base Characters* + *Universal Animation Library* (modèles riggés +
animations idles/marche/attaque). Le pipeline `SkeletalActor` les charge tels quels.
