from timeit import default_timer
import datetime as dt


class Timer:
    @staticmethod
    def get_timer():
        return default_timer()

    def __init__(self):
        self.start = self.get_timer()

    def now(self):
        return self.get_timer()

    def elapsed(self):
        elapsed = self.now() - self.start
        return elapsed

    def __str__(self):
        return str(dt.timedelta(self.elapsed()))


def timer():
    return Timer()


def iso_timestamp():
    return dt.datetime.now().astimezone().replace(microsecond=0).isoformat()
