#!/usr/bin/env python
# coding: utf-8

# TODO: incomplete <c:NUMA>

# In[1]:

from dataclasses import dataclass, field
import numpy as np
import pandas as pd

import time
import os
import os.path
import re
import glob
import sys
import argparse
from datetime import datetime
from typing import Optional

# In[2]:

from vce.cli.xargs import get_part_argparser

from vce.common.util.trace import trace_logger
from vce.common.util.kernel import in_notebook
from vce.common.util.lint import unused
from vce.config.data import cfd

# In[3]:

import logging

logging.basicConfig(level=logging.DEBUG)
log = logging.getLogger(__name__)
trc = trace_logger("dmy")

# //////////////////////////////////////////////////////////////////////////////////////////////////

# In[3]:

RC = 0

TIME_START = datetime.now()

TEST_CASE_1_TINY = "test_one-80.csv"
TEST_CASE_1_SMALL = "test_one-1k.csv"
TEST_CASE_1_MEDIUM = "test_one-2k.csv"
TEST_CASE_1_LARGE = "test_one-35k.csv"
TEST_CASE_DEFAULT = TEST_CASE_1_SMALL

ARGV_DEFAULT = [
    "--jobname",
    "_",
    "--group",
    "test",
    "--filename",
    TEST_CASE_DEFAULT,
]

ARGV_NOTEBOOK = ARGV_DEFAULT

# -----

args = None
in_data = None
out_data = None
df = None
sentence = None
dat = None
model = None

# //////////////////////////////////////////////////////////////////////////////////////////////////

# In[4]:


def get_argv(argv=None):
    if argv is not None:
        return argv
    if in_notebook():
        return ARGV_NOTEBOOK
    if len(sys.argv) > 1:
        return sys.argv[1:]
    return ARGV_DEFAULT


def argparser(options=None):
    """Base Argument Parser."""
    unused(options)
    parser = argparse.ArgumentParser(add_help=False, conflict_handler="resolve")

    parser.add_argument("-j", "--jobname", type=str, help="job name", default="_")
    parser.add_argument("-g", "--group", type=str, help="job group", default="_")
    parser.add_argument("-f", "--filename", type=str, help="data file name", default="_")
    return parser


def parse_args(argv=None, **kwargs):
    parser = get_part_argparser()
    result = parser.parse_args(argv, **kwargs)
    return result


# //////////////////////////////////////////////////////////////////////////////////////////////////


def is_core_parallel():
    slots = os.getenv("X_CORE_SLOTS")
    if not slots:
        return False
    return int(slots) > 0


def is_core_simple():
    return not is_core_parallel()


def is_core_mode(mode):
    if is_core_simple():
        return False
    env_mode = os.getenv("X_CORE_MODE")
    if not env_mode:
        return False
    return int(env_mode) == mode


def is_core_worker():
    if is_core_simple():
        return True
    return is_core_mode(0)


def is_core_distributor():
    return is_core_mode(1)


def is_core_collector():
    return is_core_mode(2)


def slot_idx():
    slot = os.getenv("X_CORE_SLOT")
    if not slot:
        return 0
    return int(slot)


def slots_num():
    slots = os.getenv("X_CORE_SLOTS")
    if not slots:
        return 1
    return int(slots)


def jobid():
    jobid = os.getenv("X_CORE_JOBID")
    if not jobid:
        return TIME_START.isoformat()
    return jobid


# //////////////////////////////////////////////////////////////////////////////////////////////////

# In[5]:


@dataclass
class Model:
    finbert: dict = field(default_factory=lambda: {"empty": True})
    tokenizer: dict = field(default_factory=dict)


def retrieve_model():
    finbert = {}  # AutoModelForSequenceClassification.from_pretrained("ProsusAI/finbert")
    tokenizer = {}  # AutoTokenizer.from_pretrained("ProsusAI/finbert")
    model = Model(finbert, tokenizer)
    return model


# //////////////////////////////////////////////////////////////////////////////////////////////////

# In[6]:


@dataclass
class DataConf:
    dd_jobid: str
    dd_slot: int
    dd_slots: int
    dd_group: str
    dd_filename: str
    dd_path: str
    dd_temp: str
    dd_part: str
    dd_indir: str
    dd_outdir: str
    dd_infile: str
    dd_outfile: str


dd_conf: Optional[DataConf] = None


def arg_jobid(args):
    unused(args)
    return jobid()


def arg_group(args):
    return args.group


def arg_filename(args):
    return args.filename


def arg_slotid(args):
    unused(args)
    return slot_idx()


def arg_slotnum(args):
    unused(args)
    return slots_num()


