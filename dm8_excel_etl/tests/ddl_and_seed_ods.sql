-- dm8_excel_etl/tests/ddl_and_seed_ods.sql
-- 说明：合并 DDL（ETL_META/ODS/MDM/ADS）并为每张 ODS 表生成 100 行演示数据。
-- 运行方式：在 DM8 客户端/管理工具中直接执行本脚本（建议空 schema）。
-- 注意：如果表已存在，请先手工 DROP 后再执行。

-- ETL 元数据表：用于记录每次导入批次、行数、状态等

CREATE TABLE etl_batch_log (
  batch_id     VARCHAR2(64)  NOT NULL,
  job_name     VARCHAR2(200) NOT NULL,
  table_name   VARCHAR2(128) NOT NULL,
  source_file  VARCHAR2(512) NOT NULL,
  total_rows   NUMBER(18,0),
  ok_rows      NUMBER(18,0),
  bad_rows     NUMBER(18,0),
  started_at   TIMESTAMP,
  finished_at  TIMESTAMP,
  status       VARCHAR2(20),
  message      VARCHAR2(2000),
  CONSTRAINT pk_etl_batch_log PRIMARY KEY (batch_id, job_name, table_name, source_file)
);

COMMENT ON TABLE etl_batch_log IS 'ETL-批次日志（每次导入/构建的记录）';

-- ODS 表（来源：docs/erp/erp_ddl.sql）

-- ODS-项目预算执行明细
CREATE TABLE ods_proj_budget_exec_dtl (
  id                     BIGINT IDENTITY(1,1) NOT NULL,
  proj_budget_cat_code   VARCHAR2(50),
  proj_budget_cat_name   VARCHAR2(200),
  parent_proj_code       VARCHAR2(50),
  parent_proj_name       VARCHAR2(200),
  pk_project             VARCHAR2(100),
  proj_code              VARCHAR2(50) NOT NULL,
  proj_name              VARCHAR2(200),
  resp_dept              VARCHAR2(200),
  budget_amt             NUMBER(18,2),
  adjust_amt             NUMBER(18,2),
  exec_amt               NUMBER(18,2),
  hist_exec_amt          NUMBER(18,2),
  etl_time               TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT pk_ods_proj_budget_exec_dtl PRIMARY KEY (id)
);

COMMENT ON TABLE ods_proj_budget_exec_dtl IS 'ODS-项目预算执行明细';
COMMENT ON COLUMN ods_proj_budget_exec_dtl.proj_budget_cat_code IS '项目预算分类编码';
COMMENT ON COLUMN ods_proj_budget_exec_dtl.proj_budget_cat_name IS '项目预算分类名称';
COMMENT ON COLUMN ods_proj_budget_exec_dtl.parent_proj_code     IS '父项目编码';
COMMENT ON COLUMN ods_proj_budget_exec_dtl.parent_proj_name     IS '父项目名称';
COMMENT ON COLUMN ods_proj_budget_exec_dtl.pk_project           IS 'PK_Project';
COMMENT ON COLUMN ods_proj_budget_exec_dtl.proj_code            IS '项目编码';
COMMENT ON COLUMN ods_proj_budget_exec_dtl.proj_name            IS '项目名称';
COMMENT ON COLUMN ods_proj_budget_exec_dtl.resp_dept            IS '责任部门：使用预算的部门';
COMMENT ON COLUMN ods_proj_budget_exec_dtl.budget_amt           IS '预算金额（元）';
COMMENT ON COLUMN ods_proj_budget_exec_dtl.adjust_amt           IS '调整金额（元）';
COMMENT ON COLUMN ods_proj_budget_exec_dtl.exec_amt             IS '执行金额（元）';
COMMENT ON COLUMN ods_proj_budget_exec_dtl.hist_exec_amt        IS '历史执行金额：项目导入的历史执行金额，实际执行金额=执行金额+历史执行金额。';
COMMENT ON COLUMN ods_proj_budget_exec_dtl.etl_time             IS 'ETL时间';

CREATE INDEX idx_ods_bgt_proj ON ods_proj_budget_exec_dtl(proj_code);

-- ODS-采购订单执行
CREATE TABLE ods_po_exec (
  id            BIGINT IDENTITY(1,1) NOT NULL,
  purchase_org  VARCHAR2(200),
  order_no      VARCHAR2(60),
  order_date    DATE,
  contract_no   VARCHAR2(60),
  order_currency VARCHAR2(50),
  supplier_name VARCHAR2(200),
  purchaser     VARCHAR2(100),
  purchase_dept VARCHAR2(200),
  proj_code     VARCHAR2(50),
  proj_name     VARCHAR2(200),
  line_no       VARCHAR2(30),
  item_code     VARCHAR2(80),
  item_name     VARCHAR2(300),
  spec          VARCHAR2(200),
  model         VARCHAR2(200),
  uom           VARCHAR2(50),
  qty           NUMBER(18,3),
  unit_price_nt NUMBER(18,4),
  unit_price_tax NUMBER(18,4),
  amt_nt        NUMBER(18,2),
  amt_tax       NUMBER(18,2),
  tax_rate      NUMBER(10,4),
  tax_amt       NUMBER(18,2),
  is_gift       VARCHAR2(20),
  recv_qty      NUMBER(18,3),
  return_qty    NUMBER(18,3),
  qc_qty        NUMBER(18,3),
  qualified_qty NUMBER(18,3),
  recv_gift_qty NUMBER(18,3),
  in_gift_qty   NUMBER(18,3),
  in_qty        NUMBER(18,3),
  in_unit_price NUMBER(18,4),
  in_amt        NUMBER(18,2),
  return_in_qty NUMBER(18,3),
  invoice_qty   NUMBER(18,3),
  invoice_amt_tax_local      NUMBER(18,2),
  invoice_pay_balance_local  NUMBER(18,2),
  etl_time      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT pk_ods_po_exec PRIMARY KEY (id)
);

