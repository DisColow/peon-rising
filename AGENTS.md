# Peon Rising

Jeu de STR 3D cartoon en **vue FPS** sous **Godot 4.7** (Forward+, mobile renderer
en secours). On incarne un péon **contrôlé directement** (WASD + souris) : on se
déplace, on regarde et on effectue soi-même chaque action (couper, miner, déposer,
construire, attaquer). Le commandant IA ne fait que **suggérer des objectifs**
affichés en permanence à l'écran ; le joueur l'influence via une "pierre de
contrôle" (influence), comme un animal de compagnie communiquerait avec son maître.

## Lancer / valider

- Lancer : `godot --path .` (scène principale `res://scenes/menu/menu.tscn`).
- Import headless : `godot --headless --import`.
- Simulation headless (debug) : `PEON_DEBUG=1 godot --headless res://scenes/main/main.tscn --quit-after 4800`.
  Le flag `PEON_DEBUG` active des `print` de télémétrie (état du péon, ordres,
  dépôts) — inoffensif hors flag.

Le binaire `godot` est dans `~/bin` (export `PATH="$HOME/bin:$PATH"`).

## Architecture (tout est construit procéduralement, peu de .tscn)

- `autoload/` — singletons :
  - `bootstrap.gd` : `Engine.max_fps=60` + création des actions d'entrée (WASD, dash, T/C/I, Échap + **manette** : stick gauche/droit, boutons A/B/X/Start).
  - `event_bus.gd` : signaux globaux (toast, resource_changed, order_assigned/completed, building_completed, base_destroyed, match_ended…).
  - `game_state.gd` : ressources (or/bois/nourriture), XP/niveau, influence, `reset_run()` (roguelite), `gain_xp()`, entrées tactiles (`touch_move`, `touch_action_pressed`, `touch_dash_pressed`).
  - `meta_progression.gd` : essence persistante, dépensée sur l'écran **progression permanente** (`scenes/menu/meta_ui.gd`).
  - `settings.gd` : réglages persistants (sensibilité souris, volume) sauvegardés dans `user://settings.json`.
  - `sound.gd` : mini-moteur audio procédural (`Sound.play("event")`), sons générés dans `assets/audio/`.
  - `pathfinder.gd` : **A\* sur grille 2D** (cellule 2.0u) pour contourner les obstacles. Autoload `Pathfinder`.
- `scripts/` — utilitaires/classe de base :
  - `builder.gd` : fabrique de meshes primitives + colliders (matériaux = `shaders/toon.gdshader`).
  - `unit_rig.gd` : **rig de personnage procédural** (tête/yeux/bras/jambes) avec animation de marche/idle (`update_animation`) et `swing_tool`. Réutilisé par `player`/`worker`/`grunt`.
  - `skeletal_actor.gd` : charge un **GLB squeletté réel** (assets artistes) et pilote son `AnimationPlayer` (`set_moving`). Preuve : `tests/test_skeletal.gd`.
  - `kaykit_rig.gd` : **rig basé sur les vrais modèles KayKit** (CC0) — charge le GLB,
    trouve `AnimationPlayer` + `Skeleton3D`, accroche `BoneAttachment3D` sur `head` /
    `handslot.r`, et expose la même interface que `UnitRig` (`update_animation`,
    `swing_tool`, `play_death`, `head`, `tool_r`, `carry_slot`). Utilisé par
    `worker`/`grunt` (fallback `UnitRig` si le GLB est introuvable).
  - `game_data.gd` : constantes (couleurs, coûts, stats des bâtiments).
  - `stats.gd` : calcul des stats d'unité (avec bonus de talents).
  - `talent_db.gd` : définition de l'arbre de talents (roguelite).
  - `order.gd` : type `Order` (enum + target/position/building_type).
  - `unit_base.gd` : base d'unité (déplacement, `navigate_to` avec pathfinding + anti-blocage, dégâts, knockback, mort). Fournit `_approach()` et `_target_radius()`.
  - `fx.gd` : particules / texte flottant / `hit_stop` (freeze-frame).
- `shaders/` — `toon.gdshader` (cel-shading : bandes douces, ombre teintée froide, rim, specular) et `ground.gdshader` (herbe procédurale world-space).
- `scenes/units/` : `player.gd` (héros FPS contrôlé par le joueur, raycast d'action,
  viewmodel animé, groupe `worker`), `worker.gd` (ouvrier allié **autonome** — machine
  à états récolte/dépôt, groupe `ally`) et `grunt.gd` (unité de mêlée allié/ennemi).
