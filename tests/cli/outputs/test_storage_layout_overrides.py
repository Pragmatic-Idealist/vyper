import pytest

from vyper.compiler import compile_code
from vyper.exceptions import StorageLayoutException


def test_storage_layout_overrides():
    code = """
a: uint256
b: uint256"""

    storage_layout_overrides = {
        "a": {"type": "uint256", "location": "storage", "slot": 1},
        "b": {"type": "uint256", "location": "storage", "slot": 0},
    }

    out = compile_code(
        code, output_formats=["layout"], storage_layout_override=storage_layout_overrides
    )

    assert out["layout"] == storage_layout_overrides


def test_storage_layout_for_more_complex():
    code = """
foo: HashMap[address, uint256]

@external
@nonreentrant("foo")
def public_foo1():
    pass

@external
@nonreentrant("foo")
def public_foo2():
    pass


@internal
@nonreentrant("bar")
def _bar():
    pass

# mix it up a little
baz: Bytes[65]
bar: uint256

@external
@nonreentrant("bar")
def public_bar():
    pass

@external
@nonreentrant("foo")
def public_foo3():
    pass
    """

    storage_layout_override = {
        "nonreentrant.foo": {"type": "nonreentrant lock", "location": "storage", "slot": 8},
        "nonreentrant.bar": {"type": "nonreentrant lock", "location": "storage", "slot": 7},
        "foo": {
            "type": "HashMap[address, uint256]",
            "location": "storage",
            "slot": 1,
        },
        "baz": {"type": "Bytes[65]", "location": "storage", "slot": 2},
        "bar": {"type": "uint256", "location": "storage", "slot": 6},
    }

    out = compile_code(
        code, output_formats=["layout"], storage_layout_override=storage_layout_override
    )

    assert out["layout"] == storage_layout_override


def test_simple_collision():
    code = """
name: public(String[64])
symbol: public(String[32])"""

    storage_layout_override = {
        "name": {"location": "storage", "slot": 0, "type": "String[64]"},
        "symbol": {"location": "storage", "slot": 1, "type": "String[32]"},
    }

    with pytest.raises(
        StorageLayoutException,
        match="Storage collision! Tried to assign 'symbol' to slot 1"
        " but it has already been reserved by 'name'",
    ):
        compile_code(
            code, output_formats=["layout"], storage_layout_override=storage_layout_override
        )


def test_incomplete_overrides():
    code = """
name: public(String[64])
symbol: public(String[32])"""

    storage_layout_override = {
        "name": {"location": "storage", "slot": 0, "type": "String[64]"},
    }

    with pytest.raises(
        StorageLayoutException,
        match="Could not find storage_slot for symbol. "
        "Have you used the correct storage layout file?",
    ):
        compile_code(
            code, output_formats=["layout"], storage_layout_override=storage_layout_override
        )
