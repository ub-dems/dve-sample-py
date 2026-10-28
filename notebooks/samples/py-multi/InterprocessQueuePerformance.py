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
# # Interprocess Queue Performance

# %% [markdown]
# * @see [@kylemcdonald:Interprocess Queue Performance.ipynb](https://gist.github.com/kylemcdonald/a2f0dcb86f01d4c57b68ac6a6c7a3068)

# %% [markdown]
# The built in `Pipe` is great if you are sending bytes.
# If you are not sending bytes, pickling and unpickling might become a bottleneck.
#
# I also checked https://github.com/portugueslab/arrayqueues which had very bad performance,
# and is specialized to numpy arrays not byte arrays.

# %% [markdown]
# ## Pyhon native `multiprocessing`

# %% [markdown]
# ### multiprocessing.Queue

# %%
import zmq

# %%
from time import time
from multiprocessing import Process
from multiprocessing import Queue
from multiprocessing import Pipe
from multiprocessing import Lock

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
    out_sync.acquire()
    try:
        print_elapsed_unsync(name, start)
    finally:
        out_sync.release()


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
# import zmq


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


address = "tcp://127.0.0.1:5557"
producer_process = Process(target=zmq_producer, args=(address,))
consumer_process = Process(target=zmq_consumer, args=(address,))
consumer_process.start()
producer_process.start()
consumer_process.join()
producer_process.join()

# %%
address = "ipc:///tmp/zmqtest"
producer_process = Process(target=zmq_producer, args=(address,))
consumer_process = Process(target=zmq_consumer, args=(address,))
consumer_process.start()
producer_process.start()
consumer_process.join()
producer_process.join()

# %% [markdown]
# ### Pair0 Example
#
# ```python
# from pynng import Pair0
# from multiprocessing import Process
#
# def nng_producer(address):
#     push = Pair0()
#     push.listen(address)
#     start = time()
#     for _i in range(n):
#         push.send(big_data)
#     print_elapsed('nng_producer', start)
#     push.close()
#
# def nng_consumer(address):
#     pull = Pair0()
#     pull.dial(address)
#     start = time()
#     for _i in range(n):
#         item = pull.recv()
#     print_elapsed('nng_consumer', start)
#     pull.close()
# ```
#
# ```python
# address = 'tcp://127.0.0.1:5557'
# producer_process = Process(target=nng_producer, args=(address,))
# consumer_process = Process(target=nng_consumer, args=(address,))
# consumer_process.start()
# producer_process.start()
# ```
#
# ```
# nng_producer: 0.828 ms/item, 1208 item/sec
# nng_consumer: 0.833 ms/item, 1201 item/sec
#
# ```
#
# ```python
# address = 'ipc://127.0.0.1:5557'
# producer_process = Process(target=nng_producer, args=(address,))
# consumer_process = Process(target=nng_consumer, args=(address,))
# consumer_process.start()
# producer_process.start()
# ```
#
# ```
# nng_producer: 1.294 ms/item, 773 item/sec
# nng_consumer: 1.301 ms/item, 768 item/sec
#
# ```
#

# %% [markdown]
# ### Cinda Example
#
# ```python
# # sudo apt install libboost-dev
# # pip install cinda
# from cinda.ipc import BytesQueue
# from cinda.ipc import free
#
# free('MyQueue')
# q = BytesQueue('MyQueue', n, len(big_data))
# producer_process = Process(target=producer, args=(q,))
# consumer_process = Process(target=consumer, args=(q,))
# consumer_process.start()
# producer_process.start()
# ```
#
# ```
# producer: 0.611 ms/item, 1637 item/sec
# consumer: 0.614 ms/item, 1629 item/sec
# ```

# %%
