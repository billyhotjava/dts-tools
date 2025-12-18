-- dm8_excel_etl/tests/ads_select_cn.sql
-- 说明：BI 对接用的“中文别名 SELECT”示例（不依赖字段注释，select 结果即可读）。

-- 预算与采购总览（KPI 卡片）
SELECT
  stat_time AS "统计日期",
  budget_amt AS "预算总金额(元)",
  exec_amt AS "执行总金额(元)",
  hist_exec_amt AS "历史执行总金额(元)",
  actual_exec_amt AS "实际执行总金额(元)",
  preoccupy_amt AS "预占/调整总金额(元)",
  exec_rate AS "执行率(%)",
  actual_exec_rate AS "实际执行率(%)",
  preoccupy_rate AS "预占率(%)",
  remain_budget AS "剩余预算(元)=预算-执行",
  remain_budget_actual AS "剩余预算(元)=预算-(执行+历史执行)",
  remain_budget_after_preoccupy AS "剩余预算(元)=预算-执行-预占",
  po_amt_tax AS "采购金额(含税,元)",
  proj_cnt AS "涉及项目数",
  dept_cnt AS "涉及责任部门数"
FROM ads_budget_overview_kpi
ORDER BY stat_time DESC;

-- 项目预算执行排名（可按采购金额/执行率排序）
SELECT
  proj_code AS "项目编码",
  proj_name AS "项目名称",
  budget_amt AS "预算金额(元)",
  exec_amt AS "执行金额(元)",
  hist_exec_amt AS "历史执行金额(元)",
  actual_exec_amt AS "实际执行金额(元)=执行+历史执行",
  preoccupy_amt AS "预占/调整金额(元)",
  exec_rate AS "执行率(%)=执行/预算*100",
  actual_exec_rate AS "实际执行率(%)=(执行+历史执行)/预算*100",
  preoccupy_rate AS "预占率(%)=预占/预算*100",
  remain_budget_after_preoccupy AS "剩余预算(元)=预算-执行-预占",
  po_amt_tax AS "采购金额(含税,元)",
  po_budget_var_rate AS "采购偏差率(%)=(采购-预算)/预算*100",
  stat_time AS "统计日期"
FROM ads_proj_budget_kpi
ORDER BY po_amt_tax DESC;

-- 部门预算分析
SELECT
  resp_dept AS "责任部门",
  budget_amt AS "预算金额(元)",
  exec_amt AS "执行金额(元)",
  actual_exec_amt AS "实际执行金额(元)=执行+历史执行",
  preoccupy_amt AS "预占/调整金额(元)",
  exec_rate AS "执行率(%)",
  budget_share AS "预算占比(%)",
  stat_time AS "统计日期"
FROM ads_dept_budget_kpi
ORDER BY budget_amt DESC;

-- 采购月度趋势
SELECT
  ym AS "月份(YYYY-MM)",
  po_amt_tax AS "月采购金额(含税,元)",
  po_qty AS "月采购数量(主数量)",
  recv_qty AS "月到货数量(主数量)",
  recv_rate AS "到货完成率(%)"
FROM ads_po_month_trend
ORDER BY ym;

-- 供应商 TOP10
SELECT
  rank_no AS "排名",
  supplier_name AS "供应商",
  po_amt_tax AS "采购金额(含税,元)",
  po_cnt AS "明细行数",
  stat_time AS "统计日期"
FROM ads_supplier_top10
ORDER BY rank_no;

-- 物料分类采购分布
SELECT
  item_class AS "物料分类",
  po_amt_tax AS "采购金额(含税,元)",
  po_cnt AS "明细行数",
  stat_time AS "统计日期"
FROM ads_item_class_po_dist
ORDER BY po_amt_tax DESC;

-- 采购金额链路（桑基：总体）
SELECT
  ym AS "月份(YYYY-MM)",
  source_node AS "源节点",
  target_node AS "目标节点",
  amt AS "金额(含税,元)",
  stat_time AS "统计日期"
FROM ads_po_amount_flow_month
ORDER BY ym, source_node, target_node;

-- 采购金额链路（桑基：物料粒度）
SELECT
  ym AS "月份(YYYY-MM)",
  item_code AS "物料编码",
  item_name AS "物料名称",
  source_node AS "源节点",
  target_node AS "目标节点",
  amt AS "金额(含税,元)",
  stat_time AS "统计日期"
FROM ads_item_amount_flow_month
ORDER BY ym, item_code, source_node, target_node;

-- 库存总览
SELECT
  stat_date AS "统计日期",
  item_cnt AS "物料种类数",
  total_onhand AS "库存总量(主数量)",
  total_reserved AS "预留总量(主数量)",
  total_frozen AS "冻结总量(主数量)",
  proj_cnt AS "涉及项目数"
FROM ads_stock_overview
ORDER BY stat_date DESC;

-- 出入库动态（日趋势）
SELECT
  biz_date AS "业务日期",
  in_qty AS "入库总量(主数量)",
  out_qty AS "出库总量(主数量)",
  net_in_qty AS "净流入(主数量)=入-出"
FROM ads_io_daily_trend
ORDER BY biz_date;

-- 物料周转（90天）
SELECT
  item_code AS "物料编码",
  item_name AS "物料名称",
  out_qty_90d AS "90天出库量(主数量)",
  in_qty_90d AS "90天入库量(主数量)",
  onhand_qty AS "当前现存量(主数量)",
  turnover_rate_90d AS "周转率(90天)=90天出库/现存(近似)",
  last_out_date AS "最近出库日期",
  days_since_last_out AS "距最近出库天数",
  stat_time AS "统计日期"
FROM ads_item_turnover_90d
ORDER BY turnover_rate_90d DESC;

-- 异常出入库（大额 TOPN）
SELECT
  rank_no AS "排名",
  biz_date AS "业务日期",
  direction AS "方向(IN/OUT)",
  io_type AS "出入库类型",
  doc_no AS "单据号",
  wh_name AS "仓库",
  proj_key AS "项目键",
  item_code AS "物料编码",
  item_name AS "物料名称",
  qty AS "数量(主数量)",
  stat_time AS "统计日期"
FROM ads_io_large_txn_topn
ORDER BY rank_no;