COMMENT ON TABLE ods_po_exec IS 'ODS-采购订单执行';
COMMENT ON COLUMN ods_po_exec.purchase_org   IS '采购组织';
COMMENT ON COLUMN ods_po_exec.order_no       IS '订单编号';
COMMENT ON COLUMN ods_po_exec.order_date     IS '订单日期';
COMMENT ON COLUMN ods_po_exec.contract_no    IS '合同号：有些采购不签订合同，合同号字段可能为空。';
COMMENT ON COLUMN ods_po_exec.order_currency IS '订单币种';
COMMENT ON COLUMN ods_po_exec.supplier_name  IS '供应商';
COMMENT ON COLUMN ods_po_exec.purchaser      IS '采购员';
COMMENT ON COLUMN ods_po_exec.purchase_dept  IS '采购部门：指的是物料的需求部门';
COMMENT ON COLUMN ods_po_exec.proj_code      IS '项目编码';
COMMENT ON COLUMN ods_po_exec.proj_name      IS '项目名称';
COMMENT ON COLUMN ods_po_exec.line_no        IS '行号';
COMMENT ON COLUMN ods_po_exec.item_code      IS '物料编码';
COMMENT ON COLUMN ods_po_exec.item_name      IS '物料名称';
COMMENT ON COLUMN ods_po_exec.spec           IS '规格';
COMMENT ON COLUMN ods_po_exec.model          IS '型号';
COMMENT ON COLUMN ods_po_exec.uom            IS '主单位';
COMMENT ON COLUMN ods_po_exec.qty            IS '主数量';
COMMENT ON COLUMN ods_po_exec.unit_price_nt  IS '主无税单价：无税单价';
COMMENT ON COLUMN ods_po_exec.unit_price_tax IS '主含税单价：含税单价';
COMMENT ON COLUMN ods_po_exec.amt_nt         IS '无税金额：无税总价';
COMMENT ON COLUMN ods_po_exec.amt_tax        IS '价税合计：含税总价';
COMMENT ON COLUMN ods_po_exec.tax_rate       IS '税率';
COMMENT ON COLUMN ods_po_exec.tax_amt        IS '税额';
COMMENT ON COLUMN ods_po_exec.is_gift        IS '赠品';
COMMENT ON COLUMN ods_po_exec.recv_qty       IS '到货主数量';
COMMENT ON COLUMN ods_po_exec.return_qty     IS '退货主数量';
COMMENT ON COLUMN ods_po_exec.qc_qty         IS '质检主数量';
COMMENT ON COLUMN ods_po_exec.qualified_qty  IS '合格品主数量';
COMMENT ON COLUMN ods_po_exec.recv_gift_qty  IS '到货赠品主数量';
COMMENT ON COLUMN ods_po_exec.in_gift_qty    IS '入库赠品主数量';
COMMENT ON COLUMN ods_po_exec.in_qty         IS '入库主数量';
COMMENT ON COLUMN ods_po_exec.in_unit_price  IS '入库单价';
COMMENT ON COLUMN ods_po_exec.in_amt         IS '入库金额';
COMMENT ON COLUMN ods_po_exec.return_in_qty  IS '退库主数量';
COMMENT ON COLUMN ods_po_exec.invoice_qty    IS '发票主数量';
COMMENT ON COLUMN ods_po_exec.invoice_amt_tax_local     IS '发票本币价税合计';
COMMENT ON COLUMN ods_po_exec.invoice_pay_balance_local IS '发票本币付款余额';
COMMENT ON COLUMN ods_po_exec.etl_time       IS 'ETL时间';

CREATE INDEX idx_ods_po_proj ON ods_po_exec(proj_code);
CREATE INDEX idx_ods_po_item ON ods_po_exec(item_code);
CREATE INDEX idx_ods_po_date ON ods_po_exec(order_date);

-- ODS-出入库流水
CREATE TABLE ods_stock_io_flow (
  id          BIGINT IDENTITY(1,1) NOT NULL,
  inv_org     VARCHAR2(200),
  biz_date    DATE,
  biz_type    VARCHAR2(200),
  io_type     VARCHAR2(200),
  doc_no      VARCHAR2(80),
  wh_name     VARCHAR2(200),
  proj        VARCHAR2(200),
  proj_code   VARCHAR2(50),
  proj_name   VARCHAR2(200),
  item_code   VARCHAR2(80),
  item_name   VARCHAR2(300),
  item_version VARCHAR2(100),
  spec        VARCHAR2(200),
  model       VARCHAR2(200),
  batch_no    VARCHAR2(100),
  main_uom    VARCHAR2(50),
  uom         VARCHAR2(50),
  conv_rate   NUMBER(18,6),
  in_main_qty  NUMBER(18,3),
  in_qty      NUMBER(18,3),
  out_main_qty NUMBER(18,3),
  out_qty     NUMBER(18,3),
  etl_time    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT pk_ods_stock_io_flow PRIMARY KEY (id)
);

