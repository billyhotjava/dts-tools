-- ODS -> MDM 构建脚本（来源：docs/erp/erp_mdm.sql）

-- 1) 项目维表：汇总多个 ODS 来源，优先用 ods_proj_base_info 的父子/名称信息
MERGE INTO mdm_project t
USING (
  SELECT
    proj_code,
    MAX(proj_name) AS proj_name,
    MAX(parent_proj_code) AS parent_proj_code,
    MAX(parent_proj_name) AS parent_proj_name
  FROM (
    SELECT
      proj_code,
      proj_name,
      parent_proj_code,
      parent_proj_name
    FROM ods_proj_base_info
    UNION ALL
    SELECT
      proj_code,
      proj_name,
      parent_proj_code,
      parent_proj_name
    FROM ods_proj_budget_exec_dtl
    UNION ALL
    SELECT proj_code, proj_name, NULL AS parent_proj_code, NULL AS parent_proj_name
    FROM ods_po_exec
    UNION ALL
    SELECT
      COALESCE(proj_code, proj) AS proj_code,
      COALESCE(proj_name, proj) AS proj_name,
      NULL AS parent_proj_code,
      NULL AS parent_proj_name
    FROM ods_stock_io_flow
    UNION ALL
    SELECT
      COALESCE(proj_code, proj) AS proj_code,
      COALESCE(proj_name, proj) AS proj_name,
      NULL AS parent_proj_code,
      NULL AS parent_proj_name
    FROM ods_stock_onhand
  ) x
  WHERE proj_code IS NOT NULL
  GROUP BY proj_code
) s
ON (t.proj_code = s.proj_code)
WHEN MATCHED THEN
  UPDATE SET
    t.proj_name        = COALESCE(s.proj_name, t.proj_name),
    t.parent_proj_code = COALESCE(s.parent_proj_code, t.parent_proj_code),
    t.parent_proj_name = COALESCE(s.parent_proj_name, t.parent_proj_name),
    t.is_active        = 1
WHEN NOT MATCHED THEN
  INSERT (
    proj_code, proj_name, parent_proj_code, parent_proj_name, proj_level, proj_path, is_active
  )
  VALUES (
    s.proj_code, s.proj_name, s.parent_proj_code, s.parent_proj_name, NULL, NULL, 1
  );

-- 2) 物料维表：优先 ods_item_master，其它 ODS 作为补充（规格/型号/单位）
MERGE INTO mdm_item t
USING (
  SELECT
    item_code,
    MAX(item_name) AS item_name,
    MAX(item_class) AS item_class,
    MAX(spec) AS spec,
    MAX(model) AS model,
    MAX(base_uom) AS base_uom,
    MAX(enable_status) AS enable_status,
    MAX(
      CASE
        WHEN enable_status IN ('已启用', '启用', 'Y', '是', '1', 'true', 'TRUE') THEN 1
        WHEN enable_status IN ('未启用', '禁用', 'N', '否', '0', 'false', 'FALSE') THEN 0
        ELSE NULL
      END
    ) AS enable_flag
  FROM (
    SELECT item_code, item_name, item_class, spec, model, base_uom, enable_status
    FROM ods_item_master
    UNION ALL
    SELECT item_code, item_name, NULL AS item_class, spec, model, uom AS base_uom, NULL AS enable_status
    FROM ods_po_exec
    UNION ALL
    SELECT
      item_code,
      item_name,
      NULL AS item_class,
      spec,
      model,
      COALESCE(main_uom, uom) AS base_uom,
      NULL AS enable_status
    FROM ods_stock_io_flow
    UNION ALL
    SELECT
      item_code,
      item_name,
      NULL AS item_class,
      spec,
      model,
      uom AS base_uom,
      NULL AS enable_status
    FROM ods_stock_onhand
  ) x
  WHERE item_code IS NOT NULL
  GROUP BY item_code
) s
ON (t.item_code = s.item_code)
WHEN MATCHED THEN
  UPDATE SET
    t.item_name     = COALESCE(s.item_name, t.item_name),
    t.item_class    = COALESCE(s.item_class, t.item_class),
    t.spec          = COALESCE(s.spec, t.spec),
    t.model         = COALESCE(s.model, t.model),
    t.base_uom      = COALESCE(s.base_uom, t.base_uom),
    t.enable_status = COALESCE(s.enable_status, t.enable_status),
    t.enable_flag   = COALESCE(s.enable_flag, t.enable_flag)
WHEN NOT MATCHED THEN
  INSERT (
    item_code, item_name, item_class, spec, model, base_uom, enable_flag, enable_status
  )
  VALUES (
    s.item_code, s.item_name, s.item_class, s.spec, s.model, s.base_uom, s.enable_flag, s.enable_status
  );

-- 3) 预算分类维表
MERGE INTO mdm_proj_budget_cat t
USING (
  SELECT
    proj_budget_cat_code AS cat_code,
    MAX(proj_budget_cat_name) AS cat_name
  FROM ods_proj_budget_exec_dtl
  WHERE proj_budget_cat_code IS NOT NULL
  GROUP BY proj_budget_cat_code
) s
ON (t.cat_code = s.cat_code)
WHEN MATCHED THEN
  UPDATE SET t.cat_name = COALESCE(s.cat_name, t.cat_name)
WHEN NOT MATCHED THEN
  INSERT (cat_code, cat_name)
  VALUES (s.cat_code, s.cat_name);

COMMIT;