- `scenes/commander/` : `commander.gd` (IA joueur) et `enemy_commander.gd` (vagues ennemies).
- `scenes/buildings/` : `building.gd` (construction/achèvement, tour qui tire), `projectile.gd`.
- `scenes/resources/` : `tree.gd` (tombe), `gold_mine.gd` (on mine à l'intérieur), `gold_chunk.gd`.
- `scenes/main/` : `main.gd` (assemblage du monde, spawns joueur/ouvriers, victoire/
  défaite), `camera_rig.gd` (**caméra FPS** : look souris yaw/pitch, suit la tête).
- `scenes/ui/` : `hud.gd` (ressources, PV, XP, influence, boutons de suggestion, écran victoire/défaite avec Rejouer/Menu), `talent_tree_ui.gd`, `pause_menu.gd` (pause + sensibilité/volume), `touch_ui.gd` (joystick + boutons tactiles Android).
- `scenes/menu/` : `menu.gd` (menu principal), `meta_ui.gd` (écran de progression permanente).

## Rendu stylisé (v1.1 → v1.2)

- `main._build_environment()` : tonemapping **ACES** + color grade (saturation/contraste),
  sky procédural chaud, **lumière clé chaude + fill froide** (soft shadows), SSAO,
  glow subtil, brouillard chaud léger. Le sol utilise `ground.gdshader`.
- En **Forward+** : **SDFGI** (illumination globale) + **brouillard volumétrique**
  (diffusion de la lumière), gardés derrière `RenderingServer.get_current_rendering_method()`.
- Tous les meshes passent par le **cel-shader** (`builder.mat()`) pour un look
  "argile cartoon" homogène. Les arbres ont une canopée en sphères, les bâtiments
  des toits à deux pans (`_add_gable_roof`) + finitions, les unités un rig animé.
- `fx.hit_stop()` fige brièvement le temps (`Engine.time_scale`) sur les coups/abattages
  (timer *unscaled* pour reprendre tout seul).

## Assets & animation réelles (v1.3 → v1.4)

- **Unités = vrais modèles KayKit (CC0)** intégrés au gameplay via `kaykit_rig.gd` :
  péon/ouvrier = `Barbarian.glb`, **héros FPS (player.gd) = `Barbarian.glb`**,
  grunt allié = `Knight.glb`, grunt ennemi = `Skeleton_Warrior.glb` (variantes
  `Mage`, `Rogue_Hooded`, `Skeleton_Minion` dispo).
- **Cel-shading sur les modèles** : `shaders/toon_textured.gdshader` (version
  texturée de `toon.gdshader`) est appliqué à chaque surface via
  `KayKitRig._apply_toon()` (override `ShaderMaterial` + texture d'albédo
  d'origine) → look « cartoon Warcraft » homogène avec le monde procédural.
- Chaque GLB embarque sa **bibliothèque d'animations** (Idle, Walking_A/B/C, Running,
  `1H_Melee_Attack_*`, `Death_A`, Hit, Jump…). `kaykit_rig.gd` mappe : idle/walk via
  `update_animation()`, attaque via `swing_tool()` (anim one-shot), mort via `play_death()`.
- Les os KayKit sont nommés (`head`, `handslot.r`, …) → `BoneAttachment3D` pour les
  armes (main) et les marqueurs d'équipe (tête). L'échelle des unités est `1.2`
  (personnage ≈ 1.8u, aligné sur les colliders).
- **Convention de grip d'arme validée** (`tests/test_weapon_grip.gd`, 15 checks) :
  l'os `handslot.r` a +Z = monde-haut et +Y = monde-avant → manches verticaux,
  lames/têtes vers le haut. Les armes (pioche/épée/masse) suivent cette convention.
- `assets/models/` contient aussi les GLB de référence `CesiumMan.glb` (CC-BY) et
  `Fox.glb` (CC0). Voir `CREDITS.md`.

## Monde / bâtiments / nature (KayKit, CC0)

- `assets/models/kaykit_props/` : modèles KayKit « Medieval Hexagon Pack »
  (`buildings_green/`, `buildings_red/`, `nature/`, `props/`) — un `.gltf` + `.bin`
  + `hexagons_medieval.png` par dossier (les `.gltf` référencent leur texture en
  chemin relatif, il faut donc préserver la structure par sous-dossier).
- `scripts/kaykit_prop.gd` (`class_name KayKitProp`) charge un prop statique et lui
  applique le même cel-shader que les personnages (`KayKitProp.create()`), avec
  `node_height()` / `scale_to_height()` pour dimensionner sur la hauteur cible.
- Intégré : `building.gd` (castle/home_A/barracks/tower_A vert vs rouge selon
  l'équipe), `tree.gd` (tree_single_A/B), `gold_mine.gd` (building_mine). Le code
  procédural reste en **fallback** si le modèle ne charge pas.

## Captures hors-écran (preuve visuelle)

- `tests/capture_showcase.gd` : capture un GLB animé (env `MODEL`, `ANIM`, `FRAME`,
  `SHOT_OUT`). Lancement : `xvfb-run -a godot --rendering-method gl_compatibility
  --path . --script res://tests/capture_showcase.gd` (nécessite `xvfb` + Mesa GL).
- `tests/capture_weapon.gd` : capture un gros plan d'une arme en main (env `MODEL`,
  `WEAPON`=sword|mace|pickaxe, `SHOT_OUT`, `FRAME`) pour valider le grip visuellement.
- `tests/capture_world.gd` : capture une scène composée (château/ferme/caserne/tour/
  mine/arbres KayKit) — preuve que le monde n'est plus procédural (env `SHOT_OUT`).
- `tests/test_props.gd` : valide que chaque prop KayKit charge, est cel-shadé et se
  dimensionne à la hauteur cible (22 checks).
- `main.gd` a un hook `PEON_SHOT=<path>` qui capture le jeu (caméra 3ᵉ personne
  orientée vers la base) après 45 frames puis quitte.
- `tests/test_game_feel.gd` valide le **game feel** : cel-shader appliqué à
  toutes les surfaces du modèle, clips walk/attack/death présents, `FX.hit_stop`
  (freeze-frame) et `FX.burst` (particules d'impact). `tests/test_skeletal.gd`
  valide l'import des GLB de référence.

## Gameplay FPS (refonte)

- `player.gd` : `_tick()` lit WASD (relatif au `yaw` de la caméra), dash/sprint, et
  `interact` (clic gauche / E) déclenche un raycast (`_look_at_node`) qui dispatch
  coupe/mine/dépôt/attaque/construction selon le groupe du nœud visé.
- Les **ordres** sont devenus des **objectifs** : `commander._choose_objective()`
  renvoie un `Order` (construire/récolter/défendre/attaquer) affiché par le HUD.
  Pour construire, le commandant **place un bâtiment fantôme** (`Building.create_ghost`)
  et dépense les ressources ; le joueur va le finir au clic.
- **Autres unités** : 3 ouvriers alliés autonomes (`worker.gd`) + grunts alliés
  (caserne) + vagues ennemies. Le joueur est le seul contrôlé en direct.
- **Coupe du bois réaliste** : `tree.chop(multiplier, chopper)` creuse une entaille
  visible par coup (`_spawn_notch`), secoue le tronc, projette des copeaux, et
  l'arbre tombe après `MAX_HITS` coups.
- Entrée : actions `interact` (clic gauche/E) et suggestions `1`–`4` (influence),
  définies dans `bootstrap.gd`. La souris est capturée (FPS) et relâchée via T.

## Points d'attention (bugs déjà corrigés)

- **Navigation** : le steering direct se bloquait sur les gros obstacles (hôtel de
  ville). Solution : A\* (autoload `Pathfinder`) + anti-blocage perpendiculaire.
  Les obstacles sont enregistrés dans `main._register_navigation_obstacles()` et à
  chaque `building_completed`. L'encodage des cellules (`_key`/`_unkey`) doit rester
  bijectif (décalage par `SIZE`).
- **Ordres de construction** : ne jamais interrompre une construction en cours
  (les ressources sont déjà dépensées) — garde dans `commander._evaluate()`.
- **Points d'approche** : toujours viser un point *hors* de la collision du bâtiment
  (`_approach()`) sinon le péon reste collé au mur.

## Release / CI (GitHub Actions)

- Dépôt : `github.com/DisColow/peon-rising`.
- `.github/workflows/build.yml` compile Windows, Linux (Steamdeck) et Android,
  puis crée une release avec les 3 `.zip` quand on pousse un tag `v*`.
- Pour publier : `git tag -a vX.Y.Z -m "..." && git push origin vX.Y.Z`.
- Exports testés localement (`godot --headless --export-release "Windows Desktop"` /
  `"Linux"`). Android exige : JDK 17 (`actions/setup-java@v4`), SDK préinstallé du
  runner (`ANDROID_HOME=/usr/local/lib/android/sdk`), `debug.keystore` généré en CI
  (dans `.gitignore`), et `textures/vram_compression/import_etc2_astc=true`.

## Multijoueur / avenir

- Toute la logique passe par des signaux `EventBus` et des groupes de nœuds
  (`worker`, `ally`, `enemy`, `building_player`, `building_enemy`) → prêt pour un
  découpage réseau (séparation simulation / présentation) ultérieur.
- Amélioration permanente entre parties : `meta_progression.gd` (essence) à relier
  à un écran de méta-progression.