COMMENT ON TABLE ods_stock_io_flow IS 'ODS-出入库流水';
COMMENT ON COLUMN ods_stock_io_flow.inv_org    IS '库存组织';
COMMENT ON COLUMN ods_stock_io_flow.biz_date   IS '业务日期';
COMMENT ON COLUMN ods_stock_io_flow.biz_type   IS '单据类型：库存采购入库单、库存物料出库单';
COMMENT ON COLUMN ods_stock_io_flow.io_type    IS '出入库类型：普通采购入库、材料出库，与业务类型字段作用基本一致';
COMMENT ON COLUMN ods_stock_io_flow.doc_no     IS '单据号';
COMMENT ON COLUMN ods_stock_io_flow.wh_name    IS '仓库：仓库名称';
COMMENT ON COLUMN ods_stock_io_flow.proj       IS '项目';
COMMENT ON COLUMN ods_stock_io_flow.proj_code  IS '项目编号/项目编码（如导出包含）';
COMMENT ON COLUMN ods_stock_io_flow.proj_name  IS '项目名称（如导出包含）';
COMMENT ON COLUMN ods_stock_io_flow.item_code  IS '物料编码';
COMMENT ON COLUMN ods_stock_io_flow.item_name  IS '物料名称';
COMMENT ON COLUMN ods_stock_io_flow.item_version IS '物料版本';
COMMENT ON COLUMN ods_stock_io_flow.spec       IS '规格';
COMMENT ON COLUMN ods_stock_io_flow.model      IS '型号';
COMMENT ON COLUMN ods_stock_io_flow.batch_no   IS '批次号';
COMMENT ON COLUMN ods_stock_io_flow.main_uom   IS '主单位';
COMMENT ON COLUMN ods_stock_io_flow.uom        IS '单位';
COMMENT ON COLUMN ods_stock_io_flow.conv_rate  IS '换算率';
COMMENT ON COLUMN ods_stock_io_flow.in_main_qty  IS '入库主数量';
COMMENT ON COLUMN ods_stock_io_flow.in_qty     IS '入库数量';
COMMENT ON COLUMN ods_stock_io_flow.out_main_qty IS '出库主数量';
COMMENT ON COLUMN ods_stock_io_flow.out_qty    IS '出库数量';
COMMENT ON COLUMN ods_stock_io_flow.etl_time   IS 'ETL时间';

CREATE INDEX idx_ods_io_date ON ods_stock_io_flow(biz_date);
CREATE INDEX idx_ods_io_item ON ods_stock_io_flow(item_code);
CREATE INDEX idx_ods_io_proj ON ods_stock_io_flow(proj_code);
CREATE INDEX idx_ods_io_wh   ON ods_stock_io_flow(wh_name);

-- ODS-现存量
CREATE TABLE ods_stock_onhand (
  id         BIGINT IDENTITY(1,1) NOT NULL,
  inv_org    VARCHAR2(200),
  wh_name    VARCHAR2(200),
  item_code  VARCHAR2(80),
  item_name  VARCHAR2(300),
  spec       VARCHAR2(200),
  model      VARCHAR2(200),
  uom        VARCHAR2(50),
  proj       VARCHAR2(200),
  proj_code  VARCHAR2(50),
  proj_name  VARCHAR2(200),
  onhand_qty NUMBER(18,3),
  reserved_qty NUMBER(18,3),
  frozen_qty NUMBER(18,3),
  supplier_owner_onhand_qty NUMBER(18,3),
  etl_time   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT pk_ods_stock_onhand PRIMARY KEY (id)
);

COMMENT ON TABLE ods_stock_onhand IS 'ODS-现存量';
COMMENT ON COLUMN ods_stock_onhand.inv_org    IS '库存组织';
COMMENT ON COLUMN ods_stock_onhand.wh_name    IS '仓库';
COMMENT ON COLUMN ods_stock_onhand.item_code  IS '物料编码';
COMMENT ON COLUMN ods_stock_onhand.item_name  IS '物料名称';
COMMENT ON COLUMN ods_stock_onhand.spec       IS '规格';
COMMENT ON COLUMN ods_stock_onhand.model      IS '型号';
COMMENT ON COLUMN ods_stock_onhand.uom        IS '主单位';
COMMENT ON COLUMN ods_stock_onhand.proj       IS '项目';
COMMENT ON COLUMN ods_stock_onhand.proj_code  IS '项目编码（如导出包含）';
COMMENT ON COLUMN ods_stock_onhand.proj_name  IS '项目名称（如导出包含）';
COMMENT ON COLUMN ods_stock_onhand.onhand_qty IS '结存主数量：库存数量';
COMMENT ON COLUMN ods_stock_onhand.reserved_qty IS '预留主数量';
COMMENT ON COLUMN ods_stock_onhand.frozen_qty IS '冻结主数量';
COMMENT ON COLUMN ods_stock_onhand.supplier_owner_onhand_qty IS '供应商物权结存主数量';
COMMENT ON COLUMN ods_stock_onhand.etl_time   IS 'ETL时间';

CREATE INDEX idx_ods_onhand_item ON ods_stock_onhand(item_code);
CREATE INDEX idx_ods_onhand_proj ON ods_stock_onhand(proj_code);
CREATE INDEX idx_ods_onhand_wh   ON ods_stock_onhand(wh_name);

-- MDM 表（来源：docs/erp/erp_mdm.sql）

-- MDM-项目维表（统一项目编码/名称/层级）
CREATE TABLE mdm_project (
  proj_code        VARCHAR2(50) NOT NULL,
  proj_name        VARCHAR2(200),
  parent_proj_code VARCHAR2(50),
  parent_proj_name VARCHAR2(200),
  proj_level       NUMBER(10,0),
  proj_path        VARCHAR2(1000),
  is_active        NUMBER(1,0) DEFAULT 1,
  CONSTRAINT pk_mdm_project PRIMARY KEY (proj_code)
);

COMMENT ON TABLE mdm_project IS 'MDM-项目维表（统一项目编码/名称/层级）';

-- MDM-物料维表（统一启停用、分类、规格型号）
CREATE TABLE mdm_item (
  item_code     VARCHAR2(80) NOT NULL,
  item_name     VARCHAR2(300),
  item_class    VARCHAR2(50),
  spec          VARCHAR2(200),
  model         VARCHAR2(200),
  base_uom      VARCHAR2(50),
  enable_flag   NUMBER(1,0),     -- 1启用 0停用
  enable_status VARCHAR2(50),    -- 原始状态保留
  CONSTRAINT pk_mdm_item PRIMARY KEY (item_code)
);

