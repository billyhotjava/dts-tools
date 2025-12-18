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
COMMENT ON COLUMN ads_budget_overview_kpi.stat_time IS '统计日期';
COMMENT ON COLUMN ads_budget_overview_kpi.budget_amt IS '预算总金额（元）';
COMMENT ON COLUMN ads_budget_overview_kpi.exec_amt IS '执行总金额（元）';
COMMENT ON COLUMN ads_budget_overview_kpi.hist_exec_amt IS '历史执行总金额（元）';
COMMENT ON COLUMN ads_budget_overview_kpi.actual_exec_amt IS '实际执行总金额（元）=执行+历史执行';
COMMENT ON COLUMN ads_budget_overview_kpi.preoccupy_amt IS '预占/调整总金额（元）=ods.adjust_amt';
COMMENT ON COLUMN ads_budget_overview_kpi.exec_rate IS '执行率（%）=执行/预算*100';
COMMENT ON COLUMN ads_budget_overview_kpi.actual_exec_rate IS '实际执行率（%）=(执行+历史执行)/预算*100';
COMMENT ON COLUMN ads_budget_overview_kpi.preoccupy_rate IS '预占率（%）=预占/预算*100';
COMMENT ON COLUMN ads_budget_overview_kpi.remain_budget IS '剩余预算（元）=预算-执行';
COMMENT ON COLUMN ads_budget_overview_kpi.remain_budget_actual IS '剩余预算（元）=预算-(执行+历史执行)';
COMMENT ON COLUMN ads_budget_overview_kpi.remain_budget_after_preoccupy IS '剩余预算（元）=预算-执行-预占';
COMMENT ON COLUMN ads_budget_overview_kpi.po_amt_tax IS '采购金额（含税，元）=SUM(ods_po_exec.amt_tax)';
COMMENT ON COLUMN ads_budget_overview_kpi.proj_cnt IS '涉及项目数（去重）';
COMMENT ON COLUMN ads_budget_overview_kpi.dept_cnt IS '涉及责任部门数（去重）';

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
COMMENT ON COLUMN ads_proj_budget_kpi.proj_code IS '项目编码';
COMMENT ON COLUMN ads_proj_budget_kpi.proj_name IS '项目名称';
COMMENT ON COLUMN ads_proj_budget_kpi.budget_amt IS '项目预算金额（元）';
COMMENT ON COLUMN ads_proj_budget_kpi.exec_amt IS '项目执行金额（元）';
COMMENT ON COLUMN ads_proj_budget_kpi.hist_exec_amt IS '项目历史执行金额（元）';
COMMENT ON COLUMN ads_proj_budget_kpi.actual_exec_amt IS '项目实际执行金额（元）=执行+历史执行';
COMMENT ON COLUMN ads_proj_budget_kpi.preoccupy_amt IS '项目预占/调整金额（元）=ods.adjust_amt';
COMMENT ON COLUMN ads_proj_budget_kpi.exec_rate IS '项目执行率（%）=执行/预算*100';
COMMENT ON COLUMN ads_proj_budget_kpi.actual_exec_rate IS '项目实际执行率（%）=(执行+历史执行)/预算*100';
COMMENT ON COLUMN ads_proj_budget_kpi.preoccupy_rate IS '项目预占率（%）=预占/预算*100';
COMMENT ON COLUMN ads_proj_budget_kpi.remain_budget IS '项目剩余预算（元）=预算-执行';
COMMENT ON COLUMN ads_proj_budget_kpi.remain_budget_actual IS '项目剩余预算（元）=预算-(执行+历史执行)';
COMMENT ON COLUMN ads_proj_budget_kpi.remain_budget_after_preoccupy IS '项目剩余预算（元）=预算-执行-预占';
COMMENT ON COLUMN ads_proj_budget_kpi.po_amt_tax IS '项目采购金额（含税，元）=SUM(ods_po_exec.amt_tax)';
COMMENT ON COLUMN ads_proj_budget_kpi.po_budget_var_rate IS '采购偏差率（%）=(采购-预算)/预算*100';
COMMENT ON COLUMN ads_proj_budget_kpi.stat_time IS '统计日期';

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
COMMENT ON COLUMN ads_dept_budget_kpi.resp_dept IS '责任部门';
COMMENT ON COLUMN ads_dept_budget_kpi.budget_amt IS '部门预算金额（元）';
COMMENT ON COLUMN ads_dept_budget_kpi.exec_amt IS '部门执行金额（元）';
COMMENT ON COLUMN ads_dept_budget_kpi.hist_exec_amt IS '部门历史执行金额（元）';
COMMENT ON COLUMN ads_dept_budget_kpi.actual_exec_amt IS '部门实际执行金额（元）=执行+历史执行';
COMMENT ON COLUMN ads_dept_budget_kpi.preoccupy_amt IS '部门预占/调整金额（元）';
COMMENT ON COLUMN ads_dept_budget_kpi.exec_rate IS '部门执行率（%）=执行/预算*100';
COMMENT ON COLUMN ads_dept_budget_kpi.budget_share IS '部门预算占比（%）=部门预算/总预算*100';
COMMENT ON COLUMN ads_dept_budget_kpi.stat_time IS '统计日期';

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
COMMENT ON COLUMN ads_supplier_top10.supplier_name IS '供应商名称';
COMMENT ON COLUMN ads_supplier_top10.po_amt_tax IS '采购金额（含税，元）';
COMMENT ON COLUMN ads_supplier_top10.po_cnt IS '订单/明细行数（按 ods_po_exec 计数）';
COMMENT ON COLUMN ads_supplier_top10.rank_no IS '排名（1=最高）';
COMMENT ON COLUMN ads_supplier_top10.stat_time IS '统计日期';

