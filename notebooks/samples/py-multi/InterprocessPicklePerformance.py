# ---
# jupyter:
#   jupytext:
#     formats: ipynb,py:percent
#     text_representation:
#       extension: .py
#       format_name: percent
#       format_version: '1.3'
#       jupytext_version: 1.19.5
#   kernelspec:
#     display_name: Python 3 (ipykernel)
#     language: python
#     name: python3
# ---

# %% [markdown]
# # Interprocess Pickle Performance

# %% [markdown]
# * @see [A Gentle Introduction to Serialization for Python](https://machinelearningmastery.com/a-gentle-introduction-to-serialization-for-python/)
# * @see [Serializing messages with PyZMQ](https://pyzmq.readthedocs.io/en/v15.4.0/serialization.html#serializing-messages-with-pyzmq)
# * @see [#](#)

# %% [markdown]
# The built in `Pipe` is great if you are sending bytes.
# If you are not sending bytes, pickling and unpickling might become a bottleneck.
#
# I also checked https://github.com/portugueslab/arrayqueues which had very bad performance,
# and is specialized to numpy arrays not byte arrays.

# %% [markdown]
# ## Imports

# %%
from time import time
from enum import Enum
from multiprocessing import Process
from multiprocessing import Queue
from multiprocessing import Pipe
from multiprocessing import Lock

# import cPickle as pickle

import numpy as np

import zmq


# %% [markdown]
# ## Abstract Types

# %% [markdown]
# ### Payloads


# %%
class PayloadsConsts:
    DEF_RANDOM_MAX = 2**31
    DEF_RANDOM_MIN = -DEF_RANDOM_MAX
    DEF_RANDOM_SIZE = 1024 * 1024 * 1024
    DEF_ARRAY_SIZE = DEF_RANDOM_SIZE
    DEF_RANDOM_RATE = 0.60

    ARR_RANDDM_DATA = np.random.default_rng().integers(DEF_RANDOM_MIN, DEF_RANDOM_MAX, DEF_RANDOM_SIZE)

    @staticmethod
    def fill(array: np.ndarray, random_rate: float = DEF_RANDOM_RATE) -> np.ndarray:
        m = int(min(array.size, min(1.0, random_rate) * PayloadsConsts.DEF_RANDOM_SIZE))
        array[:m] = PayloadsConsts.ARR_RANDDM_DATA[:m]
        return array


class PayloadData:
    def __init__(self, size: int = 0):
        self.size = size


class IntArrayPayloadData:
    def __init__(self, size: int, random_rate: float):
        self.size = size
        self.random_rate = random_rate
        self.array = PayloadsConsts.fill(np.zeros(size), random_rate)


class Payloads:
    INT_SZ_DEF_RND_DEF = IntArrayPayloadData(PayloadsConsts.DEF_ARRAY_SIZE, PayloadsConsts.DEF_RANDOM_RATE)
    DEF_ARRAY = INT_SZ_DEF_RND_DEF


# %% [markdown]
# ### Messages


# %%
class MsgType(Enum):
    CTL_BEGIN = -1
    CTL_END = -2
    DAT_PAYLOAD = 1


class Message:
    def __init__(self, msg_type: MsgType, stream_name: str, seq: int):
        self.msg_type = msg_type
        self.stream_name = stream_name
        self.seq = seq

    def is_data_msg(self) -> bool:
        return not self.is_control_msg()

    def is_control_msg(self) -> bool:
        return False


class ControlMessage(Message):
    def __init__(self, msg_type: MsgType, stream_name: str, seq: int):
        super().__init__(msg_type, stream_name, seq)

    def is_control_msg(self) -> bool:
        return True


class DataMessage(Message):
    def __init__(self, msg_type: MsgType, stream_name: str, seq: int):
        super().__init__(msg_type, stream_name, seq)


class StartStreamMessage(ControlMessage):
    MSG_TYPE = MsgType.CTL_BEGIN

    def __init__(self, stream_name: str):
        super().__init__(StartStreamMessage.MSG_TYPE, stream_name, 0)


class EndStreamMessage(ControlMessage):
    MSG_TYPE = MsgType.CTL_END

    def __init__(self, stream_name: str, seq: int):
        super().__init__(EndStreamMessage.MSG_TYPE, stream_name, seq)


class PayloadDataMessage(DataMessage):
    MSG_TYPE = MsgType.DAT_PAYLOAD

    def __init__(self, stream_name: str, seq: int):
        super().__init__(PayloadDataMessage.MSG_TYPE, stream_name, seq)