COMMENT ON TABLE mdm_item IS 'MDM-物料维表（统一启停用、分类、规格型号）';

-- MDM-项目预算分类
CREATE TABLE mdm_proj_budget_cat (
  cat_code VARCHAR2(50) NOT NULL,
  cat_name VARCHAR2(200),
  CONSTRAINT pk_mdm_proj_budget_cat PRIMARY KEY (cat_code)
);

COMMENT ON TABLE mdm_proj_budget_cat IS 'MDM-项目预算分类（统一编码/名称）';


-- ADS 表（来源：docs/erp/erp_ads.sql，按大屏直连设计）

-- ============================================================================
-- 大屏 1：预算与采购监控
-- ============================================================================

-- ADS-预算与采购总览KPI（全局 1 行）
CREATE TABLE ads_budget_overview_kpi (
  stat_time                 DATE NOT NULL,
  budget_amt                NUMBER(18,2),
  exec_amt                  NUMBER(18,2),
  hist_exec_amt             NUMBER(18,2),
  actual_exec_amt           NUMBER(18,2),
  preoccupy_amt             NUMBER(18,2),      -- ods_proj_budget_exec_dtl.adjust_amt
  exec_rate                 NUMBER(10,2),      -- 执行金额/预算金额
  actual_exec_rate          NUMBER(10,2),      -- (执行+历史执行)/预算
  preoccupy_rate            NUMBER(10,2),      -- 预占金额/预算
  remain_budget             NUMBER(18,2),      -- 预算-执行
  remain_budget_actual      NUMBER(18,2),      -- 预算-(执行+历史执行)
  remain_budget_after_preoccupy NUMBER(18,2),  -- 预算-执行-预占
  po_amt_tax                NUMBER(18,2),      -- 采购订单价税合计汇总（含税）
  proj_cnt                  NUMBER(18,0),
  dept_cnt                  NUMBER(18,0),
  CONSTRAINT pk_ads_budget_overview_kpi PRIMARY KEY (stat_time)
);

COMMENT ON TABLE ads_budget_overview_kpi IS 'ADS-预算与采购总览KPI（大屏直连）';

-- ADS-项目预算执行看板（项目粒度，含执行率/剩余）
CREATE TABLE ads_proj_budget_kpi (
  proj_code       VARCHAR2(50) NOT NULL,
  proj_name       VARCHAR2(200),
  budget_amt      NUMBER(18,2),
  exec_amt        NUMBER(18,2),
  hist_exec_amt   NUMBER(18,2),
  actual_exec_amt NUMBER(18,2),
  preoccupy_amt   NUMBER(18,2),  -- ods_proj_budget_exec_dtl.adjust_amt
  exec_rate       NUMBER(10,2),  -- 执行金额/预算金额
  actual_exec_rate NUMBER(10,2), -- (执行+历史执行)/预算
  preoccupy_rate  NUMBER(10,2),  -- 预占金额/预算金额
  remain_budget   NUMBER(18,2),  -- 预算-执行
  remain_budget_actual NUMBER(18,2), -- 预算-(执行+历史执行)
  remain_budget_after_preoccupy NUMBER(18,2), -- 预算-执行-预占
  po_amt_tax      NUMBER(18,2),  -- 采购订单价税合计汇总（含税）
  po_budget_var_rate NUMBER(10,2), -- (采购-预算)/预算
  stat_time       DATE DEFAULT CURRENT_DATE,
  CONSTRAINT pk_ads_proj_budget_kpi PRIMARY KEY (proj_code)
);

COMMENT ON TABLE ads_proj_budget_kpi IS 'ADS-项目预算KPI（大屏直连）';

-- ADS-部门预算分析（按责任部门）
CREATE TABLE ads_dept_budget_kpi (
  resp_dept        VARCHAR2(200) NOT NULL,
  budget_amt       NUMBER(18,2),
  exec_amt         NUMBER(18,2),
  hist_exec_amt    NUMBER(18,2),
  actual_exec_amt  NUMBER(18,2),
  preoccupy_amt    NUMBER(18,2),
  exec_rate        NUMBER(10,2),
  budget_share     NUMBER(10,2), -- 部门预算/全局预算
  stat_time        DATE DEFAULT CURRENT_DATE,
  CONSTRAINT pk_ads_dept_budget_kpi PRIMARY KEY (resp_dept)
);

COMMENT ON TABLE ads_dept_budget_kpi IS 'ADS-部门预算KPI（大屏直连）';

-- ADS-供应商采购TOP10（全量快照）
CREATE TABLE ads_supplier_top10 (
  supplier_name VARCHAR2(200) NOT NULL,
  po_amt_tax    NUMBER(18,2),
  po_cnt        NUMBER(18,0),
  rank_no       NUMBER(18,0),
  stat_time     DATE DEFAULT CURRENT_DATE,
  CONSTRAINT pk_ads_supplier_top10 PRIMARY KEY (supplier_name)
);

COMMENT ON TABLE ads_supplier_top10 IS 'ADS-供应商采购TOP10（大屏直连）';

-- ADS-物料分类采购分布（全量快照）
CREATE TABLE ads_item_class_po_dist (
  item_class  VARCHAR2(50) NOT NULL,
  po_amt_tax  NUMBER(18,2),
  po_cnt      NUMBER(18,0),
  stat_time   DATE DEFAULT CURRENT_DATE,
  CONSTRAINT pk_ads_item_class_po_dist PRIMARY KEY (item_class)
);

COMMENT ON TABLE ads_item_class_po_dist IS 'ADS-物料分类采购分布（大屏直连）';