-- ADS-物料分类采购分布（全量快照）
CREATE TABLE ads_item_class_po_dist (
  item_class  VARCHAR2(50) NOT NULL,
  po_amt_tax  NUMBER(18,2),
  po_cnt      NUMBER(18,0),
  stat_time   DATE DEFAULT CURRENT_DATE,
  CONSTRAINT pk_ads_item_class_po_dist PRIMARY KEY (item_class)
);

COMMENT ON TABLE ads_item_class_po_dist IS 'ADS-物料分类采购分布（大屏直连）';
COMMENT ON COLUMN ads_item_class_po_dist.item_class IS '物料分类编码（来自 mdm_item.item_class；未知=UNKNOWN）';
COMMENT ON COLUMN ads_item_class_po_dist.po_amt_tax IS '分类采购金额（含税，元）';
COMMENT ON COLUMN ads_item_class_po_dist.po_cnt IS '分类订单/明细行数（按 ods_po_exec 计数）';
COMMENT ON COLUMN ads_item_class_po_dist.stat_time IS '统计日期';

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
COMMENT ON COLUMN ads_po_month_trend.ym IS '月份（YYYY-MM）';
COMMENT ON COLUMN ads_po_month_trend.po_amt_tax IS '月采购金额（含税，元）';
COMMENT ON COLUMN ads_po_month_trend.po_qty IS '月采购数量（主数量）';
COMMENT ON COLUMN ads_po_month_trend.recv_qty IS '月到货数量（主数量）';
COMMENT ON COLUMN ads_po_month_trend.recv_rate IS '到货完成率（%）=到货数量/采购数量*100';

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
COMMENT ON COLUMN ads_po_amount_flow_month.ym IS '月份（YYYY-MM）';
COMMENT ON COLUMN ads_po_amount_flow_month.source_node IS '源节点（如：订单金额/到货金额/入库金额）';
COMMENT ON COLUMN ads_po_amount_flow_month.target_node IS '目标节点（如：到货金额/未到货金额/开票金额）';
COMMENT ON COLUMN ads_po_amount_flow_month.amt IS '金额（含税，元）';
COMMENT ON COLUMN ads_po_amount_flow_month.stat_time IS '统计日期';

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
COMMENT ON COLUMN ads_item_amount_flow_month.ym IS '月份（YYYY-MM）';
COMMENT ON COLUMN ads_item_amount_flow_month.item_code IS '物料编码';
COMMENT ON COLUMN ads_item_amount_flow_month.item_name IS '物料名称';
COMMENT ON COLUMN ads_item_amount_flow_month.source_node IS '源节点（如：订单金额/到货金额/入库金额）';
COMMENT ON COLUMN ads_item_amount_flow_month.target_node IS '目标节点（如：到货金额/未到货金额/开票金额）';
COMMENT ON COLUMN ads_item_amount_flow_month.amt IS '金额（含税，元）';
COMMENT ON COLUMN ads_item_amount_flow_month.stat_time IS '统计日期';

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
COMMENT ON COLUMN ads_stock_overview.stat_date IS '统计日期';
COMMENT ON COLUMN ads_stock_overview.item_cnt IS '物料种类数（去重 item_code）';
COMMENT ON COLUMN ads_stock_overview.total_onhand IS '库存总量（主数量）';
COMMENT ON COLUMN ads_stock_overview.total_reserved IS '预留总量（主数量）';
COMMENT ON COLUMN ads_stock_overview.total_frozen IS '冻结总量（主数量）';
COMMENT ON COLUMN ads_stock_overview.proj_cnt IS '涉及项目数（去重 COALESCE(proj_code,proj)）';

