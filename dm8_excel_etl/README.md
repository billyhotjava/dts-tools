# dm8_excel_etl

离线环境（鲲鹏 ARM64 + 麒麟 OS）下的 Excel → DM8（ODBC）ETL 工具，按 ODS/MDM/ADS 分层演进。

## 依赖前提

- Python 3.9+（建议 3.10）
- ODBC 模式：unixODBC + DM8 ODBC Driver + 已配置 DSN（例如 `DM8`）
- JDBC 模式（可选兜底）：Java + DM JDBC Driver（已放在 `drivers/jdbc/`）
- 数据量：单次全量 ≤ 100,000 行

## 快速开始（本机 Pop!_OS / x86 联调）

1) 创建虚拟环境并安装依赖：

```bash
cd dm8_excel_etl
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
pip install -e .
```

2) 配置数据库连接（推荐二选一）：
- 方式 A：把账号口令放在 DSN（`odbc.ini`）里；`config/app.yaml` 只写 `db.dsn`
- 方式 B：通过环境变量（或 `.env`）注入：`DM8_DSN/DM8_UID/DM8_PWD`

3) 执行全链路（一键联调）：

```bash
cd dm8_excel_etl
./scripts/one_click_test.sh --config config/app.yaml
```

说明：
- 每次导入会生成 `batch_id`，日志在 `logs/etl_<batch_id>.log`
- 导入成功后，输入文件会从 `data/inbox/` 移动到 `data/archive/`
- 必填/类型失败行会落盘到 `data/badrows/`

## 使用仓库示例数据联调（docs/erp/samples）

仓库内置了 4 张 ODS 表的示例文件（2 个 xlsx + 2 个 csv），可直接跑通 ODS/MDM/ADS：

```bash
cd dm8_excel_etl
cp ../docs/erp/samples/* data/inbox/
DM8_MODE=odbc ./scripts/one_click_test.sh --config config/app.samples.yaml
```

只验证解析/映射（不连库、不执行 DDL、不归档文件）：

```bash
./scripts/one_click_test.sh --config config/app.samples.yaml --dry-run
```

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

## ODBC / JDBC 模式切换

- 强制 ODBC：`DM8_MODE=odbc ...`
- 强制 JDBC：`DM8_MODE=jdbc ...`（需要额外依赖）
- 自动（默认）：`DM8_MODE=auto`（先 ODBC，失败再尝试 JDBC）

JDBC 依赖安装：

```bash
pip install -r requirements-jdbc.txt
```

## Docker 运行（可选）

目标：把运行环境打进镜像，Excel/配置通过 volume 挂载，后续用 `docker exec -it` 进入容器执行命令。

在 `dm8_excel_etl/` 下：

```bash
docker-compose up -d --build
docker exec -it dm8-etl bash
```

容器内执行（示例）：

```bash
dm8-etl run-sql --config config/app.samples.yaml --dir sql/ddl
dm8-etl load-ods --config config/app.samples.yaml
./scripts/one_click_test.sh --config config/app.samples.yaml
```

说明：
- Excel 放在宿主机 `dm8_excel_etl/data/inbox/`（compose 已挂载到容器 `/app/data/inbox/`）
- 环境变量写在宿主机 `dm8_excel_etl/.env`（已在 `.gitignore` 忽略；compose 会自动加载）
- 若 DM8 在宿主机本机且 JDBC URL 用 `127.0.0.1`：在 `dm8_excel_etl/docker-compose.yml` 里启用 `network_mode: host`（Docker 18.09 + docker-compose 1.29 兼容）

## 常见问题（ODBC）

- 报错 `Encryption module failed to load (-70089)`：
  - 常见于系统只安装了 OpenSSL 运行库（例如 `libssl.so.3`/`libcrypto.so.3`），但没有安装 `libssl.so`/`libcrypto.so` 的开发包软链接。
  - 本项目的 `scripts/one_click_test.sh` 会自动执行 `scripts/setup_odbc_runtime.sh`，在项目根目录创建 `lib/libssl.so`、`lib/libcrypto.so` 的本地软链接用于联调（不改系统、不需要 sudo）。
  - 若仍失败：优先使用 DM8 官方客户端/驱动包自带的 `libssl/libcrypto`（放到项目根 `lib/` 下），或改用 JDBC 模式（`DM8_MODE=jdbc`）。
- 报 `no files matched inbox=... pattern=...`：
  - 表示 `data/inbox/` 下没有匹配到输入文件（可能被上次成功导入后移到了 `data/archive/`），重新拷贝/放入即可。
- DSN 不生效（找不到 DSN / Driver）：
  - 以 `odbcinst -j` 输出为准，确认使用的 `odbc.ini/odbcinst.ini` 路径。
  - 不要在 `odbc.ini` 行尾写注释（如 `UID=SYSDBA #用户名`），会被当作值的一部分。
