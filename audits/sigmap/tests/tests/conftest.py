import types
import brownie
import pytest
from brownie import web3


@pytest.fixture(scope="session")
def constants():
    """Parameters used in the default setup/deployment, useful constants."""
    return types.SimpleNamespace(
        ZERO_ADDRESS=brownie.ZERO_ADDRESS,
        STABLE_SUPPLY=1_000_000 * 10 ** 6,
        MAX_UINT256=2 ** 256 - 1,
        DAY=60 * 60 * 24,
    )


# Pytest Adjustments
####################

# Copied from https://docs.pytest.org/en/latest/example/simple.html?highlight=skip#control-skipping-of-tests-according-to-command-line-option


def pytest_addoption(parser):
    parser.addoption(
        "--runslow", action="store_true", default=False, help="run slow tests"
    )


def pytest_configure(config):
    config.addinivalue_line("markers", "slow: mark test as slow to run")


def pytest_collection_modifyitems(config, items):
    if config.getoption("--runslow"):
        # --runslow given in cli: do not skip slow tests
        return
    skip_slow = pytest.mark.skip(reason="need --runslow option to run")
    for item in items:
        if "slow" in item.keywords:
            item.add_marker(skip_slow)


## Account Fixtures
###################


@pytest.fixture(scope="module")
def owner(accounts):
    """Account used as the default owner/guardian."""
    return accounts[0]


@pytest.fixture(scope="module")
def proxy_admin(accounts):
    """
    Account used as the admin to proxies.
    Use this account to deploy proxies as it allows the default account (i.e. accounts[0])
    to call contracts without setting the `from` field.
    """
    return accounts[1]


@pytest.fixture(scope="module")
def alice(accounts):
    return accounts[2]


@pytest.fixture(scope="module")
def bob(accounts):
    return accounts[3]


@pytest.fixture(scope="module")
def carol(accounts):
    return accounts[4]


## Mainnet Contracts
####################

# Instance of `AaveGovernanceV2` on Ethereum Mainnet
@pytest.fixture(scope='session', autouse=True)
def aave_governance_v2(AaveGovernanceV2):
    return AaveGovernanceV2.at("0xEC568fffba86c094cf06b22134B23074DFE2252c")


# Instance of `GovernanceStrategy` on Ethereum Mainnet
@pytest.fixture(scope='session', autouse=True)
def governance_strategy(GovernanceStrategy):
    return GovernanceStrategy.at("0xb7e383ef9b1e9189fc0f71fb30af8aa14377429e")


# Instance of `Executor` (renamed `OldExecutor`) on Ethereum Mainnet
# This is the previous executor for level 1 (short)
@pytest.fixture(scope='session', autouse=True)
def short_executor(OldExecutor):
    return OldExecutor.at("0xEE56e2B3D491590B5b31738cC34d5232F378a8D5")


# Instance of `Executor` (renamed `OldExecutor`) on Ethereum Mainnet
# This is the previous executor for level 2 (long)
@pytest.fixture(scope='session', autouse=True)
def long_executor(OldExecutor):
    return OldExecutor.at("0x61910EcD7e8e942136CE7Fe7943f956cea1CC2f7")


# Instance of Aave ERC20 Proxy on Ethereum Mainnet
# Note `InitializableAdminUpgradeabilityProxy` is compiled with 0.7.5 in brownie but 0.6.12 on mainnet
@pytest.fixture(scope='session', autouse=True)
def aave_token_proxy(InitializableAdminUpgradeabilityProxy):
    return InitializableAdminUpgradeabilityProxy.at("0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9")


# Instance of ABPT Proxy on Ethereum Mainnet
# Note `InitializableAdminUpgradeabilityProxy` is compiled with 0.7.5 in brownie but 0.6.12 on mainnet
@pytest.fixture(scope='session', autouse=True)
def abpt_proxy(InitializableAdminUpgradeabilityProxy):
    return InitializableAdminUpgradeabilityProxy.at("0x41A08648C3766F9F9d85598fF102a08f4ef84F84")


# Instance of ABPT Proxy on Ethereum Mainnet
# Note `InitializableAdminUpgradeabilityProxy` is compiled with 0.7.5 in brownie but 0.6.12 on mainnet
@pytest.fixture(scope='session', autouse=True)
def stk_aave_proxy(InitializableAdminUpgradeabilityProxy):
    return InitializableAdminUpgradeabilityProxy.at("0x4da27a545c0c5B758a6BA100e3a049001de870f5")


# Instance of ABPT Proxy on Ethereum Mainnet
# Note `InitializableAdminUpgradeabilityProxy` is compiled with 0.7.5 in brownie but 0.6.12 on mainnet
@pytest.fixture(scope='session', autouse=True)
def stk_abpt_proxy(InitializableAdminUpgradeabilityProxy):
    return InitializableAdminUpgradeabilityProxy.at("0xa1116930326D21fB917d5A27F1E9943A9595fb47")


# Instance of ABPT Proxy on Ethereum Mainnet
# Note `InitializableAdminUpgradeabilityProxy` is compiled with 0.7.5 in brownie but 0.6.12 on mainnet
@pytest.fixture(scope='session', autouse=True)
def aave_ecosystem_reserve_proxy(InitializableAdminUpgradeabilityProxy):
    return InitializableAdminUpgradeabilityProxy.at("0x25F2226B597E8F9514B3F68F00f494cF4f286491")


# Returns a list of the top Aave Token holders
# Total weight is ~19.56% of total supply
@pytest.fixture(scope='session', autouse=True)
def top_aave_holders():
    return [
        # Exchanges
        "0xf977814e90da44bfa03b6295a0616a897441acec", # Binance 8 ~4.10%
        "0xbe0eb53f46cd790cd13851d5eff43d12404d33e8", # Binance 7 ~3.75
        "0x47ac0fb4f2d84898e4d9e7b4dab3c24507a6d503", # Binanace: Binance-Peg Tokens ~2.50%
        "0x317625234562b1526ea2fac4030ea499c5291de4", # Aave LEND to AAVE Migrator ~2.28%
        "0x2faf487a4414fe77e2327f0bf4ae2a264a776ad2", # FTX Exchange ~1.19%
        # EOAs
        "0x26a78d5b6d7a7aceedd1e6ee3229b372a624d8b7", # EOA ~1.58%
        "0x4048c47b546b68ad226ea20b5f0acac49b086a21", # EOA ~1.23%
        "0x3744da57184575064838bbc87a0fc791f5e39ea2", # EOA ~1.15%
        "0x61b0e6b68184eb0316b1285c4e76a15bfc7cd857", # EOA ~1.00%
        "0x80845058350b8c3df5c3015d8a717d64b3bf9267", # EOA ~0.78%
    ]
