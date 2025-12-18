-- ODS/MDM -> ADS 刷新脚本（来源：docs/erp/erp_ads.sql）
-- 建议：全量导入场景下，ADS 采用 truncate + rebuild

-- ============================================================================
-- 大屏 1：预算与采购监控
-- ============================================================================

-- 1.1 预算与采购总览 KPI（全局 1 行）
TRUNCATE TABLE ads_budget_overview_kpi;
INSERT INTO ads_budget_overview_kpi (
  stat_time,
  budget_amt,
  exec_amt,
  hist_exec_amt,
  actual_exec_amt,
  preoccupy_amt,
  exec_rate,
  actual_exec_rate,
  preoccupy_rate,
  remain_budget,
  remain_budget_actual,
  remain_budget_after_preoccupy,
  po_amt_tax,
  proj_cnt,
  dept_cnt
)
SELECT
  CURRENT_DATE AS stat_time,
  SUM(NVL(b.budget_amt, 0)) AS budget_amt,
  SUM(NVL(b.exec_amt, 0)) AS exec_amt,
  SUM(NVL(b.hist_exec_amt, 0)) AS hist_exec_amt,
  SUM(NVL(b.exec_amt, 0) + NVL(b.hist_exec_amt, 0)) AS actual_exec_amt,
  SUM(NVL(b.adjust_amt, 0)) AS preoccupy_amt,
  CASE
    WHEN SUM(NVL(b.budget_amt, 0)) = 0 THEN NULL
    ELSE ROUND(SUM(NVL(b.exec_amt, 0)) / SUM(NVL(b.budget_amt, 0)) * 100, 2)
  END AS exec_rate,
  CASE
    WHEN SUM(NVL(b.budget_amt, 0)) = 0 THEN NULL
    ELSE ROUND(SUM(NVL(b.exec_amt, 0) + NVL(b.hist_exec_amt, 0)) / SUM(NVL(b.budget_amt, 0)) * 100, 2)
  END AS actual_exec_rate,
  CASE
    WHEN SUM(NVL(b.budget_amt, 0)) = 0 THEN NULL
    ELSE ROUND(SUM(NVL(b.adjust_amt, 0)) / SUM(NVL(b.budget_amt, 0)) * 100, 2)
  END AS preoccupy_rate,
  SUM(NVL(b.budget_amt, 0)) - SUM(NVL(b.exec_amt, 0)) AS remain_budget,
  SUM(NVL(b.budget_amt, 0)) - SUM(NVL(b.exec_amt, 0) + NVL(b.hist_exec_amt, 0)) AS remain_budget_actual,
  SUM(NVL(b.budget_amt, 0)) - SUM(NVL(b.exec_amt, 0)) - SUM(NVL(b.adjust_amt, 0)) AS remain_budget_after_preoccupy,
  (SELECT SUM(NVL(p.amt_tax, 0)) FROM ods_po_exec p) AS po_amt_tax,
  COUNT(DISTINCT b.proj_code) AS proj_cnt,
  COUNT(DISTINCT b.resp_dept) AS dept_cnt
FROM ods_proj_budget_exec_dtl b
WHERE b.proj_code IS NOT NULL;

