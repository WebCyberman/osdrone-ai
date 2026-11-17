class EpisodicMemory:

    def __init__(self):

        self.events = []

    def remember(
        self,
        event: dict
    ):
        self.events.append(event)
        