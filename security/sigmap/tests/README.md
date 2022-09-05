# Brownie Tests

## Installing Brownie

Brownie can be installed via

```sh
pip install eth-brownie
```

Alternatively all required packages can be installed via

```sh
pip install -r requirements.txt
```

## Running the Tests

Tests can be run from this directory.

```sh
brownie test
```

Note you can add all the pytest parameters/flags e.g.

* `tests/test_executor.py` (pick a specific file)
* `-s` (print std out)
* `-v` (verbose)
* `-k <test_name>` (run a specific test)


## Writing tests

Add a file named `tests_<blah>.py` to the folder `./tests`.

Each individual test case in the file created above must be a function named
`test_<test_case>()`.

Checkout the [brownie docs](https://eth-brownie.readthedocs.io/en/stable/tests-pytest-intro.html)
for details on the syntax.

Note `print(dir(Object))` is a handy way to see available methods for a python object.

## Mainnet Fork Tests

This repo uses a fork of mainnet at block 15265830.

Before the tests may be run we need to add this network to brownie. Change `INFURA_RPC_URL` to be your Infura (or other provider) address.

```sh
brownie networks add development mainnet-fork-15265830 cmd=ganache-cli host=http://127.0.0.1 fork=<INFURA_RPC_URL>@15265830 accounts=10 mnemonic=brownie port=8545
```

### Out of Space

If the tests run out of space because there's not enough memory in `/tmp` try running `ganache-cli` pointing to a disk location.

Run `ganache-cli` in one terminal.

```sh
ganache-cli --accounts 20 --fork https://mainnet.infura.io/v3/<INFURA_KEY>@15265830 --mnemonic brownie --port 8545 --defaultBalanceEther 1000000 --hardfork istanbul --db <path to disk storage folder>
```

Then in another terminal run `brownie`.

```sh
brownie test
```

Note you'll need to kill `ganache-cli` and delete the folder `<path to disk storage folder>` to run the tests again otherwise it re-uses the previous db and complains about block numbers.