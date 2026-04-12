import json

file_names = [
    "app_en.arb",
    "app_fr.arb",
]
for file_name in file_names:
    with open(f"lib/l10n/{file_name}", "r", encoding="utf-8") as f:
        content = json.load(f)
    sorted_content = dict(sorted(content.items()))
    with open(f"lib/l10n/{file_name}", "w", encoding="utf-8") as f:
        json.dump(sorted_content, f, ensure_ascii=False, indent=2)