-- 1.2 项目预算 KPI（项目粒度，含预算/执行/预占/采购对比）
TRUNCATE TABLE ads_proj_budget_kpi;
INSERT INTO ads_proj_budget_kpi (
  proj_code,
  proj_name,
  budget_amt,
  exec_amt,
  hist_exec_amt,
  actual_exec_amt,
  preoccupy_amt,
  exec_rate,
  actual_exec_rate,
  preoccupy_rate,
  remain_budget,
  remain_budget_actual,
  remain_budget_after_preoccupy,
  po_amt_tax,
  po_budget_var_rate,
  stat_time
)
SELECT
  p.proj_code,
  COALESCE(mp.proj_name, MAX(p.proj_name)) AS proj_name,
  SUM(NVL(p.budget_amt, 0)) AS budget_amt,
  SUM(NVL(p.exec_amt, 0)) AS exec_amt,
  SUM(NVL(p.hist_exec_amt, 0)) AS hist_exec_amt,
  SUM(NVL(p.exec_amt, 0) + NVL(p.hist_exec_amt, 0)) AS actual_exec_amt,
  SUM(NVL(p.adjust_amt, 0)) AS preoccupy_amt,
  CASE
    WHEN SUM(NVL(p.budget_amt, 0)) = 0 THEN NULL
    ELSE ROUND(SUM(NVL(p.exec_amt, 0)) / SUM(NVL(p.budget_amt, 0)) * 100, 2)
  END AS exec_rate,
  CASE
    WHEN SUM(NVL(p.budget_amt, 0)) = 0 THEN NULL
    ELSE ROUND(SUM(NVL(p.exec_amt, 0) + NVL(p.hist_exec_amt, 0)) / SUM(NVL(p.budget_amt, 0)) * 100, 2)
  END AS actual_exec_rate,
  CASE
    WHEN SUM(NVL(p.budget_amt, 0)) = 0 THEN NULL
    ELSE ROUND(SUM(NVL(p.adjust_amt, 0)) / SUM(NVL(p.budget_amt, 0)) * 100, 2)
  END AS preoccupy_rate,
  SUM(NVL(p.budget_amt, 0)) - SUM(NVL(p.exec_amt, 0)) AS remain_budget,
  SUM(NVL(p.budget_amt, 0)) - SUM(NVL(p.exec_amt, 0) + NVL(p.hist_exec_amt, 0)) AS remain_budget_actual,
  SUM(NVL(p.budget_amt, 0)) - SUM(NVL(p.exec_amt, 0)) - SUM(NVL(p.adjust_amt, 0)) AS remain_budget_after_preoccupy,
  NVL(po.po_amt_tax, 0) AS po_amt_tax,
  CASE
    WHEN SUM(NVL(p.budget_amt, 0)) = 0 THEN NULL
    ELSE ROUND((NVL(po.po_amt_tax, 0) - SUM(NVL(p.budget_amt, 0))) / SUM(NVL(p.budget_amt, 0)) * 100, 2)
  END AS po_budget_var_rate,
  CURRENT_DATE AS stat_time
FROM ods_proj_budget_exec_dtl p
LEFT JOIN mdm_project mp ON mp.proj_code = p.proj_code
LEFT JOIN (
  SELECT proj_code, SUM(NVL(amt_tax, 0)) AS po_amt_tax
  FROM ods_po_exec
  WHERE proj_code IS NOT NULL
  GROUP BY proj_code
) po ON po.proj_code = p.proj_code
WHERE p.proj_code IS NOT NULL
GROUP BY p.proj_code, mp.proj_name, po.po_amt_tax;

-- 1.3 部门预算分析（按责任部门）
TRUNCATE TABLE ads_dept_budget_kpi;
INSERT INTO ads_dept_budget_kpi (
  resp_dept,
  budget_amt,
  exec_amt,
  hist_exec_amt,
  actual_exec_amt,
  preoccupy_amt,
  exec_rate,
  budget_share,
  stat_time
)
WITH dept_agg AS (
  SELECT
    resp_dept,
    SUM(NVL(budget_amt, 0)) AS budget_amt,
    SUM(NVL(exec_amt, 0)) AS exec_amt,
    SUM(NVL(hist_exec_amt, 0)) AS hist_exec_amt,
    SUM(NVL(exec_amt, 0) + NVL(hist_exec_amt, 0)) AS actual_exec_amt,
    SUM(NVL(adjust_amt, 0)) AS preoccupy_amt
  FROM ods_proj_budget_exec_dtl
  WHERE resp_dept IS NOT NULL
  GROUP BY resp_dept
),
total_agg AS (
  SELECT SUM(NVL(budget_amt, 0)) AS total_budget
  FROM ods_proj_budget_exec_dtl
)
SELECT
  d.resp_dept,
  d.budget_amt,
  d.exec_amt,
  d.hist_exec_amt,
  d.actual_exec_amt,
  d.preoccupy_amt,
  CASE
    WHEN d.budget_amt = 0 THEN NULL
    ELSE ROUND(d.exec_amt / d.budget_amt * 100, 2)
  END AS exec_rate,
  CASE
    WHEN t.total_budget = 0 THEN NULL
    ELSE ROUND(d.budget_amt / t.total_budget * 100, 2)
  END AS budget_share,
  CURRENT_DATE AS stat_time
