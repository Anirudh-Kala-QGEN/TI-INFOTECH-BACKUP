CREATE OR REPLACE procedure APPS.TEST1 AUTHID CURRENT_USER as
BEGIN
  Begin
      dbms_output.put_line('Testing');
  end;
END;
/
