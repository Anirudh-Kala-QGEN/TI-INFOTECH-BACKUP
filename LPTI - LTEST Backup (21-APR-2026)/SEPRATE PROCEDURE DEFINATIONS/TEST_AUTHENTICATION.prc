CREATE OR REPLACE procedure APPS.test_authentication AUTHID CURRENT_USER as
begin
htp.bodyOpen();
htp.htmlOpen();
htp.bodyClose();
htp.p('Does authentication work?');
htp.p(fnd_web_sec.validate_login('SYSADMIN','SYSADMIN'));
htp.htmlClose();
END test_authentication;
/
