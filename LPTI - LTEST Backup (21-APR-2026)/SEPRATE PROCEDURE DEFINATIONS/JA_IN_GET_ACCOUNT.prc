CREATE OR REPLACE PROCEDURE APPS.ja_in_get_account(p_chart_of_accounts_id IN NUMBER,
                                              p_ccid IN NUMBER, p_account_number OUT NOCOPY VARCHAR2) IS

CURSOR get_segments_used(coa_id NUMBER) IS
   SELECT segment_num, application_column_name
   FROM   fnd_id_flex_segments
   WHERE  id_flex_num = coa_id
   AND    id_flex_code = 'GL#'
   ORDER BY segment_num;

v_account_number  VARCHAR2(1000) := NULL;
v_segment         VARCHAR2(25);
v_segment_cur     INTEGER;
v_execute         INTEGER;
v_rows          INTEGER;

BEGIN
/* $Header: ja_in_get_account_p.sql 115.2.6107.1 2007/02/08 16:09:58 rallamse noship $ */

    FOR i IN get_segments_used(p_chart_of_accounts_id) LOOP       --L1
       v_segment_cur := DBMS_SQL.OPEN_CURSOR;
       DBMS_SQL.PARSE(v_segment_cur, 'SELECT '||i.application_column_name||' FROM gl_code_combinations'
                      ||' WHERE code_combination_id = '||p_ccid, DBMS_SQL.NATIVE);
       DBMS_SQL.DEFINE_COLUMN(v_segment_cur, 1, v_segment, 1000);
       v_execute := DBMS_SQL.EXECUTE(v_segment_cur);
       v_rows := DBMS_SQL.FETCH_ROWS(v_segment_cur);
       DBMS_SQL.COLUMN_VALUE(v_segment_cur, 1, v_segment);

       IF v_account_number IS NOT NULL AND v_segment IS NOT NULL THEN
          v_account_number := v_account_number||'-'||v_segment;
       ELSIF v_account_number IS NULL AND v_segment IS NOT NULL THEN
          v_account_number := v_segment;
       END IF;
       DBMS_SQL.CLOSE_CURSOR(v_segment_cur);
    END LOOP;                                --L1
    p_account_number := v_account_number;
EXCEPTION
  WHEN OTHERS THEN
    IF dbms_sql.is_open(v_segment_cur) THEN
      dbms_sql.close_cursor(v_segment_cur);
    END IF;

END;
/
