import json
from pathlib import Path

from src.ingestion.faostat.client import FAOSTATClient


OUTPUT_PATH = Path("samples/faostat/groupsanddomains.json")


def main() -> None:
    client = FAOSTATClient()

    response = client.get("groupsanddomains")

    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)

    with OUTPUT_PATH.open("w", encoding="utf-8") as file:
        json.dump(
            response,
            file,
            indent=2,
            ensure_ascii=False,
        )

    print(f"FAOSTAT catalogue saved to: {OUTPUT_PATH}")


if __name__ == "__main__":
    main()