FROM dept_agg d
CROSS JOIN total_agg t;

-- 1.4 采购月趋势（按月）
TRUNCATE TABLE ads_po_month_trend;
INSERT INTO ads_po_month_trend (ym, po_amt_tax, po_qty, recv_qty, recv_rate)
SELECT
  TO_CHAR(order_date, 'YYYY-MM') AS ym,
  SUM(NVL(amt_tax, 0)) AS po_amt_tax,
  SUM(NVL(qty, 0)) AS po_qty,
  SUM(NVL(recv_qty, 0)) AS recv_qty,
  CASE
    WHEN SUM(NVL(qty, 0)) = 0 THEN NULL
    ELSE ROUND(SUM(NVL(recv_qty, 0)) / SUM(NVL(qty, 0)) * 100, 2)
  END AS recv_rate
FROM ods_po_exec
WHERE order_date IS NOT NULL
GROUP BY TO_CHAR(order_date, 'YYYY-MM');

-- 1.5 供应商采购 TOP10（全量快照）
TRUNCATE TABLE ads_supplier_top10;
INSERT INTO ads_supplier_top10 (supplier_name, po_amt_tax, po_cnt, rank_no, stat_time)
SELECT
  supplier_name,
  po_amt_tax,
  po_cnt,
  rank_no,
  CURRENT_DATE AS stat_time
FROM (
  SELECT
    supplier_name,
    SUM(NVL(amt_tax, 0)) AS po_amt_tax,
    COUNT(1) AS po_cnt,
    ROW_NUMBER() OVER (ORDER BY SUM(NVL(amt_tax, 0)) DESC) AS rank_no
  FROM ods_po_exec
  WHERE supplier_name IS NOT NULL
  GROUP BY supplier_name
) x
WHERE x.rank_no <= 10;

-- 1.6 物料分类采购分布（全量快照）
TRUNCATE TABLE ads_item_class_po_dist;
INSERT INTO ads_item_class_po_dist (item_class, po_amt_tax, po_cnt, stat_time)
SELECT
  COALESCE(mi.item_class, 'UNKNOWN') AS item_class,
  SUM(NVL(p.amt_tax, 0)) AS po_amt_tax,
  COUNT(1) AS po_cnt,
  CURRENT_DATE AS stat_time
FROM ods_po_exec p
LEFT JOIN mdm_item mi ON mi.item_code = p.item_code
GROUP BY COALESCE(mi.item_class, 'UNKNOWN');

-- 1.7 采购金额链路（桑基图，按月，金额口径）
TRUNCATE TABLE ads_po_amount_flow_month;
INSERT INTO ads_po_amount_flow_month (ym, source_node, target_node, amt, stat_time)
SELECT
  ym,
  source_node,
  target_node,
  amt,
  CURRENT_DATE AS stat_time
FROM (
  WITH m AS (
    SELECT
      TO_CHAR(order_date, 'YYYY-MM') AS ym,
      SUM(NVL(amt_tax, 0)) AS order_amt_tax,
      SUM(NVL(recv_qty, 0) * NVL(unit_price_tax, 0)) AS recv_amt_tax,
      SUM(NVL(in_amt, 0)) AS in_amt,
      SUM(NVL(invoice_amt_tax_local, 0)) AS invoice_amt_tax_local
    FROM ods_po_exec
    WHERE order_date IS NOT NULL
    GROUP BY TO_CHAR(order_date, 'YYYY-MM')
  )
  SELECT ym, '订单金额' AS source_node, '到货金额' AS target_node, recv_amt_tax AS amt FROM m
  UNION ALL
  SELECT ym, '到货金额' AS source_node, '入库金额' AS target_node, in_amt AS amt FROM m
  UNION ALL
  SELECT ym, '入库金额' AS source_node, '开票金额' AS target_node, invoice_amt_tax_local AS amt FROM m
  UNION ALL
  SELECT
    ym,
    '订单金额' AS source_node,
    '未到货金额' AS target_node,
    CASE WHEN order_amt_tax - recv_amt_tax < 0 THEN 0 ELSE order_amt_tax - recv_amt_tax END AS amt
  FROM m
  UNION ALL
  SELECT
    ym,
    '到货金额' AS source_node,
    '未入库金额' AS target_node,
    CASE WHEN recv_amt_tax - in_amt < 0 THEN 0 ELSE recv_amt_tax - in_amt END AS amt
  FROM m
  UNION ALL
  SELECT
    ym,
    '入库金额' AS source_node,
    '未开票金额' AS target_node,
    CASE WHEN in_amt - invoice_amt_tax_local < 0 THEN 0 ELSE in_amt - invoice_amt_tax_local END AS amt
  FROM m
) e
WHERE e.amt IS NOT NULL AND e.amt > 0;

