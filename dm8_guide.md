
# dm8_excel_etl · OpenAI Codex 开发指令文档

本文档用于在 **OpenAI Codex** 中直接执行/辅助开发一个 **Excel → DM8（ODS / MDM / ADS）** 的离线 ETL 工具。  
适用环境：**鲲鹏 ARM64 + 麒麟 OS + 离线环境 + DM8 + ODBC**

---

## 0. 项目背景与前提

- OS：KylinOS / ARM64（aarch64）  
- Kernel：4.19.x  
- 数据源：Excel  
- 数据量：≤ 100,000 行（全量）  
- 数据库：DM8  
- 接入方式：ODBC（unixODBC 2.3.14 已安装）  
- 目标：  
  - Excel → ODS（ods_ 前缀）  
  - ODS → MDM（主数据统一）  
  - ODS/MDM → ADS（BI 大屏直连）  

---

## 1. 工程初始化（Codex 执行）

```bash
mkdir -p dm8_excel_etl/{config,data/{inbox,archive,badrows},logs,sql/{ddl,mdm,ads},src/etl}
cd dm8_excel_etl
```

### README 初始化

```bash
cat > README.md <<'EOF'
# dm8_excel_etl
Excel -> DM8 (ODS/MDM/ADS) ETL tool for offline Kunpeng + KylinOS.

## Prereq
- Python 3.9+
- unixODBC 2.3.14
- DM8 ODBC Driver
- Data volume <= 100k rows

## Run
1) Configure ODBC DSN and config/app.yaml
2) Create tables using sql/ddl
3) Put Excel files into data/inbox
4) Run:
   python -m etl.cli load-ods
   python -m etl.cli build-mdm
   python -m etl.cli build-ads
EOF
```

---

## 2. Python 环境与依赖

### 2.1 虚拟环境

```bash
python3 -m venv .venv
source .venv/bin/activate
```

### 2.2 依赖安装

```bash
cat > requirements.txt <<'EOF'
pyodbc==5.1.0
openpyxl==3.1.5
PyYAML==6.0.2
python-dateutil==2.9.0.post0
EOF

pip install -r requirements.txt
```

### 2.3 离线 wheels 准备

```bash
mkdir -p wheels
pip download -r requirements.txt -d wheels
```

离线安装：

```bash
pip install --no-index --find-links=./wheels -r requirements.txt
```

---

## 3. ODBC 与 DM8 连接确认

### 3.1 基础检查

```bash
odbc_config --version
which isql
```

### 3.2 Driver 注册

```bash
cat /etc/odbcinst.ini
```

如未注册 DM8：

```ini
[DM8 ODBC DRIVER]
Description=DM8 ODBC Driver
Driver=/opt/dmdbms/bin/libdodbc.so
```

### 3.3 DSN 配置

```bash
cat > /etc/odbc.ini <<'EOF'
[dm8]
Driver=DM8 ODBC DRIVER
Server=127.0.0.1
PORT=5236
UID=DMUSER
PWD=DM_PASSWORD
EOF
```

### 3.4 isql 验证

```bash
isql dm8
```

---

## 4. ETL 配置文件（config/app.yaml）

用于描述：  
- Excel 文件  
- Sheet  
- 字段映射  
- 类型  
- 必填规则  

> 该文件由 Codex 持续维护与扩展

（详见前文完整 app.yaml 示例）

---

## 5. Python 代码结构

```text
src/etl/
├── __init__.py
├── cli.py        # 命令入口
├── db.py         # pyodbc 连接
├── config.py     # YAML 加载
├── excel.py      # Excel 读取与类型转换
├── loader.py     # Excel → ODS 批量导入
```

支持特性：
- 批量 insert（executemany）
- 必填字段校验
- 错误行输出到 data/badrows
- ≤100k 行性能安全

---

## 6. 核心执行命令

### 6.1 ODS 导入

```bash
python -m etl.cli load-ods --config config/app.yaml
```

### 6.2 预期目录行为

- `data/inbox/`：Excel 输入
- `data/badrows/`：错误行 CSV
- `data/archive/`：成功文件归档（后续实现）

---

## 7. 后续 Codex TODO（建议按顺序）

- [ ] build-mdm：ODS → MDM（项目/物料去重、启用状态映射）
- [ ] build-ads：生成 BI 大屏 ADS 表
- [ ] run-sql：执行 sql/ddl、sql/ads 脚本
- [ ] etl_batch_log：导入日志表
- [ ] truncate / append / merge 三种导入模式
- [ ] JDBC 备用连接模式（jaydebeapi）

---

## 8. 使用建议

- **当前阶段**：单进程 Python 足够  
- **BI 友好**：ADS 表可采用 truncate + rebuild  
- **安全**：全流程离线、无公网依赖  
- **演进**：后续可迁移至 Java / DTS 平台，不影响表结构

---

> 本文档作为 Codex 的“执行蓝本”，可直接用于生成代码、补全函数、持续演进。
