CREATE OR REPLACE PROCEDURE APPS.TI_AP_SUPPLIER_SITES_INT_NEW1      (ERRBUF OUT VARCHAR2,
                                                         RETCODE OUT VARCHAR2
                                                        )
 IS
 
 
 V_STATUS                BOOLEAN        := TRUE;
 V_RECORD_INSERTED       NUMBER         := 0;
 V_RECORD_REJECT         NUMBER         := 0;
 V_CONC_REQUEST_ID       NUMBER;
 V_VENDOR_ID             NUMBER;
 V_CITY_NAME             VARCHAR2(50);
 V_ADDRESSES             VARCHAR2(250);
 nCOUNT_V                NUMBER         :=0;
 nCOUNT_INT              NUMBER         :=0; 
 nVENDOR_NO              NUMBER; 
 vCITY                   VARCHAR2(10);
 V_CODE_COMBINATION_ID   NUMBER;
  v_city_code  varchar2(240);
 v_ADDRESS1   varchar2(240);
 v_ADDRESS2   varchar2(240);
 v_ADDRESS3   varchar2(240);
 v_PHONE_NO1  varchar2(20);
 v_PIN_NO     varchar2(10);
 v_EMAIL      varchar2(250);
 v_MOBILE_NO  varchar2(15); 
   l_ERRBUF     VARCHAR2 (32767);
    l_RETCODE    VARCHAR2 (32767);
    l_P_ORG_ID   VARCHAR2 (32767);
    P_SUPP_CODE   VARCHAr2(32767);
 
 BEGIN
 
     FOR I IN (
                      SELECT   TYPE || '-' || code segment1,
                                NAME,
                                ALT_NAME,
                                DECODE (TYPE,
                                        'V', 'VENDOR',
                                        'H', 'HOTEL',
                                        'G', 'GUIDE',
                                        'OTHERS')
                                   V_TYPE,
                                CITY_NAME,
                                ADDRESSES
                         FROM   VENDOR_VW_ALL@TAPROD_DBLINK A
                        WHERE   A.TYPE IN ('V', 'H', 'G') 
                            AND A.SBU_CODE = '0002'
                            AND TRUNC(A.ENTERED_DATE) >='01-JAN-2017'
                            AND A.ACTIVE_FLG='Y'
                            --and a.code ='H0007529'
                            AND A.TYPE || '-' || A.CODE NOT IN (SELECT   SEGMENT1 FROM AP_SUPPLIERS)
                            AND A.TYPE || '-' || A.CODE NOT IN (SELECT   SEGMENT1 FROM AP_SUPPLIERS_INT)   
           ) LOOP
      
     FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'1'); 
      
         
     BEGIN
     FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'4');
     SELECT  CITY_NAME,ADDRESSES
             INTO V_CITY_NAME,V_ADDRESSES
             FROM VENDOR_VW@TAPROD_DBLINK WHERE TYPE IN ('V','H','G')
              AND SBU_CODE ='0002'
              AND TYPE||'-'||CODE=I.SEGMENT1;
     EXCEPTION WHEN OTHERS THEN
     FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'5');
        V_CITY_NAME:=NULL;
        V_ADDRESSES:=NULL;
        --V_STATUS   :=FALSE;
     END;              
     
    begin
    select CITY_CODE,
           ADDRESS1,
           ADDRESS2,
           ADDRESS3,
           replace(PHONE_NO1,chr(32),'') PHONE_NO1,
           PIN_NO ,
           EMAIL,
           replace(MOBILE_NO,chr(32),'') MOBILE_NO
      into v_city_code,
           v_ADDRESS1,
           v_ADDRESS2,
           v_ADDRESS3,
           v_PHONE_NO1,
           v_PIN_NO ,
           v_EMAIL,
           v_MOBILE_NO         
      from ta_vendor_dtl 
     where type||'-'||code=I.SEGMENT1;
     FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'6');
     exception when others then
     v_ADDRESS1 :=V_ADDRESSES;
     v_ADDRESS2 :=null;
     v_ADDRESS3 :=null;
     v_PHONE_NO1:=null;
     v_PIN_NO   :=null  ;
     FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'7');
    end;
     
     
 DECLARE
    -- Variable declarations
  
BEGIN
    -- Variable initializations
    l_P_ORG_ID := 81;

    -- Call
    APPS.PKG_TA_AP_TRF_INT.TI_AP_VENDOR_INTERFACE_PROC (
        ERRBUF     => l_ERRBUF,
        RETCODE    => l_RETCODE,
        P_ORG_ID   => l_P_ORG_ID,
        P_SUPP_CODE => i.segment1);
        
       
    -- Transaction control
    COMMIT;

  
END;
   
   END LOOP;
   FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'10');
     

     IF V_STATUS = TRUE
     THEN
     COMMIT;
     V_RECORD_INSERTED := V_RECORD_INSERTED + 1;
     ELSE
     V_RECORD_REJECT := V_RECORD_REJECT + 1;
     END IF;
   
     FND_FILE.PUT_LINE (FND_FILE.OUTPUT,
                       'Number of Invoices Inserted are: ' || v_record_inserted
                       );
     FND_FILE.PUT_LINE (FND_FILE.OUTPUT,
                       'Number of Invoices Rejected are: ' || v_record_reject
                       );

                     
-----------------------------------------------------------------------------------------------------------------
/* call interface program "Supplier Sites Open Interface Import" to upload the Supplier Sitesn into base table */
-----------------------------------------------------------------------------------------------------------------

    IF V_RECORD_INSERTED > 0
    THEN
      FND_GLOBAL.APPS_INITIALIZE
                           (USER_ID           => FND_PROFILE.VALUE ('USER_ID'),
                            RESP_ID           => FND_PROFILE.VALUE ('RESP_ID'),
                            RESP_APPL_ID      => FND_PROFILE.VALUE ('RESP_APPL_ID')
                           );
                           
      V_CONC_REQUEST_ID :=
         FND_REQUEST.SUBMIT_REQUEST (APPLICATION                  => 'SQLAP',
                                         PROGRAM                  => 'APXSSIMP',
                                       ARGUMENT1                  => 'NEW',
                                       ARGUMENT2                  => 1000,
                                       ARGUMENT3                  => 'N',
                                       ARGUMENT4                  => 'N',
                                       ARGUMENT5                  => 'N',
                                       ARGUMENT6                  => '-99'
                                    );
      COMMIT;

      IF (V_CONC_REQUEST_ID = 0)
      THEN
         FND_FILE.PUT_LINE
                   (FND_FILE.OUTPUT,
                    'NOT Able TO Submit the Payable Interface Import Program'
                   );
         
         
      END IF;
      END IF;    
  
  

 EXCEPTION
 WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(SQLERRM);
 END;
/

CREATE OR REPLACE PROCEDURE APPS.TI_UPLOAD_FLEX_VALUES2(
                                                        RETCODE OUT VARCHAR2,
                                                        ERRBUF OUT VARCHAR2
                                                      )
IS

BEGIN

DECLARE 
CURSOR c1 IS
        SELECT DISTINCT FILE_CODE,COSTING_NAME 
          FROM TOUR_COSTING_MAS1@APPS_OLD.LPTI.COM
         WHERE FILE_CODE IS NOT NULL
           AND CANCEL_FLG <> 'Y'
           AND SBU_CODE ='0002'
           --AND FILE_CODE IN ('PLT17010001')
           AND FILE_CODE NOT IN (
                                 SELECT FLEX_VALUE 
                                   FROM FND_FLEX_VALUES  A, 
                                        FND_FLEX_VALUES_TL  B
                                  WHERE A.FLEX_VALUE_ID = B.FLEX_VALUE_ID
                                    AND PARENT_FLEX_VALUE_LOW = '12400'
                                 )
UNION
        SELECT DISTINCT SUBSTR(FILE_CODE,1,25),REMARKS 
          FROM PO_MAS1@APPS_OLD.LPTI.COM
         WHERE ADDL_FIELD9 LIKE 'OPENING%'
           AND ADDL_FIELD9 IS NOT NULL
           AND FILE_CODE NOT IN (SELECT FLEX_VALUE 
                                   FROM FND_FLEX_VALUES  A, 
                                        FND_FLEX_VALUES_TL  B
                                  WHERE A.FLEX_VALUE_ID = B.FLEX_VALUE_ID
                                    AND PARENT_FLEX_VALUE_LOW = '12400'
                                );
                                
nCOUNT NUMBER:=0;

BEGIN

FOR I IN C1 LOOP
    nCOUNT:=0;
    SELECT COUNT(1) 
      INTO nCOUNT 
      FROM FND_FLEX_VALUES
     WHERE FLEX_VALUE =UPPER(I.FILE_CODE) 
       AND PARENT_FLEX_VALUE_LOW='12400';
            
        IF nCOUNT = 0  THEN
           
           INSERT INTO FND_FLEX_VALUES(
                                       FLEX_VALUE_SET_ID,
                                       FLEX_VALUE_ID,
                                       FLEX_VALUE,
                                       ENABLED_FLAG,
                                       SUMMARY_FLAG,
                                       COMPILED_VALUE_ATTRIBUTES,
                                       CREATION_DATE,LAST_UPDATE_DATE,
                                       CREATED_BY,
                                       LAST_UPDATED_BY,
                                       PARENT_FLEX_VALUE_LOW,
                                       ATTRIBUTE50
                                       )
                                VALUES (
                                       '1016629',--'1009629',
                                       FND_FLEX_VALUES_S.NEXTVAL,
                                       UPPER(I.FILE_CODE),'Y','N','Y'||CHR(10)||'Y',
                                       SYSDATE,
                                       SYSDATE,
                                       1110,
                                       1110,
                                       '12400',
                                       'TIUPLOAD'
                                       );
                                       
         INSERT INTO FND_FLEX_VALUES_TL(
                                        FLEX_VALUE_ID,
                                        LANGUAGE,
                                        SOURCE_LANG,
                                        FLEX_VALUE_MEANING,
                                        DESCRIPTION,
                                        CREATION_dATE,
                                        LAST_UPDATE_DATE,
                                        CREATED_BY,
                                        LAST_UPDATED_BY
                                        )
                                VALUES ( 
                                        FND_FLEX_VALUES_S.CURRVAL,
                                        'US',
                                        'US',
                                        UPPER(I.FILE_CODE),
                                        I.COSTING_NAME,
                                        SYSDATE,
                                        SYSDATE,
                                        1130,
                                        1130
                                        );
        END IF;
        
END LOOP;
COMMIT;
END;
END ;
/

CREATE OR REPLACE PROCEDURE APPS.TI_UPLOAD_FLEX_VALUES1(
                                                        RETCODE OUT VARCHAR2,
                                                        ERRBUF OUT VARCHAR2
                                                      )
IS

BEGIN

DECLARE 
CURSOR c1 IS
        SELECT DISTINCT FILE_CODE,COSTING_NAME 
          FROM TOUR_COSTING_MAS@taprod_dblink
         WHERE FILE_CODE IS NOT NULL
           AND CANCEL_FLG <> 'Y'
           AND SBU_CODE ='0002'
           --AND FILE_CODE IN ('PLT17010001')
           AND FILE_CODE NOT IN (
                                 SELECT FLEX_VALUE 
                                   FROM FND_FLEX_VALUES  A, 
                                        FND_FLEX_VALUES_TL  B
                                  WHERE A.FLEX_VALUE_ID = B.FLEX_VALUE_ID
                                    AND PARENT_FLEX_VALUE_LOW = '12400'
                                 )
        and file_code in(select flex_value from proj_code                     )                                  
UNION
        SELECT DISTINCT SUBSTR(FILE_CODE,1,25),REMARKS 
          FROM PO_MAS@taprod_dblink
         WHERE ADDL_FIELD9 LIKE 'OPENING%'
           AND ADDL_FIELD9 IS NOT NULL
           AND FILE_CODE NOT IN (SELECT FLEX_VALUE 
                                   FROM FND_FLEX_VALUES  A, 
                                        FND_FLEX_VALUES_TL  B
                                  WHERE A.FLEX_VALUE_ID = B.FLEX_VALUE_ID
                                    AND PARENT_FLEX_VALUE_LOW = '12400'
                                )
            and file_code in(select flex_value from proj_code                     )                                 ;
                                
nCOUNT NUMBER:=0;

BEGIN