-- ADS-采购月趋势（按月）
CREATE TABLE ads_po_month_trend (
  ym            VARCHAR2(7) NOT NULL,   -- YYYY-MM
  po_amt_tax    NUMBER(18,2),
  po_qty        NUMBER(18,3),
  recv_qty      NUMBER(18,3),
  recv_rate     NUMBER(10,2),
  CONSTRAINT pk_ads_po_month_trend PRIMARY KEY (ym)
);

COMMENT ON TABLE ads_po_month_trend IS 'ADS-采购月趋势（大屏直连）';

-- ADS-采购金额链路（桑基图，按月，金额口径）
-- 说明：按订单日期聚合（如需严格按到货/入库日期，需要源表补日期字段）
CREATE TABLE ads_po_amount_flow_month (
  ym          VARCHAR2(7)  NOT NULL,  -- YYYY-MM
  source_node VARCHAR2(50) NOT NULL,
  target_node VARCHAR2(50) NOT NULL,
  amt         NUMBER(18,2),
  stat_time   DATE DEFAULT CURRENT_DATE,
  CONSTRAINT pk_ads_po_amount_flow_month PRIMARY KEY (ym, source_node, target_node)
);

COMMENT ON TABLE ads_po_amount_flow_month IS 'ADS-采购金额链路（桑基图，按月，大屏直连）';

-- ADS-物料采购金额链路（桑基图，按月，物料粒度）
-- 说明：用于“采购→库存关联”类桑基；按订单日期聚合，金额口径与 ods_po_exec 一致。
CREATE TABLE ads_item_amount_flow_month (
  ym          VARCHAR2(7)  NOT NULL,  -- YYYY-MM
  item_code   VARCHAR2(80) NOT NULL,
  item_name   VARCHAR2(300),
  source_node VARCHAR2(50) NOT NULL,
  target_node VARCHAR2(50) NOT NULL,
  amt         NUMBER(18,2),
  stat_time   DATE DEFAULT CURRENT_DATE,
  CONSTRAINT pk_ads_item_amount_flow_month PRIMARY KEY (ym, item_code, source_node, target_node)
);

COMMENT ON TABLE ads_item_amount_flow_month IS 'ADS-物料采购金额链路（桑基图，按月，物料粒度，大屏直连）';

-- ============================================================================
-- 大屏 2：库存与出入库
-- ============================================================================

-- ADS-库存总览（全局汇总）
CREATE TABLE ads_stock_overview (
  stat_date      DATE NOT NULL,
  item_cnt       NUMBER(18,0),
  total_onhand   NUMBER(18,3),
  total_reserved NUMBER(18,3),
  total_frozen   NUMBER(18,3),
  proj_cnt       NUMBER(18,0),
  CONSTRAINT pk_ads_stock_overview PRIMARY KEY (stat_date)
);

COMMENT ON TABLE ads_stock_overview IS 'ADS-库存总览（大屏直连）';

-- ADS-出入库日趋势（近N天）
CREATE TABLE ads_io_daily_trend (
  biz_date    DATE NOT NULL,
  in_qty      NUMBER(18,3),
  out_qty     NUMBER(18,3),
  net_in_qty  NUMBER(18,3),
  CONSTRAINT pk_ads_io_daily_trend PRIMARY KEY (biz_date)
);

COMMENT ON TABLE ads_io_daily_trend IS 'ADS-出入库日趋势（大屏直连）';

-- ADS-仓库库存分布（按仓库汇总）
CREATE TABLE ads_wh_stock_dist (
  wh_name        VARCHAR2(200) NOT NULL,
  total_onhand   NUMBER(18,3),
  total_reserved NUMBER(18,3),
  total_frozen   NUMBER(18,3),
  stat_time      DATE DEFAULT CURRENT_DATE,
  CONSTRAINT pk_ads_wh_stock_dist PRIMARY KEY (wh_name)
);

COMMENT ON TABLE ads_wh_stock_dist IS 'ADS-仓库库存分布（大屏直连）';

-- ADS-项目库存分布（按项目汇总；兼容无 proj_code 的导出）
CREATE TABLE ads_proj_stock_dist (
  proj_key     VARCHAR2(200) NOT NULL,
  proj_code    VARCHAR2(50),
  proj_name    VARCHAR2(200),
  total_onhand NUMBER(18,3),
  stat_time    DATE DEFAULT CURRENT_DATE,
  CONSTRAINT pk_ads_proj_stock_dist PRIMARY KEY (proj_key)
);

COMMENT ON TABLE ads_proj_stock_dist IS 'ADS-项目库存分布（大屏直连）';

-- ADS-物料周转（90天，数量口径；近似：90天出库/当前现存）
CREATE TABLE ads_item_turnover_90d (
  item_code          VARCHAR2(80) NOT NULL,
  item_name          VARCHAR2(300),
  out_qty_90d        NUMBER(18,3),
  in_qty_90d         NUMBER(18,3),
  onhand_qty         NUMBER(18,3),
  turnover_rate_90d  NUMBER(10,4), -- out_90d / onhand
  last_out_date      DATE,
  days_since_last_out NUMBER(18,0),
  stat_time          DATE DEFAULT CURRENT_DATE,
  CONSTRAINT pk_ads_item_turnover_90d PRIMARY KEY (item_code)
);

COMMENT ON TABLE ads_item_turnover_90d IS 'ADS-物料周转（90天，数量口径，大屏直连）';

-- ADS-项目用料结构（90天出库，项目+物料）
CREATE TABLE ads_proj_item_out_90d (
  proj_key    VARCHAR2(200) NOT NULL,
  proj_code   VARCHAR2(50),
  proj_name   VARCHAR2(200),
  item_code   VARCHAR2(80) NOT NULL,
  item_name   VARCHAR2(300),
  out_qty_90d NUMBER(18,3),
  stat_time   DATE DEFAULT CURRENT_DATE,
  CONSTRAINT pk_ads_proj_item_out_90d PRIMARY KEY (proj_key, item_code)
);

