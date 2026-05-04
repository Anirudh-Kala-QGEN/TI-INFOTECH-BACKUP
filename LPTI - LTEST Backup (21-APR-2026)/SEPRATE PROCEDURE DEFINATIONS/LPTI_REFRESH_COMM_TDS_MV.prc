CREATE OR REPLACE PROCEDURE APPS.LPTI_REFRESH_COMM_TDS_MV(ERRBUF OUT VARCHAR2,
                                                     RETCODE OUT VARCHAR2)
is
begin
   dbms_mview.refresh( 'COMM_TDS_VW' );
end;
/