-- 1.8 物料采购金额链路（桑基图，按月，物料粒度）
TRUNCATE TABLE ads_item_amount_flow_month;
INSERT INTO ads_item_amount_flow_month (ym, item_code, item_name, source_node, target_node, amt, stat_time)
SELECT
  ym,
  item_code,
  item_name,
  source_node,
  target_node,
  amt,
  CURRENT_DATE AS stat_time
FROM (
  WITH m AS (
    SELECT
      TO_CHAR(order_date, 'YYYY-MM') AS ym,
      p.item_code,
      MAX(COALESCE(mi.item_name, p.item_name)) AS item_name,
      SUM(NVL(p.amt_tax, 0)) AS order_amt_tax,
      SUM(NVL(p.recv_qty, 0) * NVL(p.unit_price_tax, 0)) AS recv_amt_tax,
      SUM(NVL(p.in_amt, 0)) AS in_amt,
      SUM(NVL(p.invoice_amt_tax_local, 0)) AS invoice_amt_tax_local
    FROM ods_po_exec p
    LEFT JOIN mdm_item mi ON mi.item_code = p.item_code
    WHERE p.order_date IS NOT NULL
      AND p.item_code IS NOT NULL
    GROUP BY TO_CHAR(order_date, 'YYYY-MM'), p.item_code
  )
  SELECT ym, item_code, item_name, '订单金额' AS source_node, '到货金额' AS target_node, recv_amt_tax AS amt FROM m
  UNION ALL
  SELECT ym, item_code, item_name, '到货金额' AS source_node, '入库金额' AS target_node, in_amt AS amt FROM m
  UNION ALL
  SELECT ym, item_code, item_name, '入库金额' AS source_node, '开票金额' AS target_node, invoice_amt_tax_local AS amt FROM m
  UNION ALL
  SELECT
    ym,
    item_code,
    item_name,
    '订单金额' AS source_node,
    '未到货金额' AS target_node,
    CASE WHEN order_amt_tax - recv_amt_tax < 0 THEN 0 ELSE order_amt_tax - recv_amt_tax END AS amt
  FROM m
  UNION ALL
  SELECT
    ym,
    item_code,
    item_name,
    '到货金额' AS source_node,
    '未入库金额' AS target_node,
    CASE WHEN recv_amt_tax - in_amt < 0 THEN 0 ELSE recv_amt_tax - in_amt END AS amt
  FROM m
  UNION ALL
  SELECT
    ym,
    item_code,
    item_name,
    '入库金额' AS source_node,
    '未开票金额' AS target_node,
    CASE WHEN in_amt - invoice_amt_tax_local < 0 THEN 0 ELSE in_amt - invoice_amt_tax_local END AS amt
  FROM m
) e
WHERE e.amt IS NOT NULL AND e.amt > 0;

-- ============================================================================
-- 大屏 2：库存与出入库
-- ============================================================================

-- 2.1 库存总览（当前快照）
TRUNCATE TABLE ads_stock_overview;
INSERT INTO ads_stock_overview (stat_date, item_cnt, total_onhand, total_reserved, total_frozen, proj_cnt)
SELECT
  CURRENT_DATE AS stat_date,
  COUNT(DISTINCT item_code) AS item_cnt,
  SUM(NVL(onhand_qty, 0)) AS total_onhand,
  SUM(NVL(reserved_qty, 0)) AS total_reserved,
  SUM(NVL(frozen_qty, 0)) AS total_frozen,
  COUNT(DISTINCT COALESCE(proj_code, proj)) AS proj_cnt
FROM ods_stock_onhand;

