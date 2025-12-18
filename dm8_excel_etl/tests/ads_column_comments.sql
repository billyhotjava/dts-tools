-- dm8_excel_etl/tests/ads_column_comments.sql
-- 说明：为 ADS 表补充中文字段说明（COMMENT ON COLUMN）。
-- 适用场景：表已创建但没有字段注释，或需要更新注释。

-- 预算与采购总览 KPI
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

-- 项目预算 KPI
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

-- 部门预算 KPI
COMMENT ON COLUMN ads_dept_budget_kpi.resp_dept IS '责任部门';
COMMENT ON COLUMN ads_dept_budget_kpi.budget_amt IS '部门预算金额（元）';
COMMENT ON COLUMN ads_dept_budget_kpi.exec_amt IS '部门执行金额（元）';
COMMENT ON COLUMN ads_dept_budget_kpi.hist_exec_amt IS '部门历史执行金额（元）';
COMMENT ON COLUMN ads_dept_budget_kpi.actual_exec_amt IS '部门实际执行金额（元）=执行+历史执行';
COMMENT ON COLUMN ads_dept_budget_kpi.preoccupy_amt IS '部门预占/调整金额（元）';
COMMENT ON COLUMN ads_dept_budget_kpi.exec_rate IS '部门执行率（%）=执行/预算*100';
COMMENT ON COLUMN ads_dept_budget_kpi.budget_share IS '部门预算占比（%）=部门预算/总预算*100';
COMMENT ON COLUMN ads_dept_budget_kpi.stat_time IS '统计日期';

-- 供应商 TOP10
COMMENT ON COLUMN ads_supplier_top10.supplier_name IS '供应商名称';
COMMENT ON COLUMN ads_supplier_top10.po_amt_tax IS '采购金额（含税，元）';
COMMENT ON COLUMN ads_supplier_top10.po_cnt IS '订单/明细行数（按 ods_po_exec 计数）';
COMMENT ON COLUMN ads_supplier_top10.rank_no IS '排名（1=最高）';
COMMENT ON COLUMN ads_supplier_top10.stat_time IS '统计日期';

-- 物料分类采购分布
COMMENT ON COLUMN ads_item_class_po_dist.item_class IS '物料分类编码（来自 mdm_item.item_class；未知=UNKNOWN）';
COMMENT ON COLUMN ads_item_class_po_dist.po_amt_tax IS '分类采购金额（含税，元）';
COMMENT ON COLUMN ads_item_class_po_dist.po_cnt IS '分类订单/明细行数（按 ods_po_exec 计数）';
COMMENT ON COLUMN ads_item_class_po_dist.stat_time IS '统计日期';

-- 采购月趋势
COMMENT ON COLUMN ads_po_month_trend.ym IS '月份（YYYY-MM）';
COMMENT ON COLUMN ads_po_month_trend.po_amt_tax IS '月采购金额（含税，元）';
COMMENT ON COLUMN ads_po_month_trend.po_qty IS '月采购数量（主数量）';
COMMENT ON COLUMN ads_po_month_trend.recv_qty IS '月到货数量（主数量）';
COMMENT ON COLUMN ads_po_month_trend.recv_rate IS '到货完成率（%）=到货数量/采购数量*100';

-- 采购金额链路（总体/物料）
COMMENT ON COLUMN ads_po_amount_flow_month.ym IS '月份（YYYY-MM）';
COMMENT ON COLUMN ads_po_amount_flow_month.source_node IS '源节点（如：订单金额/到货金额/入库金额）';
COMMENT ON COLUMN ads_po_amount_flow_month.target_node IS '目标节点（如：到货金额/未到货金额/开票金额）';
COMMENT ON COLUMN ads_po_amount_flow_month.amt IS '金额（含税，元）';
COMMENT ON COLUMN ads_po_amount_flow_month.stat_time IS '统计日期';