COMMENT ON TABLE ads_proj_item_out_90d IS 'ADS-项目用料结构（90天出库，大屏直连）';

-- ADS-异常出入库：大额记录TOPN（90天，按数量绝对值排序）
CREATE TABLE ads_io_large_txn_topn (
  rank_no    NUMBER(18,0) NOT NULL,
  biz_date   DATE,
  direction  VARCHAR2(10), -- IN/OUT
  io_type    VARCHAR2(200),
  doc_no     VARCHAR2(80),
  wh_name    VARCHAR2(200),
  proj_key   VARCHAR2(200),
  item_code  VARCHAR2(80),
  item_name  VARCHAR2(300),
  qty        NUMBER(18,3),
  stat_time  DATE DEFAULT CURRENT_DATE,
  CONSTRAINT pk_ads_io_large_txn_topn PRIMARY KEY (rank_no)
);

COMMENT ON TABLE ads_io_large_txn_topn IS 'ADS-异常出入库-大额记录TOPN（90天，大屏直连）';

-- ADS-异常出入库：高频物料TOPN（90天，按流水次数排序）
CREATE TABLE ads_item_io_freq_topn (
  rank_no     NUMBER(18,0) NOT NULL,
  item_code   VARCHAR2(80),
  item_name   VARCHAR2(300),
  txn_cnt_90d NUMBER(18,0),
  stat_time   DATE DEFAULT CURRENT_DATE,
  CONSTRAINT pk_ads_item_io_freq_topn PRIMARY KEY (rank_no)
);

COMMENT ON TABLE ads_item_io_freq_topn IS 'ADS-异常出入库-高频物料TOPN（90天，大屏直连）';

-- ============================================================================
-- 大屏 3：物料全链路追踪
-- ============================================================================

-- ADS-物料总览KPI（全局 1 行）
CREATE TABLE ads_item_overview_kpi (
  stat_time        DATE NOT NULL,
  item_cnt         NUMBER(18,0),
  enabled_item_cnt NUMBER(18,0),
  item_class_cnt   NUMBER(18,0),
  CONSTRAINT pk_ads_item_overview_kpi PRIMARY KEY (stat_time)
);

COMMENT ON TABLE ads_item_overview_kpi IS 'ADS-物料总览KPI（大屏直连）';

-- ADS-库存→项目关联（网络图边：项目-物料-数量）
CREATE TABLE ads_proj_item_onhand_edge (
  proj_key    VARCHAR2(200) NOT NULL,
  proj_code   VARCHAR2(50),
  proj_name   VARCHAR2(200),
  item_code   VARCHAR2(80) NOT NULL,
  item_name   VARCHAR2(300),
  onhand_qty  NUMBER(18,3),
  stat_time   DATE DEFAULT CURRENT_DATE,
  CONSTRAINT pk_ads_proj_item_onhand_edge PRIMARY KEY (proj_key, item_code)
);

COMMENT ON TABLE ads_proj_item_onhand_edge IS 'ADS-库存到项目关联（网络图边，大屏直连）';

-- ADS-规格型号库存分析（旭日图，按分类/规格/型号汇总）
CREATE TABLE ads_item_spec_model_stock (
  item_class   VARCHAR2(50),
  spec         VARCHAR2(200),
  model        VARCHAR2(200),
  total_onhand NUMBER(18,3),
  stat_time    DATE DEFAULT CURRENT_DATE
);

COMMENT ON TABLE ads_item_spec_model_stock IS 'ADS-规格型号库存分析（旭日图，大屏直连）';

-- ADS-物料价格月追踪
CREATE TABLE ads_item_price_month (
  item_code    VARCHAR2(80) NOT NULL,
  ym           VARCHAR2(7)  NOT NULL,
  avg_price_nt NUMBER(18,4),
  min_price_nt NUMBER(18,4),
  max_price_nt NUMBER(18,4),
  CONSTRAINT pk_ads_item_price_month PRIMARY KEY (item_code, ym)
);

COMMENT ON TABLE ads_item_price_month IS 'ADS-物料无税单价月追踪（大屏直连）';


-- ============================================================================
-- ODS 演示数据（每表 100 行）
-- 生成方式：INSERT INTO ... SELECT ... CONNECT BY LEVEL <= 100
-- ============================================================================

-- ODS-项目预算执行明细（100 行，引用前 20 个项目）
INSERT INTO ods_proj_budget_exec_dtl (
  proj_budget_cat_code,
  proj_budget_cat_name,
  parent_proj_code,
  parent_proj_name,
  pk_project,
  proj_code,
  proj_name,
  resp_dept,
  budget_amt,
  adjust_amt,
  exec_amt,
  hist_exec_amt
)
SELECT
  'CAT' || LPAD(TO_CHAR(MOD(LEVEL - 1, 5) + 1), 2, '0') AS proj_budget_cat_code,
  '预算分类' || TO_CHAR(MOD(LEVEL - 1, 5) + 1) AS proj_budget_cat_name,
  NULL AS parent_proj_code,
  NULL AS parent_proj_name,
  'PK_' || ('P' || LPAD(TO_CHAR(MOD(LEVEL - 1, 20) + 1), 4, '0')) AS pk_project,
  'P' || LPAD(TO_CHAR(MOD(LEVEL - 1, 20) + 1), 4, '0') AS proj_code,
  '项目' || TO_CHAR(MOD(LEVEL - 1, 20) + 1) AS proj_name,
  '责任部门' || TO_CHAR(MOD(LEVEL - 1, 6) + 1) AS resp_dept,
  ROUND(100000 + LEVEL * 1000.25, 2) AS budget_amt,
  ROUND(CASE WHEN MOD(LEVEL, 10) = 0 THEN 5000 ELSE 0 END, 2) AS adjust_amt,
  ROUND(50000 + LEVEL * 500.12, 2) AS exec_amt,
  ROUND(CASE WHEN MOD(LEVEL, 3) = 0 THEN 8000 ELSE 0 END, 2) AS hist_exec_amt