-- 2.2 出入库日趋势
TRUNCATE TABLE ads_io_daily_trend;
INSERT INTO ads_io_daily_trend (biz_date, in_qty, out_qty, net_in_qty)
SELECT
  biz_date,
  SUM(NVL(COALESCE(in_main_qty, in_qty), 0)) AS in_qty,
  SUM(NVL(COALESCE(out_main_qty, out_qty), 0)) AS out_qty,
  SUM(NVL(COALESCE(in_main_qty, in_qty), 0)) - SUM(NVL(COALESCE(out_main_qty, out_qty), 0)) AS net_in_qty
FROM ods_stock_io_flow
WHERE biz_date IS NOT NULL
GROUP BY biz_date;

-- 2.3 仓库库存分布
TRUNCATE TABLE ads_wh_stock_dist;
INSERT INTO ads_wh_stock_dist (wh_name, total_onhand, total_reserved, total_frozen, stat_time)
SELECT
  wh_name,
  SUM(NVL(onhand_qty, 0)) AS total_onhand,
  SUM(NVL(reserved_qty, 0)) AS total_reserved,
  SUM(NVL(frozen_qty, 0)) AS total_frozen,
  CURRENT_DATE AS stat_time
FROM ods_stock_onhand
WHERE wh_name IS NOT NULL
GROUP BY wh_name;

-- 2.4 项目库存分布（proj_key）
TRUNCATE TABLE ads_proj_stock_dist;
INSERT INTO ads_proj_stock_dist (proj_key, proj_code, proj_name, total_onhand, stat_time)
SELECT
  COALESCE(s.proj_code, s.proj) AS proj_key,
  CASE WHEN s.proj_code IS NOT NULL THEN s.proj_code ELSE NULL END AS proj_code,
  COALESCE(mp.proj_name, s.proj_name, s.proj) AS proj_name,
  SUM(NVL(s.onhand_qty, 0)) AS total_onhand,
  CURRENT_DATE AS stat_time
FROM ods_stock_onhand s
LEFT JOIN mdm_project mp ON mp.proj_code = s.proj_code
WHERE COALESCE(s.proj_code, s.proj) IS NOT NULL
GROUP BY COALESCE(s.proj_code, s.proj),
         CASE WHEN s.proj_code IS NOT NULL THEN s.proj_code ELSE NULL END,
         COALESCE(mp.proj_name, s.proj_name, s.proj);

-- 2.5 物料周转（90天，数量口径；近似：90天出库/当前现存）
TRUNCATE TABLE ads_item_turnover_90d;
INSERT INTO ads_item_turnover_90d (
  item_code,
  item_name,
  out_qty_90d,
  in_qty_90d,
  onhand_qty,
  turnover_rate_90d,
  last_out_date,
  days_since_last_out,
  stat_time
)
WITH io90 AS (
  SELECT
    item_code,
    MAX(item_name) AS item_name,
    SUM(NVL(COALESCE(out_main_qty, out_qty), 0)) AS out_qty_90d,
    SUM(NVL(COALESCE(in_main_qty, in_qty), 0)) AS in_qty_90d,
    MAX(CASE WHEN NVL(COALESCE(out_main_qty, out_qty), 0) > 0 THEN biz_date ELSE NULL END) AS last_out_date
  FROM ods_stock_io_flow
  WHERE biz_date IS NOT NULL
    AND biz_date >= CURRENT_DATE - 90
    AND item_code IS NOT NULL
  GROUP BY item_code
),
onh AS (
  SELECT item_code, SUM(NVL(onhand_qty, 0)) AS onhand_qty
  FROM ods_stock_onhand
  WHERE item_code IS NOT NULL
  GROUP BY item_code
)
SELECT
  i.item_code,
  COALESCE(mi.item_name, i.item_name) AS item_name,
  i.out_qty_90d,
  i.in_qty_90d,
  NVL(o.onhand_qty, 0) AS onhand_qty,
  CASE
    WHEN NVL(o.onhand_qty, 0) = 0 THEN NULL
    ELSE ROUND(i.out_qty_90d / o.onhand_qty, 4)
  END AS turnover_rate_90d,
  i.last_out_date,
  CASE
    WHEN i.last_out_date IS NULL THEN NULL
    ELSE (CURRENT_DATE - i.last_out_date)
  END AS days_since_last_out,
  CURRENT_DATE AS stat_time
FROM io90 i
LEFT JOIN onh o ON o.item_code = i.item_code
LEFT JOIN mdm_item mi ON mi.item_code = i.item_code;