-- ADS-出入库日趋势（近N天）
CREATE TABLE ads_io_daily_trend (
  biz_date    DATE NOT NULL,
  in_qty      NUMBER(18,3),
  out_qty     NUMBER(18,3),
  net_in_qty  NUMBER(18,3),
  CONSTRAINT pk_ads_io_daily_trend PRIMARY KEY (biz_date)
);

COMMENT ON TABLE ads_io_daily_trend IS 'ADS-出入库日趋势（大屏直连）';
COMMENT ON COLUMN ads_io_daily_trend.biz_date IS '业务日期';
COMMENT ON COLUMN ads_io_daily_trend.in_qty IS '日入库总量（主数量；优先 in_main_qty）';
COMMENT ON COLUMN ads_io_daily_trend.out_qty IS '日出库总量（主数量；优先 out_main_qty）';
COMMENT ON COLUMN ads_io_daily_trend.net_in_qty IS '净流入量（主数量）=入库-出库';

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
COMMENT ON COLUMN ads_wh_stock_dist.wh_name IS '仓库名称';
COMMENT ON COLUMN ads_wh_stock_dist.total_onhand IS '仓库库存总量（主数量）';
COMMENT ON COLUMN ads_wh_stock_dist.total_reserved IS '仓库预留总量（主数量）';
COMMENT ON COLUMN ads_wh_stock_dist.total_frozen IS '仓库冻结总量（主数量）';
COMMENT ON COLUMN ads_wh_stock_dist.stat_time IS '统计日期';

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
COMMENT ON COLUMN ads_proj_stock_dist.proj_key IS '项目键（优先 proj_code；否则用 ods_stock_onhand.proj 文本）';
COMMENT ON COLUMN ads_proj_stock_dist.proj_code IS '项目编码（如导出包含）';
COMMENT ON COLUMN ads_proj_stock_dist.proj_name IS '项目名称';
COMMENT ON COLUMN ads_proj_stock_dist.total_onhand IS '项目库存总量（主数量）';
COMMENT ON COLUMN ads_proj_stock_dist.stat_time IS '统计日期';

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
COMMENT ON COLUMN ads_item_turnover_90d.item_code IS '物料编码';
COMMENT ON COLUMN ads_item_turnover_90d.item_name IS '物料名称';
COMMENT ON COLUMN ads_item_turnover_90d.out_qty_90d IS '90天出库量（主数量）';
COMMENT ON COLUMN ads_item_turnover_90d.in_qty_90d IS '90天入库量（主数量）';
COMMENT ON COLUMN ads_item_turnover_90d.onhand_qty IS '当前现存量（主数量；来自 ods_stock_onhand 汇总）';
COMMENT ON COLUMN ads_item_turnover_90d.turnover_rate_90d IS '周转率（90天）=90天出库量/当前现存量（近似）';
COMMENT ON COLUMN ads_item_turnover_90d.last_out_date IS '最近一次出库日期（90天窗口内）';
COMMENT ON COLUMN ads_item_turnover_90d.days_since_last_out IS '距最近一次出库天数';
COMMENT ON COLUMN ads_item_turnover_90d.stat_time IS '统计日期';

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
COMMENT ON COLUMN ads_proj_item_out_90d.proj_key IS '项目键（优先 proj_code；否则用 ods_stock_io_flow.proj 文本）';
COMMENT ON COLUMN ads_proj_item_out_90d.proj_code IS '项目编码（如导出包含）';
COMMENT ON COLUMN ads_proj_item_out_90d.proj_name IS '项目名称';
COMMENT ON COLUMN ads_proj_item_out_90d.item_code IS '物料编码';
COMMENT ON COLUMN ads_proj_item_out_90d.item_name IS '物料名称';
COMMENT ON COLUMN ads_proj_item_out_90d.out_qty_90d IS '90天项目出库量（主数量）';
COMMENT ON COLUMN ads_proj_item_out_90d.stat_time IS '统计日期';

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
COMMENT ON COLUMN ads_io_large_txn_topn.rank_no IS '排名（1=最大）';
COMMENT ON COLUMN ads_io_large_txn_topn.biz_date IS '业务日期';
COMMENT ON COLUMN ads_io_large_txn_topn.direction IS '方向（IN/OUT）';
COMMENT ON COLUMN ads_io_large_txn_topn.io_type IS '出入库类型';
COMMENT ON COLUMN ads_io_large_txn_topn.doc_no IS '单据号';
COMMENT ON COLUMN ads_io_large_txn_topn.wh_name IS '仓库名称';
COMMENT ON COLUMN ads_io_large_txn_topn.proj_key IS '项目键（优先 proj_code；否则 proj 文本）';
COMMENT ON COLUMN ads_io_large_txn_topn.item_code IS '物料编码';
COMMENT ON COLUMN ads_io_large_txn_topn.item_name IS '物料名称';
COMMENT ON COLUMN ads_io_large_txn_topn.qty IS '数量（主数量，取绝对值用于排序）';
COMMENT ON COLUMN ads_io_large_txn_topn.stat_time IS '统计日期';

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
COMMENT ON COLUMN ads_item_io_freq_topn.rank_no IS '排名（1=最高频）';
COMMENT ON COLUMN ads_item_io_freq_topn.item_code IS '物料编码';
COMMENT ON COLUMN ads_item_io_freq_topn.item_name IS '物料名称';
COMMENT ON COLUMN ads_item_io_freq_topn.txn_cnt_90d IS '90天流水次数';
COMMENT ON COLUMN ads_item_io_freq_topn.stat_time IS '统计日期';

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
COMMENT ON COLUMN ads_item_overview_kpi.stat_time IS '统计日期';
COMMENT ON COLUMN ads_item_overview_kpi.item_cnt IS '物料总数（mdm_item 行数）';
COMMENT ON COLUMN ads_item_overview_kpi.enabled_item_cnt IS '启用物料数（enable_flag=1）';
COMMENT ON COLUMN ads_item_overview_kpi.item_class_cnt IS '物料分类数（去重 item_class）';

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
COMMENT ON COLUMN ads_proj_item_onhand_edge.proj_key IS '项目键（优先 proj_code；否则 proj 文本）';
COMMENT ON COLUMN ads_proj_item_onhand_edge.proj_code IS '项目编码（如导出包含）';
COMMENT ON COLUMN ads_proj_item_onhand_edge.proj_name IS '项目名称';
COMMENT ON COLUMN ads_proj_item_onhand_edge.item_code IS '物料编码';
COMMENT ON COLUMN ads_proj_item_onhand_edge.item_name IS '物料名称';
COMMENT ON COLUMN ads_proj_item_onhand_edge.onhand_qty IS '项目-物料库存数量（主数量）';
COMMENT ON COLUMN ads_proj_item_onhand_edge.stat_time IS '统计日期';

