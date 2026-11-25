#!/usr/bin/env python3
"""Generate bootstrap GLB assets for FAMILY COLONY.

Original procedural mesh assemblies for import/pipeline testing only. They are
NOT production-approved art and must not be treated as final visual approval.
Requires: pip install trimesh
"""
from pathlib import Path
import trimesh

ROOT = Path(__file__).resolve().parents[1]
CHAR_DIR = ROOT / "assets" / "characters"
ENV_DIR = ROOT / "assets" / "environment"


def sphere(name, pos, scale, color):
    m = trimesh.creation.icosphere(subdivisions=3, radius=1)
    m.apply_scale(scale)
    m.apply_translation(pos)
    m.visual.vertex_colors = color
    m.metadata["name"] = name
    return m


def capsule(name, pos, radius, height, color, axis="y"):
    m = trimesh.creation.capsule(radius=radius, height=height, count=[16, 16])
    if axis == "y":
        m.apply_transform(trimesh.transformations.rotation_matrix(1.57079632679, [1, 0, 0]))
    elif axis == "x":
        m.apply_transform(trimesh.transformations.rotation_matrix(1.57079632679, [0, 1, 0]))
    m.apply_translation(pos)
    m.visual.vertex_colors = color
    m.metadata["name"] = name
    return m


def export_character(path, palette):
    meshes = [
        sphere("head", (0, 1.55, 0), (.34, .38, .32), palette[0]),
        capsule("torso", (0, .95, 0), .24, .62, palette[1]),
        capsule("left_arm", (-.36, .98, 0), .10, .48, palette[1], "x"),
        capsule("right_arm", (.36, .98, 0), .10, .48, palette[1], "x"),
        capsule("left_leg", (-.15, .40, 0), .12, .52, palette[2]),
        capsule("right_leg", (.15, .40, 0), .12, .52, palette[2]),
        sphere("left_eye", (-.12, 1.62, .285), (.055, .075, .035), [18,18,24,255]),
        sphere("right_eye", (.12, 1.62, .285), (.055, .075, .035), [18,18,24,255]),
        capsule("antenna_left", (-.13, 1.94, 0), .035, .20, palette[3]),
        capsule("antenna_right", (.13, 1.94, 0), .035, .20, palette[3]),
        sphere("wing_left", (-.40, 1.25, -.05), (.23, .38, .06), [180,220,235,170]),
        sphere("wing_right", (.40, 1.25, -.05), (.23, .38, .06), [180,220,235,170]),
    ]
    scene = trimesh.Scene()
    for m in meshes:
        scene.add_geometry(m, node_name=m.metadata.get("name", "mesh"))
    scene.export(path, file_type="glb")


def build_environment(path):
    scene = trimesh.Scene()
    ground = trimesh.creation.box(extents=(14, .15, 14))
    ground.apply_translation((0, -.08, 0))
    ground.visual.vertex_colors = [70, 110, 120, 255]
    scene.add_geometry(ground, node_name="ground")
    for i, (x, z, h, col) in enumerate([
        (-3.0,-2.5,2.2,[115,155,170,255]), (3.2,-2.0,3.0,[150,170,185,255]),
        (-2.8,3.0,2.7,[100,145,160,255]), (2.6,3.1,1.8,[175,190,200,255])
    ]):
        b = trimesh.creation.box(extents=(1.6,h,1.4))
        b.apply_translation((x,h/2,z))
        b.visual.vertex_colors = col
        scene.add_geometry(b, node_name=f"building_{i}")
    for i, (x,z) in enumerate([(-1.8,0),(1.8,0),(0,-1.8),(0,1.8)]):
        tree = trimesh.creation.icosphere(subdivisions=2, radius=.65)
        tree.apply_translation((x,1.25,z))
        tree.visual.vertex_colors = [75,145,110,255]
        scene.add_geometry(tree, node_name=f"tree_canopy_{i}")
        trunk = trimesh.creation.cylinder(radius=.12,height=1.1)
        trunk.apply_translation((x,.55,z))
        trunk.visual.vertex_colors = [115,90,70,255]
        scene.add_geometry(trunk, node_name=f"tree_trunk_{i}")
    scene.export(path, file_type="glb")


def main():
    CHAR_DIR.mkdir(parents=True, exist_ok=True)
    ENV_DIR.mkdir(parents=True, exist_ok=True)
    export_character(CHAR_DIR / "bootstrap_character.glb", [
        [220,200,185,255], [100,150,175,255], [60,80,105,255], [90,190,205,255]
    ])
    build_environment(ENV_DIR / "bootstrap_environment.glb")
    print("Generated bootstrap GLB assets. Not production visual approval.")


if __name__ == "__main__":
    main()