FROM dual
CONNECT BY LEVEL <= 100;

-- ODS-采购订单执行（100 行，引用前 20 项目、前 30 物料）
INSERT INTO ods_po_exec (
  purchase_org,
  order_no,
  order_date,
  contract_no,
  order_currency,
  supplier_name,
  purchaser,
  purchase_dept,
  proj_code,
  proj_name,
  line_no,
  item_code,
  item_name,
  spec,
  model,
  uom,
  qty,
  unit_price_nt,
  unit_price_tax,
  amt_nt,
  amt_tax,
  tax_rate,
  tax_amt,
  is_gift,
  recv_qty,
  return_qty,
  qc_qty,
  qualified_qty,
  recv_gift_qty,
  in_gift_qty,
  in_qty,
  in_unit_price,
  in_amt,
  return_in_qty,
  invoice_qty,
  invoice_amt_tax_local,
  invoice_pay_balance_local
)
SELECT
  '采购组织A' AS purchase_org,
  'PO' || TO_CHAR(TO_DATE('2025-01-01', 'YYYY-MM-DD') + MOD(LEVEL - 1, 30), 'YYYYMMDD') || LPAD(TO_CHAR(LEVEL), 4, '0') AS order_no,
  TO_DATE('2025-01-01', 'YYYY-MM-DD') + MOD(LEVEL - 1, 30) AS order_date,
  'HT' || LPAD(TO_CHAR(LEVEL), 6, '0') AS contract_no,
  CASE WHEN MOD(LEVEL, 2) = 0 THEN 'CNY' ELSE 'USD' END AS order_currency,
  '供应商' || TO_CHAR(MOD(LEVEL - 1, 20) + 1) AS supplier_name,
  '采购员' || TO_CHAR(MOD(LEVEL - 1, 5) + 1) AS purchaser,
  '采购部' || TO_CHAR(MOD(LEVEL - 1, 3) + 1) AS purchase_dept,
  'P' || LPAD(TO_CHAR(MOD(LEVEL - 1, 20) + 1), 4, '0') AS proj_code,
  '项目' || TO_CHAR(MOD(LEVEL - 1, 20) + 1) AS proj_name,
  TO_CHAR(MOD(LEVEL - 1, 10) + 1) AS line_no,
  'I' || LPAD(TO_CHAR(MOD(LEVEL - 1, 30) + 1), 5, '0') AS item_code,
  '物料' || TO_CHAR(MOD(LEVEL - 1, 30) + 1) AS item_name,
  '规格' || TO_CHAR(MOD(LEVEL - 1, 10) + 1) AS spec,
  '型号' || TO_CHAR(MOD(LEVEL - 1, 12) + 1) AS model,
  'EA' AS uom,
  ROUND(10 + MOD(LEVEL - 1, 5) * 2.5, 3) AS qty,
  ROUND(100 + MOD(LEVEL - 1, 10) * 1.23, 4) AS unit_price_nt,
  ROUND((100 + MOD(LEVEL - 1, 10) * 1.23) * 1.13, 4) AS unit_price_tax,
  ROUND(ROUND(10 + MOD(LEVEL - 1, 5) * 2.5, 3) * ROUND(100 + MOD(LEVEL - 1, 10) * 1.23, 4), 2) AS amt_nt,
  ROUND(ROUND(ROUND(10 + MOD(LEVEL - 1, 5) * 2.5, 3) * ROUND(100 + MOD(LEVEL - 1, 10) * 1.23, 4), 2) * 1.13, 2) AS amt_tax,
  0.13 AS tax_rate,
  ROUND(ROUND(ROUND(10 + MOD(LEVEL - 1, 5) * 2.5, 3) * ROUND(100 + MOD(LEVEL - 1, 10) * 1.23, 4), 2) * 0.13, 2) AS tax_amt,
  CASE WHEN MOD(LEVEL, 20) = 0 THEN 'Y' ELSE 'N' END AS is_gift,
  ROUND(ROUND(10 + MOD(LEVEL - 1, 5) * 2.5, 3) * 0.80, 3) AS recv_qty,
  0 AS return_qty,
  ROUND(ROUND(10 + MOD(LEVEL - 1, 5) * 2.5, 3) * 0.70, 3) AS qc_qty,
  ROUND(ROUND(10 + MOD(LEVEL - 1, 5) * 2.5, 3) * 0.70, 3) AS qualified_qty,
  CASE WHEN MOD(LEVEL, 20) = 0 THEN ROUND(ROUND(10 + MOD(LEVEL - 1, 5) * 2.5, 3) * 0.10, 3) ELSE 0 END AS recv_gift_qty,
  CASE WHEN MOD(LEVEL, 20) = 0 THEN ROUND(ROUND(10 + MOD(LEVEL - 1, 5) * 2.5, 3) * 0.10, 3) ELSE 0 END AS in_gift_qty,
  ROUND(ROUND(10 + MOD(LEVEL - 1, 5) * 2.5, 3) * 0.60, 3) AS in_qty,
  ROUND(100 + MOD(LEVEL - 1, 10) * 1.23, 4) AS in_unit_price,
  ROUND(ROUND(ROUND(10 + MOD(LEVEL - 1, 5) * 2.5, 3) * 0.60, 3) * ROUND(100 + MOD(LEVEL - 1, 10) * 1.23, 4), 2) AS in_amt,
  0 AS return_in_qty,
  ROUND(ROUND(10 + MOD(LEVEL - 1, 5) * 2.5, 3) * 0.50, 3) AS invoice_qty,
  ROUND(ROUND(ROUND(ROUND(10 + MOD(LEVEL - 1, 5) * 2.5, 3) * ROUND(100 + MOD(LEVEL - 1, 10) * 1.23, 4), 2) * 1.13, 2) * 0.50, 2) AS invoice_amt_tax_local,
  ROUND(ROUND(ROUND(ROUND(10 + MOD(LEVEL - 1, 5) * 2.5, 3) * ROUND(100 + MOD(LEVEL - 1, 10) * 1.23, 4), 2) * 1.13, 2) * 0.20, 2) AS invoice_pay_balance_local
