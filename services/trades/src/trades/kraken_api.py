import json
from typing import Any

from loguru import logger
from pydantic import BaseModel
from websocket import create_connection


class Trade(BaseModel):
    product_id: str
    price: float
    quantity: float
    timestamp: str

    def to_dict(self) -> dict[str, Any]:
        result: dict[str, Any] = self.model_dump()
        return result


class KrakenAPI:
    URL = "wss://ws.kraken.com/v2"

    def __init__(
        self,
        product_ids: list[str],
    ) -> None:
        self.product_ids = product_ids

        # create a websocket client
        self._ws_client = create_connection(self.URL)

        # send initial subscribe message
        self._subscribe(product_ids)

    def get_trades(self) -> list[Trade]:
        data: str = self._ws_client.recv()

        if "heartbeat" in data:
            logger.info("Heartbeat received")
            return []

        # transform raw string into a JSON object
        try:
            parsed_data: dict[str, Any] = json.loads(data)
        except json.JSONDecodeError as e:
            logger.error(f"Error decoding JSON: {e}")
            return []

        try:
            trades_data: list[dict[str, Any]] = parsed_data["data"]
        except KeyError as e:
            logger.error(f"No `data` field with trades in the message {e}")
            return []

        # Using list comprehension (this is faster)
        trades = [
            Trade(
                product_id=str(trade["symbol"]),
                price=float(trade["price"]),
                quantity=float(trade["qty"]),
                timestamp=str(trade["timestamp"]),
            )
            for trade in trades_data
        ]

        return trades

    def _subscribe(self, product_ids: list[str]) -> None:
        """
        Subscribes to the websocket for the given `product_ids`
        and waits for the initial snapshot.
        """
        # send a subscribe message to the websocket
        self._ws_client.send(
            json.dumps(
                {
                    "method": "subscribe",
                    "params": {
                        "channel": "trade",
                        "symbol": product_ids,
                        "snapshot": False,
                    },
                }
            )
        )

        # discard the first 2 messages for each product_id
        # as they contain no trade data
        for _ in product_ids:
            _ = self._ws_client.recv()
            _ = self._ws_client.recv()
