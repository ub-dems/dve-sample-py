# ---
# jupyter:
#   jupytext:
#     formats: ipynb,py:percent
#     text_representation:
#       extension: .py
#       format_name: percent
#       format_version: '1.3'
#       jupytext_version: 1.19.6
#   kernelspec:
#     display_name: Python 3 (ipykernel)
#     language: python
#     name: python3
# ---

# %% [markdown]
# # PyTorch CUDA Check
#
# - see: [pyproject.toml#optional-dependencies](https://gitlab.com/ub-dems/ds-labs/dve-sample-r/-/blob/main/pyproject.toml#L156)
#

# %% [markdown]
# ## GPU Autodetection
#

# %% language="bash"
#
# (type nvidia-smi && nvidia-smi -L) &> /dev/null \
#     && X_HAS_GPU=1 || X_HAS_GPU=0;
#
# case "$X_HAS_GPU" in
#      1) export X_UV_EXTRA='gpu' ;;
#      *) export X_UV_EXTRA='cpu' ;;
# esac
# export X_HAS_GPU
#
# echo "X_HAS_GPU=$X_HAS_GPU"
# echo "X_UV_EXTRA=$X_UV_EXTRA"

# %% [markdown]
# ## NVIDIA CUDA Linkage
#
# ```bash
# uv lock
# uv sync --extra"$X_UV_EXTRA" --all-groups
# ```

# %%
# ! uv pip list | grep -e keras -e torch -e tensorflow -e ^nv

# %% [markdown]
# ## PyTorch Test

# %%
#from __future__ import annotations
import argparse
from typing import Any

# %%
import torch
from torch import nn
import torch.nn.functional as F
from torch import optim

from torchvision import datasets, transforms
from torch.optim.lr_scheduler import StepLR

# %%
print(f"cuda.is_available={torch.cuda.is_available()}")

# %%
torch.cuda.init()

# %%
device = torch.cuda.current_device()
print(f"cuda.get_device_name={torch.cuda.get_device_name()}")
print(f"cuda.get_device_capability={torch.cuda.get_device_capability()}")
print(f"cuda.get_device_properties={torch.cuda.get_device_properties(device)}")

# %%
X_tensor = torch.FloatTensor([0.0, 1.0, 2.0])
Y_tensor = X_tensor.cuda()
print(f"X_tensor.is_cuda={X_tensor.is_cuda}")
print(f"Y_tensor.is_cuda={Y_tensor.is_cuda}")


# %%
class Net(nn.Module):
    def __init__(self):
        super(Net, self).__init__()
        self.conv1 = nn.Conv2d(1, 32, 3, 1)
        self.conv2 = nn.Conv2d(32, 64, 3, 1)
        self.dropout1 = nn.Dropout(0.25)
        self.dropout2 = nn.Dropout(0.5)
        self.fc1 = nn.Linear(9216, 128)
        self.fc2 = nn.Linear(128, 10)

    def forward(self, x):
        x = self.conv1(x)
        x = F.relu(x)
        x = self.conv2(x)
        x = F.relu(x)
        x = F.max_pool2d(x, 2)
        x = self.dropout1(x)
        x = torch.flatten(x, 1)
        x = self.fc1(x)
        x = F.relu(x)
        x = self.dropout2(x)
        x = self.fc2(x)
        output = F.log_softmax(x, dim=1)
        return output


# ruff: noqa: PLW2901
def train(args, model, device, train_loader, optimizer, epoch):
    model.train()
    for batch_idx, (data, target) in enumerate(train_loader):
        data, target = data.to(device), target.to(device)
        optimizer.zero_grad()
        output = model(data)
        loss = F.nll_loss(output, target)
        loss.backward()
        optimizer.step()
        if batch_idx % args.log_interval == 0:
            print(
                "Train Epoch: {} [{}/{} ({:.0f}%)]\tLoss: {:.6f}".format(
                    epoch,
                    batch_idx * len(data),
                    len(train_loader.dataset),
                    100.0 * batch_idx / len(train_loader),
                    loss.item(),
                )
            )
            if args.dry_run:
                break