-- 2.6 项目用料结构（90天出库，项目+物料）
TRUNCATE TABLE ads_proj_item_out_90d;
INSERT INTO ads_proj_item_out_90d (
  proj_key,
  proj_code,
  proj_name,
  item_code,
  item_name,
  out_qty_90d,
  stat_time
)
SELECT
  COALESCE(f.proj_code, f.proj) AS proj_key,
  CASE WHEN f.proj_code IS NOT NULL THEN f.proj_code ELSE NULL END AS proj_code,
  COALESCE(mp.proj_name, f.proj_name, f.proj) AS proj_name,
  f.item_code,
  MAX(COALESCE(mi.item_name, f.item_name)) AS item_name,
  SUM(NVL(COALESCE(f.out_main_qty, f.out_qty), 0)) AS out_qty_90d,
  CURRENT_DATE AS stat_time
FROM ods_stock_io_flow f
LEFT JOIN mdm_project mp ON mp.proj_code = f.proj_code
LEFT JOIN mdm_item mi ON mi.item_code = f.item_code
WHERE f.biz_date IS NOT NULL
  AND f.biz_date >= CURRENT_DATE - 90
  AND COALESCE(f.proj_code, f.proj) IS NOT NULL
  AND f.item_code IS NOT NULL
GROUP BY
  COALESCE(f.proj_code, f.proj),
  CASE WHEN f.proj_code IS NOT NULL THEN f.proj_code ELSE NULL END,
  COALESCE(mp.proj_name, f.proj_name, f.proj),
  f.item_code;

-- 2.7 异常出入库：大额记录 TOPN（90天，数量口径）
TRUNCATE TABLE ads_io_large_txn_topn;
INSERT INTO ads_io_large_txn_topn (
  rank_no,
  biz_date,
  direction,
  io_type,
  doc_no,
  wh_name,
  proj_key,
  item_code,
  item_name,
  qty,
  stat_time
)
SELECT
  rank_no,
  biz_date,
  direction,
  io_type,
  doc_no,
  wh_name,
  proj_key,
  item_code,
  item_name,
  qty,
  CURRENT_DATE AS stat_time
FROM (
  SELECT
    ROW_NUMBER() OVER (ORDER BY qty DESC) AS rank_no,
    biz_date,
    direction,
    io_type,
    doc_no,
    wh_name,
    proj_key,
    item_code,
    item_name,
    qty
  FROM (
    SELECT
      f.biz_date,
      'IN' AS direction,
      f.io_type,
      f.doc_no,
      f.wh_name,
      COALESCE(f.proj_code, f.proj) AS proj_key,
      f.item_code,
      f.item_name,
      ABS(NVL(COALESCE(f.in_main_qty, f.in_qty), 0)) AS qty
    FROM ods_stock_io_flow f
    WHERE f.biz_date IS NOT NULL
      AND f.biz_date >= CURRENT_DATE - 90
      AND NVL(COALESCE(f.in_main_qty, f.in_qty), 0) <> 0
    UNION ALL
    SELECT
      f.biz_date,
      'OUT' AS direction,
      f.io_type,
      f.doc_no,
      f.wh_name,
      COALESCE(f.proj_code, f.proj) AS proj_key,
      f.item_code,
      f.item_name,
      ABS(NVL(COALESCE(f.out_main_qty, f.out_qty), 0)) AS qty
    FROM ods_stock_io_flow f
    WHERE f.biz_date IS NOT NULL
      AND f.biz_date >= CURRENT_DATE - 90
      AND NVL(COALESCE(f.out_main_qty, f.out_qty), 0) <> 0
  ) u
) x
WHERE x.rank_no <= 100;

-- 2.8 异常出入库：高频物料 TOPN（90天，按流水次数）
TRUNCATE TABLE ads_item_io_freq_topn;
INSERT INTO ads_item_io_freq_topn (rank_no, item_code, item_name, txn_cnt_90d, stat_time)
SELECT
  rank_no,
  item_code,
  item_name,
  txn_cnt_90d,
  CURRENT_DATE AS stat_time
