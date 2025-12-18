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

