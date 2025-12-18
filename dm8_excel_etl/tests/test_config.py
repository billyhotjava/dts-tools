import tempfile
import textwrap
import unittest
from pathlib import Path

from etl.config import ConfigError, load_config


class TestConfig(unittest.TestCase):
    def test_missing_root_keys(self):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d) / "app.yaml"
            p.write_text("{}", encoding="utf-8")
            with self.assertRaises(ConfigError):
                load_config(p)

    def test_paths_resolve_to_project_root_by_default(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            (root / "config").mkdir()
            (root / "data" / "inbox").mkdir(parents=True)
            (root / "data" / "archive").mkdir(parents=True)
            (root / "data" / "badrows").mkdir(parents=True)
            (root / "logs").mkdir()

            cfg_path = root / "config" / "app.yaml"
            cfg_path.write_text(
                textwrap.dedent(
                    """
                    odbc:
                      dsn: dm8
                    paths:
                      inbox: data/inbox
                      archive: data/archive
                      badrows: data/badrows
                      logs: logs
                    jobs:
                      - name: demo
                        enabled: true
                        table: ODS_DEMO
                        mode: append
                        excel:
                          pattern: "*.xlsx"
                          sheet: Sheet1
                          header_row: 1
                          start_row: 2
                        columns:
                          - excel: ID
                            db: ID
                            type: int
                            required: true
                    """
                ).lstrip(),
                encoding="utf-8",
            )

            cfg = load_config(cfg_path)
            self.assertEqual(cfg.paths.root, root.resolve())
            self.assertEqual(cfg.paths.inbox, (root / "data" / "inbox").resolve())

    def test_tables_schema(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            (root / "config").mkdir()
            (root / "data" / "inbox").mkdir(parents=True)

            cfg_path = root / "config" / "app.yaml"
            cfg_path.write_text(
                textwrap.dedent(
                    """
                    db:
                      dsn: dm8
                      batch_size: 2000
                    tables:
                      ods_demo:
                        file: "demo.xlsx"
                        sheet: "Sheet1"
                        columns:
                          - {excel: "ID", db: "id", type: "int", required: true}
                          - {excel: "AMT", db: "amt", type: "decimal"}
                    """
                ).lstrip(),
                encoding="utf-8",
            )

            cfg = load_config(cfg_path)
            self.assertEqual(cfg.odbc.batch_size, 2000)
            self.assertEqual(len(cfg.jobs), 1)
            self.assertEqual(cfg.jobs[0].table, "ods_demo")
            self.assertEqual(cfg.jobs[0].excel.pattern, "demo.xlsx")
