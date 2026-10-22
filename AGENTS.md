# Peon Rising

Jeu de STR 3D cartoon en **vue FPS** sous **Godot 4.7** (Forward+, mobile renderer
en secours). On incarne un péon **contrôlé directement** (WASD + souris) : on se
déplace, on regarde et on effectue soi-même chaque action (couper, miner, déposer,
construire, attaquer). Le commandant IA ne fait que **suggérer des objectifs**
affichés en permanence à l'écran ; le joueur l'influence via une "pierre de
contrôle" (influence), comme un animal de compagnie communiquerait avec son maître.

## Lancer / valider

- Lancer : `godot --path .` (scène principale `res://scenes/main/main.tscn`).
- Import headless : `godot --headless --import`.
- Simulation headless (debug) : `PEON_DEBUG=1 godot --headless --quit-after 4800`.
  Le flag `PEON_DEBUG` active des `print` de télémétrie (état du péon, ordres,
  dépôts) — inoffensif hors flag.

Le binaire `godot` est dans `~/bin` (export `PATH="$HOME/bin:$PATH"`).

## Architecture (tout est construit procéduralement, peu de .tscn)

- `autoload/` — singletons :
  - `bootstrap.gd` : `Engine.max_fps=60` + création des actions d'entrée (WASD, dash, T/C/I…).
  - `event_bus.gd` : signaux globaux (toast, resource_changed, order_assigned/completed, building_completed, base_destroyed, match_ended…).
  - `game_state.gd` : ressources (or/bois/nourriture), XP/niveau, influence, `reset_run()` (roguelite), `gain_xp()`.
  - `meta_progression.gd` : essence persistante (améliorations permanentes à venir).
  - `pathfinder.gd` : **A\* sur grille 2D** (cellule 2.0u) pour contourner les obstacles. Autoload `Pathfinder`.
- `scripts/` — utilitaires/classe de base :
  - `builder.gd` : fabrique de meshes primitives + colliders.
  - `game_data.gd` : constantes (couleurs, coûts, stats des bâtiments).
  - `stats.gd` : calcul des stats d'unité (avec bonus de talents).
  - `talent_db.gd` : définition de l'arbre de talents (roguelite).
  - `order.gd` : type `Order` (enum + target/position/building_type).
  - `unit_base.gd` : base d'unité (déplacement, `navigate_to` avec pathfinding + anti-blocage, dégâts, knockback, mort). Fournit `_approach()` et `_target_radius()`.
  - `fx.gd` : particules / texte flottant.
- `scenes/units/` : `player.gd` (héros FPS contrôlé par le joueur, raycast d'action,
  viewmodel animé, groupe `worker`), `worker.gd` (ouvrier allié **autonome** — machine
  à états récolte/dépôt, groupe `ally`) et `grunt.gd` (unité de mêlée allié/ennemi).
- `scenes/commander/` : `commander.gd` (IA joueur) et `enemy_commander.gd` (vagues ennemies).
- `scenes/buildings/` : `building.gd` (construction/achèvement, tour qui tire), `projectile.gd`.
- `scenes/resources/` : `tree.gd` (tombe), `gold_mine.gd` (on mine à l'intérieur), `gold_chunk.gd`.
- `scenes/main/` : `main.gd` (assemblage du monde, spawns joueur/ouvriers, victoire/
  défaite), `camera_rig.gd` (**caméra FPS** : look souris yaw/pitch, suit la tête).
- `scenes/ui/` : `hud.gd` (ressources, PV, XP, influence, boutons de suggestion), `talent_tree_ui.gd`.

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