FROM (
  SELECT
    f.item_code,
    MAX(COALESCE(mi.item_name, f.item_name)) AS item_name,
    COUNT(1) AS txn_cnt_90d,
    ROW_NUMBER() OVER (ORDER BY COUNT(1) DESC) AS rank_no
  FROM ods_stock_io_flow f
  LEFT JOIN mdm_item mi ON mi.item_code = f.item_code
  WHERE f.biz_date IS NOT NULL
    AND f.biz_date >= CURRENT_DATE - 90
    AND f.item_code IS NOT NULL
  GROUP BY f.item_code
) x
WHERE x.rank_no <= 100;

-- ============================================================================
-- 大屏 3：物料全链路追踪
-- ============================================================================

-- 3.1 物料总览 KPI（全局 1 行）
TRUNCATE TABLE ads_item_overview_kpi;
INSERT INTO ads_item_overview_kpi (stat_time, item_cnt, enabled_item_cnt, item_class_cnt)
SELECT
  CURRENT_DATE AS stat_time,
  COUNT(1) AS item_cnt,
  SUM(CASE WHEN enable_flag = 1 THEN 1 ELSE 0 END) AS enabled_item_cnt,
  COUNT(DISTINCT item_class) AS item_class_cnt
FROM mdm_item;

-- 3.2 采购→价格追踪（按月）已在 ads_item_price_month
TRUNCATE TABLE ads_item_price_month;
INSERT INTO ads_item_price_month (item_code, ym, avg_price_nt, min_price_nt, max_price_nt)
SELECT
  item_code,
  TO_CHAR(order_date, 'YYYY-MM') AS ym,
  ROUND(AVG(NVL(unit_price_nt, 0)), 4) AS avg_price_nt,
  MIN(unit_price_nt) AS min_price_nt,
  MAX(unit_price_nt) AS max_price_nt
FROM ods_po_exec
WHERE item_code IS NOT NULL
  AND order_date IS NOT NULL
  AND unit_price_nt IS NOT NULL
GROUP BY item_code, TO_CHAR(order_date, 'YYYY-MM');

-- 3.3 库存→项目关联（网络图边）
TRUNCATE TABLE ads_proj_item_onhand_edge;
INSERT INTO ads_proj_item_onhand_edge (
  proj_key,
  proj_code,
  proj_name,
  item_code,
  item_name,
  onhand_qty,
  stat_time
)
SELECT
  COALESCE(s.proj_code, s.proj) AS proj_key,
  CASE WHEN s.proj_code IS NOT NULL THEN s.proj_code ELSE NULL END AS proj_code,
  COALESCE(mp.proj_name, s.proj_name, s.proj) AS proj_name,
  s.item_code,
  MAX(COALESCE(mi.item_name, s.item_name)) AS item_name,
  SUM(NVL(s.onhand_qty, 0)) AS onhand_qty,
  CURRENT_DATE AS stat_time
FROM ods_stock_onhand s
LEFT JOIN mdm_project mp ON mp.proj_code = s.proj_code
LEFT JOIN mdm_item mi ON mi.item_code = s.item_code
WHERE COALESCE(s.proj_code, s.proj) IS NOT NULL
  AND s.item_code IS NOT NULL
GROUP BY
  COALESCE(s.proj_code, s.proj),
  CASE WHEN s.proj_code IS NOT NULL THEN s.proj_code ELSE NULL END,
  COALESCE(mp.proj_name, s.proj_name, s.proj),
  s.item_code;

-- 3.4 规格型号库存分析（分类/规格/型号）
TRUNCATE TABLE ads_item_spec_model_stock;
INSERT INTO ads_item_spec_model_stock (item_class, spec, model, total_onhand, stat_time)
SELECT
  COALESCE(mi.item_class, 'UNKNOWN') AS item_class,
  COALESCE(mi.spec, 'UNKNOWN') AS spec,
  COALESCE(mi.model, 'UNKNOWN') AS model,
  SUM(NVL(s.onhand_qty, 0)) AS total_onhand,
  CURRENT_DATE AS stat_time
FROM ods_stock_onhand s
LEFT JOIN mdm_item mi ON mi.item_code = s.item_code
GROUP BY
  COALESCE(mi.item_class, 'UNKNOWN'),
  COALESCE(mi.spec, 'UNKNOWN'),
  COALESCE(mi.model, 'UNKNOWN');

COMMIT;