FOR I IN C1 LOOP
    nCOUNT:=0;
    SELECT COUNT(1) 
      INTO nCOUNT 
      FROM FND_FLEX_VALUES
     WHERE FLEX_VALUE =UPPER(I.FILE_CODE) 
       AND PARENT_FLEX_VALUE_LOW='12400';
            
        IF nCOUNT = 0  THEN
           
          begin
             INSERT INTO FND_FLEX_VALUES(
                                       FLEX_VALUE_SET_ID,
                                       FLEX_VALUE_ID,
                                       FLEX_VALUE,
                                       ENABLED_FLAG,
                                       SUMMARY_FLAG,
                                       COMPILED_VALUE_ATTRIBUTES,
                                       CREATION_DATE,LAST_UPDATE_DATE,
                                       CREATED_BY,
                                       LAST_UPDATED_BY,
                                       PARENT_FLEX_VALUE_LOW,
                                       ATTRIBUTE50
                                       )
                                VALUES (
                                       '1016629',--'1009629',
                                       FND_FLEX_VALUES_S.NEXTVAL,
                                       UPPER(I.FILE_CODE),'Y','N','Y'||CHR(10)||'Y',
                                       SYSDATE,
                                       SYSDATE,
                                       1130,
                                       1130,
                                       '12400',
                                       'TIUPLOAD'
                                       );
           exception when others then
                dbms_output.Put_line(I.FILE_CODE||sqlerrm);
           end;                            
               
               begin                        
                 INSERT INTO FND_FLEX_VALUES_TL(
                                        FLEX_VALUE_ID,
                                        LANGUAGE,
                                        SOURCE_LANG,
                                        FLEX_VALUE_MEANING,
                                        DESCRIPTION,
                                        CREATION_dATE,
                                        LAST_UPDATE_DATE,
                                        CREATED_BY,
                                        LAST_UPDATED_BY
                                        )
                                VALUES ( 
                                        FND_FLEX_VALUES_S.CURRVAL,
                                        'US',
                                        'US',
                                        UPPER(I.FILE_CODE),
                                        I.COSTING_NAME,
                                        SYSDATE,
                                        SYSDATE,
                                        1130,
                                        1130
                                        );
               exception when others then
                dbms_output.Put_line('-'||I.FILE_CODE||sqlerrm);
               end;                       
        END IF;
        
END LOOP;
COMMIT;
END;
END TI_UPLOAD_FLEX_VALUES1;
/

CREATE OR REPLACE PROCEDURE APPS.LPTI_GL_AUTOCOPY_PRO (
   errbuf           OUT varchar2,
   retcode          OUT varchar2,
   p_je_category        varchar2,
   p_fperiod_name       varchar2,
   p_je_header_id       number,
   p_header_name        varchar2,
   p_period_name        varchar2,
   p_reverse            varchar2,
   p_revese_period      varchar2
)
IS
   V_SET_OF_BOOK_ID        NUMBER := FND_PROFILE.VALUE ('GL_SET_OF_BKS_ID');
   V_USER_ID               NUMBER := FND_PROFILE.VALUE ('USER_ID');
   V_STATUS                BOOLEAN := TRUE;
   V_CODE_COMBINATION_ID   AP_BANK_ACCOUNTS_ALL.ASSET_CODE_COMBINATION_ID%TYPE;
   V_SEGMENT1              GL_CODE_COMBINATIONS_KFV.SEGMENT1%TYPE;
   V_SEGMENT2              GL_CODE_COMBINATIONS_KFV.SEGMENT2%TYPE;
   V_SEGMENT3              GL_CODE_COMBINATIONS_KFV.SEGMENT3%TYPE;
   V_SEGMENT4              GL_CODE_COMBINATIONS_KFV.SEGMENT4%TYPE;
   V_SEGMENT5              GL_CODE_COMBINATIONS_KFV.SEGMENT5%TYPE;
   V_SEGMENT6              GL_CODE_COMBINATIONS_KFV.SEGMENT6%TYPE;
   V_SEGMENT7              GL_CODE_COMBINATIONS_KFV.SEGMENT7%TYPE;
   V_SEGMENT8              GL_CODE_COMBINATIONS_KFV.SEGMENT8%TYPE;
   V_CHART_ACCOUNT_ID      GL_CODE_COMBINATIONS_KFV.CHART_OF_ACCOUNTS_ID%TYPE;
   V_CURRENCY_CODE         FND_CURRENCIES.CURRENCY_CODE%TYPE;
   V_RECORD_INSERTED       NUMBER := 0;
   V_RECORD_REJECT         NUMBER := 0;
   V_GROUP_ID              NUMBER;
   V_GL_DATE               DATE;
   V_PERIOD_STATUS         NUMBER;
   V_END_DATE              DATE;
   V_RUN_ID                NUMBER;
   V_CONC_REQUEST_ID       NUMBER;

   --dSTART_DATE DATE := FND_DATE.CANONICAL_TO_DATE(P_FROM_DATE);
   --dEND_DATE  DATE := FND_DATE.CANONICAL_TO_DATE(P_TILL_DATE);

   CURSOR C1
   IS
        SELECT   glh.je_header_id,
                 gll.je_line_num,
                 glh.je_category,
                 glh.doc_sequence_value,
                 gcc.segment1,
                 gcc.segment2,
                 gcc.segment3,
                 gcc.segment4,
                 gcc.segment5,
                 gcc.segment6,
                 gcc.segment7,
                 gcc.segment8,
                 glh.period_name,
                 glh.currency_code,
                 DECODE (NVL (entered_dr, 0), 0, NULL, NVL (entered_dr, 0))
                    entered_dr,
                 DECODE (NVL (entered_cr, 0), 0, NULL, NVL (entered_cr, 0))
                    entered_cr,
                 gll.description line_description
          FROM   gl_je_headers glh, gl_je_lines gll, gl_code_combinations gcc
         WHERE       glh.je_header_id = gll.je_header_id
                 AND gll.code_combination_id = gcc.code_combination_id
                 AND glh.je_category = p_je_category
                 AND glh.period_name = p_fperiod_name
                 AND glh.je_header_id = p_je_header_id
                 AND glh.je_source NOT IN ('Payables', 'Receivables')
                 AND glh.je_category NOT IN
                          ('Cross Currency',
                           'Payments',
                           'Sales Invoices',
                           'Debit Memos',
                           'Trade Receipts',
                           'Credit Memos',
                           'Purchase Invoices')
      ORDER BY   gll.je_line_num;
BEGIN
   FND_GLOBAL.APPS_INITIALIZE ('1130', '20434', '101');

   FND_GLOBAL.APPS_INITIALIZE (FND_PROFILE.VALUE ('USER_ID'),
                               FND_PROFILE.VALUE ('RESP_ID'),
                               FND_PROFILE.VALUE ('RESP_APPL_ID'));

   SELECT   GL_INTERFACE_CONTROL_S.NEXTVAL INTO V_GROUP_ID FROM DUAL;

   IF V_USER_ID IN (1253, 1228, 1130)
   THEN
   SELECT   GL_INTERFACE_CONTROL_S.NEXTVAL INTO V_GROUP_ID FROM DUAL;
      FOR I IN C1
      LOOP
         


         BEGIN
            SELECT   END_DATE
              INTO   V_END_DATE
              FROM   GL_PERIOD_STATUSES
             WHERE   PERIOD_NAME = p_period_name AND APPLICATION_ID = 101;
         END;

         IF V_STATUS = TRUE
         THEN
            BEGIN
               INSERT INTO GL_INTERFACE (
                                            STATUS,
                                            SET_OF_BOOKS_ID,
                                            REFERENCE1,
                                            REFERENCE2,
                                            REFERENCE4,
                                            REFERENCE10,
                                            REFERENCE6,
                                            REFERENCE7 ,
                                            REFERENCE8,
                                            REFERENCE9,
                                            SEGMENT1,
                                            SEGMENT2,
                                            SEGMENT3,
                                            SEGMENT4,
                                            SEGMENT5,
                                            SEGMENT6,
                                            SEGMENT7,
                                            SEGMENT8,
                                            ENTERED_DR,
                                            ENTERED_CR,
                                            PERIOD_NAME,
                                            ACCOUNTING_DATE,
                                            CURRENCY_CODE,
                                            ACTUAL_FLAG,
                                            USER_JE_CATEGORY_NAME,
                                            USER_JE_SOURCE_NAME,
                                            DATE_CREATED,
                                            CREATED_BY,
                                            GROUP_ID,
                                            ATTRIBUTE1,
                                            ATTRIBUTE11
                          )
                 VALUES   (
                              'NEW',
                              V_SET_OF_BOOK_ID,
                                 'AUTO COPY VOUCHER AGAINST VCH_NO-'
                              || I.doc_sequence_value
                              || 'HEADER_ID-'
                              || I.JE_HEADER_ID,
                              p_header_name,
                              p_header_name,
                              i.line_description,
                              i.doc_sequence_value,
                              decode(p_reverse,'NO','No','YES','Yes'),
                              decode(p_reverse,'NO',null,p_revese_period),
                              decode(p_reverse,'NO','No','YES','Yes'),
                              I.SEGMENT1,
                              I.SEGMENT2,
                              I.SEGMENT3,
                              I.SEGMENT4,
                              I.SEGMENT5,
                              I.SEGMENT6,
                              I.SEGMENT7,
                              I.SEGMENT8,
                              I.ENTERED_DR,
                              I.ENTERED_CR,
                              p_period_name,
                              V_END_DATE,
                              I.CURRENCY_CODE,
                              'A',
                              'LPTI_PROV_VCH',
                              'LPTI_MANUAL',
                              SYSDATE,
                              V_USER_ID,
                              V_GROUP_ID,
                              'GL_VOUCHER_' || I.PERIOD_NAME,
                              I.JE_HEADER_ID
                          --I.SEQ
                          );

               COMMIT;
            EXCEPTION
               WHEN OTHERS
               THEN
                  FND_FILE.PUT_LINE (FND_FILE.OUTPUT, SQLERRM);
            END;
         END IF;
      END LOOP;

      /* When you submit Journal Import from Application(Front End) it will insert one reconrd into GL_INTERFACE_CONTROL table and
                                after successful completion it will delete the record from that table. If you submit the Journal Import through any
      PL/SQL code, it wont insert the record into GL_INTERFACE_CONTROL table. So you need to enter one record into GL_INTERFACE_CONTROL table.

      v_irun_id:=gl_interface_control_pkg.get_unique_run_id;

      inserting data into gl_interface_control

      GL_INTERFACE_CONTROL_PKG.insert_row(v_set_of_b ooks_id,v_irun_id, v_je_source_name, v_group_id, null);
  */

      /*-get the run id to insert the record into gl_interface_control-*/

      SELECT   gl_interface_control_pkg.get_unique_run_id
        INTO   V_RUN_ID
        FROM   DUAL;

      /*-get the run id to insert the record into gl_interface_control-*/

      /*-insert the record into gl_interface_control-*/

      GL_INTERFACE_CONTROL_PKG.insert_row (1001,
                                           v_run_id,
                                           '1',
                                           V_GROUP_ID,
                                           NULL);

      /*-insert the record into gl_interface_control-*/



      /************** clling the journal import from backend ******************/


      V_CONC_REQUEST_ID :=
         fnd_request.submit_request (application   => 'SQLGL',
                                     program       => 'GLLEZL',
                                     description   => NULL,
                                     start_time    => SYSDATE,
                                     sub_request   => FALSE,
                                     argument1     => TO_CHAR (V_RUN_ID),
                                     argument2     => '1001',
                                     argument3     => 'N', 
                                     argument4     => NULL,      
                                     argument5     => NULL,      
                                     argument6     => 'N', 
                                     argument7     => 'O'        
                                                         );


      COMMIT;


      /************** aclling the journal import from backend ******************/

      IF (V_CONC_REQUEST_ID = 0)
      THEN
         FND_FILE.PUT_LINE (
            FND_FILE.OUTPUT,
            'NOT Able TO Submit the Journal Interface Program'
         );
         RETCODE := 3;
      END IF;
   ELSE
      NULL;
   END IF;

   COMMIT;
END;
/


