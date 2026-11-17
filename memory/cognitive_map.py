class CognitiveMap:

    def __init__(self):

        self.positions = []

    def add_position(
        self,
        x: float,
        y: float,
        z: float
    ):
        self.positions.append(
            (x, y, z)
        )
        