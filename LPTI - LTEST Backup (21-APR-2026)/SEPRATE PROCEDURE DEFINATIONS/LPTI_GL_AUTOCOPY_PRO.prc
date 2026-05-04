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