CREATE OR REPLACE PROCEDURE APPS.PRO_SUB_GL_UPLOAD_OTHER2
IS
   vcnt number;
   vnew_value number;

   BEGIN
   FOR   cur1 IN (select b.flex_value_id FLEX_VALUE_ID
                    ,a.LANGUAGE,a.LAST_UPDATE_DATE,a.LAST_UPDATED_BY,a.CREATION_DATE,a.CREATED_BY,a.LAST_UPDATE_LOGIN,a.DESCRIPTION,a.SOURCE_LANG,a.FLEX_VALUE_MEANING 
                  from FND_FLEX_VALUES_TL@APPS_OLD.LPTI.COM a,FND_FLEX_VALUES b
                  where  a.flex_value_id = nvl(b.ATTRIBUTE12,b.flex_value_id)
                  and b.flex_value_set_id in('1016629')
                  and PARENT_FLEX_VALUE_LOW =12400
                  and trunc(b.creation_date) = '31-JUL-2020'
                  
--                  select b.flex_value_id FLEX_VALUE_ID
--                    ,a.LANGUAGE,a.LAST_UPDATE_DATE,a.LAST_UPDATED_BY,a.CREATION_DATE,a.CREATED_BY,a.LAST_UPDATE_LOGIN,a.DESCRIPTION,a.SOURCE_LANG,a.FLEX_VALUE_MEANING 
--                  from FND_FLEX_VALUES_TL@apps_old a,FND_FLEX_VALUES b
--                  where  a.flex_value_id = nvl(b.ATTRIBUTE12,b.flex_value_id)
--                  and b.flex_value_set_id in('1016629')
--                  and PARENT_FLEX_VALUE_LOW !=12400
                  )
        

         LOOP
         
            DBMS_OUTPUT.PUT_LINE ('start TL-' || cur1.FLEX_VALUE_ID);
            
              BEGIN
                 SELECT COUNT (1)
                   INTO vcnt
                   FROM FND_FLEX_VALUES_TL
                  WHERE flex_value_id = cur1.flex_value_id;
              EXCEPTION
                 WHEN OTHERS
                 THEN
                    vcnt := 0;
              END;

              IF vcnt = 0 THEN
                 BEGIN
                    INSERT INTO FND_FLEX_VALUES_TL (FLEX_VALUE_ID,
                                                    LANGUAGE,
                                                    LAST_UPDATE_DATE,
                                                    LAST_UPDATED_BY,
                                                    CREATION_DATE,
                                                    CREATED_BY,
                                                    LAST_UPDATE_LOGIN,
                                                    DESCRIPTION,
                                                    SOURCE_LANG,
                                                    FLEX_VALUE_MEANING)
                         VALUES (cur1.FLEX_VALUE_ID,
                                 cur1.LANGUAGE,
                                 SYSDATE,
                                 cur1.LAST_UPDATED_BY,
                                 SYSDATE,
                                 cur1.CREATED_BY,
                                 cur1.LAST_UPDATE_LOGIN,
                                 cur1.DESCRIPTION,
                                 cur1.SOURCE_LANG,
                                 cur1.FLEX_VALUE_MEANING
                                 );
                 EXCEPTION
                    WHEN others
                    THEN
                       DBMS_OUTPUT.PUT_LINE ('Error During insertion into Existing flex field TL-'|| cur1.FLEX_VALUE_ID);
                 END;
              END IF;

              COMMIT;

              IF vcnt > 0
              THEN
                 BEGIN
                    SELECT MAX (flex_value_id) + 1
                      INTO vnew_value
                      FROM FND_FLEX_VALUES_TL;
                 EXCEPTION
                    WHEN OTHERS
                    THEN
                       vnew_value := 0;
                 END;

                 IF vnew_value != 0
                 THEN
                    DBMS_OUTPUT.PUT_LINE (
                          'Error During insertion into Existing flex field SUB GL 12400  NEW -'
                       || cur1.FLEX_VALUE_ID);
                 END IF;
              END IF;
         
         end loop;
          EXCEPTION WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE(' Exception in cursor'|| SQLERRM || ' '|| SQLCODE);
          END;
/

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

CREATE OR REPLACE PROCEDURE APPS.PRO_SUB_GL_UPLOAD_OTHER
IS
   vcnt number;
   vnew_value number;

   BEGIN
   FOR   cur1 IN (select b.flex_value_id FLEX_VALUE_ID
                    ,a.LANGUAGE,a.LAST_UPDATE_DATE,a.LAST_UPDATED_BY,a.CREATION_DATE,a.CREATED_BY,a.LAST_UPDATE_LOGIN,a.DESCRIPTION,a.SOURCE_LANG,a.FLEX_VALUE_MEANING 
                  from FND_FLEX_VALUES_TL@apps_old a,FND_FLEX_VALUES b
                  where  a.flex_value_id = nvl(b.ATTRIBUTE12,b.flex_value_id)
                  and b.flex_value_set_id in('1016629')
                  and PARENT_FLEX_VALUE_LOW =12400
                  and trunc(b.creation_date) =trunc(sysdate)
                  
--                  select b.flex_value_id FLEX_VALUE_ID
--                    ,a.LANGUAGE,a.LAST_UPDATE_DATE,a.LAST_UPDATED_BY,a.CREATION_DATE,a.CREATED_BY,a.LAST_UPDATE_LOGIN,a.DESCRIPTION,a.SOURCE_LANG,a.FLEX_VALUE_MEANING 
--                  from FND_FLEX_VALUES_TL@apps_old a,FND_FLEX_VALUES b
--                  where  a.flex_value_id = nvl(b.ATTRIBUTE12,b.flex_value_id)
--                  and b.flex_value_set_id in('1016629')
--                  and PARENT_FLEX_VALUE_LOW !=12400
                  )
        

         LOOP
         
            DBMS_OUTPUT.PUT_LINE ('start TL-' || cur1.FLEX_VALUE_ID);
--              BEGIN
--                 SELECT COUNT (1)
--                   INTO vcnt
--                   FROM FND_FLEX_VALUES_TL
--                  WHERE flex_value_id = cur1.flex_value_id;
--              EXCEPTION
--                 WHEN OTHERS
--                 THEN
--                    vcnt := 0;
--              END;
--
--              IF vcnt = 0
             -- THEN
                 BEGIN
                    INSERT INTO FND_FLEX_VALUES_TL (FLEX_VALUE_ID,
                                                    LANGUAGE,
                                                    LAST_UPDATE_DATE,
                                                    LAST_UPDATED_BY,
                                                    CREATION_DATE,
                                                    CREATED_BY,
                                                    LAST_UPDATE_LOGIN,
                                                    DESCRIPTION,
                                                    SOURCE_LANG,
                                                    FLEX_VALUE_MEANING)
                         VALUES (cur1.FLEX_VALUE_ID,
                                 cur1.LANGUAGE,
                                 SYSDATE,
                                 cur1.LAST_UPDATED_BY,
                                 SYSDATE,
                                 cur1.CREATED_BY,
                                 cur1.LAST_UPDATE_LOGIN,
                                 cur1.DESCRIPTION,
                                 cur1.SOURCE_LANG,
                                 cur1.FLEX_VALUE_MEANING
                                 );
                 EXCEPTION
                    WHEN others
                    THEN
                       DBMS_OUTPUT.PUT_LINE (
                             'Error During insertion into Existing flex field TL-'
                          || cur1.FLEX_VALUE_ID);
                 END;
             -- END IF;

              COMMIT;

              IF vcnt > 0
              THEN
                 BEGIN
                    SELECT MAX (flex_value_id) + 1
                      INTO vnew_value
                      FROM FND_FLEX_VALUES_TL;
                 EXCEPTION
                    WHEN OTHERS
                    THEN
                       vnew_value := 0;
                 END;

                 IF vnew_value != 0
                 THEN
                    DBMS_OUTPUT.PUT_LINE (
                          'Error During insertion into Existing flex field SUB GL 12400  NEW -'
                       || cur1.FLEX_VALUE_ID);
                 END IF;
              END IF;
         
         end loop;
          EXCEPTION WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE(' Exception in cursor'|| SQLERRM || ' '|| SQLCODE);
          END;
/

CREATE OR REPLACE PROCEDURE APPS.PRO_SUB_GL_UPLOAD
IS
   vcnt number;
   vnew_value number;

   BEGIN
   FOR   cur1 IN (select 
                            --nvl(b.ATTRIBUTE12,b.flex_value_id) FLEX_VALUE_ID
                    b.flex_value_id FLEX_VALUE_ID
                    ,a.LANGUAGE,a.LAST_UPDATE_DATE,a.LAST_UPDATED_BY,a.CREATION_DATE,a.CREATED_BY,a.LAST_UPDATE_LOGIN,a.DESCRIPTION,a.SOURCE_LANG,a.FLEX_VALUE_MEANING 
                  from FND_FLEX_VALUES_TL@apps_old a,FND_FLEX_VALUES b
                  where  a.flex_value_id = nvl(b.ATTRIBUTE12,b.flex_value_id)
                  and b.flex_value_set_id in('1016629')
                  and (b.PARENT_FLEX_VALUE_LOW,flex_value) in(SELECT gcc.segment2,gcc.segment3
                                            FROM GL_JE_HEADERS@apps_old gl_mas,GL_JE_LINES@apps_old gl_dtl,gl_code_combinations@apps_old gcc
                                            WHERE gl_mas.JE_HEADER_ID = gl_dtl.JE_HEADER_ID
                                            and gl_dtl.code_combination_id = gcc.code_combination_id 
                                            and gl_mas.JE_SOURCE NOT IN('Payable','Receivable')
                                            AND TRUNC(gl_mas.DEFAULT_EFFECTIVE_DATE) >'31-MAR-2017'
                                            and gcc.segment2='12400'))
        

         LOOP
         
            DBMS_OUTPUT.PUT_LINE ('start TL-' || cur1.FLEX_VALUE_ID);
--              BEGIN
--                 SELECT COUNT (1)
--                   INTO vcnt
--                   FROM FND_FLEX_VALUES_TL
--                  WHERE flex_value_id = cur1.flex_value_id;
--              EXCEPTION
--                 WHEN OTHERS
--                 THEN
--                    vcnt := 0;
--              END;
--
--              IF vcnt = 0
             -- THEN
                 BEGIN
                    INSERT INTO FND_FLEX_VALUES_TL (FLEX_VALUE_ID,
                                                    LANGUAGE,
                                                    LAST_UPDATE_DATE,
                                                    LAST_UPDATED_BY,
                                                    CREATION_DATE,
                                                    CREATED_BY,
                                                    LAST_UPDATE_LOGIN,
                                                    DESCRIPTION,
                                                    SOURCE_LANG,
                                                    FLEX_VALUE_MEANING)
                         VALUES (cur1.FLEX_VALUE_ID,
                                 cur1.LANGUAGE,
                                 SYSDATE,
                                 cur1.LAST_UPDATED_BY,
                                 SYSDATE,
                                 cur1.CREATED_BY,
                                 cur1.LAST_UPDATE_LOGIN,
                                 cur1.DESCRIPTION,
                                 cur1.SOURCE_LANG,
                                 cur1.FLEX_VALUE_MEANING
                                 );
                 EXCEPTION
                    WHEN others
                    THEN
                       DBMS_OUTPUT.PUT_LINE (
                             'Error During insertion into Existing flex field TL-'
                          || cur1.FLEX_VALUE_ID);
                 END;
             -- END IF;

              COMMIT;

              IF vcnt > 0
              THEN
                 BEGIN
                    SELECT MAX (flex_value_id) + 1
                      INTO vnew_value
                      FROM FND_FLEX_VALUES_TL;
                 EXCEPTION
                    WHEN OTHERS
                    THEN
                       vnew_value := 0;
                 END;

                 IF vnew_value != 0
                 THEN
                    DBMS_OUTPUT.PUT_LINE (
                          'Error During insertion into Existing flex field SUB GL 12400  NEW -'
                       || cur1.FLEX_VALUE_ID);
                 END IF;
              END IF;
         
         end loop;
          EXCEPTION WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE(' Exception in cursor'|| SQLERRM || ' '|| SQLCODE);
          END;
/

CREATE OR REPLACE procedure APPS.TI_UPDATE_PAYMENT_VOUCHER_REF ( 
                                                           ERRBUF OUT VARCHAR2,
                                                           RETCODE OUT VARCHAR2,
                                                           P_BANK_ACCOUNT_ID NUMBER,
                                                           P_DOC_NUMBER NUMBER,
                                                           P_CHECK_DATE VARCHAR2,
                                                           P_NEFT_RTGS_NO VARCHAR2
                                                           ) IS 

