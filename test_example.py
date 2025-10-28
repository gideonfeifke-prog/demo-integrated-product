def add(a, b):
    return a + b

def test_add(record_property):
    record_property("test-item-id", "spec-sensor-module")
    assert add(2, 3) == 5