FROM dual
CONNECT BY LEVEL <= 100;

-- ODS-出入库流水（100 行，偶数入库 / 奇数出库）
INSERT INTO ods_stock_io_flow (
  inv_org,
  biz_date,
  biz_type,
  io_type,
  doc_no,
  wh_name,
  proj,
  proj_code,
  proj_name,
  item_code,
  item_name,
  item_version,
  spec,
  model,
  batch_no,
  main_uom,
  uom,
  conv_rate,
  in_main_qty,
  in_qty,
  out_main_qty,
  out_qty
)
SELECT
  '库存组织A' AS inv_org,
  TO_DATE('2025-02-01', 'YYYY-MM-DD') + MOD(LEVEL - 1, 30) AS biz_date,
  CASE WHEN MOD(LEVEL, 2) = 0 THEN '库存采购入库单' ELSE '库存物料出库单' END AS biz_type,
  CASE WHEN MOD(LEVEL, 2) = 0 THEN '普通采购入库' ELSE '材料出库' END AS io_type,
  'IO' || TO_CHAR(TO_DATE('2025-02-01', 'YYYY-MM-DD') + MOD(LEVEL - 1, 30), 'YYYYMMDD') || LPAD(TO_CHAR(LEVEL), 4, '0') AS doc_no,
  '仓库' || TO_CHAR(MOD(LEVEL - 1, 4) + 1) AS wh_name,
  '项目' || TO_CHAR(MOD(LEVEL - 1, 20) + 1) AS proj,
  'P' || LPAD(TO_CHAR(MOD(LEVEL - 1, 20) + 1), 4, '0') AS proj_code,
  '项目' || TO_CHAR(MOD(LEVEL - 1, 20) + 1) AS proj_name,
  'I' || LPAD(TO_CHAR(MOD(LEVEL - 1, 30) + 1), 5, '0') AS item_code,
  '物料' || TO_CHAR(MOD(LEVEL - 1, 30) + 1) AS item_name,
  'V' || TO_CHAR(MOD(LEVEL - 1, 3) + 1) AS item_version,
  '规格' || TO_CHAR(MOD(LEVEL - 1, 10) + 1) AS spec,
  '型号' || TO_CHAR(MOD(LEVEL - 1, 12) + 1) AS model,
  'B' || TO_CHAR(MOD(LEVEL - 1, 8) + 1) AS batch_no,
  'EA' AS main_uom,
  'EA' AS uom,
  1 AS conv_rate,
  CASE WHEN MOD(LEVEL, 2) = 0 THEN ROUND(5 + MOD(LEVEL - 1, 7) * 1.2, 3) ELSE 0 END AS in_main_qty,
  CASE WHEN MOD(LEVEL, 2) = 0 THEN ROUND(5 + MOD(LEVEL - 1, 7) * 1.2, 3) ELSE 0 END AS in_qty,
  CASE WHEN MOD(LEVEL, 2) = 1 THEN ROUND(4 + MOD(LEVEL - 1, 6) * 1.1, 3) ELSE 0 END AS out_main_qty,
  CASE WHEN MOD(LEVEL, 2) = 1 THEN ROUND(4 + MOD(LEVEL - 1, 6) * 1.1, 3) ELSE 0 END AS out_qty
FROM dual
CONNECT BY LEVEL <= 100;

-- ODS-现存量（100 行，引用前 20 项目、前 30 物料）
INSERT INTO ods_stock_onhand (
  inv_org,
  wh_name,
  item_code,
  item_name,
  spec,
  model,
  uom,
  proj,
  proj_code,
  proj_name,
  onhand_qty,
  reserved_qty,
  frozen_qty,
  supplier_owner_onhand_qty
)
SELECT
  '库存组织A' AS inv_org,
  '仓库' || TO_CHAR(MOD(LEVEL - 1, 4) + 1) AS wh_name,
  'I' || LPAD(TO_CHAR(MOD(LEVEL - 1, 30) + 1), 5, '0') AS item_code,
  '物料' || TO_CHAR(MOD(LEVEL - 1, 30) + 1) AS item_name,
  '规格' || TO_CHAR(MOD(LEVEL - 1, 10) + 1) AS spec,
  '型号' || TO_CHAR(MOD(LEVEL - 1, 12) + 1) AS model,
  'EA' AS uom,
  '项目' || TO_CHAR(MOD(LEVEL - 1, 20) + 1) AS proj,
  'P' || LPAD(TO_CHAR(MOD(LEVEL - 1, 20) + 1), 4, '0') AS proj_code,
  '项目' || TO_CHAR(MOD(LEVEL - 1, 20) + 1) AS proj_name,
  ROUND(100 + MOD(LEVEL - 1, 20) * 7.5, 3) AS onhand_qty,
  ROUND(10 + MOD(LEVEL - 1, 10) * 1.1, 3) AS reserved_qty,
  ROUND(CASE WHEN MOD(LEVEL, 12) = 0 THEN 5 ELSE 0 END, 3) AS frozen_qty,
  ROUND(CASE WHEN MOD(LEVEL, 8) = 0 THEN 15 ELSE 0 END, 3) AS supplier_owner_onhand_qty
FROM dual
CONNECT BY LEVEL <= 100;

COMMIT;