V_CHECK_ID      AP_CHECKS_ALL.CHECK_ID%TYPE;
V_ATTRIBUTE6    AP_CHECKS_ALL.ATTRIBUTE6%TYPE;
A_ATTRIBUTE6    AP_CHECKS_ALL.ATTRIBUTE6%TYPE;    
V_BANK_ACCOUNT_NAME AP_CHECKS_ALL.BANK_ACCOUNT_NAME%TYPE;
DEND_DATE                       DATE;

BEGIN

dEND_DATE   := FND_DATE.CANONICAL_TO_DATE(P_CHECK_DATE);

FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Bank Account ID:'||P_BANK_ACCOUNT_ID);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Check Id:'||P_DOC_NUMBER);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Check Date:'||P_CHECK_DATE);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'NEFT/RTGS:'||P_NEFT_RTGS_NO);


FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Check Date:'||dEND_DATE);

BEGIN
SELECT CHECK_ID ,ATTRIBUTE6,BANK_ACCOUNT_NAME
INTO V_CHECK_ID , V_ATTRIBUTE6,V_BANK_ACCOUNT_NAME
FROM AP_CHECKS_ALL
WHERE BANK_ACCOUNT_ID=P_BANK_ACCOUNT_ID
AND CHECK_ID= P_DOC_NUMBER
AND CHECK_DATE=dEND_DATE;
EXCEPTION WHEN OTHERS THEN
V_CHECK_ID:=NULL;
END;

FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'V_CHECK_ID:'||V_CHECK_ID);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Bank Account Name:'||V_BANK_ACCOUNT_NAME);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Intinal Value for Check No:'||P_DOC_NUMBER||' IS:'||V_ATTRIBUTE6);

IF V_CHECK_ID IS NOT NULL THEN
UPDATE AP_CHECKS_ALL
SET ATTRIBUTE6=P_NEFT_RTGS_NO
WHERE CHECK_ID= V_CHECK_ID
AND BANK_ACCOUNT_ID=P_BANK_ACCOUNT_ID
AND CHECK_ID=P_DOC_NUMBER
AND CHECK_DATE=dEND_DATE
AND ATTRIBUTE6 IS NULL;

COMMIT;
END IF;

FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Bank Account Name:'||V_BANK_ACCOUNT_NAME);

BEGIN
SELECT 
ATTRIBUTE6 
INTO A_ATTRIBUTE6 
FROM AP_CHECKS_ALL
WHERE CHECK_ID=V_CHECK_ID;
END;
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Value After Updated the NEFT Value is:'||A_ATTRIBUTE6);

EXCEPTION WHEN OTHERS THEN  
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,SQLERRM);
END;
/

CREATE OR REPLACE PROCEDURE APPS.LPTI_POST_GENERAL_VOUCHER(ERRORBUF OUT VARCHAR2,
                                                      RECODE OUT VARCHAR2,
                                                      P_FDATE VARCHAR2,
                                                      P_TDATE VARCHAR2
                                                     )
                                                     IS
   x_user_id             NUMBER;
   x_sob_id              NUMBER;
   x_coa_id              NUMBER;
   x_user_source_name    VARCHAR2 (80);
   x_source_name         VARCHAR2 (30);
   x_appl_id             VARCHAR2 (50);
   x_resp_id             VARCHAR2 (50);
   x_summary_flag        VARCHAR2 (1)    := 'N';
   x_conc_id             NUMBER;
   x_posting_run_id      NUMBER;
   x_access_set_id       NUMBER;
   P_FROM_DATE           DATE;
   P_TO_DATE             DATE;   
   x_req_return_status   BOOLEAN;
   err_msg               VARCHAR2 (2000);
   
BEGIN
   fnd_message.CLEAR;
   
   P_FROM_DATE := FND_DATE.CANONICAL_TO_DATE(P_FDATE);
   P_TO_DATE   := FND_DATE.CANONICAL_TO_DATE(P_TDATE);
   
   fnd_file.put_line(fnd_file.output,'01');


for i  in (SELECT DISTINCT b.je_batch_id 
             FROM  gl_je_batches b
            where b.default_effective_date between P_FROM_DATE and P_TO_DATE
              and b.status <>'P'
              and b.je_batch_id in (select distinct je_batch_id from gl_je_headers a where a.je_batch_id=b.je_batch_id)
              --order by b.default_effective_date
              ) loop  

fnd_file.put_line(fnd_file.output,'02');

   SELECT user_id
     INTO x_user_id
     FROM fnd_user
    WHERE user_name = 'TIADMIN';

   SELECT application_id
     INTO x_appl_id
     FROM fnd_application
    WHERE application_short_name = 'SQLGL';

   SELECT responsibility_id
     INTO x_resp_id
     FROM fnd_application fa, fnd_responsibility_tl fr
    WHERE fa.application_short_name = 'SQLGL'
      AND fa.application_id = fr.application_id
      AND fr.responsibility_name = 'General Ledger Super User';

   fnd_global.apps_initialize (x_user_id, x_resp_id, x_appl_id);

   SELECT set_of_books_id, chart_of_accounts_id
     INTO x_sob_id, x_coa_id
     FROM gl_sets_of_books
    WHERE short_name = 'LPTI_SOB';

   SELECT gl_je_posting_s.NEXTVAL
     INTO x_posting_run_id
     FROM DUAL;

   /* SELECT gl_interface_control_pkg.get_unique_run_id 
        INTO V_RUN_ID 
        FROM DUAL;
     */   
        
    --GL_INTERFACE_CONTROL_PKG.insert_row(1001, v_run_id, '1', V_GROUP_ID, null);     

fnd_file.put_line (fnd_file.output,'posting ID: ' || TO_CHAR (x_posting_run_id));    

update gl_je_batches
set status='S',
POSTING_RUN_ID=x_posting_run_id
where je_batch_id=i.je_batch_id;

commit;


/*
   SELECT gl_access_sets_s.NEXTVAL
     INTO x_access_set_id
     FROM DUAL;*/

x_conc_id:=fnd_request.submit_request('SQLGL', 
                                      'GLPPOS', 
                                      '', 
                                      '', 
                                      FALSE,
                                      To_Char(1001),      
                                      To_Char(50268),
                                      To_Char(x_posting_run_id),
                                      chr(0),
                                      '','','','','','','','','','','','','','','','','','','','',
                                      '','','','','','','','','','','','','','','','','','','','',
                                      '','','','','','','','','','','','','','','','','','','','',
                                      '','','','','','','','','','','','','','','','','','','','',
                                      '','','','','','','','','','','','','','','',''
                                      );



                                        
fnd_file.put_line (fnd_file.output,'ID: ' || TO_CHAR (x_conc_id));               

    IF x_conc_id = 0
       THEN
          fnd_file.put_line (fnd_file.output,'ID=0: ' || TO_CHAR (x_conc_id));
          --fnd_message.retrieve (err_msg);
          DBMS_OUTPUT.put_line (err_msg);
          fnd_file.put_line (fnd_file.output,err_msg);
          DBMS_OUTPUT.put_line (fnd_message.get);
          fnd_file.put_line (fnd_file.output,fnd_message.get);
          fnd_message.raise_error;
    ELSE
          DBMS_OUTPUT.put_line ('Submitted request_id ' || x_conc_id);
          COMMIT;                                               -- submit the job
    END IF;
    
end loop;
END;
/

CREATE OR REPLACE procedure APPS.lpti_ar_open_item_fifo (
                                        retcode out varchar2,
                                        errbuf out varchar2,
                                        P_AS_ON_DATE varchar2,
                                        p_currency_wise varchar2
                                        ) is 
                                        
  
  P_USER_ID VARCHAR2(200);
  P_TO_DATE                       DATE := FND_DATE.CANONICAL_TO_DATE(P_AS_ON_DATE);
BEGIN 
  /*------------------------------------------------
  P_AS_ON_DATE Parameter Must be date without Time
  /*------------------------------------------------
  --P_AS_ON_DATE := TRUNC(SYSDATE);
  /*------------------------------------------------*/
   
  P_USER_ID := '01136';
  
  if p_currency_wise='F' then 
      begin
      APS_AR_INV_AUTO_ADJ_PACK.GEN_AR_INV_AGEING ( P_TO_DATE, P_USER_ID );
      COMMIT;
      end; 
  elsif p_currency_wise='T' then
      begin
      APS_AR_INV_AUTO_ADJ_CUR_PACK1.GEN_AR_INV_AGEING (P_TO_DATE,P_USER_ID );
      COMMIT;
      end; 
  else
  null;
  end if;
   
END;
/

CREATE OR REPLACE PROCEDURE APPS.TI_GL_TA_INTERFACE_NEW (
   errbuf     OUT VARCHAR2,
   retcode    OUT VARCHAR2,
   P_PERIOD_NAME    VARCHAR2
   )

IS
    p_set_books_id  number        := '2121';
    vDailry_rates number;

BEGIN

     FND_FILE.PUT_line (FND_FILE.LOG, 'START_PERIOD_NAME'||P_PERIOD_NAME);
     dbms_output.PUT_line ('START_PERIOD_NAME'||P_PERIOD_NAME);


        BEGIN
        LOOP
INSERT INTO GL_INTERFACE
            (STATUS,SET_OF_BOOKS_ID,REFERENCE1,REFERENCE2,REFERENCE4,REFERENCE5,REFERENCE10,
            SEGMENT1,
            SEGMENT2,
            SEGMENT3,
            SEGMENT4,
            SEGMENT5,
            SEGMENT6,
            SEGMENT7,
            SEGMENT8,
            ENTERED_DR,ENTERED_CR,ACCOUNTED_DR,ACCOUNTED_CR,ACCOUNTING_DATE,CURRENCY_CODE,ACTUAL_FLAG,
            USER_JE_CATEGORY_NAME,USER_JE_SOURCE_NAME,DATE_CREATED,CREATED_BY,REFERENCE11,REFERENCE12)
            SELECT
            'NEW' STATUS,
            '2121' SET_OF_BOOKS_ID,
            h.JE_BATCH_ID||'-'||'LPTI_MANUAL' BATCH_NAME,
            h.JE_BATCH_ID||'-'||'LPTI_MANUAL' BATCH_DESCRIPTION,
            h.name JOURNAL_NAME,
            h.DESCRIPTION JOURNAL_DESCRIPTION,
            l.DESCRIPTION LINE_DESCRIPTION,
            s.SEGMENT1,
            s.SEGMENT2,
            s.SEGMENT3,
            s.SEGMENT4,
            s.SEGMENT5,
            s.SEGMENT6,
            s.SEGMENT7,
            s.SEGMENT8,
            ROUND(TO_NUMBER(ABS(l.ENTERED_DR)),2) ENTERED_DR,
            ROUND(TO_NUMBER(ABS(l.ENTERED_CR)),2) ENTERED_CR,
            ROUND(TO_NUMBER(ABS(l.ENTERED_DR * NVL(H.CURRENCY_CONVERSION_RATE,1))),2) ACCOUNTED_DR,
            ROUND(TO_NUMBER(ABS(l.ENTERED_CR * NVL(H.CURRENCY_CONVERSION_RATE,1))),2) ACCOUNTED_CR,
            l.EFFECTIVE_DATE GL_DATE,
            h.CURRENCY_CODE CURR_CODE,
            'A' ACTUAL_FLG,
            'LPTI_MANUAL' JE_CATEGORY,
            'LPTI_MANUAL' JE_SOURCE,
            l.EFFECTIVE_DATE,
            1110 CREATED_BY,
            'TA_JOURNAL_IMPORT',
            NULL
            FROM
                 GL_JE_HEADERS@APPS_OLD.LPTI.COM h
                ,GL_JE_LINES@APPS_OLD.LPTI.COM l
                , GL_CODE_COMBINATIONS@APPS_OLD.LPTI.COM s 
            where h.JE_HEADER_ID = l.JE_HEADER_ID
            and s.CODE_COMBINATION_ID = l.CODE_COMBINATION_ID
            and h.PERIOD_NAME IN ('MAR-24','APR-24','MAY-24','JUN-24','JUL-24')
            AND h.JE_SOURCE NOT IN ('Payables', 'Receivables')           ;

        END LOOP;

        EXCEPTION
            WHEN OTHERS THEN
            FND_FILE.PUT_line (FND_FILE.LOG, 'EXCEPTION PERIOD_NAME'||P_PERIOD_NAME);
         DBMS_OUTPUT.PUT_LINE(SQLERRM);
       END;

        commit;

 END;
