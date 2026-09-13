#!/usr/bin/env python3
"""
Regenerates the repetitive per-tendril uniform boilerplate for Border.qml
and shaders/border.frag from a single count. Run this any time you want to
change the render capacity (Theme.tendrilRenderCapacity), then paste the
output blocks into place and re-run ./compile-shaders.

Usage: python3 gen_tendril_uniforms.py <count>
"""
import sys

count = int(sys.argv[1]) if len(sys.argv) > 1 else 16

print("// ==== Paste into Border.qml (replaces existing tendrilNPos/Thick block) ====")
for i in range(count):
    print(f"    property vector4d tendril{i}Pos: slotPos({i})")
for i in range(count):
    print(f"    property vector4d tendril{i}Thick: slotThick({i})")

print()
print("// ==== Paste into border.frag uniform buf { ... } (replaces existing members) ====")
for i in range(count):
    print(f"    vec4 tendril{i}Pos;")
for i in range(count):
    print(f"    vec4 tendril{i}Thick;")

print()
print("// ==== Paste into border.frag main() (replaces existing addTendril calls) ====")
for i in range(count):
    print(f"    scene = addTendril(scene, px, tendril{i}Pos, tendril{i}Thick, tendrilBlendRadius);")

print()
print(f"// Remember to also set Theme.tendrilRenderCapacity: {count}")
