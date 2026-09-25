import os
from typing import Any

import requests
from dotenv import load_dotenv


load_dotenv(override=True)


class FAOSTATClient:
    BASE_URL = "https://faostatservices.fao.org/api/v1/en"

    def __init__(self) -> None:
        self.access_token = os.getenv("FAOSTAT_ACCESS_TOKEN")

        if not self.access_token:
            raise ValueError(
                "FAOSTAT_ACCESS_TOKEN is not configured in the environment."
            )

        self.session = requests.Session()
        self.session.headers.update(
            {
                "Authorization": f"Bearer {self.access_token}",
                "Accept": "application/json",
            }
        )

    def get(
        self,
        endpoint: str,
        params: dict[str, Any] | None = None,
        timeout: int = 30,
    ) -> dict[str, Any]:
        url = f"{self.BASE_URL}/{endpoint.lstrip('/')}"

        response = self.session.get(
            url,
            params=params,
            timeout=timeout,
        )

        if not response.ok:
            raise RuntimeError(
                "FAOSTAT API request failed. "
                f"status={response.status_code}, "
                f"url={response.url}, "
                f"response={response.text[:500]}"
            )

        return response.json()