/

CREATE OR REPLACE PROCEDURE APPS.LPTI_AP_DATA_UPLOAD_28_out 
                                                   
IS
 
   V_VENDOR_ID             NUMBER;
   M_CREATION_DATE         DATE           := SYSDATE;
   M_CREATED_BY            NUMBER         := fnd_profile.VALUE ('USER_ID');
   M_LAST_UPDATED_DATE     DATE           := SYSDATE;
   M_LAST_UPDATED_BY       NUMBER         := fnd_profile.VALUE ('USER_ID');
   p_org_id           NUMBER      := fnd_profile.value ('org_id' );    
   V_VENDOR_SITE_ID        NUMBER;
   V_TERM_ID               NUMBER;
   V_STATUS                BOOLEAN        := TRUE;
   V_INVOICE_COUNT         NUMBER;
   V_PERIOD_STATUS         NUMBER;
   V_INVOICE_DATE          DATE;
   V_INV_TYPE_COUNT        NUMBER;
   V_CURR_COUNT            NUMBER;
   V_SOURCE_COUNT          NUMBER;
   V_CURRENCY_CODE         VARCHAR2 (5);
   V_EXT_RATE_TYPE_CODE    VARCHAR2 (25);
   V_EXT_RATE_TYPE_COUNT   NUMBER;
   V_USER_CON_TYPE         VARCHAR2 (25);
   V_CONVERSION_RATE       NUMBER;
   V_INVOICE_ID            NUMBER;
   V_TAX_CODE              VARCHAR2 (50);
   V_CCID                  NUMBER;
   V_CODE_ID               NUMBER;
   V_INVOICE_LINE_ID       NUMBER;
   V_RECORD_INSERTED       NUMBER         := 0;
   V_RECORD_REJECT         NUMBER         := 0;
   V_CONC_REQUEST_ID       NUMBER;
   V_SOURCE                VARCHAR2 (25);
   V_DESCRIPTION           VARCHAR2 (240);
   V_DOC_CAT_CODE          VARCHAR2 (50);
   V_CURRENCY               VARCHAR2(5);
   V_EXCHANGE_RATE           NUMBER;
   V_EXCHANGE_DATE           DATE;
   V_EXCHANGE_RATE_TYPE    VARCHAR2(25);
   V_CODE_COMBINATION_ID   NUMBER;
   --P_ORG_ID                NUMBER :=0;
   V_PAY_GROUP_LOOKUP_CODE VARCHAR2(25);

   CURSOR CUR_INVOICE_HEADER
   IS
      SELECT
        *
      FROM LPTI_UPLOAD_AP_INV; 
      
   
BEGIN
               dbms_output.put_line('A-1');
               FND_GLOBAL.APPS_INITIALIZE('1130','50252','200');
/*
      fnd_global.apps_initialize
                           (user_id           => fnd_profile.VALUE ('USER_ID'),
                            resp_id           => fnd_profile.VALUE ('RESP_ID'),
                            resp_appl_id      => fnd_profile.VALUE ('resp_appl_id'));*/
               dbms_output.put_line('A-2');
               
   FOR I IN CUR_INVOICE_HEADER
   LOOP
           
             
------------------------------------------------------------------------
/* Check Wheather Invoice Source is defined or not*/
-------------------------------------------------------------------------
/*      BEGIN
         IF i.SOURCE IS NOT NULL
         THEN
            SELECT COUNT (1)
              INTO v_source_count
              FROM fnd_lookup_values
             WHERE lookup_type = 'SOURCE'
               AND lookup_code = TRIM (UPPER (i.SOURCE))
               AND enabled_flag = 'Y';

            IF v_source_count = 0
            THEN
               v_status := FALSE;
               fnd_file.put_line
                           (fnd_file.output,
                               'Invoice Source Code is wrong for invoice no.'
                            || I.RECEIPT_NUMBER
                           );
            --  ELSE
             --   V_STATUS := TRUE;
            END IF;
         ELSE
            fnd_file.put_line
                         (fnd_file.output,
                             'Invoice Source Code cannot be null invoice no.'
                          || I.RECEIPT_NUMBER
                         );
         END IF;
      END;
*/




      /*Getting Invoice Hedear Id*/

      SELECT AP_INVOICES_INTERFACE_S.NEXTVAL
        INTO V_INVOICE_ID
        FROM DUAL;

------------------------------------------------------------------------
/* Inserting Data into AP_Invoices_interface table */
-------------------------------------------------------------------------
      --IF V_STATUS = TRUE
      --THEN
                  dbms_output.put_line('7');
         BEGIN
              dbms_output.put_line('8');
            --V_RECORD_INSERTED := 1;
           
           INSERT INTO AP_INVOICES_INTERFACE AII
                        (AII.INVOICE_ID, 
                         AII.INVOICE_NUM, 
                         AII.CREATION_DATE,
                         AII.CREATED_BY, 
                         AII.LAST_UPDATE_DATE,
                         AII.LAST_UPDATED_BY, 
                         AII.INVOICE_TYPE_LOOKUP_CODE,
                         AII.INVOICE_DATE, 
                         AII.vendor_NUM,
                         AII.vendor_site_CODE,
                         AII.INVOICE_AMOUNT,
                         AII.INVOICE_CURRENCY_CODE,
                         AII.EXCHANGE_RATE,
                         AII.EXCHANGE_DATE,
                         AII.EXCHANGE_RATE_TYPE,
                         AII.TERMS_ID,
                         AII.ATTRIBUTE13,--ATTRIBUTE13 IS STORE THE invoice_id
                         AII.ATTRIBUTE15,
                         AII.TERMS_DATE, 
                         AII.DESCRIPTION,
                         AII.SOURCE, 
                         AII.GROUP_ID,
                         AII.ORG_ID, 
                         AII.GL_DATE,
                         AII.PAY_GROUP_LOOKUP_CODE 
                        )                                
                 VALUES (V_INVOICE_ID, 
                         I.INVOICE_NUM, 
                         M_CREATION_DATE,
                         M_CREATED_BY, 
                         M_LAST_UPDATED_DATE,
                         M_LAST_UPDATED_BY,
                         DECODE(I.TYPE,'SI','STANDARD','CN','CREDIT'), 
                         I.GL_DATE, 
                         I.SEGMENT1,
                         'IBT',
                         I.AMOUNT,
                         'INR',
                         V_EXCHANGE_RATE,
                         I.GL_DATE,
                         NULL,    
                         10000,
                         NULL,
                         NULL,
                         I.GL_DATE, 
                         'Outstanding INV '||I.GL_DATE,
                         'TA_MANUAL_IBT',
                         'TA_MANUAL_IBT', 
                         FND_PROFILE.VALUE ('ORG_ID' ), 
                         I.GL_DATE,
                         'TA MANUAL IBT'
                        );
                        
                         /*INSERT INTO AP_INVOICES_INTERFACE AII
                        (AII.INVOICE_ID, 
                         AII.INVOICE_NUM, 
                         AII.CREATION_DATE,
                         AII.CREATED_BY, 
                         AII.LAST_UPDATE_DATE,
                         AII.LAST_UPDATED_BY, 
                         AII.INVOICE_TYPE_LOOKUP_CODE,
                         AII.INVOICE_DATE, 
                         AII.VENDOR_NUM,
                         AII.VENDOR_SITE_CODE,
                         AII.INVOICE_AMOUNT,
                         AII.INVOICE_CURRENCY_CODE,
                         AII.EXCHANGE_RATE,
                         AII.EXCHANGE_DATE,
                         AII.TERMS_ID,
                       --aii.TERMS_NAME,
                         AII.TERMS_DATE, 
                         AII.DESCRIPTION,
                         AII.SOURCE, 
                         AII.ORG_ID, 
                         AII.GL_DATE,
                         PAY_GROUP_LOOKUP_CODE  ,
                         GROUP_ID                       
                        )                             
                 VALUES (V_INVOICE_ID, 
                         I.INVOICE_NUM, 
                         M_CREATION_DATE,
                         M_CREATED_BY, 
                         M_LAST_UPDATED_DATE,
                         M_LAST_UPDATED_BY,
                         DECODE(I.TYPE,'SI','STANDARD','CN','CREDIT'), 
                         I.GL_DATE, 
                         I.SEGMENT1,
                         'IBT',
                         I.AMOUNT,
                         'INR',
                         V_EXCHANGE_RATE,
                         I.GL_DATE,
                          --V_EXCHANGE_RATE_TYPE,    
                         DECODE(I.TYPE,'SI','10000','CN',NULL),
                    --  'Immediate',
                          I.GL_DATE, 
                         'Outstanding INV '||I.GL_DATE,
                         'LPTI_TA_IBT', 
                          P_ORG_ID, 
                         I.GL_DATE,
                         'TA MANUAL IBT',--'OTHERS IBT',
                         to_char(trunc(sysdate),'ddmmrrrr')
                        -- 'STD INV',
                        -- V_PAY_GROUP_LOOKUP_CODE
                        ); */
                        
                        
           
                        
                        
                        
         EXCEPTION
            WHEN OTHERS
            THEN
               FND_FILE.PUT_LINE (FND_FILE.OUTPUT,
                                     'Error in Loading Data for invoice no.'
                                  || I.SEGMENT1||'-'||I.TYPE
                                 );
               V_STATUS := FALSE;

          END;
 


            SELECT AP_INVOICE_LINES_INTERFACE_S.NEXTVAL
              INTO V_INVOICE_LINE_ID
              FROM DUAL;



               BEGIN
                  INSERT INTO ap_invoice_lines_interface ail
                              (ail.invoice_id, 
                               ail.invoice_line_id,
                               ail.line_number,
                               ail.line_type_lookup_code,
                               ail.amount,
                               ail.description,
                               --ail.tax_code,
                               AIL.DIST_CODE_CONCATENATED,
                               AIL.ACCOUNTING_DATE,
                               ail.creation_date, 
                               ail.created_by,
                               ail.last_update_date, 
                               ail.last_updated_by,
                               ail.org_id
                              )
                       VALUES (V_INVOICE_ID, 
                               V_INVOICE_LINE_ID,
                               1,
                               'ITEM',
                               I.AMOUNT,
                               'Outstanding INV '||I.GL_DATE,
                               --NULL,
                               '13516.12400.00000.000000000000.000000.00000.00000.000',
                               --'13516'||'.'||i.account_code||'.'||'00000'||'.'||'000000'||'.'||'00000'||'.'||'000000000000'||'.'||'00000'||'.'||'000',
                               I.GL_DATE,
                               M_CREATION_DATE, 
                               M_CREATED_BY,
                               M_LAST_UPDATED_DATE, 
                               M_LAST_UPDATED_BY,
                               P_ORG_ID
                              );
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     ROLLBACK;
                     V_STATUS := FALSE;
                     FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'Unable to insert data at line level for invoice no. '|| I.SEGMENT1||'-'||I.TYPE
                                       );

                     
               END;
       
   END LOOP;

   
   

EXCEPTION
   WHEN OTHERS
   THEN
   dbms_output.put_line('19');
      FND_FILE.PUT_LINE (FND_FILE.OUTPUT, 'Unable to insert Data');
END ;
/

CREATE OR REPLACE PROCEDURE APPS.XXAR_RECEIPT_APT_TEMP_DEL(
                                                       ERRBUFF OUT VARCHAR2,
                                                       RETCODE OUT VARCHAR2
                                                       ) IS

BEGIN

FND_FILE.PUT_LINE(FND_FILE.LOG,'DATA DELETED');

EXECUTE IMMEDIATE 'DROP TABLE XXAR_RECEIPT_API_TEMP';

COMMIT;
EXECUTE IMMEDIATE 'CREATE TABLE XXAR_RECEIPT_API_TEMP ( STATUS  NUMBER )';
EXCEPTION 
WHEN OTHERS THEN
FND_FILE.PUT_LINE(FND_FILE.LOG,'EXCEPTION :'||SQLERRM);

END;
/

CREATE OR REPLACE procedure APPS.lpti_ap_aging_fix(v_run_id varchar2) is

PP_BAL NUMBER;
CR_BAL NUMBER;
SI_BAL NUMBER;

