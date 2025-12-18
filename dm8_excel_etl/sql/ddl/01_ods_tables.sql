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

-- ODS-项目基本信息
CREATE TABLE ods_proj_base_info (
  id               BIGINT IDENTITY(1,1) NOT NULL,
  parent_proj_code VARCHAR2(50),
  parent_proj_name VARCHAR2(200),
  proj_code        VARCHAR2(50) NOT NULL,
  proj_name        VARCHAR2(200),
  creator          VARCHAR2(100),
  etl_time         TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT pk_ods_proj_base_info PRIMARY KEY (id)
);

COMMENT ON TABLE ods_proj_base_info IS 'ODS-项目基本信息';
COMMENT ON COLUMN ods_proj_base_info.parent_proj_code IS '父项目编码：1、大部分项目都有多个层级，也有单个层级的项目（无父级项目和子项目）；2、层级不固定，一般分为项目（顶层）-分系统（第二层）-单机（第三层）-物料（第四层）。';
COMMENT ON COLUMN ods_proj_base_info.parent_proj_name IS '父项目名称';
COMMENT ON COLUMN ods_proj_base_info.proj_code        IS '项目编码';
COMMENT ON COLUMN ods_proj_base_info.proj_name        IS '项目名称';
COMMENT ON COLUMN ods_proj_base_info.creator          IS '创建人';
COMMENT ON COLUMN ods_proj_base_info.etl_time         IS 'ETL时间';

CREATE UNIQUE INDEX uk_ods_proj_code ON ods_proj_base_info(proj_code);
CREATE INDEX idx_ods_proj_parent ON ods_proj_base_info(parent_proj_code);

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

-- ODS-物料主数据
CREATE TABLE ods_item_master (
  id            BIGINT IDENTITY(1,1) NOT NULL,
  item_code     VARCHAR2(80) NOT NULL,
  item_name     VARCHAR2(300),
  item_class    VARCHAR2(50),
  spec          VARCHAR2(200),
  model         VARCHAR2(200),
  base_uom      VARCHAR2(50),
  enable_status VARCHAR2(50),
  etl_time      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT pk_ods_item_master PRIMARY KEY (id)
);

COMMENT ON TABLE ods_item_master IS 'ODS-物料主数据';
COMMENT ON COLUMN ods_item_master.item_code      IS '物料编码';
COMMENT ON COLUMN ods_item_master.item_name      IS '物料名称';
COMMENT ON COLUMN ods_item_master.item_class     IS '物料分类：物料分为大类、小类、细类三类，物料分类码说明：01001001，前两位数字01代表材料，中间三位001代表金属材料，后三位001代表黑色金属材料。';
COMMENT ON COLUMN ods_item_master.spec           IS '规格';
COMMENT ON COLUMN ods_item_master.model          IS '型号';
COMMENT ON COLUMN ods_item_master.base_uom       IS '主计量单位';
COMMENT ON COLUMN ods_item_master.enable_status  IS '启用状态：已启用、未启用';
COMMENT ON COLUMN ods_item_master.etl_time       IS 'ETL时间';

CREATE UNIQUE INDEX uk_ods_item_code ON ods_item_master(item_code);
