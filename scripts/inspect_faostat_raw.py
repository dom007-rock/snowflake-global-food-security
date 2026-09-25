import os
from pprint import pprint

import requests
from dotenv import load_dotenv


BASE_URL = "https://faostatservices.fao.org/api/v1/en"

load_dotenv(override=True)

token = os.getenv("FAOSTAT_ACCESS_TOKEN")

if not token:
    raise RuntimeError("FAOSTAT_ACCESS_TOKEN is not configured.")

response = requests.get(
    f"{BASE_URL}/data/QCL",
    headers={
        "Authorization": f"Bearer {token}",
        "Accept": "application/json",
    },
    params={
        "area": "106",
        "item": "15",
        "element": "2510",
        "year": "2023",
    },
    timeout=30,
)

if not response.ok:
    raise RuntimeError(
        f"FAOSTAT request failed: "
        f"{response.status_code} "
        f"{response.url}\n"
        f"{response.text[:500]}"
    )

payload = response.json()

print("\nPAYLOAD TYPE")
print(type(payload).__name__)

if isinstance(payload, dict):
    print("\nTOP-LEVEL KEYS")
    print(list(payload.keys()))

    for key, value in payload.items():
        if isinstance(value, list):
            print(f"\nLIST FIELD: {key}")
            print(f"ROW COUNT: {len(value)}")

            if value:
                print("\nFIRST RECORD")
                pprint(value[0])

            break
else:
    print("\nPAYLOAD PREVIEW")
    pprint(payload)