# %% [markdown]
# ### Queues

# %%

# %% [markdown]
# ## Python native `multiprocessing`

# %% [markdown]
# ### multiprocessing.Queue

# %%
n = 5000
sz = 1000 * 1000 * 10
big_data = b"\0" * sz

out_sync = Lock()


def print_elapsed_unsync(name, start):
    elapsed = time() - start
    ms_per_item = 1000 * elapsed / n
    item_per_sec = n / elapsed
    bytes_per_sec = n * sz / elapsed / (1024 * 1024)
    print(
        f"{name}: {ms_per_item:.3f} ms/item,",
        f"{item_per_sec:.0f} item/sec,",
        f"{bytes_per_sec:.0f} Mbytes/sec",
    )


def print_elapsed(name, start):
    with out_sync:
        print_elapsed_unsync(name, start)


def producer(q):
    start = time()
    for _i in range(n):
        q.put(big_data)
    print_elapsed("producer", start)


def consumer(q):
    start = time()
    for _i in range(n):
        out = q.get()
        assert out is not None
    print_elapsed("consumer", start)


# %%
if __name__ == "__main__":
    q = Queue()
    producer_process = Process(target=producer, args=(q,))
    consumer_process = Process(target=consumer, args=(q,))
    consumer_process.start()
    producer_process.start()
    consumer_process.join()
    producer_process.join()


# %% [markdown]
# ### multiprocessing.Pipe


# %%
class PipeQueue:
    def __init__(self, *args):
        self.out_pipe, self.in_pipe = Pipe(*args)

    def put(self, item):
        self.in_pipe.send(item)

    def get(self):
        return self.out_pipe.recv()

    def close(self):
        self.out_pipe.close()
        self.in_pipe.close()


if __name__ == "__main__":
    q = PipeQueue()
    producer_process = Process(target=producer, args=(q,))
    consumer_process = Process(target=consumer, args=(q,))
    consumer_process.start()
    producer_process.start()
    consumer_process.join()
    producer_process.join()
    q.close()


# %%
class BytesPipeQueue:
    def __init__(self, *args):
        self.out_pipe, self.in_pipe = Pipe(*args)

    def put(self, item):
        self.in_pipe.send_bytes(item)

    def get(self):
        return self.out_pipe.recv_bytes()

    def close(self):
        self.out_pipe.close()
        self.in_pipe.close()


# %%
if __name__ == "__main__":
    q = BytesPipeQueue()
    producer_process = Process(target=producer, args=(q,))
    consumer_process = Process(target=consumer, args=(q,))
    consumer_process.start()
    producer_process.start()
    consumer_process.join()
    producer_process.join()
    q.close()

# %% [markdown]
# In CPython setting `duplex=False` uses an `os.pipe`
# [instead of two blocking sockets](https://github.com/python/cpython/blob/3.7/Lib/multiprocessing/connection.py#L510-L519).
# This seems to be much slower.

# %%
if __name__ == "__main__":
    q = BytesPipeQueue(False)
    producer_process = Process(target=producer, args=(q,))
    consumer_process = Process(target=consumer, args=(q,))
    consumer_process.start()
    producer_process.start()
    consumer_process.join()
    producer_process.join()
    q.close()


# %% [markdown]
# ## Alternative Frameworks

# %% [markdown]
# ### 0MQ Example


# %%
def zmq_producer(address):
    context = zmq.Context()
    push = context.socket(zmq.PUSH)
    push.bind(address)
    start = time()
    for _i in range(n):
        push.send(big_data)
    print_elapsed("zmq_producer", start)
    push.close()


def zmq_consumer(address):
    context = zmq.Context()
    pull = context.socket(zmq.PULL)
    pull.connect(address)
    start = time()
    for _i in range(n):
        item = pull.recv()
        assert item is not None
    print_elapsed("zmq_consumer", start)
    pull.close()


# %%
if __name__ == "__main__":
    address = "tcp://127.0.0.1:5557"
    producer_process = Process(target=zmq_producer, args=(address,))
    consumer_process = Process(target=zmq_consumer, args=(address,))
    consumer_process.start()
    producer_process.start()
    consumer_process.join()
    producer_process.join()

# %%
if __name__ == "__main__":
    address = "ipc:///tmp/zmqtest"
    producer_process = Process(target=zmq_producer, args=(address,))
    consumer_process = Process(target=zmq_consumer, args=(address,))
    consumer_process.start()
    producer_process.start()
    consumer_process.join()
    producer_process.join()
