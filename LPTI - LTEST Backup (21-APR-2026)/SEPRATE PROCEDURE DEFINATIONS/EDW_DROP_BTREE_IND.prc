CREATE OR REPLACE PROCEDURE APPS.edw_drop_btree_ind (owner VARCHAR2, table_name VARCHAR2) AUTHID CURRENT_USER AS
/* $Header: EDWDRIND.pls 115.1.310.3 2001/08/31 18:52:16 pkm ship    $*/

x_index_name	varchar(30);
sql_stmt	varchar(2000);
cur_stmt	varchar2(2000);
x_table_name	varchar2(30);
x_owner		varchar2(30);

TYPE IndexCurType is REF CURSOR;
ind_cv	IndexCurType;

BEGIN

x_table_name := UPPER(table_name);
x_owner := UPPER(owner);

cur_stmt := 'SELECT index_name FROM dba_indexes
where index_type = ''NORMAL''
and uniqueness = ''NONUNIQUE''
and owner = :x_owner
and table_name =:x_table_name';

OPEN ind_cv FOR cur_stmt USING x_owner, x_table_name;

LOOP
	FETCH ind_cv INTO x_index_name;
	EXIT WHEN ind_cv%NOTFOUND;
	sql_stmt := 'drop index '|| x_owner ||'.'|| x_index_name ;
	execute immediate sql_stmt;
END LOOP;

CLOSE ind_cv;

EXCEPTION
	WHEN OTHERS THEN NULL;

END edw_drop_btree_ind;

/
