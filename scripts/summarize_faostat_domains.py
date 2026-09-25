import csv
import json
from pathlib import Path


FAOSTAT_ROOT = Path("samples/faostat")
DOMAINS = ["QCL", "LC", "ESB", "FBS", "GT", "FS"]

OUTPUT_PATH = FAOSTAT_ROOT / "domain_profile_summary.csv"


def load_json(path: Path):
    with path.open("r", encoding="utf-8") as file:
        return json.load(file)


def summarize_domain(domain: str) -> dict:
    domain_dir = FAOSTAT_ROOT / domain.lower()

    dimensions = load_json(domain_dir / "dimensions.json")

    top_level_dimensions = []
    subdimensions = []

    for dimension in dimensions.get("data", []):
        top_level_dimensions.append(dimension["id"])

        for subdimension in dimension.get("subdimensions", []):
            subdimensions.append(subdimension["id"])

    code_counts = {}

    codes_dir = domain_dir / "codes"

    if codes_dir.exists():
        for file_path in sorted(codes_dir.glob("*.json")):
            records = load_json(file_path)

            code_counts[file_path.stem] = (
                len(records) if isinstance(records, list) else None
            )

    return {
        "domain": domain,
        "dimensions": ", ".join(top_level_dimensions),
        "subdimensions": ", ".join(subdimensions),
        "code_counts": json.dumps(code_counts, sort_keys=True),
    }


def main() -> None:
    results = [summarize_domain(domain) for domain in DOMAINS]

    with OUTPUT_PATH.open("w", newline="", encoding="utf-8") as file:
        writer = csv.DictWriter(
            file,
            fieldnames=[
                "domain",
                "dimensions",
                "subdimensions",
                "code_counts",
            ],
        )

        writer.writeheader()
        writer.writerows(results)

    print(f"Domain profile summary written to {OUTPUT_PATH}")

    for result in results:
        print(
            f"{result['domain']:<4} "
            f"dimensions=[{result['dimensions']}] "
            f"subdimensions=[{result['subdimensions']}]"
        )


if __name__ == "__main__":
    main()