COMMENT ON COLUMN ads_item_amount_flow_month.ym IS '月份（YYYY-MM）';
COMMENT ON COLUMN ads_item_amount_flow_month.item_code IS '物料编码';
COMMENT ON COLUMN ads_item_amount_flow_month.item_name IS '物料名称';
COMMENT ON COLUMN ads_item_amount_flow_month.source_node IS '源节点（如：订单金额/到货金额/入库金额）';
COMMENT ON COLUMN ads_item_amount_flow_month.target_node IS '目标节点（如：到货金额/未到货金额/开票金额）';
COMMENT ON COLUMN ads_item_amount_flow_month.amt IS '金额（含税，元）';
COMMENT ON COLUMN ads_item_amount_flow_month.stat_time IS '统计日期';

-- 库存与出入库
COMMENT ON COLUMN ads_stock_overview.stat_date IS '统计日期';
COMMENT ON COLUMN ads_stock_overview.item_cnt IS '物料种类数（去重 item_code）';
COMMENT ON COLUMN ads_stock_overview.total_onhand IS '库存总量（主数量）';
COMMENT ON COLUMN ads_stock_overview.total_reserved IS '预留总量（主数量）';
COMMENT ON COLUMN ads_stock_overview.total_frozen IS '冻结总量（主数量）';
COMMENT ON COLUMN ads_stock_overview.proj_cnt IS '涉及项目数（去重 COALESCE(proj_code,proj)）';

COMMENT ON COLUMN ads_io_daily_trend.biz_date IS '业务日期';
COMMENT ON COLUMN ads_io_daily_trend.in_qty IS '日入库总量（主数量；优先 in_main_qty）';
COMMENT ON COLUMN ads_io_daily_trend.out_qty IS '日出库总量（主数量；优先 out_main_qty）';
COMMENT ON COLUMN ads_io_daily_trend.net_in_qty IS '净流入量（主数量）=入库-出库';

COMMENT ON COLUMN ads_wh_stock_dist.wh_name IS '仓库名称';
COMMENT ON COLUMN ads_wh_stock_dist.total_onhand IS '仓库库存总量（主数量）';
COMMENT ON COLUMN ads_wh_stock_dist.total_reserved IS '仓库预留总量（主数量）';
COMMENT ON COLUMN ads_wh_stock_dist.total_frozen IS '仓库冻结总量（主数量）';
COMMENT ON COLUMN ads_wh_stock_dist.stat_time IS '统计日期';

COMMENT ON COLUMN ads_proj_stock_dist.proj_key IS '项目键（优先 proj_code；否则用 ods_stock_onhand.proj 文本）';
COMMENT ON COLUMN ads_proj_stock_dist.proj_code IS '项目编码（如导出包含）';
COMMENT ON COLUMN ads_proj_stock_dist.proj_name IS '项目名称';
COMMENT ON COLUMN ads_proj_stock_dist.total_onhand IS '项目库存总量（主数量）';
COMMENT ON COLUMN ads_proj_stock_dist.stat_time IS '统计日期';

COMMENT ON COLUMN ads_item_turnover_90d.item_code IS '物料编码';
COMMENT ON COLUMN ads_item_turnover_90d.item_name IS '物料名称';
COMMENT ON COLUMN ads_item_turnover_90d.out_qty_90d IS '90天出库量（主数量）';
COMMENT ON COLUMN ads_item_turnover_90d.in_qty_90d IS '90天入库量（主数量）';
COMMENT ON COLUMN ads_item_turnover_90d.onhand_qty IS '当前现存量（主数量；来自 ods_stock_onhand 汇总）';
COMMENT ON COLUMN ads_item_turnover_90d.turnover_rate_90d IS '周转率（90天）=90天出库量/当前现存量（近似）';
COMMENT ON COLUMN ads_item_turnover_90d.last_out_date IS '最近一次出库日期（90天窗口内）';
COMMENT ON COLUMN ads_item_turnover_90d.days_since_last_out IS '距最近一次出库天数';
COMMENT ON COLUMN ads_item_turnover_90d.stat_time IS '统计日期';