PP_ADJ NUMBER:=0;
SI_ADJ NUMBER;
V_AMT  NUMBER:=0;
V_BAL_AMT   NUMBER:=0;
V_REF_INV_ID    VARCHAR2(250):=NULL;
V_COUNT NUMBER:=0;
v_si_amount number:=0;
v_pp_amount number:=0;
begin

--final pro

---- run the below script before runing the procedure ------

    begin
    
    begin
    update lpti_ap_open_item_wise_os
    set si_amount=Remaining_amt,
    pp_amount=0,
    REF_INV_ID=null
    where invoice_type IN ('STANDARD')
    and run_req_id=v_run_id
    and vendor_id <> 9323;
    exception when others then 
    null;   
    end;
               
    begin
    update lpti_ap_open_item_wise_os
    set pp_amount=Remaining_amt,
    si_amount=0,
    REF_INV_ID=null
    where invoice_type IN ('PREPAYMENT','CREDIT')
    and run_req_id=v_run_id
    and vendor_id <> 9323;
    exception when others then 
    null;   
    end;
    
    commit;
               
    end;

---- run the above script before runing the procedure ------


for i in (select invoice_id ,
                 VENDOR_ID,
                 SUPPLIER_NUMBER,
                 invoice_type,
                 --OUTSTANDING_AMT_FUNC_T,
                 --OUTSTANDING_AMT_FUNC_02,
                 DAYS,
                 --ADDJ_OUTS_BAL,
                 NVL(Remaining_amt,0) Remaining_amt,
                 nvl(pp_amount,0) pp_amount,
                 nvl(si_amount,0) si_amount,
                 run_req_id
            from lpti_ap_open_item_wise_os
           where invoice_type IN ('PREPAYMENT','CREDIT')
             and run_req_id=v_run_id
             and round(nvl(pp_amount,0)) <> 0
             and vendor_id <> 9323
             --and round(pp_amount) <> 0
           ORDER BY VENDOR_ID,DAYS DESC ,INVOICE_ID) LOOP
           
FOR J IN (select invoice_id ,
                 VENDOR_ID,
                 SUPPLIER_NUMBER,
                 invoice_type,
                 --OUTSTANDING_AMT_FUNC_T,
                 --OUTSTANDING_AMT_FUNC_02,
                 DAYS,
                -- NVL(ADDJ_OUTS_BAL,0) ADDJ_OUTS_BAL,
                 nvl(pp_amount,0) pp_amount,
                 nvl(si_amount,0) si_amount,
                 run_req_id
            from lpti_ap_open_item_wise_os
           where invoice_type IN ('STANDARD')
             and run_req_id=v_run_id
             AND VENDOR_ID=I.VENDOR_ID
             and round(nvl(si_amount,0)) <> 0
             and vendor_id <> 9323
             --and round(si_amount) <> 0
             and rownum=1
           ORDER BY DAYS DESC ,INVOICE_ID )   LOOP

--V_BAL_AMOUNT;

-- FOR SI----

v_si_amount:=j.si_amount;
v_pp_amount:=i.pp_amount;

if abs(v_pp_amount) < abs(v_si_amount) and abs(v_pp_amount)>0 then

update lpti_ap_open_item_wise_os l
set 
l.si_amount=v_pp_amount+v_si_amount,
l.pp_amount=0,
ref_inv_id=j.invoice_id
where l.vendor_id=i.vendor_id
and l.invoice_id=i.invoice_id
and l.run_req_id=i.run_req_id
and vendor_id <> 9323;
v_si_amount:=v_pp_amount+v_si_amount;
v_pp_amount:=0;
commit;

--*************************************
update lpti_ap_open_item_wise_os kk
set kk.si_amount=v_si_amount,
kk.pp_amount=v_pp_amount
where kk.invoice_id=j.invoice_id
and vendor_id <> 9323;
--*************************************
commit;
--insert into test (text,SI_ADJ) values ('1-'||j.invoice_id,v_si_amount); 
exit;

elsif abs(v_pp_amount) > abs(v_si_amount) and abs(v_si_amount) >0 then

update lpti_ap_open_item_wise_os l
set l.si_amount=0,
l.pp_amount=v_pp_amount+v_si_amount,
ref_inv_id=i.invoice_id
where l.vendor_id=i.vendor_id
and l.invoice_id=j.invoice_id
and l.run_req_id=i.run_req_id
and vendor_id <> 9323;
v_pp_amount:=v_pp_amount+v_si_amount;
v_si_amount:=0;
commit;

--*************************************
update lpti_ap_open_item_wise_os kk
set kk.si_amount=v_si_amount,
kk.pp_amount=v_pp_amount
where kk.invoice_id=i.invoice_id
and kk.run_req_id=i.run_req_id
and vendor_id <> 9323;
--*************************************
commit;

--insert into test (text) values ('2-'||i.invoice_id);

--elsif abs(i.pp_amount) = abs(j.si_amount) then
--update LPTI_AP_OPEN_ITEM_31MAR2015 l
--set l.si_amount=0,
--l.pp_amount=0,
--ref_inv_id=j.invoice_id
--where l.vendor_id=i.vendor_id
--and l.invoice_id=j.invoice_id;
--commit;
--insert into test (text) values ('3');
end if;


commit;
END LOOP;

END LOOP;
  
commit;

----after runing the below procedure  run the below script------

UPDATE lpti_ap_open_item_wise_os
SET PP_AMOUNT=0
where SI_amount=0
and invoice_type='STANDARD'
and run_req_id=v_run_id
AND REF_INV_ID IS NOT NULL
and vendor_id <> 9323;

commit;

UPDATE lpti_ap_open_item_wise_os
SET SI_AMOUNT=0
where pp_amount=0
and invoice_type IN ('CREDIT','PREPAYMENT')
and run_req_id=v_run_id
AND REF_INV_ID IS NOT NULL
and vendor_id <> 9323;

commit;


----after runing the below procedure  run the below script------


--query to fetch the data for final statment



--SELECT 
--aa.vendor_id,
--aa.SUPPLIER_NUMBER,
--aa.SUPPLIER_Name,
--sum(nvl(aa.pp_amount,0))+sum(nvl(aa.si_amount,0)) remaining_amount,
--aa.invoice_id,
--aa.invoice_num ,
--(select api.gl_date from ap_invoices_all@appsprod_dblink api where api.invoice_id=aa.invoice_id) gl_date,
--(select api.invoice_date from ap_invoices_all@appsprod_dblink api where api.invoice_id=aa.invoice_id) invoice_date,
--aa.days
--FROM lpti_ap_open_item_31mar2015_02 aa
--where aa.vendor_id in (select bb.vendor_id from xx_vendor_id bb where bb.vendor_id=aa.vendor_id)
--group by aa.invoice_id,aa.vendor_id,aa.SUPPLIER_NUMBER,
--aa.SUPPLIER_Name,aa.invoice_num,aa.days
--having sum(nvl(aa.pp_amount,0))+sum(nvl(aa.si_amount,0)) <> 0
--order by remaining_amount desc


end;
/

CREATE OR REPLACE PROCEDURE APPS.LPTI_GL_TA_INTERFACE(retcode OUT VARCHAR2,errbuf OUT VARCHAR2,P_ORG_ID VARCHAR2,P_FROM_DATE VARCHAR2,P_TILL_DATE VARCHAR2 ) IS
nCNT NUMBER :=0; vNAME VARCHAR2(1000);
BEGIN
-----PROCEDURE TO TRANSFER TOUR FILES CASH ENTRIES FROM TRAVEL ASSIST TO GL -----------  
------------ENTERING TOUR FILES DR ENTRIES -----
FOR I IN (SELECT FILE_CODE,REMARKS,BILL_PASS_INR_AMT,ENTERED_DATE
FROM AP_BILL_DTL@TAPROD_DBLINK A
WHERE VCH_TYP_CODE = '00009'
AND ENTERED_DATE BETWEEN P_FROM_DATE AND P_TILL_DATE
AND (FILE_CODE,ENTERED_DATE,BILL_PASS_INR_AMT) NOT IN
(SELECT CC.SEGMENT3,VH.DEFAULT_EFFECTIVE_DATE,VD.ACCOUNTED_CR
from gl_je_headers VH,
gl_je_lines VD,
gl_code_combinations CC
where VH.je_header_id = VD.je_header_id
and VD.code_combination_id = CC.code_combination_id
AND SEGMENT2='12400')
ORDER BY ENTERED_DATE
)
LOOP
	BEGIN
		SELECT COUNT(1) INTO nCNT FROM GL_JE_HEADERS
		WHERE NAME LIKE 'FILES CASH%' AND DEFAULT_EFFECTIVE_DATE = I.ENTERED_DATE;
	EXCEPTION
	WHEN OTHERS THEN
		nCNT := 0;
	END;
vNAME := 'FILES CASH -'||I.ENTERED_DATE ||'_'||nCNT+1;
 INSERT INTO GL_INTERFACE
(STATUS,SET_OF_BOOKS_ID,REFERENCE1,REFERENCE2,REFERENCE4,REFERENCE5,REFERENCE10, 
SEGMENT1,
SEGMENT2,
SEGMENT3,
SEGMENT4,
SEGMENT5,
SEGMENT6,
SEGMENT7,
SEGMENT8,
ENTERED_DR,ENTERED_CR,ACCOUNTED_DR,ACCOUNTED_CR,ACCOUNTING_DATE,CURRENCY_CODE,ACTUAL_FLAG,
USER_JE_CATEGORY_NAME,USER_JE_SOURCE_NAME,DATE_CREATED,CREATED_BY) VALUES
('NEW' ,
'1001' ,
vNAME   ,
vNAME   ,
vNAME  ,
vNAME ,
I.REMARKS ,
'13516' ,
'12400' ,
I.FILE_CODE ,
'000000' ,
'00000' ,
'00000000' ,
'00000' ,
'000' ,
DECODE(SIGN(I.BILL_PASS_INR_AMT),1,I.BILL_PASS_INR_AMT,0) ,
DECODE(SIGN(I.BILL_PASS_INR_AMT),-1,ABS(I.BILL_PASS_INR_AMT),0) ,
DECODE(SIGN(I.BILL_PASS_INR_AMT),1,I.BILL_PASS_INR_AMT,0) ,
DECODE(SIGN(I.BILL_PASS_INR_AMT),-1,ABS(I.BILL_PASS_INR_AMT),0) ,
I.ENTERED_DATE ,
'INR' ,
'A' ,
'LPTI_JV_CV_FILE' ,
'LPTI_TA_CASH' ,
SYSDATE ,
-1 );
END LOOP;
------------ENTERING CASH CR ENTRY -----
FOR J IN (SELECT ENTERED_DATE,SUM(BILL_PASS_INR_AMT) AMT
FROM AP_BILL_DTL@TAPROD_DBLINK A
WHERE VCH_TYP_CODE = '00009'
AND ENTERED_DATE BETWEEN P_FROM_DATE AND P_TILL_DATE
AND (FILE_CODE,ENTERED_DATE,BILL_PASS_INR_AMT) NOT IN
(SELECT CC.SEGMENT3,VH.DEFAULT_EFFECTIVE_DATE,VD.ACCOUNTED_CR
from gl_je_headers VH,
gl_je_lines VD,
gl_code_combinations CC
where VH.je_header_id = VD.je_header_id
and VD.code_combination_id = CC.code_combination_id
AND SEGMENT2='12400')
GROUP BY ENTERED_DATE
ORDER BY ENTERED_DATE
)
LOOP
BEGIN
	SELECT COUNT(1) INTO nCNT FROM GL_JE_HEADERS
	WHERE NAME LIKE 'FILES CASH%' AND DEFAULT_EFFECTIVE_DATE = J.ENTERED_DATE;
	EXCEPTION
	WHEN OTHERS THEN
		nCNT := 0;
	END;
