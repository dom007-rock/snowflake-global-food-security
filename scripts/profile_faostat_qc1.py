from pprint import pprint

from src.ingestion.faostat.client import FAOSTATClient


def main() -> None:
    client = FAOSTATClient()

    params = {
        "area": 106,
        "item": 15,
        "element": 2510,
        "year": 2022,
    }

    response = client.get(
        endpoint="data/QCL",
        params=params,
    )

    pprint(response)


if __name__ == "__main__":
    main()