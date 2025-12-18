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
