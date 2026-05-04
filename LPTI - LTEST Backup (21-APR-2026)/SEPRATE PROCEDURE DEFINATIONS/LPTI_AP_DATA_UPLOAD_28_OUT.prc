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
