from pprint import pprint

from src.ingestion.faostat.client import FAOSTATClient


def main() -> None:
    client = FAOSTATClient()

    response = client.get("groupsanddomains")

    pprint(response)


if __name__ == "__main__":
    main()