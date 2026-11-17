class StateMachine:

    IDLE = "idle"
    EXPLORE = "explore"
    OBSERVE = "observe"

    def __init__(self):

        self.state = self.IDLE
