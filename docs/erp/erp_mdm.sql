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

-- ============================================================
-- ODS -> MDM 构建脚本（可按需定期执行：建议 truncate+merge 或直接 merge）
-- ============================================================

-- 1) 项目维表：汇总多个 ODS 来源
-- 说明：当前 ERP 导出为“中间表”，项目编码/名称在多张 ODS 表中已包含，因此不依赖 ods_proj_base_info。
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
    FROM ods_proj_budget_exec_dtl
    UNION ALL
    SELECT proj_code, proj_name, NULL AS parent_proj_code, NULL AS parent_proj_name
    FROM ods_po_exec
    UNION ALL
    SELECT
      proj_code AS proj_code,
      COALESCE(proj_name, proj) AS proj_name,
      NULL AS parent_proj_code,
      NULL AS parent_proj_name
    FROM ods_stock_io_flow
    UNION ALL
    SELECT
      proj_code AS proj_code,
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

-- 2) 物料维表：汇总多个 ODS 来源
-- 说明：当前 ERP 导出为“中间表”，物料编码/名称/规格型号等在多张 ODS 表中已包含，因此不依赖 ods_item_master。
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
    SELECT item_code, item_name, NULL AS item_class, spec, model, uom AS base_uom, NULL AS enable_status
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