vNAME := 'FILES CASH -'||J.ENTERED_DATE ||'_'||nCNT+1;
INSERT INTO GL_INTERFACE
(STATUS,SET_OF_BOOKS_ID,REFERENCE1,REFERENCE2,REFERENCE4,REFERENCE5,REFERENCE10,
SEGMENT1,
SEGMENT2,
SEGMENT3,
SEGMENT4,
SEGMENT5,
SEGMENT6,
SEGMENT7,
SEGMENT8,
ENTERED_DR,ENTERED_CR,ACCOUNTED_DR,ACCOUNTED_CR,ACCOUNTING_DATE,CURRENCY_CODE,ACTUAL_FLAG,
USER_JE_CATEGORY_NAME,USER_JE_SOURCE_NAME,DATE_CREATED,CREATED_BY) VALUES
('NEW',
'1001',
vNAME   ,
vNAME   ,
vNAME  ,
vNAME ,
'CASH - '||J.ENTERED_DATE ,
'13516' ,
'21550',
'00000' ,
'000000' ,
'00000' ,
'00000000' ,
'00000' ,
'000' ,
0 ,
J.AMT ,
0 ,
J.AMT ,
J.ENTERED_DATE ,
'INR' ,
'A',
'LPTI_JV_CV_FILE' ,
'LPTI_TA_CASH' ,
SYSDATE ,
-1  );
END LOOP;
COMMIT;
END;
/

CREATE OR REPLACE PROCEDURE APPS.LPTI_AP_DATA_UPLOAD_281 
                                                   
IS
 
   V_VENDOR_ID             NUMBER;
   M_CREATION_DATE         DATE           := SYSDATE;
   M_CREATED_BY            NUMBER         := fnd_profile.VALUE ('USER_ID');
   M_LAST_UPDATED_DATE     DATE           := SYSDATE;
   M_LAST_UPDATED_BY       NUMBER         := fnd_profile.VALUE ('USER_ID');
   --p_org_id           NUMBER      := fnd_profile.value ('org_id' );    
   V_VENDOR_SITE_ID        NUMBER;
   V_TERM_ID               NUMBER;
   V_STATUS                BOOLEAN        := TRUE;
   V_INVOICE_COUNT         NUMBER;
   V_PERIOD_STATUS         NUMBER;
   V_INVOICE_DATE          DATE;
   V_INV_TYPE_COUNT        NUMBER;
   V_CURR_COUNT            NUMBER;
   V_SOURCE_COUNT          NUMBER;
   V_CURRENCY_CODE         VARCHAR2 (5);
   V_EXT_RATE_TYPE_CODE    VARCHAR2 (25);
   V_EXT_RATE_TYPE_COUNT   NUMBER;
   V_USER_CON_TYPE         VARCHAR2 (25);
   V_CONVERSION_RATE       NUMBER;
   V_INVOICE_ID            NUMBER;
   V_TAX_CODE              VARCHAR2 (50);
   V_CCID                  NUMBER;
   V_CODE_ID               NUMBER;
   V_INVOICE_LINE_ID       NUMBER;
   V_RECORD_INSERTED       NUMBER         := 0;
   V_RECORD_REJECT         NUMBER         := 0;
   V_CONC_REQUEST_ID       NUMBER;
   V_SOURCE                VARCHAR2 (25);
   V_DESCRIPTION           VARCHAR2 (240);
   V_DOC_CAT_CODE          VARCHAR2 (50);
   V_CURRENCY               VARCHAR2(5);
   V_EXCHANGE_RATE           NUMBER;
   V_EXCHANGE_DATE           DATE;
   V_EXCHANGE_RATE_TYPE    VARCHAR2(25);
   V_CODE_COMBINATION_ID   NUMBER;
   P_ORG_ID                NUMBER :=0;
   V_PAY_GROUP_LOOKUP_CODE VARCHAR2(25);

   CURSOR CUR_INVOICE_HEADER
   IS
      SELECT
        *
      FROM LPTI_UPLOAD_AP_INV1; 
      
   
BEGIN
               dbms_output.put_line('A-1');
               FND_GLOBAL.APPS_INITIALIZE('1130','50252','200');
/*
      fnd_global.apps_initialize
                           (user_id           => fnd_profile.VALUE ('USER_ID'),
                            resp_id           => fnd_profile.VALUE ('RESP_ID'),
                            resp_appl_id      => fnd_profile.VALUE ('resp_appl_id'));*/
               dbms_output.put_line('A-2');
               
   FOR I IN CUR_INVOICE_HEADER
   LOOP
           
             
------------------------------------------------------------------------
/* Check Wheather Invoice Source is defined or not*/
-------------------------------------------------------------------------
/*      BEGIN
         IF i.SOURCE IS NOT NULL
         THEN
            SELECT COUNT (1)
              INTO v_source_count
              FROM fnd_lookup_values
             WHERE lookup_type = 'SOURCE'
               AND lookup_code = TRIM (UPPER (i.SOURCE))
               AND enabled_flag = 'Y';

            IF v_source_count = 0
            THEN
               v_status := FALSE;
               fnd_file.put_line
                           (fnd_file.output,
                               'Invoice Source Code is wrong for invoice no.'
                            || I.RECEIPT_NUMBER
                           );
            --  ELSE
             --   V_STATUS := TRUE;
            END IF;
         ELSE
            fnd_file.put_line
                         (fnd_file.output,
                             'Invoice Source Code cannot be null invoice no.'
                          || I.RECEIPT_NUMBER
                         );
         END IF;
      END;
*/




      /*Getting Invoice Hedear Id*/

      SELECT AP_INVOICES_INTERFACE_S.NEXTVAL
        INTO V_INVOICE_ID
        FROM DUAL;

------------------------------------------------------------------------
/* Inserting Data into AP_Invoices_interface table */
-------------------------------------------------------------------------
      --IF V_STATUS = TRUE
      --THEN
                  dbms_output.put_line('7');
         BEGIN
              dbms_output.put_line('8');
            --V_RECORD_INSERTED := 1;
            INSERT INTO AP_INVOICES_INTERFACE AII
                        (AII.INVOICE_ID, 
                         AII.INVOICE_NUM, 
                         AII.CREATION_DATE,
                         AII.CREATED_BY, 
                         AII.LAST_UPDATE_DATE,
                         AII.LAST_UPDATED_BY, 
                         AII.INVOICE_TYPE_LOOKUP_CODE,
                         AII.INVOICE_DATE, 
                         AII.VENDOR_NUM,
                         AII.VENDOR_SITE_CODE,
                         AII.INVOICE_AMOUNT,
                         AII.INVOICE_CURRENCY_CODE,
                         AII.EXCHANGE_RATE,
                         AII.EXCHANGE_DATE,
                         AII.EXCHANGE_RATE_TYPE,
                         AII.TERMS_ID,
                         aii.TERMS_NAME,
                         AII.TERMS_DATE, 
                         AII.DESCRIPTION,
                         AII.SOURCE, 
                         AII.ORG_ID, 
                         AII.GL_DATE,
                         PAY_GROUP_LOOKUP_CODE  ,
                         GROUP_ID                       
                        )                                
                 VALUES (V_INVOICE_ID, 
                         I.INVOICE_NUM, 
                         M_CREATION_DATE,
                         M_CREATED_BY, 
                         M_LAST_UPDATED_DATE,
                         M_LAST_UPDATED_BY,
                         DECODE(I.TYPE,'SI','STANDARD','CN','CREDIT'), 
                         I.GL_DATE, 
                         I.SEGMENT1,
                         'IBT',
                         I.AMOUNT,
                         'INR',
                         V_EXCHANGE_RATE,
                         I.GL_DATE,
                         'User',    
                         10000,
                         'IMMEDIATE',
                          I.GL_DATE, 
                         'WRITEOFF INV '||I.GL_DATE,
                         'LPTI_TA_IBT', 
                          P_ORG_ID, 
                         I.GL_DATE,
                         'OTHERS IBT',
                         to_char(trunc(sysdate),'ddmmrrrr')
                        -- 'STD INV',
                        -- V_PAY_GROUP_LOOKUP_CODE
                        );
         EXCEPTION
            WHEN OTHERS
            THEN
               FND_FILE.PUT_LINE (FND_FILE.OUTPUT,
                                     'Error in Loading Data for invoice no.'
                                  || I.SEGMENT1||'-'||I.TYPE
                                 );
               V_STATUS := FALSE;

          END;
 


            SELECT AP_INVOICE_LINES_INTERFACE_S.NEXTVAL
              INTO V_INVOICE_LINE_ID
              FROM DUAL;



               BEGIN
                  INSERT INTO ap_invoice_lines_interface ail
                              (ail.invoice_id, 
                               ail.invoice_line_id,
                               ail.line_number,
                               ail.line_type_lookup_code,
                               ail.amount,
                               ail.description,
                               --ail.tax_code,
                               AIL.DIST_CODE_CONCATENATED,
                               AIL.ACCOUNTING_DATE,
                               ail.creation_date, 
                               ail.created_by,
                               ail.last_update_date, 
                               ail.last_updated_by,
                               ail.org_id
                              )
                       VALUES (V_INVOICE_ID, 
                               V_INVOICE_LINE_ID,
                               1,
                               'ITEM',
                               I.AMOUNT,
                               'WRITEOFF INV '||I.GL_DATE,
                               --NULL,
                               '13516'||'.'||i.account_code||'.'||'00000'||'.'||'000000000000'||'.'||'000000'||'.'||'00000'||'.'||'00000'||'.'||'000',
                               I.GL_DATE,
                               M_CREATION_DATE, 
                               M_CREATED_BY,
                               M_LAST_UPDATED_DATE, 
                               M_LAST_UPDATED_BY,
                               P_ORG_ID
                              );
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     ROLLBACK;
                     V_STATUS := FALSE;
                     FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'Unable to insert data at line level for invoice no. '|| I.SEGMENT1||'-'||I.TYPE
                                       );

                     
               END;
       
   END LOOP;

   
   

EXCEPTION
   WHEN OTHERS
   THEN
   dbms_output.put_line('19');
      FND_FILE.PUT_LINE (FND_FILE.OUTPUT, 'Unable to insert Data');
END ;
/

CREATE OR REPLACE PROCEDURE APPS.LPTI_AP_DATA_UPLOAD_28 
                                                   
IS
 
   V_VENDOR_ID             NUMBER;
   M_CREATION_DATE         DATE           := SYSDATE;
   M_CREATED_BY            NUMBER         := fnd_profile.VALUE ('USER_ID');
   M_LAST_UPDATED_DATE     DATE           := SYSDATE;
   M_LAST_UPDATED_BY       NUMBER         := fnd_profile.VALUE ('USER_ID');
   --p_org_id           NUMBER      := fnd_profile.value ('org_id' );    
   V_VENDOR_SITE_ID        NUMBER;
   V_TERM_ID               NUMBER;
   V_STATUS                BOOLEAN        := TRUE;
   V_INVOICE_COUNT         NUMBER;
   V_PERIOD_STATUS         NUMBER;
   V_INVOICE_DATE          DATE;
   V_INV_TYPE_COUNT        NUMBER;
   V_CURR_COUNT            NUMBER;
   V_SOURCE_COUNT          NUMBER;
   V_CURRENCY_CODE         VARCHAR2 (5);
   V_EXT_RATE_TYPE_CODE    VARCHAR2 (25);
   V_EXT_RATE_TYPE_COUNT   NUMBER;
   V_USER_CON_TYPE         VARCHAR2 (25);
   V_CONVERSION_RATE       NUMBER;
   V_INVOICE_ID            NUMBER;
   V_TAX_CODE              VARCHAR2 (50);
   V_CCID                  NUMBER;
   V_CODE_ID               NUMBER;
   V_INVOICE_LINE_ID       NUMBER;
   V_RECORD_INSERTED       NUMBER         := 0;
   V_RECORD_REJECT         NUMBER         := 0;
   V_CONC_REQUEST_ID       NUMBER;
   V_SOURCE                VARCHAR2 (25);
   V_DESCRIPTION           VARCHAR2 (240);
   V_DOC_CAT_CODE          VARCHAR2 (50);
   V_CURRENCY               VARCHAR2(5);
   V_EXCHANGE_RATE           NUMBER;
   V_EXCHANGE_DATE           DATE;
   V_EXCHANGE_RATE_TYPE    VARCHAR2(25);
   V_CODE_COMBINATION_ID   NUMBER;
   P_ORG_ID                NUMBER :=0;
   V_PAY_GROUP_LOOKUP_CODE VARCHAR2(25);

   CURSOR CUR_INVOICE_HEADER
   IS
      SELECT
        *
      FROM LPTI_UPLOAD_AP_INV; 
      
   
BEGIN
               dbms_output.put_line('A-1');
               FND_GLOBAL.APPS_INITIALIZE('1130','50252','200');
