import datetime as dt
import unittest

from etl.config import OdbcConfig
from etl.db import Db, DbError, adapt_param_rows, adapt_params, connect


class TestDb(unittest.TestCase):
    def test_jdbc_requires_uid_and_pwd(self):
        cfg = OdbcConfig(
            dsn=None,
            uid=None,
            pwd=None,
            mode="jdbc",
            jdbc_url="jdbc:dm://127.0.0.1:5236",
            jdbc_driver="dm.jdbc.driver.DmDriver",
            jdbc_jars=["/tmp/does-not-matter.jar"],
        )
        with self.assertRaises(DbError) as ctx:
            connect(cfg)
        self.assertIn("JDBC mode requires non-empty username/password", str(ctx.exception))

    def test_jdbc_adapt_date_and_datetime_when_jvm_not_started(self):
        db = Db(conn=None, mode="jdbc", autocommit=False)
        adapted = adapt_params(
            db,
            [
                dt.date(2025, 1, 2),
                dt.datetime(2025, 1, 2, 3, 4, 5, 123456),
            ],
        )
        self.assertEqual(adapted[0], "2025-01-02")
        self.assertEqual(adapted[1], "2025-01-02 03:04:05.123456")

        rows = adapt_param_rows(
            db,
            [
                (dt.date(2025, 1, 2), 1),
                (dt.datetime(2025, 1, 2, 3, 4, 5), 2),
            ],
        )
        self.assertEqual(rows[0][0], "2025-01-02")
        self.assertEqual(rows[1][0], "2025-01-02 03:04:05")
