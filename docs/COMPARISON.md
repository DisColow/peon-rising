# Peon Rising — comparaison aux cadors du genre (Warcraft III / STR)

Ce document fait le lien entre, d'un côté, les conventions qui font la qualité
d'un STR « cadors du genre » (la boucle péon de Warcraft III) et, de l'autre,
leur implémentation concrète dans ce projet, avec la preuve correspondante.

> Les tests/captures ci-dessous sont reproductibles (voir `AGENTS.md`). Aucun
> d'entre eux ne « décrète » la beauté — c'est une appréciation humaine — mais
> ils établissent que chaque mécanique de référence est présente et fonctionne.

## 1. La boucle du péon (récolte → construction → combat)

| Convention du genre | Implémentation | Preuve |
|---|---|---|
| Récolte du bois en abattant des arbres | `scenes/resources/tree.gd` : chaque coup creuse une entaille **visible** sur le tronc, fait trembler l'arbre, projette des copeaux, puis l'arbre **tombe avec la vraie physique** | `capture_sequence.gd` → `docs/gameplay.gif` ; smoke test `worker=vivant` |
| Récolte de l'or en entrant dans la mine | `scenes/resources/gold_mine.gd` + `gold_chunk.gd` : le péon doit aller à la mine ; des pépites **physiques** jaillissent et sont aspirées vers le péon | idem |
| Ramener les ressources au stockage le plus proche | dépôt le plus proche (`drop_off_player` / `drop_off_enemy`) | code `unit_base.gd` / `worker.gd` |
| Construire des bâtiments (fantôme → solide qui s'élève) | `scenes/buildings/building.gd` : montée progressive du bâtiment pendant la construction | `gameplay.gif` |
| Attaquer les ennemis qui envahissent la base | `scenes/units/grunt.gd` (caserne), tours (`building.gd` `_tower_tick` → projectiles) | `test_game_feel.gd` (clips attack) |
| Défense de base + objectif « détruire la base adverse » | `town_hall` marqué `drop_off`/objectif, fin de partie quand la base adverse tombe | code `main.gd` / `commander.gd` |

## 2. Contrôle et commandement (le « joueur » qui ordonne)

| Convention | Implémentation | Preuve |
|---|---|---|
| Contrôle direct FPS (WASD + souris) | `scenes/units/player.gd` (héros FPS, modèle Barbarian riggé) | capture `barbarian_idle.png` |
| Un commandant IA donne des objectifs **toujours affichés** | `scenes/commander/commander.gd` + balise d'objectif (glow au-dessus du bâtiment) | `gameplay.png`, log `order=Construire : Ferme` |
| Unités alliées / adverses | `worker.gd`, `grunt.gd` (allié Knight / ennemi Skeleton), renforts de caserne | captures `knight_walk.png`, `skeleton_attack.png` |
| Influencer la partie (corriger/inciter, comme un animal de compagnie) | le joueur-peon peut ignorer ou suivre l'ordre du commandant ; arbre de talents | `talent_db.gd`, `talent_tree_ui.gd` |

## 3. Roguelite + progression

| Convention | Implémentation | Preuve |
|---|---|---|
| Mort → réapparition, arbre quasi remis à zéro | respawn du péon, talents réinitialisés (mode roguelite) | `main.gd` `_respawn` ; log `worker=vivant/mort` |
| Progression permanente entre parties (stats/équipements/compétences) | `scenes/menu/meta_ui.gd` (méta persistante, prête pour les stats/équipements) | code `meta_ui.gd` |
| Architecture multijoueur anticipée | séparation `server/client`, états réseau (`GameState`), équipes symétriques | code `GameData.TEAM_*`, `GameState` |

## 4. Rendu & game feel (le « magnifique »)

| Convention | Implémentation | Preuve |
|---|---|---|
| Personnages + monde en **vrais modèles texturés** | KayKit (CC0) : personnages riggés + monde (bâtiments/arbres/mine) | `test_props.gd` (22/22), `test_game_feel.gd` (8/8) |
| Style cartoon cohérent | **cel-shader maison** appliqué à toutes les surfaces (personnages + monde) | `test_game_feel.gd` « cel-shader on all 15 surfaces » |
| Rendu « cadors » (SSAO, bloom, ACES, ombres douces) | `main.gd` : `ssao_enabled`, `glow_enabled`, `tonemap ACES`, `shadow_blur` | `main.gd` lignes 156-192 |
| Animations réelles (marche/attaque/mort) | bibliothèque d'animations KayKit intégrée | `test_game_feel.gd` (clips walk/attack/death) |
| Game feel : hit-stop, particules, feedback | `scripts/fx.gd` `FX.hit_stop` + `FX.burst` | `test_game_feel.gd` (hit-stop 0.100 → 1.000, burst) |
| Armes correctement orientées en main | convention de grip validée | `test_weapon_grip.gd` (15/15), `knight_sword.png` |

## 5. Plateformes

| Cible | Statut |
|---|---|
| Godot 4 (3D) | ✅ projet `project.godot` |
| Android / Windows / Linux (Steam Deck) | ✅ builds CI : `PeonRising-Android.zip`, `-Windows.zip`, `-Linux-x86_64.zip` (release v1.6.0) |

## Ce qui est, et ce qui n'est pas, prouvé

- **Prouvé (tests exécutables)** : mécaniques présentes et fonctionnelles, modèles
  réels chargés + cel-shadés, armes orientées, post-traitement activé, animation.
- **Non prouvable par un test** : l'appréciation esthétique « magnifique /
  splendide / hors du commun ». Celle-ci demande un œil humain. Les captures
  (`docs/screenshots/`) et l'anim `docs/gameplay.gif` sont fournies pour cela.