-- ADS-规格型号库存分析（旭日图，按分类/规格/型号汇总）
CREATE TABLE ads_item_spec_model_stock (
  item_class   VARCHAR2(50),
  spec         VARCHAR2(200),
  model        VARCHAR2(200),
  total_onhand NUMBER(18,3),
  stat_time    DATE DEFAULT CURRENT_DATE
);

COMMENT ON TABLE ads_item_spec_model_stock IS 'ADS-规格型号库存分析（旭日图，大屏直连）';
COMMENT ON COLUMN ads_item_spec_model_stock.item_class IS '物料分类（来自 mdm_item.item_class；未知=UNKNOWN）';
COMMENT ON COLUMN ads_item_spec_model_stock.spec IS '规格（来自 mdm_item.spec；未知=UNKNOWN）';
COMMENT ON COLUMN ads_item_spec_model_stock.model IS '型号（来自 mdm_item.model；未知=UNKNOWN）';
COMMENT ON COLUMN ads_item_spec_model_stock.total_onhand IS '库存数量（主数量）';
COMMENT ON COLUMN ads_item_spec_model_stock.stat_time IS '统计日期';

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
COMMENT ON COLUMN ads_item_price_month.item_code IS '物料编码';
COMMENT ON COLUMN ads_item_price_month.ym IS '月份（YYYY-MM）';
COMMENT ON COLUMN ads_item_price_month.avg_price_nt IS '平均无税单价';
COMMENT ON COLUMN ads_item_price_month.min_price_nt IS '最低无税单价';
COMMENT ON COLUMN ads_item_price_month.max_price_nt IS '最高无税单价';
