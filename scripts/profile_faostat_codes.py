import argparse
import os
from pathlib import Path

import faostat
from dotenv import load_dotenv


OUTPUT_ROOT = Path("samples/faostat")


def configure_faostat() -> None:
    load_dotenv(override=True)

    token = os.getenv("FAOSTAT_ACCESS_TOKEN")
    if not token:
        raise RuntimeError("FAOSTAT_ACCESS_TOKEN is not configured.")

    faostat.set_requests_args(
        token=token,
        timeout=120,
    )


def get_subdimensions(domain: str) -> list[str]:
    parameters = faostat.list_pars(domain)

    subdimensions = []

    for _, _, available_subdimensions in parameters[1:]:
        subdimensions.extend(available_subdimensions.keys())

    return subdimensions


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Export FAOSTAT dimension code lists."
    )
    parser.add_argument("--domain", required=True)

    args = parser.parse_args()
    domain = args.domain.upper()

    configure_faostat()

    output_dir = OUTPUT_ROOT / domain.lower() / "codes"
    output_dir.mkdir(parents=True, exist_ok=True)

    subdimensions = get_subdimensions(domain)

    for subdimension in subdimensions:
        data = faostat.get_par_df(domain, subdimension)

        output_path = output_dir / f"{subdimension}.json"

        data.to_json(
            output_path,
            orient="records",
            indent=2,
            force_ascii=False,
        )

        print(
            f"{subdimension:<15} "
            f"rows={len(data):>5}  "
            f"path={output_path}"
        )


if __name__ == "__main__":
    main()