from pathlib import Path


path = Path("lib/features/main_module/map/view/map_screen.dart")
text = path.read_text(encoding="utf-8")

old = """  void _reorderIntermediatePoints(int oldIndex, int newIndex) {
    setState(() {
      final adjusted = newIndex > oldIndex ? newIndex - 1 : newIndex;
      final point = _intermediatePoints.removeAt(oldIndex);
      _intermediatePoints.insert(adjusted, point);
    });
  }"""
new = """  void _reorderIntermediatePoints(int oldIndex, int newIndex) {
    setState(() {
      final point = _intermediatePoints.removeAt(oldIndex);
      _intermediatePoints.insert(newIndex, point);
    });
  }"""

if new not in text:
    if text.count(old) != 1:
        raise RuntimeError("Could not find the route reorder implementation")
    text = text.replace(old, new, 1)
    path.write_text(text, encoding="utf-8")
    print(f"Updated {path}")
else:
    print(f"No changes needed for {path}")