/*
      fnd_global.apps_initialize
                           (user_id           => fnd_profile.VALUE ('USER_ID'),
                            resp_id           => fnd_profile.VALUE ('RESP_ID'),
                            resp_appl_id      => fnd_profile.VALUE ('resp_appl_id'));*/
               dbms_output.put_line('A-2');
               
   FOR I IN CUR_INVOICE_HEADER
   LOOP
           
             
------------------------------------------------------------------------
/* Check Wheather Invoice Source is defined or not*/
-------------------------------------------------------------------------
/*      BEGIN
         IF i.SOURCE IS NOT NULL
         THEN
            SELECT COUNT (1)
              INTO v_source_count
              FROM fnd_lookup_values
             WHERE lookup_type = 'SOURCE'
               AND lookup_code = TRIM (UPPER (i.SOURCE))
               AND enabled_flag = 'Y';

            IF v_source_count = 0
            THEN
               v_status := FALSE;
               fnd_file.put_line
                           (fnd_file.output,
                               'Invoice Source Code is wrong for invoice no.'
                            || I.RECEIPT_NUMBER
                           );
            --  ELSE
             --   V_STATUS := TRUE;
            END IF;
         ELSE
            fnd_file.put_line
                         (fnd_file.output,
                             'Invoice Source Code cannot be null invoice no.'
                          || I.RECEIPT_NUMBER
                         );
         END IF;
      END;
*/




      /*Getting Invoice Hedear Id*/

      SELECT AP_INVOICES_INTERFACE_S.NEXTVAL
        INTO V_INVOICE_ID
        FROM DUAL;

------------------------------------------------------------------------
/* Inserting Data into AP_Invoices_interface table */
-------------------------------------------------------------------------
      --IF V_STATUS = TRUE
      --THEN
                  dbms_output.put_line('7');
         BEGIN
              dbms_output.put_line('8');
            --V_RECORD_INSERTED := 1;
            INSERT INTO AP_INVOICES_INTERFACE AII
                        (AII.INVOICE_ID, 
                         AII.INVOICE_NUM, 
                         AII.CREATION_DATE,
                         AII.CREATED_BY, 
                         AII.LAST_UPDATE_DATE,
                         AII.LAST_UPDATED_BY, 
                         AII.INVOICE_TYPE_LOOKUP_CODE,
                         AII.INVOICE_DATE, 
                         AII.VENDOR_NUM,
                         AII.VENDOR_SITE_CODE,
                         AII.INVOICE_AMOUNT,
                         AII.INVOICE_CURRENCY_CODE,
                         AII.EXCHANGE_RATE,
                         AII.EXCHANGE_DATE,
                         AII.TERMS_ID,
                       --aii.TERMS_NAME,
                         AII.TERMS_DATE, 
                         AII.DESCRIPTION,
                         AII.SOURCE, 
                         AII.ORG_ID, 
                         AII.GL_DATE,
                         PAY_GROUP_LOOKUP_CODE  ,
                         GROUP_ID                       
                        )                                
                 VALUES (V_INVOICE_ID, 
                         I.INVOICE_NUM, 
                         M_CREATION_DATE,
                         M_CREATED_BY, 
                         M_LAST_UPDATED_DATE,
                         M_LAST_UPDATED_BY,
                         DECODE(I.TYPE,'SI','STANDARD','CN','CREDIT'), 
                         I.GL_DATE, 
                         I.SEGMENT1,
                         'IBT',
                         I.AMOUNT,
                         'INR',
                         V_EXCHANGE_RATE,
                         I.GL_DATE,
                          --V_EXCHANGE_RATE_TYPE,    
                         10000,
                    --  'Immediate',
                          I.GL_DATE, 
                         'WRITEOFF INV '||I.GL_DATE,
                         'LPTI_TA_IBT', 
                          P_ORG_ID, 
                         I.GL_DATE,
                         'OTHERS IBT',
                         to_char(trunc(sysdate),'ddmmrrrr')
                        -- 'STD INV',
                        -- V_PAY_GROUP_LOOKUP_CODE
                        );
         EXCEPTION
            WHEN OTHERS
            THEN
               FND_FILE.PUT_LINE (FND_FILE.OUTPUT,
                                     'Error in Loading Data for invoice no.'
                                  || I.SEGMENT1||'-'||I.TYPE
                                 );
               V_STATUS := FALSE;

          END;
 


            SELECT AP_INVOICE_LINES_INTERFACE_S.NEXTVAL
              INTO V_INVOICE_LINE_ID
              FROM DUAL;



               BEGIN
                  INSERT INTO ap_invoice_lines_interface ail
                              (ail.invoice_id, 
                               ail.invoice_line_id,
                               ail.line_number,
                               ail.line_type_lookup_code,
                               ail.amount,
                               ail.description,
                               --ail.tax_code,
                               AIL.DIST_CODE_CONCATENATED,
                               AIL.ACCOUNTING_DATE,
                               ail.creation_date, 
                               ail.created_by,
                               ail.last_update_date, 
                               ail.last_updated_by,
                               ail.org_id
                              )
                       VALUES (V_INVOICE_ID, 
                               V_INVOICE_LINE_ID,
                               1,
                               'ITEM',
                               I.AMOUNT,
                               'WRITEOFF INV '||I.GL_DATE,
                               --NULL,
                               '13516'||'.'||i.account_code||'.'||'00000'||'.'||'000000000000'||'.'||'000000'||'.'||'00000'||'.'||'00000'||'.'||'000',
                               I.GL_DATE,
                               M_CREATION_DATE, 
                               M_CREATED_BY,
                               M_LAST_UPDATED_DATE, 
                               M_LAST_UPDATED_BY,
                               P_ORG_ID
                              );
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     ROLLBACK;
                     V_STATUS := FALSE;
                     FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'Unable to insert data at line level for invoice no. '|| I.SEGMENT1||'-'||I.TYPE
                                       );

                     
               END;
       
   END LOOP;

   
   

EXCEPTION
   WHEN OTHERS
   THEN
   dbms_output.put_line('19');
      FND_FILE.PUT_LINE (FND_FILE.OUTPUT, 'Unable to insert Data');
END ;
/

CREATE OR REPLACE PROCEDURE APPS.LPTI_TA_UPLOAD_REM IS
p_invoice_id VARCHAR2(25);
P_VCH_TYPE VARCHAR2(25) :='ALL';
cPaygroup  VARCHAR2(100);
J NUMBER :=1;
CURSOR C1 IS SELECT DISTINCT INVOICE_DATE,GL_DATE,INVOICE_TYPE,VENDOR_NUM,SEGMENT2,INVOICE_CURRENCY_CODE,SUM(INVOICE_AMOUNT)INVOICE_AMOUNT FROM UPLOAD_REIMBURSEMENT@TAPROD_DBLINK
WHERE SEGMENT2 NOT IN ('30350','30950')
GROUP BY INVOICE_DATE,GL_DATE,INVOICE_TYPE,VENDOR_NUM,SEGMENT2,INVOICE_CURRENCY_CODE;
BEGIN
 FOR i in c1 loop
 -----FIND PAY GROUP OF VENDOR
/*	BEGIN
	SELECT PAY_GROUP_LOOKUP_CODE INTO cPaygroup FROM po_vendors WHERE
	     SEGMENT1 = 'V'||'-'||'R01071';
        EXCEPTION
	WHEN OTHERS THEN
	  cPaygroup := NULL;
	END;
	-----FIND PAY GROUP OF VENDOR*/
 select LPTI_AP_TA_INVOICES_S.nextval into p_invoice_id from dual;
 insert into ap_invoices_interface
    (invoice_id,
     INVOICE_DATE,
      GL_DATE,
     TERMS_NAME,
     invoice_type_lookup_code,
     vendor_NUM,
     vendor_site_CODE,
     ACCTS_PAY_CODE_COMBINATION_ID,
     invoice_amount,
     invoice_currency_code,
     source,
     group_id,
     ORG_ID,
     INVOICE_NUM)
VALUES
    ( p_invoice_id,
      TRUNC(I.INVOICE_DATE),
      TRUNC(I.GL_DATE),
     'IMMEDIATE',
      'STANDARD',
     'V-R01071',
     'HO',
     NULL,
     I.INVOICE_AMOUNT,
     'INR',
     'LPTI_TA_INV',
     'LPTI_TA_INV' ,
     '0',
     'REIM-FEB-'||J);
/* INSERT AP INVOICE LINES DISTRIBUTIONS */
DECLARE
 K NUMBER :=1;
CURSOR C2 IS SELECT * FROM UPLOAD_REIMBURSEMENT@TAPROD_DBLINK
WHERE SEGMENT2=I.SEGMENT2;
BEGIN
 FOR J IN C2 LOOP
  INSERT into ap_invoice_lines_interface
      ( invoice_id,
         invoice_line_id,
        line_number,
      line_type_lookup_code,
      amount,
       DIST_CODE_CONCATENATED,
      DESCRIPTION)
      VALUES
      (  p_invoice_id,
         LPTI_AP_OPEN_INVOICES_LINE_S.nextval,
         K,
        'ITEM',
         J.invoice_amount,
         J.SEGMENT1||'.'||J.SEGMENT2||'.'||J.SEGMENT3||'.'||'000000'||'.'||'00000'||'.'||'00000000'||'.'||'00000'||'.'||'000',
        J.ADDL_FIELD1);
--INSERT INTO LPTI_AP_TRF_INVOICES VALUES(I.BILL_NO,cVENDOR_TYPE||'-'||I.SUPP_CODE,I.BILL_VOUCHER_NO,I.VCH_TYP_CODE);
 		 commit;
 K:=K+1;
END LOOP;
END;
 COMMIT;
 J:=J+1;
end loop;
END;
/

CREATE OR REPLACE procedure APPS.lpti_update_bank_trx_number(retcode    OUT VARCHAR2,
                                                             errbuf OUT VARCHAR2
                                                             ) is
v_trx_number varchar2(50);
begin
for i in (
SELECT RTRIM(LTRIM(REF_RECEIPT_NO)) REF_RECEIPT_NO,TO_CHAR(BANK_BRANCH_ID) BANK_BRANCH_ID,AMOUNT,RECEIPT_NUMBER 
FROM oa_ar_receipt_mas@taprod_dblink
WHERE (RTRIM(LTRIM(REF_RECEIPT_NO)),BANK_BRANCH_ID,AMOUNT) IN (
SELECT BANK_TRX_NUMBER,bank_account_id,amount
FROM CE_STATEMENT_HEADERS_ALL h,
CE_STATEMENT_LINES l
where h.STATEMENT_HEADER_ID=l.STATEMENT_HEADER_ID
and l.trx_type='CREDIT'
AND l.status = 'UNRECONCILED'
and RTRIM(LTRIM(REF_RECEIPT_NO))='124952'
)) loop

UPDATE CE_STATEMENT_LINES
SET BANK_TRX_NUMBER=I.RECEIPT_NUMBER
WHERE ATTRIBUTE5=I.REF_RECEIPT_NO
AND ATTRIBUTE7=i.BANK_BRANCH_ID
and amount=i.amount;

end loop;
commit;
end;
/

CREATE OR REPLACE procedure APPS.TI_AR_PURGE_INTERFACE(retcode OUT VARCHAR2,errbuf OUT VARCHAR2)
IS
BEGIN

DELETE  FROM RA_INTERFACE_LINES_ALL
WHERE INTERFACE_LINE_ATTRIBUTE4 <>'LPTI_IMPREST_INV';

DELETE FROM RA_INTERFACE_DISTRIBUTIONS_ALL
WHERE INTERFACE_LINE_ATTRIBUTE4 <>'LPTI_IMPREST_INV';

COMMIT;

END;
/

CREATE OR REPLACE PROCEDURE APPS.LPTI_REFRESH_COMM_TDS_MV(ERRBUF OUT VARCHAR2,
                                                     RETCODE OUT VARCHAR2)
is
begin
   dbms_mview.refresh( 'COMM_TDS_VW' );
end;
/

CREATE OR REPLACE PROCEDURE APPS.get_install(p_installid OUT VARCHAR2) AUTHID CURRENT_USER AS
/* $Header: ARTAESDY.pls 115.3 2000/07/10 16:18:52 pkm ship      $ */
BEGIN
        p_installid := '0';
END get_install;
/

CREATE OR REPLACE procedure APPS.TEST1 AUTHID CURRENT_USER as
BEGIN
  Begin
      dbms_output.put_line('Testing');
  end;
END;
/

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

