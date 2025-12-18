# dm8_excel_etl

离线环境（鲲鹏 ARM64 + 麒麟 OS）下的 Excel → DM8（ODBC）ETL 工具，按 ODS/MDM/ADS 分层演进。

## 依赖前提

- Python 3.9+（建议 3.10）
- unixODBC（已安装）+ DM8 ODBC Driver + 已配置 DSN（例如 `dm8`）
- 数据量：单次全量 ≤ 100,000 行

## 初始化（离线）

1) 准备依赖 wheel（在可联网机器执行）：

```bash
cd dm8_excel_etl
pip download -r requirements.txt -d wheels
```

说明：离线部署到鲲鹏（aarch64）时，建议在同架构机器上下载 wheels；若只能在 x86_64 下载，需要使用 `pip download --platform ... --python-version ... --only-binary=:all:` 指定目标平台。
补充：`pyodbc` 在 aarch64 环境可能需要本地编译（依赖 `gcc`、`python3-devel`、`unixODBC-devel` 等），建议在目标环境先打好 wheel 再随包交付。

2) 离线安装（在部署机执行）：

```bash
cd dm8_excel_etl
python3 -m venv .venv
source .venv/bin/activate
pip install --no-index --find-links=./wheels -r requirements.txt
pip install -e .
```

## ODBC / JDBC 切换（可选）

- 默认使用 ODBC：在 `config/app.yaml` 配置 `db.dsn`（以及可选的 `db.uid/db.pwd`）
- 如需 JDBC：设置 `db.mode: jdbc`，并提供 `db.jdbc_url/db.jdbc_driver/db.jdbc_jars`
  - 依赖：`pip install -e ".[jdbc]"` 或 `pip install -r requirements-jdbc.txt`（离线同理准备 wheels）
  - jar：建议随项目打包到 `drivers/`（例如 `drivers/DmJdbcDriver18.jar`）

## 配置与运行

1) 配置数据库连接（推荐二选一）：
   - 方式 A：编辑 `config/app.yaml`（只写 `db.dsn`，账号口令放在 `/etc/odbc.ini`）
   - 方式 B：保留 `config/app.yaml` 不含明文口令，通过环境变量注入：`DM8_DSN/DM8_UID/DM8_PWD`
     - 例：`export DM8_UID=SYSDBA; export DM8_PWD='***'`
   - 方式 C（本机更方便）：在 `dm8_excel_etl/.env` 写环境变量（模板：`dm8_excel_etl/.env.example`，程序会自动加载）
   - 也可以复制一份本机配置为 `config/app.local.yaml`（已在 `.gitignore` 忽略），运行时 `--config config/app.local.yaml`
2) 执行 DDL：`sql/ddl/`（建议顺序：`00_etl_meta.sql` → `01_ods_tables.sql` → `02_mdm_tables.sql` → `03_ads_tables.sql`）
3) 将 Excel 放入 `data/inbox/`
   - 也支持 `.csv`：把 `tables.<table>.file` 改为 `*.csv` 或具体文件名，并按需配置 `csv.encoding/delimiter`
4) 导入 ODS：

```bash
dm8-etl load-ods --config config/app.yaml
```

说明：
- `config/app.yaml` 推荐使用 `db/excel/tables`（更适合多表 Excel 导入），也兼容旧版 `odbc/paths/jobs`
- `tables` schema 下，未显式配置 `mode` 时默认按全量导入处理：`truncate`
- 每次导入都会生成 `batch_id`，写入 `logs/etl_<batch_id>.log`，badrows/归档文件名也会包含 batch_id
- 若已创建 `etl_batch_log`（`sql/ddl/00_etl_meta.sql`），导入与 run-sql 会尝试写入批次记录；没有该表也不会影响主流程

## 执行 SQL（可选）

除了用 DM 工具执行 SQL，也可以用内置命令：

```bash
dm8-etl run-sql --config config/app.yaml --dir sql/ddl
dm8-etl build-mdm --config config/app.yaml
dm8-etl build-ads --config config/app.yaml
```

## 一键联调（推荐）

```bash
cd dm8_excel_etl
./scripts/one_click_test.sh --config config/app.yaml
```

## 本机先验证（无 DM8 也可）

只验证 Excel 解析/必填校验/类型转换，不连接数据库、不执行 DDL：

```bash
cd dm8_excel_etl
./scripts/one_click_test.sh --config config/app.yaml --dry-run
```

## 离线交付打包（推荐）

在“可构建环境”（同架构更稳：麒麟/鲲鹏 aarch64）准备好 `wheels/` 后打包：

```bash
cd dm8_excel_etl
./scripts/make_offline_bundle.sh
```

将生成的目录拷贝到离线部署机后执行：

```bash
./install_offline.sh
./run_pipeline.sh config/app.yaml
```

## 自检（可选）

```bash
python -m unittest -q
```

输出目录：

- `data/badrows/`：必填校验/类型转换失败的行（CSV）
- `logs/`：运行日志
