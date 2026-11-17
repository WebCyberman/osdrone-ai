import random


class Explorer:

    def next_target(self):

        return {
            "x": random.randint(10, 240),
            "y": random.randint(10, 240),
            "z": random.randint(10, 50)
        }
