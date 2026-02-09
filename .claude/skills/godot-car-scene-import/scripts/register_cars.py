#!/usr/bin/env python3
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[4]
MAIN_SCENE = ROOT / "scenes/main.tscn"
CAR_SCENES_DIR = ROOT / "scenes/cars"
MODELS_DIR = ROOT / "assets/models"


CAR_SCENE_TEMPLATE = """[gd_scene format=3]

[ext_resource type=\"PackedScene\" path=\"res://assets/models/{name}/{name}.glb\" id=\"1_model\"]

[node name=\"CarBody\" type=\"RigidBody3D\"]

[node name=\"Model\" parent=\".\" instance=ExtResource(\"1_model\")]

[editable path=\"Model\"]
"""


def slug(name: str) -> str:
	return re.sub(r"[^a-z0-9]", "", name.lower())[:8] or "car"


def display_name(name: str) -> str:
	parts = [p for p in name.split("_") if p]
	return " ".join(p.upper() if p.isdigit() else p.capitalize() for p in parts) if parts else name


def ensure_model_exists(name: str) -> None:
	model = MODELS_DIR / name / f"{name}.glb"
	if not model.exists():
		raise FileNotFoundError(f"Missing model: {model}")


def ensure_car_scene(name: str) -> Path:
	CAR_SCENES_DIR.mkdir(parents=True, exist_ok=True)
	path = CAR_SCENES_DIR / f"{name}.tscn"
	if not path.exists():
		path.write_text(CAR_SCENE_TEMPLATE.format(name=name), encoding="utf-8")
	return path


def _next_ext_id(main_text: str) -> int:
	ids = [int(m.group(1)) for m in re.finditer(r'id="(\d+)_', main_text)]
	return (max(ids) + 1) if ids else 1


def _upsert_ext_resources(main_text: str, car_names: list[str]) -> tuple[str, dict[str, str]]:
	path_to_id: dict[str, str] = {}
	for m in re.finditer(r'\[ext_resource[^\n]*path="([^"]+)"[^\n]*id="([^"]+)"\]', main_text):
		path_to_id[m.group(1)] = m.group(2)

	next_id = _next_ext_id(main_text)
	new_lines: list[str] = []
	added_map: dict[str, str] = {}

	for name in car_names:
		res_path = f"res://scenes/cars/{name}.tscn"
		if res_path in path_to_id:
			added_map[name] = path_to_id[res_path]
			continue
		ext_id = f"{next_id}_auto{slug(name)}"
		next_id += 1
		new_lines.append(
			f"[ext_resource type=\"PackedScene\" path=\"{res_path}\" id=\"{ext_id}\"]"
		)
		added_map[name] = ext_id

	if not new_lines:
		for name in car_names:
			res_path = f"res://scenes/cars/{name}.tscn"
			added_map[name] = path_to_id[res_path]
		return main_text, added_map

	all_lines = main_text.splitlines()
	insert_at = -1
	for i, line in enumerate(all_lines):
		if line.startswith("[ext_resource "):
			insert_at = i
	if insert_at < 0:
		raise RuntimeError("No ext_resource block found in scenes/main.tscn")

	updated = all_lines[: insert_at + 1] + new_lines + all_lines[insert_at + 1 :]
	return "\n".join(updated) + "\n", added_map


def _append_unique_items(bracket_content: str, items: list[str]) -> str:
	existing = [x.strip() for x in bracket_content.split(",") if x.strip()]
	for item in items:
		if item not in existing:
			existing.append(item)
	return ", ".join(existing)


def _update_car_manager_arrays(main_text: str, car_names: list[str], id_map: dict[str, str]) -> str:
	new_scene_items = [f'ExtResource("{id_map[n]}")' for n in car_names]
	new_name_items = [f'"{display_name(n)}"' for n in car_names]

	def repl_scenes(match: re.Match) -> str:
		content = _append_unique_items(match.group(1), new_scene_items)
		return f"car_scenes = [{content}]"

	def repl_names(match: re.Match) -> str:
		content = _append_unique_items(match.group(1), new_name_items)
		return f"car_names = Array[String]([{content}])"

	text = re.sub(r"car_scenes\s*=\s*\[(.*)\]", repl_scenes, main_text, count=1)
	text = re.sub(r"car_names\s*=\s*Array\[String\]\(\[(.*)\]\)", repl_names, text, count=1)
	return text


def register(cars: list[str]) -> None:
	if not cars:
		raise ValueError("Usage: register_cars.py <car_name> [car_name...]")

	for name in cars:
		ensure_model_exists(name)
		scene = ensure_car_scene(name)
		print(f"Scene ready: {scene.relative_to(ROOT)}")

	main_text = MAIN_SCENE.read_text(encoding="utf-8")
	main_text, id_map = _upsert_ext_resources(main_text, cars)
	main_text = _update_car_manager_arrays(main_text, cars, id_map)
	MAIN_SCENE.write_text(main_text, encoding="utf-8")
	print(f"Updated: {MAIN_SCENE.relative_to(ROOT)}")


if __name__ == "__main__":
	try:
		register(sys.argv[1:])
	except Exception as exc:
		print(f"Error: {exc}", file=sys.stderr)
		sys.exit(1)
