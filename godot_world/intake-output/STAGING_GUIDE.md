# Candidate model staging

Run `python godot_world/tools/stage_candidate_models.py` after candidate GLB files have been placed in `godot_world/intake-output/`.

The script checks GLB headers and mesh/node data, stages skinned models into `assets/characters` and unskinned models into `assets/environment`, and never modifies the production acceptance manifest. Staging does not establish visual quality, licensing, Android suitability, or production acceptance. The current candidate collection consists of skinned models; therefore it does not supply environment scenery assets.
