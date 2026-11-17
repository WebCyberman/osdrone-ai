import json


class Collector:

    def save(self, event: dict):

        print(
            json.dumps(
                event,
                indent=2
            )
        )
