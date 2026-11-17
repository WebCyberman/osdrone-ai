class Navigator:

    def distance(
        self,
        a,
        b
    ):
        return (
            (a[0] - b[0]) ** 2 +
            (a[1] - b[1]) ** 2 +
            (a[2] - b[2]) ** 2
        ) ** 0.5