COMMENT ON COLUMN ads_proj_item_out_90d.proj_key IS '项目键（优先 proj_code；否则用 ods_stock_io_flow.proj 文本）';
COMMENT ON COLUMN ads_proj_item_out_90d.proj_code IS '项目编码（如导出包含）';
COMMENT ON COLUMN ads_proj_item_out_90d.proj_name IS '项目名称';
COMMENT ON COLUMN ads_proj_item_out_90d.item_code IS '物料编码';
COMMENT ON COLUMN ads_proj_item_out_90d.item_name IS '物料名称';
COMMENT ON COLUMN ads_proj_item_out_90d.out_qty_90d IS '90天项目出库量（主数量）';
COMMENT ON COLUMN ads_proj_item_out_90d.stat_time IS '统计日期';

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

COMMENT ON COLUMN ads_item_io_freq_topn.rank_no IS '排名（1=最高频）';
COMMENT ON COLUMN ads_item_io_freq_topn.item_code IS '物料编码';
COMMENT ON COLUMN ads_item_io_freq_topn.item_name IS '物料名称';
COMMENT ON COLUMN ads_item_io_freq_topn.txn_cnt_90d IS '90天流水次数';
COMMENT ON COLUMN ads_item_io_freq_topn.stat_time IS '统计日期';

-- 物料全链路追踪
COMMENT ON COLUMN ads_item_overview_kpi.stat_time IS '统计日期';
COMMENT ON COLUMN ads_item_overview_kpi.item_cnt IS '物料总数（mdm_item 行数）';
COMMENT ON COLUMN ads_item_overview_kpi.enabled_item_cnt IS '启用物料数（enable_flag=1）';
COMMENT ON COLUMN ads_item_overview_kpi.item_class_cnt IS '物料分类数（去重 item_class）';

COMMENT ON COLUMN ads_proj_item_onhand_edge.proj_key IS '项目键（优先 proj_code；否则 proj 文本）';
COMMENT ON COLUMN ads_proj_item_onhand_edge.proj_code IS '项目编码（如导出包含）';
COMMENT ON COLUMN ads_proj_item_onhand_edge.proj_name IS '项目名称';
COMMENT ON COLUMN ads_proj_item_onhand_edge.item_code IS '物料编码';
COMMENT ON COLUMN ads_proj_item_onhand_edge.item_name IS '物料名称';
COMMENT ON COLUMN ads_proj_item_onhand_edge.onhand_qty IS '项目-物料库存数量（主数量）';
COMMENT ON COLUMN ads_proj_item_onhand_edge.stat_time IS '统计日期';

COMMENT ON COLUMN ads_item_spec_model_stock.item_class IS '物料分类（来自 mdm_item.item_class；未知=UNKNOWN）';
COMMENT ON COLUMN ads_item_spec_model_stock.spec IS '规格（来自 mdm_item.spec；未知=UNKNOWN）';
COMMENT ON COLUMN ads_item_spec_model_stock.model IS '型号（来自 mdm_item.model；未知=UNKNOWN）';
COMMENT ON COLUMN ads_item_spec_model_stock.total_onhand IS '库存数量（主数量）';
COMMENT ON COLUMN ads_item_spec_model_stock.stat_time IS '统计日期';

COMMENT ON COLUMN ads_item_price_month.item_code IS '物料编码';
COMMENT ON COLUMN ads_item_price_month.ym IS '月份（YYYY-MM）';
COMMENT ON COLUMN ads_item_price_month.avg_price_nt IS '平均无税单价';
COMMENT ON COLUMN ads_item_price_month.min_price_nt IS '最低无税单价';
COMMENT ON COLUMN ads_item_price_month.max_price_nt IS '最高无税单价';

COMMIT;