def config_data() -> DataConf:
    dd_jobid = arg_jobid(args)
    dd_slot = arg_slotid(args)
    dd_slots = arg_slotnum(args)
    dd_group = arg_group(args)
    dd_filename = arg_filename(args)
    dd_path = f"{cfd().DATA_HOME}/{dd_group}"
    dd_temp = f"{cfd().DATA_TEMP}/{__name__}/{dd_jobid}/{dd_slots}"
    dd_indir = "Output R"
    dd_outdir = "Output Python"

    if is_core_parallel():
        if is_core_collector():
            dd_part = f"{dd_temp}/{{dd_slot}}/"
            dd_infile = f"{dd_path}/{dd_indir}/{dd_filename}"
            dd_outfile = f"{dd_part}/{dd_indir}/{dd_filename}"
        elif is_core_worker():
            dd_part = f"{dd_temp}/{dd_slot}/"
            dd_infile = f"{dd_part}/{dd_indir}/{dd_filename}"
            dd_outfile = f"{dd_temp}/{dd_outdir}/{dd_filename}"
        elif is_core_collector():
            dd_part = f"{dd_temp}/{{dd_slot}}/"
            dd_infile = f"{dd_part}/{dd_outdir}/{dd_filename}"
            dd_outfile = f"{dd_path}/{dd_outdir}/{dd_filename}"
        else:
            raise ValueError("is_core_parallel")
    elif is_core_simple():
        dd_part = f"{dd_temp}/_/"
        dd_infile = f"{dd_path}/{dd_indir}/{dd_filename}"
        dd_outfile = f"{dd_path}/{dd_outdir}/{dd_filename}"
    else:
        raise ValueError("is_core_what")

    dd_conf = DataConf(
        dd_jobid=dd_jobid,
        dd_slot=dd_slot,
        dd_slots=dd_slots,
        dd_group=dd_group,
        dd_filename=dd_filename,
        dd_path=dd_path,
        dd_temp=dd_temp,
        dd_part=dd_part,
        dd_indir=dd_indir,
        dd_outdir=dd_outdir,
        dd_infile=dd_infile,
        dd_outfile=dd_outfile,
    )

    return dd_conf


# //////////////////////////////////////////////////////////////////////////////////////////////////

# In[7]:


def ensure_path(filename):
    dir_name = os.path.dirname(filename)
    os.makedirs(dir_name, mode=0o775, exist_ok=True)
    return filename


def load_data(dd_conf=dd_conf):
    unused(dd_conf)
    dd_infile = "infile.csv"  # dd_conf.dd_infile
    df = pd.read_csv(dd_infile, sep=";")
    # print (df)
    return df


# In[8]:


@dataclass
class InputData:
    df: Optional[pd.DataFrame] = None
    id: Optional[pd.Series] = None
    sentence: Optional[pd.Series] = None
    dat: Optional[pd.Series] = None


CNF_INPUT_MAX_INDEXES = 512


def prepare_data(df=df, model=model):
    assert model is not None
    tokenizer = model.tokenizer
    assert df is not None
    sentence = df["text"]
    dat = df["created_at"]
    id = df["id"]
    # print(*sentence,sep="\n")
    # print(dat)
    alert = 0
    i = 0
    t11 = time.time()
    for ind in range(len(sentence)):
        inputs2 = tokenizer(sentence[ind], return_tensors="pt", padding=True)
        if len(inputs2["input_ids"][0]) >= CNF_INPUT_MAX_INDEXES:
            alert = 1
            i = ind

    if alert == 1:
        print("Attenzione la stringa n  " + str(i) + " con id numero " + str(id[i]) + " produce troppi indici")
    else:
        print("ok")

    t12 = time.time()
    print(t12 - t11)

    in_data = InputData(df=df, id=id, sentence=sentence, dat=dat)
    return in_data


# In[9]:


def softmax(x):
    """Compute softmax values for each sets of scores in x."""
    e_x = np.exp(x - np.max(x, axis=1)[:, None])
    return e_x / np.sum(e_x, axis=1)[:, None]


def evaluate_model(limits, in_data=in_data, model=model):
    unused(limits, in_data, model)
    time.time()
    # _finbert, _tokenizer = model.finbert, model.tokenizer
    # id, sentence, dat = in_data.id, in_data.sentence, in_data.dat
    results = pd.DataFrame(
        columns=[
            "id",
            "data",
            "sentence",
            "logit_positive",
            "logit_negative",
            "logit_neutral",
            "prediction",
            "sentiment_score",
        ]
    )

    # for idk in range(limits):
    # inputs = tokenizer(sentence[idk], return_tensors="pt", padding=True)
    # print(idk)
    # with torch.no_grad():
    #     logits = softmax(np.array(finbert(**inputs)[0]))
    #     prediction = labels[np.argmax(logits)]
    #     sentiment_score = pd.Series(logits[:, 0] - logits[:, 1])
    #     first_result = {
    #         "id": id[idk],
    #         "data": dat[idk],
    #         "sentence": sentence[idk],
    #         "logit_positive": logits[0][0],
    #         "logit_negative": logits[0][1],
    #         "logit_neutral": logits[0][2],
    #         "prediction": prediction,
    #         "sentiment_score": sentiment_score,
    #     }
    #     rows.append(first_result)
    #     trc.update()

    # results = results.append(rows, ignore_index=True, sort=False)
    # t2 = time.time()
    # print(t2 - t1)
    return results


