import argparse
import json
from pathlib import Path

from src.ingestion.faostat.client import FAOSTATClient


OUTPUT_ROOT = Path("samples/faostat")


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Retrieve FAOSTAT domain metadata for source profiling."
    )

    parser.add_argument(
        "--domain",
        required=True,
        help="FAOSTAT domain code, for example QCL.",
    )

    return parser.parse_args()


def main() -> None:
    args = parse_arguments()
    domain = args.domain.upper()

    client = FAOSTATClient()

    response = client.get(f"dimensions/{domain}")

    output_directory = OUTPUT_ROOT / domain.lower()
    output_directory.mkdir(parents=True, exist_ok=True)

    output_path = output_directory / "dimensions.json"

    with output_path.open("w", encoding="utf-8") as file:
        json.dump(
            response,
            file,
            indent=2,
            ensure_ascii=False,
        )

    print(
        f"FAOSTAT domain metadata saved: "
        f"domain={domain}, path={output_path}"
    )


if __name__ == "__main__":
    main()