- 找不到 `.so`（例如 `libdmdpi.so`/`libdmfldr.so`/`libdodbc.so` 相关依赖）：
  - 先用 `ldd /opt/dmdbms/bin/libdodbc.so` 看哪些依赖是 `not found`。
  - 临时修复（当前 shell 生效）：`export LD_LIBRARY_PATH=/opt/dmdbms/bin:$LD_LIBRARY_PATH`
  - 若你把 DM8 驱动库放在项目里（例如 `dm8_excel_etl/drivers/odbc/` 或自定义目录），同理把该目录加进来：`export LD_LIBRARY_PATH=/path/to/dm8_odbc_libs:$LD_LIBRARY_PATH`
  - 永久修复（需要 root）：把目录写入 `/etc/ld.so.conf.d/dm8.conf` 后执行 `ldconfig`。
  - `scripts/one_click_test.sh` 会尽量把 “DM8 ODBC DRIVER” 的 `Driver=` 所在目录加入 `LD_LIBRARY_PATH`，但如果你的驱动不在 `odbcinst.ini` 里或依赖链更复杂，仍以手工设置为准。

## 本机先验证（无 DM8 也可）

只验证 Excel 解析/必填校验/类型转换，不连接数据库、不执行 DDL：

```bash
cd dm8_excel_etl
./scripts/one_click_test.sh --config config/app.yaml --dry-run
```

## 离线交付打包（推荐）

在“可构建环境”（同架构更稳：麒麟/鲲鹏 aarch64）准备好 `wheels/` 后打包。

1) 在可联网机器准备 wheels（建议与目标同架构/同 Python 版本）：

```bash
cd dm8_excel_etl
pip download -r requirements.txt -d wheels
pip download -r requirements-jdbc.txt -d wheels   # 如需 JDBC 兜底
```

```bash
cd dm8_excel_etl
./scripts/make_offline_bundle.sh
```

将生成的目录拷贝到离线部署机后执行：

```bash
./install_offline.sh
./run_pipeline.sh config/app.yaml
```

## 离线部署（麒麟 V10 + 鲲鹏 aarch64）

目标：在离线机“开箱即用”运行 ETL（Excel/CSV → ODS → MDM → ADS），并保留 ODBC/JDBC 双模式切换能力。

### 1) 打包阶段（建议在“可联网的鲲鹏 aarch64 构建机”完成）

1. 准备依赖 wheel 仓库（`wheels/`）：
   - 尽量使用与目标机一致的：CPU 架构（aarch64）、Python 版本、glibc/发行版。
   - 对于需要编译的包（最典型：`pyodbc`、`JPype1`），建议直接在该 aarch64 构建机上构建 wheel。

示例（可联网构建机）：

```bash
cd dm8_excel_etl
python3 -m pip download -r requirements.txt -d wheels
python3 -m pip download -r requirements-jdbc.txt -d wheels   # 如需 JDBC 兜底

# 如发现 wheels 中缺少 aarch64 的二进制 wheel（例如 pyodbc/JPype1），在构建机补构建：
# python3 -m pip wheel pyodbc==5.1.0 -w wheels --no-deps
# python3 -m pip wheel JPype1==1.5.0 -w wheels --no-deps
```

2. 生成离线包（会把 `wheels/`、SQL、配置、脚本一起打进去）：

```bash
cd dm8_excel_etl
./scripts/make_offline_bundle.sh --force
```

3. 通过 U 盘/刻录介质把 `dist_bundle/dm8_excel_etl_<version>_<date>/` 整目录拷贝到离线机。

### 2) 安装阶段（离线机：麒麟 V10 + 鲲鹏）

1. 确认系统前置（离线机需要提前装好）：
   - Python 3.9+（含 `venv`/`pip` 或 `ensurepip`）
   - ODBC 模式：unixODBC + DM8 ODBC Driver（并配置 DSN）
   - JDBC 模式：Java（如需 JDBC 兜底）

> 提醒：麒麟系统上常见默认 `python` 仍是 2.7，请使用 `python3`；若没有 `pip`，可尝试 `python3 -m ensurepip --upgrade`（或通过系统包管理器安装 python3-pip）。

2. 进入离线包目录并安装：

```bash
cd dm8_excel_etl_<version>_<date>
INSTALL_JDBC=1 ./install_offline.sh   # 需要 JDBC 兜底就设 1；只用 ODBC 可不设
```

3. 配置连接信息（推荐用 `.env`，避免改动模板配置）：
   - 在离线包根目录创建 `.env`（参考 `.env.example`），设置：
     - `DM8_DSN`（DSN 名）
     - `DM8_UID`/`DM8_PWD`
     - `DM8_MODE`：`odbc` / `jdbc` / `auto`

4. 如果 ODBC 驱动依赖的 `.so` 找不到（常见于驱动目录不在系统库搜索路径），在运行前设置：

```bash
export LD_LIBRARY_PATH=/opt/dmdbms/bin:$LD_LIBRARY_PATH
```

（排查命令：`ldd /opt/dmdbms/bin/libdodbc.so` 看是否还有 `not found`）

5. 运行：
   - 把 Excel/CSV 放进 `data/inbox/`（文件名需匹配配置），然后执行：

```bash
./run_pipeline.sh config/app.yaml
```

产物目录：
- `data/archive/`：成功导入后归档的输入文件
- `data/badrows/`：校验失败/类型转换失败的行（CSV）
- `logs/`：每批次日志

## 自检（可选）

```bash
python -m unittest -q
```

输出目录：

- `data/badrows/`：必填校验/类型转换失败的行（CSV）
- `logs/`：运行日志
