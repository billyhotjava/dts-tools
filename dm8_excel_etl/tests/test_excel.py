import datetime as dt
import unittest
from decimal import Decimal

from etl.excel import convert_value


class TestExcelConvert(unittest.TestCase):
    def test_int(self):
        self.assertEqual(convert_value("1", "int"), 1)
        self.assertEqual(convert_value(1.0, "int"), 1)

    def test_float(self):
        self.assertEqual(convert_value("1.5", "float"), 1.5)

    def test_decimal(self):
        self.assertEqual(convert_value("1.50", "decimal"), Decimal("1.50"))

    def test_date(self):
        self.assertEqual(convert_value("2025-01-02", "date"), dt.date(2025, 1, 2))
        self.assertEqual(convert_value(dt.datetime(2025, 1, 2, 3, 4, 5), "date"), dt.date(2025, 1, 2))

    def test_bool(self):
        self.assertEqual(convert_value("是", "bool"), True)
        self.assertEqual(convert_value("否", "bool"), False)