@dataclass
class OutputData:
    out: Optional[pd.DataFrame] = None


def process_data(in_data=in_data, model=model):
    # lim = 1000
    # lim = len(in_data.sentence)
    lim = 10
    with trc:
        out = evaluate_model(lim, in_data=in_data, model=model)
        # print(out)
        # ciclo()
        # print(out.iloc[999,0:7])
        out_data = OutputData(out=out)
        return out_data


# In[10]:


def save_data(out_data=out_data, dd_conf=dd_conf):
    unused(dd_conf)
    dd_outfile = "outfil.csv"  # dd_conf.dd_outfile
    ensure_path(dd_outfile)
    assert out_data is not None
    out = out_data.out
    out.to_csv(dd_outfile, sep=";", index=False, encoding="utf-8-sig")


# //////////////////////////////////////////////////////////////////////////////////////////////////

# In[11]:


def distribute_data(dd_conf: Optional[DataConf] = dd_conf):
    assert dd_conf is not None

    num_chunks = dd_conf.dd_slots

    dd_infile = dd_conf.dd_infile
    dd_outfile = dd_conf.dd_outfile

    with open(dd_infile) as f:
        lines_count = sum(1 for _ in f)

    chunksize = lines_count // num_chunks
    i = 0
    with pd.read_csv(dd_infile, chunksize=chunksize) as reader:
        for chunk in reader:
            f = ensure_path(dd_outfile.format(dd_slot=i))
            chunk.to_csv(f)
            i = i + 1


# //////////////////////////////////////////////////////////////////////////////////////////////////

# In[12]:


def collect_data(dd_conf: Optional[DataConf] = dd_conf):
    assert dd_conf is not None

    dd_temp = dd_conf.dd_temp
    dd_outdir = dd_conf.dd_outdir
    dd_outfile = dd_conf.dd_outfile
    ensure_path(dd_outfile)

    os.chdir(dd_temp)

    extension = "csv"
    all_csvfiles = list(glob.glob("*.{}".format(extension)))
    all_outfiles = filter(lambda x: re.search(rf"{dd_outdir}", x), all_csvfiles)

    combined_csv = pd.concat([pd.read_csv(f) for f in all_outfiles])
    combined_csv.to_csv(dd_outfile, index=False, encoding="utf-8-sig")


# //////////////////////////////////////////////////////////////////////////////////////////////////

# In[13]:


def pre_eval():
    model = retrieve_model()
    dd_conf = config_data()
    df = load_data(dd_conf=dd_conf)
    in_data = prepare_data(df=df, model=model)
    return in_data, model, dd_conf


def do_eval(in_data=in_data, model=model):
    out_data = process_data(in_data=in_data, model=model)
    return out_data


def post_eval(out_data=out_data, dd_conf=dd_conf):
    save_data(out_data=out_data, dd_conf=dd_conf)


def run_worker():
    in_data, model, dd_conf = pre_eval()
    out_data = do_eval(in_data=in_data, model=model)
    post_eval(out_data=out_data, dd_conf=dd_conf)


def do_distribute(dd_conf=dd_conf):
    distribute_data(dd_conf=dd_conf)


def run_distributor():
    dd_conf = config_data()
    do_distribute(dd_conf=dd_conf)
    return RC


def do_collect(dd_conf=dd_conf):
    collect_data(dd_conf=dd_conf)


def run_collector():
    dd_conf = config_data()
    do_collect(dd_conf=dd_conf)
    return RC


def main(argv=None, **kwargs):
    print(argv)
    print(__name__ + "main:" + str(argv))

    argv = get_argv(argv)

    log.info(">> ### %s.main(argv=%s)", __name__, str(argv))
    parse_args(argv, **kwargs)

    if is_core_parallel():
        if is_core_distributor():
            run_distributor()
        elif is_core_worker():
            run_worker()
        elif is_core_collector():
            run_collector()
        else:
            raise ValueError("is_core_parallel")
    elif is_core_simple():
        run_worker()
    else:
        raise ValueError("is_core_what")

    log.info("<< ### %s.main => (rc=%d)", __name__, RC)
    return RC


# //////////////////////////////////////////////////////////////////////////////////////////////////

# In[14]:

if __name__ == "__main__":
    main()