# ruff: noqa: PLW2901
def test(model, device, test_loader):
    model.eval()
    test_loss = 0
    correct = 0
    with torch.no_grad():
        for data, target in test_loader:
            data, target = data.to(device), target.to(device)
            output = model(data)
            test_loss += F.nll_loss(output, target, reduction="sum").item()  # sum up batch loss
            pred = output.argmax(dim=1, keepdim=True)  # get the index of the max log-probability
            correct += pred.eq(target.view_as(pred)).sum().item()

    test_loss /= len(test_loader.dataset)

    print(
        "\nTest set: Average loss: {:.4f}, Accuracy: {}/{} ({:.0f}%)\n".format(
            test_loss, correct, len(test_loader.dataset), 100.0 * correct / len(test_loader.dataset)
        )
    )


def main(argv: list[str]):
    # Training settings
    parser = argparse.ArgumentParser(description="PyTorch MNIST Example")
    parser.add_argument(
        "--batch-size",
        type=int,
        default=64,
        metavar="N",
        help="input batch size for training (default: 64)",
    )
    parser.add_argument(
        "--test-batch-size",
        type=int,
        default=1000,
        metavar="N",
        help="input batch size for testing (default: 1000)",
    )
    parser.add_argument(
        "--epochs",
        type=int,
        default=14,
        metavar="N",
        help="number of epochs to train (default: 14)",
    )
    parser.add_argument("--lr", type=float, default=1.0, metavar="LR", help="learning rate (default: 1.0)")
    parser.add_argument(
        "--gamma",
        type=float,
        default=0.7,
        metavar="M",
        help="Learning rate step gamma (default: 0.7)",
    )
    parser.add_argument("--no-cuda", action="store_true", default=False, help="disables CUDA training")
    parser.add_argument("--no-mps", action="store_true", default=False, help="disables macOS GPU training")
    parser.add_argument("--dry-run", action="store_true", default=False, help="quickly check a single pass")
    parser.add_argument("--seed", type=int, default=1, metavar="S", help="random seed (default: 1)")
    parser.add_argument(
        "--log-interval",
        type=int,
        default=10,
        metavar="N",
        help="how many batches to wait before logging training status",
    )
    parser.add_argument("--save-model", action="store_true", default=False, help="For Saving the current Model")
    args = parser.parse_args(argv)
    use_cuda = not args.no_cuda and torch.cuda.is_available()
    use_mps = not args.no_mps and torch.backends.mps.is_available()

    torch.manual_seed(args.seed)

    if use_cuda:
        device = torch.device("cuda")
    elif use_mps:
        device = torch.device("mps")
    else:
        device = torch.device("cpu")

    train_kwargs: dict[str, Any] = {"batch_size": args.batch_size}
    test_kwargs: dict[str, Any] = {"batch_size": args.test_batch_size}

    if use_cuda:
        cuda_kwargs: dict[str, Any] = {"num_workers": 1, "pin_memory": True, "shuffle": True}
        train_kwargs.update(cuda_kwargs)
        test_kwargs.update(cuda_kwargs)

    transform = transforms.Compose([transforms.ToTensor(), transforms.Normalize((0.1307,), (0.3081,))])
    dataset1 = datasets.MNIST("../data", train=True, download=True, transform=transform)
    dataset2 = datasets.MNIST("../data", train=False, transform=transform)

    # Calculate values dynamically based on use_cuda
    workers = 1 if use_cuda else 0
    pin = True if use_cuda else False

    train_loader = torch.utils.data.DataLoader(
        dataset1, batch_size=args.batch_size, num_workers=workers, pin_memory=pin, shuffle=True
    )

    test_loader = torch.utils.data.DataLoader(
        dataset2, batch_size=args.test_batch_size, num_workers=workers, pin_memory=pin, shuffle=False
    )

    model = Net().to(device)
    optimizer = optim.Adadelta(model.parameters(), lr=args.lr)

    scheduler = StepLR(optimizer, step_size=1, gamma=args.gamma)
    for epoch in range(1, args.epochs + 1):
        train(args, model, device, train_loader, optimizer, epoch)
        test(model, device, test_loader)
        scheduler.step()

    if args.save_model:
        torch.save(model.state_dict(), "mnist_cnn.pt")


# %%
main(["--epochs=3"])

# %%
device = torch.cuda.current_device()
print(f"cuda.utilization={torch.cuda.utilization(device)}")

# %%
