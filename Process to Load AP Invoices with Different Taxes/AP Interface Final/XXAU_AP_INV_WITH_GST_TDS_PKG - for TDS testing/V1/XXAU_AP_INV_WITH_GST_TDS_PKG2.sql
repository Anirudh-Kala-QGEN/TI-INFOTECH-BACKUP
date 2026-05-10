CREATE OR REPLACE PACKAGE BODY APPS.XXAU_AP_INV_WITH_GST_TDS_PKG2
IS
    /*************************************************************************************************
     *                 Copy Rights Reserved @ Ti Infotech- 2026
     *
     * $Header: @(#)
     * Program Name : XXAU_AP_INV_WITH_GST_TDS_PKG (Body)
     * Language     : PL/SQL
     * Description  : This is the package to insert the custom AP Invoice, Lines and Tax details into the Oracle ERP system.
	 *				  This package can be used for Invoice with taxes as well as for invoices with taxes.
     * History      :
     *
     * WHO              Version #   WHEN            WHAT
     * ===============  =========   =============   ====================================================
     * AKALA            1.0         23-APR-2026      Initial Version
     * AKALA            1.1         24-APR-2026      Updated (LOAD_DATA_TO_INTERFACE)
     * AKALA            1.2         27-APR-2026      Created (SHOW_DATA), Updated (MIGRATE_TO_ERP)
     * AKALA            1.3         28-APR-2026      Created (CREATE_AP_INVOICES, CREATE_ONLY_AP_INVOICES), Updated(SHOW_DATA)
	 ***************************************************************************************************/


---------------------------------------------------------------------------------------------------------------------------------


    /*************************************************************************************************
     * Program Name : REG_ERR_MSG
     * Language     : PL/SQL
     * Description  : This a local function is used for Message formatting.
     * Parameters : 1. P_MSG => Varchar2 , Old message
	 *      		2. N_MSG => New Message String
     *
     * History      :
     * WHO              Version #   WHEN            WHAT
     * ===============  =========   =============   ====================================================
     * AKALA            1.0         23-APR-2026      Initial Version
     ***************************************************************************************************/
	
	FUNCTION REG_ERR_MSG (P_MSG VARCHAR2, N_MSG VARCHAR2)
        RETURN VARCHAR2
    AS
        LC_MSG   VARCHAR2 (4000);
    BEGIN
        IF TRIM (P_MSG) IS NULL
        THEN
            LC_MSG := N_MSG;
        ELSE
            LC_MSG := P_MSG || '; ' || N_MSG;
        END IF;

        RETURN LC_MSG;
    EXCEPTION
        WHEN OTHERS
        THEN
            LC_MSG := P_MSG || ' ' || N_MSG;
            RETURN LC_MSG;
    END;

    /*************************************************************************************************
     * Program Name : MIGRATE_TO_ERP
     * Language     : PL/SQL
     * Description  : This a local procedure which is used for submitting the standard program : Payable Open Interface Import. 
						It will migrate the data to ERP.
     * Parameters : 1. P_BATCH_ID => Number , It is Mandatory Parameter
     *
     * History      :
     * WHO              Version #   WHEN            WHAT
     * ===============  =========   =============   ====================================================
     * AKALA            1.0         23-APR-2026     Initial Version
     * AKALA            1.1         27-APR-2026     Updated WAIT_FOR_REQUEST logic
     ***************************************************************************************************/
	
	PROCEDURE VALIDATE_INV_IN_ERP (P_BATCH_ID NUMBER)
	AS
		PRAGMA AUTONOMOUS_TRANSACTION;
		GN_CP_REQUEST_ID FND_CONCURRENT_REQUESTS.REQUEST_ID%TYPE;
		P_PHASE VARCHAR2(4000);
		P_STATUS VARCHAR2(4000);
		P_DEV_PHASE VARCHAR2(4000);
		P_DEV_STATUS VARCHAR2(4000);
		P_MESSAGE VARCHAR2(4000);
		WAIT_RES BOOLEAN;
	BEGIN
		GN_CP_REQUEST_ID:=0;
		FND_GLOBAL.APPS_INITIALIZE (GN_USER_ID, GN_RESP_ID, GN_RESP_APPL_ID);
		MO_GLOBAL.SET_POLICY_CONTEXT('S', GN_ORG_ID);
		
		FND_FILE.PUT_LINE(FND_FILE.LOG, 'VALIDATE INVOICES IN ERP ... 1');
		
		GN_CP_REQUEST_ID := FND_REQUEST.SUBMIT_REQUEST (
                      APPLICATION   => 'SQLAP'
                    , PROGRAM       => 'APPRVL'
					, DESCRIPTION   => NULL 
                    , START_TIME    => SYSDATE
                    , SUB_REQUEST	=> FALSE
					, ARGUMENT1 	=> GN_ORG_ID
					, ARGUMENT2 	=> 'New'
					, ARGUMENT3 	=> NULL
					, ARGUMENT4 	=> NULL
					, ARGUMENT5 	=> NULL
					, ARGUMENT6 	=> NULL
					, ARGUMENT7 	=> NULL
					, ARGUMENT8 	=> NULL
					, ARGUMENT9 	=> GN_USER_ID
					, ARGUMENT10 	=> 'N'
					, ARGUMENT11 	=> 1000
					, ARGUMENT12 	=> 1
					, ARGUMENT13 	=> 'N'
                    );

            COMMIT;
		FND_FILE.PUT_LINE(FND_FILE.LOG,'GN_CP_REQUEST_ID :'||GN_CP_REQUEST_ID||'; GN_LOGIN_ID: '||GN_LOGIN_ID);
		IF GN_CP_REQUEST_ID <> 0
		THEN 
			/*Added AKALA on 27-APR-2026 for wait for request*/
			FND_FILE.PUT_LINE(FND_FILE.LOG, 'VALIDATE INVOICES IN ERP ... 2');
			FND_FILE.PUT_LINE(FND_FILE.LOG,'GN_CP_REQUEST_ID :'||GN_CP_REQUEST_ID);
			WAIT_RES := FND_CONCURRENT.WAIT_FOR_REQUEST (
				REQUEST_ID   => GN_CP_REQUEST_ID,
				INTERVAL     => 60,
				MAX_WAIT     => 240,
				PHASE        => P_PHASE,
				STATUS       => P_STATUS,
				DEV_PHASE    => P_DEV_PHASE,
				DEV_STATUS   => P_DEV_STATUS,
				MESSAGE      => P_MESSAGE);
				
			
			FND_FILE.PUT_LINE(FND_FILE.LOG,'P_PHASE : '||P_PHASE||'; P_STATUS : '||P_STATUS);
			FND_FILE.PUT_LINE(FND_FILE.LOG,'P_DEV_PHASE : '||P_DEV_PHASE||'; P_DEV_STATUS : '||P_DEV_STATUS);
			FND_FILE.PUT_LINE(FND_FILE.LOG,'P_MESSAGE : '||P_MESSAGE);
		ELSE
			FND_FILE.PUT_LINE(FND_FILE.LOG,'Unable to submit program.');
		END IF;
		
	EXCEPTION WHEN OTHERS THEN
		FND_FILE.PUT_LINE(FND_FILE.LOG,SQLCODE||' - '||SQLERRM);
	END VALIDATE_INV_IN_ERP;

    /*************************************************************************************************
     * Program Name : SHOW_DATA
     * Language     : PL/SQL
     * Description  : This a local procedure which is used for Updating the Process_flag and Error_msg after Payable Open Interface Import Program.
     * Parameters : 1. P_BATCH_ID => Number , It is Mandatory Parameter
     *
     * History      :
     * WHO              Version #   WHEN            WHAT
     * ===============  =========   =============   ====================================================
     * AKALA            1.0         27-APR-2026     Initial Version
     * AKALA            1.1         28-APR-2026     Update logic for Custom table status updation.
     ***************************************************************************************************/
	
	PROCEDURE SHOW_DATA (P_BATCH_ID NUMBER)
	AS
		
	CURSOR CUR_HDR_DATA IS
	(SELECT  INVOICE_NUMBER              
			, ERP_INVOICE_ID              
			, INVOICE_TYPE                
			, INVOICE_TYPE_LOOKUP_CODE    
			, LEDGER_ID                   
			, PARTY_NAME                  
			, VENDOR_CODE                 
			, ERP_VENDOR_ID               
			, VENDOR_SITE_CODE 
			, OPERATING_UNIT				
			, VENDOR_SITE_ID              
			, ACCTS_PAY_CC_ID             
			, TRUNC(GL_DATE) GL_DATE                     
			, TRUNC(INVOICE_DATE) INVOICE_DATE                
			, INVOICE_CURRENCY_CODE       
			, EXCHANGE_RATE
			, ERP_ORG_ID
			, SUM(LINE_AMOUNT) INVOICE_AMOUNT
	FROM XXAU_AP_INV_WITH_GST_TDS_TBL@ebstohr A
	WHERE 1=1
	AND BATCH_ID = P_BATCH_ID
	AND PROCESS_FLAG = 'P'
	AND EXISTS (SELECT INVOICE_ID 
				FROM AP_INVOICES_ALL 
				WHERE INVOICE_NUM = A.INVOICE_NUMBER 
				AND ORG_ID = A.ERP_ORG_ID )
	GROUP BY  INVOICE_NUMBER              
			, INVOICE_TYPE                
			, LEDGER_ID                   
			, PARTY_NAME                  
			, VENDOR_CODE                 
			, VENDOR_SITE_CODE 
			, OPERATING_UNIT				
			, ACCTS_PAY_CC_ID             
			, TRUNC(GL_DATE)                      
			, TRUNC(INVOICE_DATE)                     
			, EXCHANGE_RATE  
			, INVOICE_CURRENCY_CODE       
			, ERP_INVOICE_ID              
			, INVOICE_TYPE_LOOKUP_CODE    
			, ERP_VENDOR_ID               
			, VENDOR_SITE_ID
			, ERP_ORG_ID
	HAVING COUNT(1) = (SELECT COUNT(1) 
						FROM XXAU_AP_INV_WITH_GST_TDS_TBL@ebstohr 
						WHERE INVOICE_NUMBER = A.INVOICE_NUMBER 
						AND OPERATING_UNIT = A.OPERATING_UNIT 
						AND BATCH_ID = P_BATCH_ID))           
	;
	
	CURSOR CUR_LINE_DATA (P_INVOICE_NUM VARCHAR2, P_OPERATING_UNIT VARCHAR2)IS
	(SELECT  ERP_INVOICE_LINE_ID         
			, GROUP_LINE_NUM              
			, LINE_TYPE                   
			, ERP_LINE_TYPE_CODE          
			, UNIT                        
			, JOB_ACTIVITY                    
			, LINE_AMOUNT                 
			, INV_ORGANIZATION_ID         
			, LOCATION_ID                 
			, HSNCODE                     
			, LINE_DESCRIPTION            
			, NATURAL_ACCOUNT             
			, LOCATION                    
			, DEPARTMENT                  
			, FUTURE1                     
			, FUTURE2                     
			, FUTURE3                     
			, FUTURE4                     
			, ERP_CCID                    
			, BUSINESS_TYPE               
			, TCS                         
			, TAX_CATEGORY                
			, TAX_CATEGORY_ID             
			, TDS_TAX_TYPE_CODE           
			, TDS_TAX_TYPE_ID             
			, TAX_RATE_NAME               
			, ERP_TAX_RATE_ID             
			, TAX_RATE_TAX_AMOUNT         
			, TAX_RECOVERABLE_OR_NOT      
			, CONTEXT_VALUE               
			, FLEX_FIELD_VALUE            
			, ATTRIBUTE10                 
			, ATTRIBUTE15                 
			, INVOICE_TAX_TYPE            
			, ERP_TAX_TYPE_ID             
			, REFERENCE_KEY1_INVOICE_NUM  
			, REFERENCE_KEY2_LINE_NUM     
			, REFERENCE_KEY3              
			, OPERATING_UNIT              
			, ERP_ORG_ID                  
			, PROCESS_FLAG                
			, ERROR_MSG                   
			, CREATED_BY                  
			, CREATION_DATE               
			, UPDATED_BY                  
			, LAST_UPDATE_DATE            
			, BATCH_ID              
	FROM XXAU_AP_INV_WITH_GST_TDS_TBL@ebstohr
	WHERE 1=1
	AND INVOICE_NUMBER = P_INVOICE_NUM
	AND OPERATING_UNIT = P_OPERATING_UNIT
	AND BATCH_ID = P_BATCH_ID
	AND PROCESS_FLAG = 'P')
	;
	
	CURSOR CUR_HDR_FAIL_DATA IS
	(SELECT  RECORD_ID
			, INVOICE_NUMBER              
			, ERP_INVOICE_ID              
			, INVOICE_TYPE                
			, INVOICE_TYPE_LOOKUP_CODE    
			, LEDGER_ID                   
			, PARTY_NAME                  
			, VENDOR_CODE                 
			, ERP_VENDOR_ID               
			, VENDOR_SITE_CODE 
			, OPERATING_UNIT				
			, VENDOR_SITE_ID              
			, ACCTS_PAY_CC_ID             
			, TRUNC(GL_DATE) GL_DATE                     
			, TRUNC(INVOICE_DATE)  INVOICE_DATE                
			, INVOICE_CURRENCY_CODE       
			, EXCHANGE_RATE
			, ERP_ORG_ID
			, SUM(LINE_AMOUNT) INVOICE_AMOUNT
	FROM XXAU_AP_INV_WITH_GST_TDS_TBL@ebstohr A
	WHERE 1=1
	AND BATCH_ID = P_BATCH_ID
	AND PROCESS_FLAG = 'P'
	AND NOT EXISTS (SELECT INVOICE_ID 
				FROM AP_INVOICES_ALL 
				WHERE INVOICE_NUM = A.INVOICE_NUMBER 
				AND ORG_ID = A.ERP_ORG_ID )
	GROUP BY  RECORD_ID
			, INVOICE_NUMBER              
			, INVOICE_TYPE                
			, LEDGER_ID                   
			, PARTY_NAME                  
			, VENDOR_CODE                 
			, VENDOR_SITE_CODE 
			, OPERATING_UNIT				
			, ACCTS_PAY_CC_ID             
			, TRUNC(GL_DATE)                      
			, TRUNC(INVOICE_DATE)                  
			, EXCHANGE_RATE  
			, INVOICE_CURRENCY_CODE       
			, ERP_INVOICE_ID              
			, INVOICE_TYPE_LOOKUP_CODE    
			, ERP_VENDOR_ID               
			, VENDOR_SITE_ID
			, ERP_ORG_ID)           
	;
	
	CURSOR CUR_TAXES (P_TAX_CATEGORY VARCHAR2, P_TAX_RATE_NAME VARCHAR2, P_TAX_TYPE VARCHAR2, P_ORG_ID NUMBER)
	IS
	(SELECT TAX_CATEGORY_ID,
			 RATE_PERCENTAGE,
			 TAX_RATE_NAME,
			 TAX_RATE_ID,
			 TAX_TYPE_ID,
			 TAX_TYPE_CODE,
			 RECOVERABLE_FLAG
		FROM TI_GST_TAX_V
	   WHERE 1=1
			AND UPPER (TAX_CATEGORY_NAME) = UPPER (P_TAX_CATEGORY)
			AND (UPPER(TAX_RATE_NAME) = UPPER(P_TAX_RATE_NAME) OR P_TAX_RATE_NAME IS NULL)
			AND (UPPER(TAX_TYPE_NAME) = UPPER(P_TAX_TYPE) OR P_TAX_TYPE IS NULL)
			AND ORG_ID = P_ORG_ID
	--ORDER BY RATE_PERCENTAGE
	)
	;
	
	BEGIN
		FND_FILE.PUT_LINE(FND_FILE.LOG, 'SHOW DATA ... 1');
		FOR REC_HDR IN CUR_HDR_DATA
		LOOP
			FND_FILE.PUT_LINE(FND_FILE.LOG,'Invoice Number in ERP: '||REC_HDR.INVOICE_NUMBER);
			
			/*Added by AKALA on 28-APR-2026, Updated code for Status and ERP_INVOICE_ID updation in Custom table*/
			
			UPDATE XXAU_AP_INV_WITH_GST_TDS_TBL@ebstohr
			SET PROCESS_FLAG = 'S'
				, ERROR_MSG = 'Invoice Create : '||(SELECT INVOICE_ID 
												FROM AP_INVOICES_ALL 
												WHERE INVOICE_NUM = REC_HDR.INVOICE_NUMBER 
												AND ORG_ID = REC_HDR.ERP_ORG_ID )
				, ERP_INVOICE_ID = (SELECT INVOICE_ID 
												FROM AP_INVOICES_ALL 
												WHERE INVOICE_NUM = REC_HDR.INVOICE_NUMBER 
												AND ORG_ID = REC_HDR.ERP_ORG_ID )
				, UPDATED_BY = GN_USER_ID
				, LAST_UPDATE_DATE = SYSDATE
			WHERE INVOICE_NUMBER = REC_HDR.INVOICE_NUMBER
			--AND RECORD_ID = REC_HDR.RECORD_ID
			AND ERP_ORG_ID = REC_HDR.ERP_ORG_ID
			AND BATCH_ID = P_BATCH_ID
			;
			COMMIT; 			
		END LOOP;
		FND_FILE.PUT_LINE(FND_FILE.LOG, 'SHOW DATA ... 2');
	EXCEPTION 
	WHEN OTHERS THEN
		FND_FILE.PUT_LINE(FND_FILE.LOG,SQLCODE||' - '||SQLERRM);
	END SHOW_DATA;										

    /*************************************************************************************************
     * Program Name : MIGRATE_TO_ERP
     * Language     : PL/SQL
     * Description  : This a local procedure which is used for submitting the standard program : Payable Open Interface Import. 
						It will migrate the data to ERP.
     * Parameters : 1. P_BATCH_ID => Number , It is Mandatory Parameter
     *
     * History      :
     * WHO              Version #   WHEN            WHAT
     * ===============  =========   =============   ====================================================
     * AKALA            1.0         23-APR-2026     Initial Version
     * AKALA            1.1         27-APR-2026     Updated WAIT_FOR_REQUEST logic
     ***************************************************************************************************/
	
	PROCEDURE MIGRATE_TO_ERP (P_BATCH_ID NUMBER)
	AS
		PRAGMA AUTONOMOUS_TRANSACTION;
		GN_CP_REQUEST_ID FND_CONCURRENT_REQUESTS.REQUEST_ID%TYPE;
		P_PHASE VARCHAR2(4000);
		P_STATUS VARCHAR2(4000);
		P_DEV_PHASE VARCHAR2(4000);
		P_DEV_STATUS VARCHAR2(4000);
		P_MESSAGE VARCHAR2(4000);
		WAIT_RES BOOLEAN;
	BEGIN
		GN_CP_REQUEST_ID:=0;
		FND_GLOBAL.APPS_INITIALIZE (GN_USER_ID, GN_RESP_ID, GN_RESP_APPL_ID);
		MO_GLOBAL.SET_POLICY_CONTEXT('S', GN_ORG_ID);
		
		FND_FILE.PUT_LINE(FND_FILE.LOG, 'MIGRATE TO ERP ... 1');
		
		GN_CP_REQUEST_ID := FND_REQUEST.SUBMIT_REQUEST (
                      APPLICATION   => 'SQLAP'
                    , PROGRAM       => 'APXIIMPT'
					, DESCRIPTION   => NULL 
                    , START_TIME    => SYSDATE
                    , SUB_REQUEST	=> FALSE
					, ARGUMENT1 	=> NULL
					, ARGUMENT2 	=> 'INVOICE GATEWAY'
					, ARGUMENT3 	=> NULL
					, ARGUMENT4 	=> TO_CHAR(NVL(P_BATCH_ID,123))
					, ARGUMENT5 	=> NULL
					, ARGUMENT6 	=> NULL
					, ARGUMENT7 	=> NULL
					, ARGUMENT8 	=> 'N'
					, ARGUMENT9 	=> 'N'
					, ARGUMENT10 	=> 'N'
					, ARGUMENT11 	=> 'N'
					, ARGUMENT12 	=> '1000'
					, ARGUMENT13 	=> GN_USER_ID
					, ARGUMENT14 	=> TO_CHAR(GN_LOGIN_ID)
					, ARGUMENT15 	=> 'N'
                    );

            COMMIT;
		FND_FILE.PUT_LINE(FND_FILE.LOG,'GN_CP_REQUEST_ID :'||GN_CP_REQUEST_ID||'; GN_LOGIN_ID: '||GN_LOGIN_ID);
		IF GN_CP_REQUEST_ID <> 0
		THEN 
			/*Added AKALA on 27-APR-2026 for wait for request*/
			FND_FILE.PUT_LINE(FND_FILE.LOG, 'MIGRATE TO ERP ... 2');
			FND_FILE.PUT_LINE(FND_FILE.LOG,'GN_CP_REQUEST_ID :'||GN_CP_REQUEST_ID);
			WAIT_RES := FND_CONCURRENT.WAIT_FOR_REQUEST (
				REQUEST_ID   => GN_CP_REQUEST_ID,
				INTERVAL     => 60,
				MAX_WAIT     => 200,
				PHASE        => P_PHASE,
				STATUS       => P_STATUS,
				DEV_PHASE    => P_DEV_PHASE,
				DEV_STATUS   => P_DEV_STATUS,
				MESSAGE      => P_MESSAGE);
				
			
			FND_FILE.PUT_LINE(FND_FILE.LOG,'P_PHASE : '||P_PHASE||'; P_STATUS : '||P_STATUS);
			FND_FILE.PUT_LINE(FND_FILE.LOG,'P_DEV_PHASE : '||P_DEV_PHASE||'; P_DEV_STATUS : '||P_DEV_STATUS);
			FND_FILE.PUT_LINE(FND_FILE.LOG,'P_MESSAGE : '||P_MESSAGE);
		ELSE
			FND_FILE.PUT_LINE(FND_FILE.LOG,'Unable to submit program.');
		END IF;
		
	EXCEPTION WHEN OTHERS THEN
		FND_FILE.PUT_LINE(FND_FILE.LOG,SQLCODE||' - '||SQLERRM);
	END;


	
	PROCEDURE NEW_INTERFACE (P_BATCH_ID NUMBER)
	AS
	CURSOR CUR_HDR_DATA IS
	(SELECT   
			 INVOICE_NUMBER              
			, ERP_INVOICE_ID              
			, INVOICE_TYPE                
			, INVOICE_TYPE_LOOKUP_CODE    
			, LEDGER_ID                   
			, PARTY_NAME                  
			, VENDOR_CODE                 
			, ERP_VENDOR_ID               
			, VENDOR_SITE_CODE 
			, OPERATING_UNIT				
			, VENDOR_SITE_ID              
			, ACCTS_PAY_CC_ID             
			, TRUNC(GL_DATE) GL_DATE                     
			, TRUNC(INVOICE_DATE) INVOICE_DATE                
			, INVOICE_CURRENCY_CODE       
			, EXCHANGE_RATE
			, ERP_ORG_ID
			, SUM(LINE_AMOUNT) INVOICE_AMOUNT
	FROM XXAU_AP_INV_WITH_GST_TDS_TBL@ebstohr
	WHERE 1=1
	AND BATCH_ID = P_BATCH_ID
	AND PROCESS_FLAG = 'V'
	GROUP BY  INVOICE_NUMBER              
			, INVOICE_TYPE                
			, LEDGER_ID                   
			, PARTY_NAME                  
			, VENDOR_CODE                 
			, VENDOR_SITE_CODE 
			, OPERATING_UNIT				
			, ACCTS_PAY_CC_ID             
			, TRUNC(GL_DATE)                     
			, TRUNC(INVOICE_DATE)                
			, EXCHANGE_RATE  
			, INVOICE_CURRENCY_CODE       
			, ERP_INVOICE_ID              
			, INVOICE_TYPE_LOOKUP_CODE    
			, ERP_VENDOR_ID               
			, VENDOR_SITE_ID
			, ERP_ORG_ID				)           
	;
		
	CURSOR CUR_LINE_DATA (P_INVOICE_NUM VARCHAR2, P_OPERATING_UNIT VARCHAR2, P_PARTY_NAME VARCHAR2)IS
	(SELECT  ERP_INVOICE_LINE_ID         
			, GROUP_LINE_NUM              
			, LINE_TYPE                   
			, ERP_LINE_TYPE_CODE          
			, UNIT                        
			, JOB_ACTIVITY                    
			, LINE_AMOUNT                 
			, INV_ORGANIZATION_ID         
			, LOCATION_ID                 
			, HSNCODE                     
			, LINE_DESCRIPTION            
			, NATURAL_ACCOUNT             
			, LOCATION                    
			, DEPARTMENT                  
			, FUTURE1                     
			, FUTURE2                     
			, FUTURE3                     
			, FUTURE4                     
			, ERP_CCID                    
			, BUSINESS_TYPE               
			, TCS                         
			, TAX_CATEGORY                
			, TAX_CATEGORY_ID             
			, TDS_TAX_TYPE_CODE           
			, TDS_TAX_TYPE_ID             
			, TAX_RATE_NAME               
			, ERP_TAX_RATE_ID             
			, TAX_RATE_TAX_AMOUNT         
			, TAX_RECOVERABLE_OR_NOT      
			, CONTEXT_VALUE               
			, FLEX_FIELD_VALUE            
			, ATTRIBUTE10                 
			, ATTRIBUTE15                 
			, INVOICE_TAX_TYPE            
			, ERP_TAX_TYPE_ID             
			, REFERENCE_KEY1_INVOICE_NUM  
			, REFERENCE_KEY2_LINE_NUM     
			, REFERENCE_KEY3              
			, OPERATING_UNIT              
			, ERP_ORG_ID                  
			, PROCESS_FLAG                
			, ERROR_MSG                   
			, CREATED_BY                  
			, CREATION_DATE               
			, UPDATED_BY                  
			, LAST_UPDATE_DATE            
			, BATCH_ID              
			, RECORD_ID              
	FROM XXAU_AP_INV_WITH_GST_TDS_TBL@ebstohr
	WHERE 1=1
	AND PARTY_NAME = P_PARTY_NAME
	AND INVOICE_NUMBER = P_INVOICE_NUM
	AND OPERATING_UNIT = P_OPERATING_UNIT
	AND BATCH_ID = P_BATCH_ID
	AND PROCESS_FLAG = 'V')
	;
	
	CURSOR CUR_TAXES (P_TAX_CATEGORY VARCHAR2, P_TAX_RATE_NAME VARCHAR2, P_TAX_TYPE VARCHAR2, P_ORG_ID NUMBER)
	IS
		   
	(SELECT TAX_CATEGORY_ID,
			 RATE_PERCENTAGE,
			 TAX_RATE_NAME,
			 TAX_RATE_ID,
			 TAX_TYPE_ID,
			 TAX_TYPE_CODE,
			 RECOVERABLE_FLAG
		FROM TI_GST_TAX_V
	   WHERE 1=1
			AND UPPER (TAX_CATEGORY_NAME) = UPPER (P_TAX_CATEGORY)
			AND (UPPER(TAX_RATE_NAME) = UPPER(P_TAX_RATE_NAME) OR P_TAX_RATE_NAME IS NULL)
			AND (UPPER(TAX_TYPE_NAME) = UPPER(P_TAX_TYPE) OR P_TAX_TYPE IS NULL)
			AND ORG_ID = P_ORG_ID
	--ORDER BY RATE_PERCENTAGE
	)
	;
		
	LN_LINE_NUMBER NUMBER;
	LN_INVOICE_ID NUMBER;
	LN_AP_LINE_ID NUMBER;
	LN_TAX_AMOUNT NUMBER;
	LN_TAX_LINE_COUNTER NUMBER;
	LN_TAX_TCS_LINE_COUNTER NUMBER;
	LN_TOT_TAX_PER NUMBER;
	LN_TOT_GST_AMOUNT NUMBER;
	LN_JAI_INTERFACE_LINE_ID NUMBER;
	LN_LIABILITY_CCID NUMBER;
	LN_JAI_TAX_LINE_ID NUMBER;
	
	BEGIN
		--FND_GLOBAL.APPS_INITIALIZE (2482, 52144, 200);
        --MO_GLOBAL.INIT ('AP');
		FND_GLOBAL.APPS_INITIALIZE (GN_USER_ID, GN_RESP_ID, GN_RESP_APPL_ID);
		MO_GLOBAL.SET_POLICY_CONTEXT('S', 386);
		FND_FILE.PUT_LINE(FND_FILE.LOG,' LOADING DATA TO INTERFACE TABLES... ');
		FOR REC_HDR IN CUR_HDR_DATA
		LOOP
			BEGIN
				
				SELECT AP_INVOICES_INTERFACE_S.NEXTVAL
				  INTO LN_INVOICE_ID
				FROM DUAL;
				
				INSERT INTO AP_INVOICES_INTERFACE (
                                INVOICE_ID,
                                INVOICE_NUM,
                                INVOICE_AMOUNT,
                                INVOICE_CURRENCY_CODE,
                                GL_DATE,
                                SOURCE,
                                ORG_ID,
                                INVOICE_TYPE_LOOKUP_CODE,
                                INVOICE_DATE,
                                VENDOR_ID,
                                VENDOR_SITE_ID,
                                DESCRIPTION,
                                CREATION_DATE,
                                CREATED_BY,
                                LAST_UPDATED_BY,
                                LAST_UPDATE_DATE,
                                LAST_UPDATE_LOGIN,
                                CALC_TAX_DURING_IMPORT_FLAG,
                                REFERENCE_KEY1,
                                REFERENCE_KEY2,
                                REFERENCE_KEY3,
                                ACCTS_PAY_CODE_COMBINATION_ID,
                                PAYMENT_METHOD_LOOKUP_CODE,
                                ATTRIBUTE15)
                     VALUES (LN_INVOICE_ID,
                             REC_HDR.INVOICE_NUMBER,
                             REC_HDR.INVOICE_AMOUNT,
                             NVL (REC_HDR.INVOICE_CURRENCY_CODE, 'INR'),
                             REC_HDR.GL_DATE,
                             'INVOICE GATEWAY',
                             REC_HDR.ERP_ORG_ID,
                             REC_HDR.INVOICE_TYPE_LOOKUP_CODE, --'STANDARD',
                             REC_HDR.INVOICE_DATE,                   --SYSDATE
                             REC_HDR.ERP_VENDOR_ID,
                             REC_HDR.VENDOR_SITE_ID,
                             'ALL GST + TDS IMPORT',
                             SYSDATE,
                             GN_USER_ID,
                             GN_USER_ID,
                             SYSDATE,
                             GN_USER_ID,
                             'Y',
                             REC_HDR.INVOICE_NUMBER,
                             1,
                             'OFI TAX IMPORT',
                             REC_HDR.ACCTS_PAY_CC_ID,
                             'CHECK',
                             'AP_INDUS_API')
							 ;
				
				LN_LINE_NUMBER := 1; 
				FOR REC_LINE IN CUR_LINE_DATA  (REC_HDR.INVOICE_NUMBER  ,REC_HDR.OPERATING_UNIT, REC_HDR.PARTY_NAME)
				LOOP
					BEGIN     
						
						SELECT AP_INVOICE_LINES_INTERFACE_S.NEXTVAL
						INTO LN_AP_LINE_ID
						FROM DUAL;
						
						INSERT INTO AP_INVOICE_LINES_INTERFACE (
                                INVOICE_ID,
                                INVOICE_LINE_ID,
                                LINE_NUMBER,
                                LINE_GROUP_NUMBER,
                                LINE_TYPE_LOOKUP_CODE,
                                AMOUNT,
                                DESCRIPTION,
                                ACCOUNTING_DATE,
                                ORG_ID,
                                CREATION_DATE,
                                CREATED_BY,
                                LAST_UPDATED_BY,
                                LAST_UPDATE_DATE,
                                LAST_UPDATE_LOGIN,
                                DIST_CODE_COMBINATION_ID,
                                REFERENCE_KEY1,
                                REFERENCE_KEY2,
                                REFERENCE_KEY3,
                                ATTRIBUTE_CATEGORY,
                                ATTRIBUTE10,
                                ATTRIBUTE15)
						 VALUES (LN_INVOICE_ID,
								 LN_AP_LINE_ID,
								 LN_LINE_NUMBER,
								 REC_LINE.GROUP_LINE_NUM,
								 REC_LINE.ERP_LINE_TYPE_CODE , --'ITEM',
								 REC_LINE.LINE_AMOUNT,
								 REC_LINE.LINE_DESCRIPTION,
								 REC_HDR.GL_DATE,
								 REC_LINE.ERP_ORG_ID,
								 SYSDATE,
								 GN_USER_ID,
								 GN_USER_ID,
								 SYSDATE,
								 GN_USER_ID,
								 REC_LINE.ERP_CCID,
								 REC_HDR.INVOICE_NUMBER,
								 LN_LINE_NUMBER,
								 'OFI TAX IMPORT',
								 REC_LINE.CONTEXT_VALUE,
								 REC_LINE.ATTRIBUTE10,
								 'AP_INDUS_API');
					LN_LINE_NUMBER := LN_LINE_NUMBER + 1;
					FND_FILE.PUT_LINE(FND_FILE.LOG,'LN_INVOICE_ID : '||LN_INVOICE_ID||'; LN_AP_LINE_ID: '||LN_AP_LINE_ID);
					EXCEPTION
					WHEN OTHERS THEN
					 FND_FILE.PUT_LINE(FND_FILE.LOG,SQLCODE||' - '||SQLERRM);
					END;
				END LOOP;
			
			EXCEPTION
			WHEN OTHERS THEN
			FND_FILE.PUT_LINE(FND_FILE.LOG,SQLCODE||' - '||SQLERRM);
			END;
			COMMIT;
		END LOOP;
	EXCEPTION
	WHEN OTHERS THEN
		FND_FILE.PUT_LINE(FND_FILE.LOG,SQLCODE||' - '||SQLERRM);
	END NEW_INTERFACE;

    /*************************************************************************************************
     * Program Name : LOAD_DATA_TO_INTERFACE
     * Language     : PL/SQL
     * Description  : This a global procedure which is used for inserting data into Interface tables.
						1. AP_INVOICES_INTERFACE 
						2. AP_INVOICE_LINES_INTERFACE
						3. JAI_INTERFACE_LINES_ALL
						4. JAI_INTERFACE_TAX_LINES_ALL
					It will migrate the data to Oracle Interface Tables.
     * Parameters : 1. P_BATCH_ID => Number , It is Mandatory Parameter
     *
     * History      :
     * WHO              Version #   WHEN            WHAT
     * ===============  =========   =============   ====================================================
     * AKALA            1.0         23-APR-2026     Initial Version
     * AKALA            1.1         24-APR-2026     Updated logic for Tax line creation
     ***************************************************************************************************/

PROCEDURE LOAD_DATA_TO_INTERFACE (P_BATCH_ID NUMBER)
	AS
	CURSOR CUR_HDR_DATA IS
	(SELECT   BATCH_ID
			, INVOICE_NUMBER              
			, ERP_INVOICE_ID              
			, INVOICE_TYPE                
			, INVOICE_TYPE_LOOKUP_CODE    
			, LEDGER_ID                   
			, PARTY_NAME                  
			, VENDOR_CODE                 
			, ERP_VENDOR_ID               
			, VENDOR_SITE_CODE 
			, OPERATING_UNIT				
			, VENDOR_SITE_ID              
			, ACCTS_PAY_CC_ID             
			, TRUNC(GL_DATE) GL_DATE                     
			, TRUNC(INVOICE_DATE) INVOICE_DATE                
			, INVOICE_CURRENCY_CODE       
			, EXCHANGE_RATE
			, ERP_ORG_ID
			, SUM(LINE_AMOUNT) INVOICE_AMOUNT
	FROM XXAU_AP_INV_WITH_GST_TDS_TBL@ebstohr B
	WHERE 1=1
	AND BATCH_ID = P_BATCH_ID
	AND NOT EXISTS (SELECT 1
								FROM AP_INVOICES_ALL AIA
							   WHERE     AIA.INVOICE_NUM = B.INVOICE_NUMBER
									 AND TRUNC (GL_DATE) >= '01-FEB-2026'
									 AND AIA.VENDOR_ID IN
											 (SELECT VENDOR_ID
												FROM PO_VENDORS POV
											   WHERE POV.SEGMENT1 = B.VENDOR_CODE)) -- AND AIA.SOURCE = 'INVOICE GATEWAY')
		AND NOT EXISTS  (SELECT 1
								FROM AP_INVOICES_INTERFACE
							   WHERE INVOICE_NUM = B.INVOICE_NUMBER)
		AND NOT EXISTS  (SELECT 1
								FROM AP_INVOICE_LINES_INTERFACE
							   WHERE INVOICE_ID IN
										 (SELECT INVOICE_ID
											FROM AP_INVOICES_INTERFACE
										   WHERE INVOICE_NUM = B.INVOICE_NUMBER))
		AND NOT EXISTS  (SELECT 1
								FROM JAI_INTERFACE_LINES_ALL
							   WHERE     IMPORT_MODULE = 'AP'
									 AND TRANSACTION_NUM = B.INVOICE_NUMBER)
		AND NOT EXISTS  (SELECT 1
								FROM JAI_INTERFACE_TAX_LINES_ALL
							   WHERE     IMPORT_MODULE = 'AP'
									 AND TRANSACTION_NUM = B.INVOICE_NUMBER)
		AND EXISTS  (SELECT 1
								FROM TI_VENDOR_DETAILS_V C ---VIEW FOR THIRD PARTY REGISTRATION VENDOR SITE---
							   WHERE    C.VENDOR_CODE = B.VENDOR_CODE
									AND C.UNIT 	 = B.UNIT
									AND C.VENDOR_SITE_CODE = B.VENDOR_SITE_CODE
									AND C.SET_OF_BOOKS_ID = B.LEDGER_ID)
		AND PROCESS_FLAG = 'V'
	GROUP BY  BATCH_ID
			, INVOICE_NUMBER              
			, INVOICE_TYPE                
			, LEDGER_ID                   
			, PARTY_NAME                  
			, VENDOR_CODE                 
			, VENDOR_SITE_CODE 
			, OPERATING_UNIT				
			, ACCTS_PAY_CC_ID             
			, TRUNC(GL_DATE)                     
			, TRUNC(INVOICE_DATE)                
			, EXCHANGE_RATE  
			, INVOICE_CURRENCY_CODE       
			, ERP_INVOICE_ID              
			, INVOICE_TYPE_LOOKUP_CODE    
			, ERP_VENDOR_ID               
			, VENDOR_SITE_ID
			, ERP_ORG_ID				)           
	;
		
	CURSOR CUR_LINE_DATA (P_INVOICE_NUM VARCHAR2, P_OPERATING_UNIT VARCHAR2, P_PARTY_NAME VARCHAR2)IS
	(SELECT  ERP_INVOICE_LINE_ID         
			, GROUP_LINE_NUM              
			, LINE_TYPE                   
			, ERP_LINE_TYPE_CODE          
			, UNIT                        
			, JOB_ACTIVITY                    
			, LINE_AMOUNT                 
			, INV_ORGANIZATION_ID         
			, LOCATION_ID                 
			, HSNCODE                     
			, LINE_DESCRIPTION            
			, NATURAL_ACCOUNT             
			, LOCATION                    
			, DEPARTMENT                  
			, FUTURE1                     
			, FUTURE2                     
			, FUTURE3                     
			, FUTURE4                     
			, ERP_CCID                    
			, BUSINESS_TYPE               
			, TCS                         
			, TAX_CATEGORY                
			, TAX_CATEGORY_ID             
			, TDS_TAX_TYPE_CODE           
			, TDS_TAX_TYPE_ID             
			, TAX_RATE_NAME               
			, ERP_TAX_RATE_ID             
			, TAX_RATE_TAX_AMOUNT         
			, TAX_RECOVERABLE_OR_NOT      
			, CONTEXT_VALUE               
			, FLEX_FIELD_VALUE            
			, ATTRIBUTE10                 
			, ATTRIBUTE15                 
			, INVOICE_TAX_TYPE            
			, ERP_TAX_TYPE_ID             
			, REFERENCE_KEY1_INVOICE_NUM  
			, REFERENCE_KEY2_LINE_NUM     
			, REFERENCE_KEY3              
			, OPERATING_UNIT              
			, ERP_ORG_ID                  
			, PROCESS_FLAG                
			, ERROR_MSG                   
			, CREATED_BY                  
			, CREATION_DATE               
			, UPDATED_BY                  
			, LAST_UPDATE_DATE            
			, BATCH_ID
			, RECORD_ID
	FROM XXAU_AP_INV_WITH_GST_TDS_TBL@ebstohr
	WHERE 1=1
	AND PARTY_NAME = P_PARTY_NAME
	AND INVOICE_NUMBER = P_INVOICE_NUM
	AND OPERATING_UNIT = P_OPERATING_UNIT
	AND BATCH_ID = P_BATCH_ID
	AND PROCESS_FLAG = 'V')
	;
	
	CURSOR CUR_TAXES (P_TAX_CATEGORY VARCHAR2, P_TAX_RATE_NAME VARCHAR2, P_TAX_TYPE VARCHAR2, P_ORG_ID NUMBER)
	IS
	(SELECT TAX_CATEGORY_ID,
			 RATE_PERCENTAGE,
			 TAX_RATE_NAME,
			 TAX_RATE_ID,
			 TAX_TYPE_ID,
			 TAX_TYPE_CODE,
			 RECOVERABLE_FLAG
		FROM TI_GST_TAX_V
	   WHERE 1=1
			AND UPPER (TAX_CATEGORY_NAME) = UPPER (P_TAX_CATEGORY)
			AND (UPPER(TAX_RATE_NAME) = UPPER(P_TAX_RATE_NAME) OR P_TAX_RATE_NAME IS NULL)
			AND (UPPER(TAX_TYPE_NAME) = UPPER(P_TAX_TYPE) OR P_TAX_TYPE IS NULL)
			AND ORG_ID = P_ORG_ID
	--ORDER BY RATE_PERCENTAGE
	)
	;
		
	LN_LINE_NUMBER NUMBER;
	LN_INVOICE_ID NUMBER;
	LN_AP_LINE_ID NUMBER;
	LN_TAX_AMOUNT NUMBER;
	LN_TAX_LINE_COUNTER NUMBER;
	LN_TAX_TCS_LINE_COUNTER NUMBER;
	LN_TOT_TAX_PER NUMBER;
	LN_TOT_GST_AMOUNT NUMBER;
	LN_JAI_INTERFACE_LINE_ID NUMBER;
	LN_LIABILITY_CCID NUMBER;
	LN_JAI_TAX_LINE_ID NUMBER;
	HDR_ERR_MSG VARCHAR2(4000);
	
	BEGIN
		FND_GLOBAL.APPS_INITIALIZE (2482, 200, 52144);
        --MO_GLOBAL.INIT ('AP');
		MO_GLOBAL.SET_POLICY_CONTEXT('S', 386);
		FND_FILE.PUT_LINE(FND_FILE.LOG,' LOADING DATA TO INTERFACE TABLES... ');
		FOR REC_HDR IN CUR_HDR_DATA
		LOOP
			BEGIN
				
				SELECT AP_INVOICES_INTERFACE_S.NEXTVAL
				  INTO LN_INVOICE_ID
				FROM DUAL;
							
				INSERT INTO AP_INVOICES_INTERFACE (
                                INVOICE_ID,
                                INVOICE_NUM,
                                INVOICE_AMOUNT,
                                INVOICE_CURRENCY_CODE,
                                GL_DATE,
                                SOURCE,
                                ORG_ID,
                                INVOICE_TYPE_LOOKUP_CODE,
                                INVOICE_DATE,
                                VENDOR_ID,
                                VENDOR_SITE_ID,
                                DESCRIPTION,
                                CREATION_DATE,
                                CREATED_BY,
                                LAST_UPDATED_BY,
                                LAST_UPDATE_DATE,
                                LAST_UPDATE_LOGIN,
                                CALC_TAX_DURING_IMPORT_FLAG,
                                REFERENCE_KEY1,
                                REFERENCE_KEY2,
                                REFERENCE_KEY3,
                                ACCTS_PAY_CODE_COMBINATION_ID,
                                PAYMENT_METHOD_LOOKUP_CODE,
                                ATTRIBUTE15)
                     VALUES (LN_INVOICE_ID,
                             REC_HDR.INVOICE_NUMBER,
                             REC_HDR.INVOICE_AMOUNT,
                             NVL (REC_HDR.INVOICE_CURRENCY_CODE, 'INR'),
                             REC_HDR.GL_DATE,
                             'INVOICE GATEWAY',
                             REC_HDR.ERP_ORG_ID,
                             REC_HDR.INVOICE_TYPE_LOOKUP_CODE, --'STANDARD',
                             REC_HDR.INVOICE_DATE,                   --SYSDATE
                             REC_HDR.ERP_VENDOR_ID,
                             REC_HDR.VENDOR_SITE_ID,
                             'ALL GST + TDS IMPORT',
                             SYSDATE,
                             GN_USER_ID,
                             GN_USER_ID,
                             SYSDATE,
                             GN_USER_ID,
                             'Y',
                             REC_HDR.INVOICE_NUMBER,
                             1,
                             'OFI TAX IMPORT',
                             REC_HDR.ACCTS_PAY_CC_ID,
                             'CHECK',
                             'AP_INDUS_API')
							 ;
				
				LN_LINE_NUMBER := 1; 
				FOR REC_LINE IN CUR_LINE_DATA  (REC_HDR.INVOICE_NUMBER  ,REC_HDR.OPERATING_UNIT, REC_HDR.PARTY_NAME)
				LOOP
					BEGIN     
						
						SELECT AP_INVOICE_LINES_INTERFACE_S.NEXTVAL
						INTO LN_AP_LINE_ID
						FROM DUAL;
						
						INSERT INTO AP_INVOICE_LINES_INTERFACE (
                                INVOICE_ID,
                                INVOICE_LINE_ID,
                                LINE_NUMBER,
                                LINE_GROUP_NUMBER,
                                LINE_TYPE_LOOKUP_CODE,
                                AMOUNT,
                                DESCRIPTION,
                                ACCOUNTING_DATE,
                                ORG_ID,
                                CREATION_DATE,
                                CREATED_BY,
                                LAST_UPDATED_BY,
                                LAST_UPDATE_DATE,
                                LAST_UPDATE_LOGIN,
                                DIST_CODE_COMBINATION_ID,
                                REFERENCE_KEY1,
                                REFERENCE_KEY2,
                                REFERENCE_KEY3,
                                ATTRIBUTE_CATEGORY,
                                ATTRIBUTE10,
                                ATTRIBUTE15)
						 VALUES (LN_INVOICE_ID,
								 LN_AP_LINE_ID,
								 LN_LINE_NUMBER,
								 REC_LINE.GROUP_LINE_NUM,
								 REC_LINE.ERP_LINE_TYPE_CODE , --'ITEM',
								 REC_LINE.LINE_AMOUNT,
								 REC_LINE.LINE_DESCRIPTION,
								 REC_HDR.GL_DATE,
								 REC_LINE.ERP_ORG_ID,
								 SYSDATE,
								 GN_USER_ID,
								 GN_USER_ID,
								 SYSDATE,
								 GN_USER_ID,
								 REC_LINE.ERP_CCID,
								 REC_HDR.INVOICE_NUMBER,
								 LN_LINE_NUMBER,
								 'OFI TAX IMPORT',
								 REC_LINE.CONTEXT_VALUE,
								 REC_LINE.ATTRIBUTE10,
								 'AP_INDUS_API');
						
						LN_TAX_LINE_COUNTER := 1;
						
						/* Added by AKALA on 24-APR-2026, for Taxes (GST + TDS) */
						FND_FILE.PUT_LINE(FND_FILE.LOG,'Entering Tax Lines start');
						FOR REC_TAXES IN CUR_TAXES (REC_LINE.TAX_CATEGORY
													, NULL--REC_LINE.TAX_RATE_NAME 
													, NULL--REC_LINE.INVOICE_TAX_TYPE
													, REC_LINE.ERP_ORG_ID)
						LOOP
							BEGIN
								-- CALCULATING FOR EACH LINE
								LN_TAX_AMOUNT := REC_LINE.LINE_AMOUNT * REC_TAXES.RATE_PERCENTAGE / 100;
								
								
								FND_FILE.PUT_LINE(FND_FILE.LOG,'Tax: '|| REC_TAXES.TAX_RATE_NAME|| ' = '|| LN_TAX_AMOUNT);
								
								-- JAI Interface Line (ONLY FIRST TAX)

								IF LN_TAX_LINE_COUNTER = 1
								THEN
									-- CALCULATING FOR HEADER LEVEL
									FND_FILE.PUT_LINE(FND_FILE.LOG,'Entering Tax Lines for LN_TAX_LINE_COUNTER : '||LN_TAX_LINE_COUNTER);
									SELECT SUM (RATE_PERCENTAGE)
									INTO LN_TOT_TAX_PER
									FROM TI_GST_TAX_V
									WHERE     UPPER (TAX_CATEGORY_NAME) =  UPPER (REC_LINE.TAX_CATEGORY)
											   AND ORG_ID = REC_LINE.ERP_ORG_ID;
									
									LN_TOT_GST_AMOUNT := REC_LINE.LINE_AMOUNT * LN_TOT_TAX_PER / 100;

									
									SELECT JAI_INTERFACE_LINES_ALL_S.NEXTVAL
									INTO LN_JAI_INTERFACE_LINE_ID
									FROM DUAL;

									INSERT INTO JAI_INTERFACE_LINES_ALL (
													ORG_ID,
													ORGANIZATION_ID,
													LOCATION_ID,
													PARTY_ID,
													PARTY_SITE_ID,
													IMPORT_MODULE,
													TRANSACTION_NUM,
													TRANSACTION_LINE_NUM,
													BATCH_SOURCE_NAME,
													CREATION_DATE,
													CREATED_BY,
													LAST_UPDATE_DATE,
													LAST_UPDATE_LOGIN,
													LAST_UPDATED_BY,
													INTERFACE_LINE_ID,
													TAXABLE_EVENT,
													HSN_CODE,
													TAX_CATEGORY_ID,
													TAXABLE_BASIS,
													EXCLUSIVE_TAX_AMOUNT,
													INTENDED_USE,
													ATTRIBUTE15)
											 VALUES (
														REC_LINE.ERP_ORG_ID,
														NVL (REC_LINE.INV_ORGANIZATION_ID,REC_LINE.ERP_ORG_ID),
														NVL (REC_LINE.LOCATION_ID, 0),
														REC_HDR.ERP_VENDOR_ID,
														NVL (REC_HDR.VENDOR_SITE_ID, 0),
														'AP',
														REC_HDR.INVOICE_NUMBER,
														LN_LINE_NUMBER,
														'OFI TAX IMPORT',
														SYSDATE,
														GN_USER_ID,
														SYSDATE,
														GN_USER_ID,
														GN_USER_ID,
														LN_JAI_INTERFACE_LINE_ID,
														'EXTERNAL',
														NVL (REC_LINE.HSNCODE, '9999'),
														REC_TAXES.TAX_CATEGORY_ID,
														'LINE_AMOUNT',
														LN_TOT_GST_AMOUNT,
														DECODE (REC_TAXES.RECOVERABLE_FLAG,'Y', UPPER ('RECOVERABLE'),NULL),
														'AP_INDUS_API');
									
								END IF;
								
								--IF UPPER(REC_LINE.TAX_CATEGORY) NOT LIKE '%TDS%'
								--THEN
									FND_FILE.PUT_LINE(FND_FILE.LOG,'TAX_LINE_NO = LN_TAX_LINE_COUNTER : '|| LN_TAX_LINE_COUNTER);
								
									-- Tax Liability CCID

									BEGIN
										SELECT INTERIM_RECOVERY_CCID --RECOVERY_CCID--LIABILITY_CCID
										  INTO LN_LIABILITY_CCID
										  FROM JAI_TAX_ACCOUNTS_V
										 WHERE     ORG_ID = REC_LINE.ERP_ORG_ID
											   AND ORGANIZATION_ID = NVL (REC_LINE.INV_ORGANIZATION_ID,REC_LINE.ERP_ORG_ID)
											   AND TAX_ACCOUNT_ENTITY_ID = REC_TAXES.TAX_TYPE_ID
											;
									EXCEPTION
										WHEN OTHERS
										THEN
											LN_LIABILITY_CCID := NULL;
									END;



									-- JAI Tax Line
									
									SELECT JAI_INTERFACE_TAX_LINES_ALL_S.NEXTVAL
									  INTO LN_JAI_TAX_LINE_ID
									  FROM DUAL;

									INSERT INTO JAI_INTERFACE_TAX_LINES_ALL (
													PARTY_ID,
													PARTY_SITE_ID,
													IMPORT_MODULE,
													TRANSACTION_NUM,
													TRANSACTION_LINE_NUM,
													TAX_LINE_NO,
													CREATION_DATE,
													CREATED_BY,
													LAST_UPDATE_DATE,
													LAST_UPDATE_LOGIN,
													LAST_UPDATED_BY,
													INTERFACE_LINE_ID,
													INTERFACE_TAX_LINE_ID,
													EXTERNAL_TAX_CODE,
													TAX_ID,
													TAX_AMOUNT,
													INCLUSIVE_TAX_FLAG,
													CODE_COMBINATION_ID,
													PRECEDENCE_1,
													PRECEDENCE_2,
													PRECEDENCE_3,
													PRECEDENCE_4,
													PRECEDENCE_5,
													PRECEDENCE_6,
													PRECEDENCE_7,
													PRECEDENCE_8,
													PRECEDENCE_9,
													PRECEDENCE_10)
										 VALUES (REC_HDR.ERP_VENDOR_ID,
												 NVL (REC_HDR.VENDOR_SITE_ID, 0),
												 'AP',
												 REC_HDR.INVOICE_NUMBER,
												 LN_LINE_NUMBER,
												 LN_TAX_LINE_COUNTER,
												 SYSDATE,
												 GN_USER_ID,
												 SYSDATE,
												 GN_USER_ID,
												 GN_USER_ID,
												 LN_JAI_INTERFACE_LINE_ID,
												 LN_JAI_TAX_LINE_ID,
												 REC_TAXES.TAX_RATE_NAME,
												 REC_TAXES.TAX_RATE_ID,
												 LN_TAX_AMOUNT,
												 'N',
												 LN_LIABILITY_CCID,
												 0,
												 (CASE WHEN LN_TAX_LINE_COUNTER >= 2 THEN 1 ELSE NULL END),
												 (CASE WHEN LN_TAX_LINE_COUNTER >= 3 THEN 2 ELSE NULL END),
												 (CASE WHEN LN_TAX_LINE_COUNTER >= 4 THEN 3 ELSE NULL END),
												 (CASE WHEN LN_TAX_LINE_COUNTER >= 5 THEN 4 ELSE NULL END),
												 (CASE WHEN LN_TAX_LINE_COUNTER >= 6 THEN 5 ELSE NULL END),
												 (CASE WHEN LN_TAX_LINE_COUNTER >= 7 THEN 6 ELSE NULL END),
												 (CASE WHEN LN_TAX_LINE_COUNTER >= 8 THEN 7 ELSE NULL END),
												 (CASE WHEN LN_TAX_LINE_COUNTER >= 9 THEN 8 ELSE NULL END),
												 (CASE WHEN LN_TAX_LINE_COUNTER = 10 THEN 9 ELSE NULL END)
												 );
									
								--ELSE
									FND_FILE.PUT_LINE(FND_FILE.LOG,'TAX CATEGORY IS TDS : '||REC_LINE.TAX_CATEGORY);
								--END IF;
								
								COMMIT;
								
								LN_TAX_LINE_COUNTER := LN_TAX_LINE_COUNTER + 1;
							EXCEPTION WHEN OTHERS THEN
								FND_FILE.PUT_LINE(FND_FILE.LOG,SQLCODE||' - '||SQLERRM);
							END;
						END LOOP;
					LN_LINE_NUMBER := LN_LINE_NUMBER + 1;
					FND_FILE.PUT_LINE(FND_FILE.LOG,'LN_INVOICE_ID : '||LN_INVOICE_ID||'; LN_AP_LINE_ID: '||LN_AP_LINE_ID);
					
					UPDATE XXAU_AP_INV_WITH_GST_TDS_TBL@ebstohr
					SET PROCESS_FLAG = 'P'
						, ERROR_MSG = 'Processed.'
						, UPDATED_BY = GN_USER_ID
						, LAST_UPDATE_DATE = SYSDATE
					WHERE RECORD_ID = REC_LINE.RECORD_ID
					AND OPERATING_UNIT = REC_LINE.OPERATING_UNIT
					AND INVOICE_NUMBER = REC_HDR.INVOICE_NUMBER
					AND BATCH_ID = REC_LINE.BATCH_ID
					;
					
					COMMIT;
					
					EXCEPTION
					WHEN OTHERS THEN
					REC_LINE.ERROR_MSG := REC_LINE.ERROR_MSG||'; '||SQLCODE||' - '||SQLERRM;
					 FND_FILE.PUT_LINE(FND_FILE.LOG,SQLCODE||' - '||SQLERRM);
					 UPDATE XXAU_AP_INV_WITH_GST_TDS_TBL@ebstohr
						SET PROCESS_FLAG = 'E'
							, ERROR_MSG = ERROR_MSG||', '||REC_LINE.ERROR_MSG
							, UPDATED_BY = GN_USER_ID
							, LAST_UPDATE_DATE = SYSDATE
						WHERE RECORD_ID = REC_LINE.RECORD_ID
						AND OPERATING_UNIT = REC_LINE.OPERATING_UNIT
						AND INVOICE_NUMBER = REC_HDR.INVOICE_NUMBER
						AND BATCH_ID = REC_LINE.BATCH_ID
						;
					END;
				END LOOP;
			
			EXCEPTION
			WHEN OTHERS THEN
			FND_FILE.PUT_LINE(FND_FILE.LOG,SQLCODE||' - '||SQLERRM);
			HDR_ERR_MSG := ', Error at header level: '||SQLCODE||' - '||SQLERRM;
			UPDATE XXAU_AP_INV_WITH_GST_TDS_TBL@ebstohr
						SET PROCESS_FLAG = 'E'
							, ERROR_MSG = ERROR_MSG||HDR_ERR_MSG
							, UPDATED_BY = GN_USER_ID
							, LAST_UPDATE_DATE = SYSDATE
						WHERE 1=1
						AND OPERATING_UNIT = REC_HDR.OPERATING_UNIT
						AND INVOICE_NUMBER = REC_HDR.INVOICE_NUMBER
						AND BATCH_ID = REC_HDR.BATCH_ID
						;
			END;
			COMMIT;
		END LOOP;
	EXCEPTION
	WHEN OTHERS THEN
		FND_FILE.PUT_LINE(FND_FILE.LOG,SQLCODE||' - '||SQLERRM);
	END LOAD_DATA_TO_INTERFACE;

    /*************************************************************************************************
     * Program Name : CREATE_AP_INVOICES
     * Language     : PL/SQL
     * Description  : This a local procedure which is used for inserting data into Interface tables.
						1. AP_INVOICES_INTERFACE 
						2. AP_INVOICE_LINES_INTERFACE
					It will migrate the data to Oracle Interface Tables.
					It contains data only for AP Invoices and Lines.
     * Parameters : 1. P_BATCH_ID => Number , It is Mandatory Parameter
     *
     * History      :
     * WHO              Version #   WHEN            WHAT
     * ===============  =========   =============   ====================================================
     * AKALA            1.0         28-APR-2026     Initial Version
     ***************************************************************************************************/
	
	PROCEDURE CREATE_AP_INVOICES (P_BATCH_ID NUMBER) 
	AS
	CURSOR CUR_HDR_DATA IS
	(SELECT  INVOICE_NUMBER              
			, ERP_INVOICE_ID              
			, INVOICE_TYPE                
			, INVOICE_TYPE_LOOKUP_CODE    
			, LEDGER_ID                   
			, PARTY_NAME                  
			, VENDOR_CODE                 
			, ERP_VENDOR_ID               
			, VENDOR_SITE_CODE 
			, OPERATING_UNIT				
			, VENDOR_SITE_ID              
			, ACCTS_PAY_CC_ID             
			, TRUNC(GL_DATE) GL_DATE                     
			, TRUNC(INVOICE_DATE) INVOICE_DATE                
			, INVOICE_CURRENCY_CODE       
			, EXCHANGE_RATE
			, ERP_ORG_ID
			, SUM(LINE_AMOUNT) INVOICE_AMOUNT
	FROM XXAU_AP_INV_WITH_GST_TDS_TBL@ebstohr B
	WHERE 1=1
	AND TAX_CATEGORY IS NULL
	AND (BATCH_ID = P_BATCH_ID OR P_BATCH_ID IS NULL)
	AND NOT EXISTS (SELECT 1
                            FROM AP_INVOICES_ALL AIA
                           WHERE     AIA.INVOICE_NUM = B.INVOICE_NUMBER
                                 AND TRUNC (GL_DATE) >= '01-FEB-2026'
                                 AND AIA.VENDOR_ID IN
                                         (SELECT VENDOR_ID
                                            FROM PO_VENDORS POV
                                           WHERE POV.SEGMENT1 = B.VENDOR_CODE)) -- AND AIA.SOURCE = 'INVOICE GATEWAY')
    AND NOT EXISTS  (SELECT 1
                            FROM AP_INVOICES_INTERFACE
                           WHERE INVOICE_NUM = B.INVOICE_NUMBER)
    AND NOT EXISTS  (SELECT 1
                            FROM AP_INVOICE_LINES_INTERFACE
                           WHERE INVOICE_ID IN
                                     (SELECT INVOICE_ID
                                        FROM AP_INVOICES_INTERFACE
                                       WHERE INVOICE_NUM = B.INVOICE_NUMBER))
    AND NOT EXISTS  (SELECT 1
                            FROM JAI_INTERFACE_LINES_ALL
                           WHERE     IMPORT_MODULE = 'AP'
                                 AND TRANSACTION_NUM = B.INVOICE_NUMBER)
    AND NOT EXISTS  (SELECT 1
                            FROM JAI_INTERFACE_TAX_LINES_ALL
                           WHERE     IMPORT_MODULE = 'AP'
                                 AND TRANSACTION_NUM = B.INVOICE_NUMBER)
	AND EXISTS  (SELECT 1
                            FROM TI_VENDOR_DETAILS_V C ---VIEW FOR THIRD PARTY REGISTRATION VENDOR SITE---
                           WHERE     C.VENDOR_CODE = B.VENDOR_CODE
                                 AND C.UNIT 	 = B.UNIT
                                 AND C.VENDOR_SITE_CODE = B.VENDOR_SITE_CODE
                                 AND C.SET_OF_BOOKS_ID = B.LEDGER_ID)
	AND PROCESS_FLAG = 'V'
	GROUP BY  BATCH_ID
			, INVOICE_NUMBER              
			, INVOICE_TYPE                
			, LEDGER_ID                   
			, PARTY_NAME                  
			, VENDOR_CODE                 
			, VENDOR_SITE_CODE 
			, OPERATING_UNIT				
			, ACCTS_PAY_CC_ID             
			, TRUNC(GL_DATE)                     
			, TRUNC(INVOICE_DATE)                
			, EXCHANGE_RATE  
			, INVOICE_CURRENCY_CODE       
			, ERP_INVOICE_ID              
			, INVOICE_TYPE_LOOKUP_CODE    
			, ERP_VENDOR_ID               
			, VENDOR_SITE_ID
			, ERP_ORG_ID
	HAVING COUNT(1) = (SELECT COUNT(1) 
						FROM XXAU_AP_INV_WITH_GST_TDS_TBL@ebstohr 
						WHERE INVOICE_NUMBER = B.INVOICE_NUMBER 
						AND OPERATING_UNIT = B.OPERATING_UNIT 
						AND TRIM(UPPER(PARTY_NAME))= TRIM(UPPER(B.PARTY_NAME)))
    )           
	;
		
	CURSOR CUR_LINE_DATA (P_INVOICE_NUM VARCHAR2, P_OPERATING_UNIT VARCHAR2, P_PARTY_NAME VARCHAR2)IS
	(SELECT  RECORD_ID
			, ERP_INVOICE_LINE_ID         
			, GROUP_LINE_NUM              
			, LINE_TYPE                   
			, ERP_LINE_TYPE_CODE          
			, UNIT                        
			, JOB_ACTIVITY                    
			, LINE_AMOUNT                 
			, INV_ORGANIZATION_ID         
			, LOCATION_ID                 
			, HSNCODE                     
			, LINE_DESCRIPTION            
			, NATURAL_ACCOUNT             
			, LOCATION                    
			, DEPARTMENT                  
			, FUTURE1                     
			, FUTURE2                     
			, FUTURE3                     
			, FUTURE4                     
			, ERP_CCID                    
			, BUSINESS_TYPE               
			, TCS                         
			, TAX_CATEGORY                
			, TAX_CATEGORY_ID             
			, TDS_TAX_TYPE_CODE           
			, TDS_TAX_TYPE_ID             
			, TAX_RATE_NAME               
			, ERP_TAX_RATE_ID             
			, TAX_RATE_TAX_AMOUNT         
			, TAX_RECOVERABLE_OR_NOT      
			, CONTEXT_VALUE               
			, FLEX_FIELD_VALUE            
			, ATTRIBUTE10                 
			, ATTRIBUTE15                 
			, INVOICE_TAX_TYPE            
			, ERP_TAX_TYPE_ID             
			, REFERENCE_KEY1_INVOICE_NUM  
			, REFERENCE_KEY2_LINE_NUM     
			, REFERENCE_KEY3              
			, OPERATING_UNIT              
			, ERP_ORG_ID                  
			, PROCESS_FLAG                
			, ERROR_MSG                   
			, CREATED_BY                  
			, CREATION_DATE               
			, UPDATED_BY                  
			, LAST_UPDATE_DATE            
			, BATCH_ID              
	FROM XXAU_AP_INV_WITH_GST_TDS_TBL@ebstohr
	WHERE 1=1
	AND TAX_CATEGORY IS NULL
	AND PARTY_NAME = P_PARTY_NAME
	AND INVOICE_NUMBER = P_INVOICE_NUM
	AND OPERATING_UNIT = P_OPERATING_UNIT
	AND BATCH_ID = P_BATCH_ID
	AND PROCESS_FLAG = 'V')
	;
		
	LN_LINE_NUMBER NUMBER;
	LN_INVOICE_ID NUMBER;
	LN_AP_LINE_ID NUMBER;
	LN_TAX_AMOUNT NUMBER;
	LN_TAX_LINE_COUNTER NUMBER;
	LN_TOT_TAX_PER NUMBER;
	LN_TOT_GST_AMOUNT NUMBER;
	LN_JAI_INTERFACE_LINE_ID NUMBER;
	LN_LIABILITY_CCID NUMBER;
	LN_JAI_TAX_LINE_ID NUMBER;
	HDR_ERR_MSG VARCHAR2(4000);
	
	BEGIN
		FND_GLOBAL.APPS_INITIALIZE (2482, 200, 52144);
        --MO_GLOBAL.INIT ('AP');
		MO_GLOBAL.SET_POLICY_CONTEXT('S', 386);
		FND_FILE.PUT_LINE(FND_FILE.LOG,' LOADING DATA TO INTERFACE TABLES... ');
		FOR REC_HDR IN CUR_HDR_DATA
		LOOP
			BEGIN
				
				SELECT AP_INVOICES_INTERFACE_S.NEXTVAL
				  INTO LN_INVOICE_ID
				FROM DUAL;
				
				INSERT INTO AP_INVOICES_INTERFACE (
                                INVOICE_ID,
                                INVOICE_NUM,
                                INVOICE_AMOUNT,
                                INVOICE_CURRENCY_CODE,
                                GL_DATE,
                                SOURCE,
                                ORG_ID,
                                INVOICE_TYPE_LOOKUP_CODE,
                                INVOICE_DATE,
                                VENDOR_ID,
                                VENDOR_SITE_ID,
                                DESCRIPTION,
                                CREATION_DATE,
                                CREATED_BY,
                                LAST_UPDATED_BY,
                                LAST_UPDATE_DATE,
                                LAST_UPDATE_LOGIN,
                                CALC_TAX_DURING_IMPORT_FLAG,
                                REFERENCE_KEY1,
                                REFERENCE_KEY2,
                                REFERENCE_KEY3,
                                ACCTS_PAY_CODE_COMBINATION_ID,
                                PAYMENT_METHOD_LOOKUP_CODE,
                                ATTRIBUTE15)
                     VALUES (LN_INVOICE_ID,
                             REC_HDR.INVOICE_NUMBER,
                             REC_HDR.INVOICE_AMOUNT,
                             NVL (REC_HDR.INVOICE_CURRENCY_CODE, 'INR'),
                             REC_HDR.GL_DATE,
                             'INVOICE GATEWAY',
                             REC_HDR.ERP_ORG_ID,
                             REC_HDR.INVOICE_TYPE_LOOKUP_CODE, --'STANDARD',
                             REC_HDR.INVOICE_DATE,                   --SYSDATE
                             REC_HDR.ERP_VENDOR_ID,
                             REC_HDR.VENDOR_SITE_ID,
                             'All invoices and line import process without tax.',
                             SYSDATE,
                             GN_USER_ID,
                             GN_USER_ID,
                             SYSDATE,
                             GN_USER_ID,
                             'Y',
                             REC_HDR.INVOICE_NUMBER,
                             1,
                             'OFI TAX IMPORT',
                             REC_HDR.ACCTS_PAY_CC_ID,
                             'CHECK',
                             'AP_INDUS_API')
							 ;
				
				LN_LINE_NUMBER := 1; 
				FOR REC_LINE IN CUR_LINE_DATA  (REC_HDR.INVOICE_NUMBER  ,REC_HDR.OPERATING_UNIT, REC_HDR.PARTY_NAME)
				LOOP
					BEGIN     
						
						SELECT AP_INVOICE_LINES_INTERFACE_S.NEXTVAL
						INTO LN_AP_LINE_ID
						FROM DUAL;
						
						INSERT INTO AP_INVOICE_LINES_INTERFACE (
                                INVOICE_ID,
                                INVOICE_LINE_ID,
                                LINE_NUMBER,
                                LINE_GROUP_NUMBER,
                                LINE_TYPE_LOOKUP_CODE,
                                AMOUNT,
                                DESCRIPTION,
                                ACCOUNTING_DATE,
                                ORG_ID,
                                CREATION_DATE,
                                CREATED_BY,
                                LAST_UPDATED_BY,
                                LAST_UPDATE_DATE,
                                LAST_UPDATE_LOGIN,
                                DIST_CODE_COMBINATION_ID,
                                REFERENCE_KEY1,
                                REFERENCE_KEY2,
                                REFERENCE_KEY3,
                                ATTRIBUTE_CATEGORY,
                                ATTRIBUTE10,
                                ATTRIBUTE15)
						 VALUES (LN_INVOICE_ID,
								 LN_AP_LINE_ID,
								 LN_LINE_NUMBER,
								 REC_LINE.GROUP_LINE_NUM,
								 REC_LINE.ERP_LINE_TYPE_CODE , --'ITEM',
								 REC_LINE.LINE_AMOUNT,
								 REC_LINE.LINE_DESCRIPTION,
								 REC_HDR.GL_DATE,
								 REC_LINE.ERP_ORG_ID,
								 SYSDATE,
								 GN_USER_ID,
								 GN_USER_ID,
								 SYSDATE,
								 GN_USER_ID,
								 REC_LINE.ERP_CCID,
								 REC_HDR.INVOICE_NUMBER,
								 LN_LINE_NUMBER,
								 'OFI TAX IMPORT',
								 REC_LINE.CONTEXT_VALUE,
								 REC_LINE.ATTRIBUTE10,
								 'AP_INDUS_API');
												
					LN_LINE_NUMBER := LN_LINE_NUMBER + 1;
					FND_FILE.PUT_LINE(FND_FILE.LOG,'LN_INVOICE_ID : '||LN_INVOICE_ID||'; LN_AP_LINE_ID: '||LN_AP_LINE_ID);
					
					UPDATE XXAU_AP_INV_WITH_GST_TDS_TBL@ebstohr
					SET PROCESS_FLAG = 'P'
						, ERROR_MSG = 'Processed.'
						, UPDATED_BY = GN_USER_ID
						, LAST_UPDATE_DATE = SYSDATE
					WHERE RECORD_ID = REC_LINE.RECORD_ID
					AND OPERATING_UNIT = REC_LINE.OPERATING_UNIT
					AND INVOICE_NUMBER = REC_HDR.INVOICE_NUMBER
					;
					
					COMMIT;
					
					EXCEPTION
					WHEN OTHERS THEN
						FND_FILE.PUT_LINE(FND_FILE.LOG,SQLCODE||' - '||SQLERRM);
					 
						UPDATE XXAU_AP_INV_WITH_GST_TDS_TBL@ebstohr
						SET PROCESS_FLAG = 'E'
						, ERROR_MSG = 'Error while inserting lines into Interface.'
						, UPDATED_BY = GN_USER_ID
						, LAST_UPDATE_DATE = SYSDATE
						WHERE RECORD_ID = REC_LINE.RECORD_ID
						AND OPERATING_UNIT = REC_LINE.OPERATING_UNIT
						AND INVOICE_NUMBER = REC_HDR.INVOICE_NUMBER
						;
						
						COMMIT;
					 
					END;
				END LOOP;
			
			EXCEPTION
			WHEN OTHERS THEN
			FND_FILE.PUT_LINE(FND_FILE.LOG,SQLCODE||' - '||SQLERRM);
			HDR_ERR_MSG := ' - Error while inserting at header level: '||SQLCODE||' - '||SQLERRM;
						
						UPDATE XXAU_AP_INV_WITH_GST_TDS_TBL@ebstohr
						SET PROCESS_FLAG = 'E'
						, ERROR_MSG = ERROR_MSG||HDR_ERR_MSG
						, UPDATED_BY = GN_USER_ID
						, LAST_UPDATE_DATE = SYSDATE
						WHERE 1=1
						AND BATCH_ID = P_BATCH_ID
						AND OPERATING_UNIT = REC_HDR.OPERATING_UNIT
						AND INVOICE_NUMBER = REC_HDR.INVOICE_NUMBER
						;
						
						COMMIT;
			END;
			COMMIT;
		END LOOP;
	EXCEPTION
	WHEN OTHERS THEN
		FND_FILE.PUT_LINE(FND_FILE.LOG,SQLCODE||' - '||SQLERRM);
	END CREATE_AP_INVOICES;
	

    /*************************************************************************************************
     * Program Name : VALIDATE_DATA
     * Language     : PL/SQL
     * Description  : This a global procedure which is used for validating data before inserting data into Interface tables.
     * Parameters : 1. P_BATCH_ID => Number , It is Mandatory Parameter
     *
     * History      :
     * WHO              Version #   WHEN            WHAT
     * ===============  =========   =============   ====================================================
     * AKALA            1.0         23-APR-2026     Initial Version
     ***************************************************************************************************/
	
	PROCEDURE VALIDATE_DATA (P_BATCH_ID IN NUMBER) 
	AS	
	CURSOR CUR_HDR_DATA IS
	(SELECT  INVOICE_NUMBER              
			, ERP_INVOICE_ID              
			, INVOICE_TYPE                
			, INVOICE_TYPE_LOOKUP_CODE    
			, LEDGER_ID                   
			, PARTY_NAME                  
			, VENDOR_CODE                 
			, ERP_VENDOR_ID               
			, VENDOR_SITE_CODE 
			, OPERATING_UNIT				
			, VENDOR_SITE_ID              
			, ACCTS_PAY_CC_ID             
			, TRUNC(GL_DATE)       GL_DATE               
			, TRUNC(INVOICE_DATE) INVOICE_DATE                
			, INVOICE_CURRENCY_CODE       
			, EXCHANGE_RATE
			, ERP_ORG_ID
			, SUM(LINE_AMOUNT) INVOICE_AMOUNT
	FROM XXAU_AP_INV_WITH_GST_TDS_TBL@ebstohr B
	WHERE 1=1
	AND (BATCH_ID = P_BATCH_ID)
	AND NOT EXISTS (SELECT 1
                            FROM AP_INVOICES_ALL AIA
                           WHERE     AIA.INVOICE_NUM = B.INVOICE_NUMBER
                                 AND TRUNC (GL_DATE) >= '01-FEB-2026'
                                 AND AIA.VENDOR_ID IN
                                         (SELECT VENDOR_ID
                                            FROM PO_VENDORS POV
                                           WHERE POV.SEGMENT1 = B.VENDOR_CODE)) -- AND AIA.SOURCE = 'INVOICE GATEWAY')
    AND NOT EXISTS  (SELECT 1
                            FROM AP_INVOICES_INTERFACE
                           WHERE INVOICE_NUM = B.INVOICE_NUMBER)
    AND NOT EXISTS  (SELECT 1
                            FROM AP_INVOICE_LINES_INTERFACE
                           WHERE INVOICE_ID IN
                                     (SELECT INVOICE_ID
                                        FROM AP_INVOICES_INTERFACE
                                       WHERE INVOICE_NUM = B.INVOICE_NUMBER))
    AND NOT EXISTS  (SELECT 1
                            FROM JAI_INTERFACE_LINES_ALL
                           WHERE     IMPORT_MODULE = 'AP'
                                 AND TRANSACTION_NUM = B.INVOICE_NUMBER)
    AND NOT EXISTS  (SELECT 1
                            FROM JAI_INTERFACE_TAX_LINES_ALL
                           WHERE     IMPORT_MODULE = 'AP'
                                 AND TRANSACTION_NUM = B.INVOICE_NUMBER)
	AND EXISTS  (SELECT 1
                            FROM TI_VENDOR_DETAILS_V C ---VIEW FOR THIRD PARTY REGISTRATION VENDOR SITE---
                           WHERE     C.VENDOR_CODE = B.VENDOR_CODE
								 AND C.UNIT 	 = B.UNIT
                                 AND C.VENDOR_SITE_CODE = B.VENDOR_SITE_CODE
                                 AND EXISTS (SELECT 1
															FROM HR_OPERATING_UNITS
															WHERE 1=1
															AND C.SET_OF_BOOKS_ID = SET_OF_BOOKS_ID
															AND UPPER(NAME) = UPPER(B.OPERATING_UNIT)))
	AND (PROCESS_FLAG = 'N' OR PROCESS_FLAG IS NULL)
	GROUP BY  INVOICE_NUMBER              
			, INVOICE_TYPE                
			, LEDGER_ID                   
			, PARTY_NAME                  
			, VENDOR_CODE                 
			, VENDOR_SITE_CODE 
			, OPERATING_UNIT				
			, ACCTS_PAY_CC_ID             
			, TRUNC(GL_DATE)                     
			, TRUNC(INVOICE_DATE)                
			, EXCHANGE_RATE  
			, INVOICE_CURRENCY_CODE       
			, ERP_INVOICE_ID              
			, INVOICE_TYPE_LOOKUP_CODE    
			, ERP_VENDOR_ID               
			, VENDOR_SITE_ID
			, ERP_ORG_ID)           
	;
		
	CURSOR CUR_LINE_DATA (P_INVOICE_NUM VARCHAR2, P_OPERATING_UNIT VARCHAR2, P_PARTY_NAME VARCHAR2)IS
	(SELECT  ERP_INVOICE_LINE_ID         
			, GROUP_LINE_NUM              
			, LINE_TYPE                   
			, ERP_LINE_TYPE_CODE          
			, UNIT                        
			, JOB_ACTIVITY                    
			, LINE_AMOUNT                 
			, INV_ORGANIZATION_ID         
			, LOCATION_ID                 
			, HSNCODE                     
			, LINE_DESCRIPTION            
			, NATURAL_ACCOUNT             
			, LOCATION                    
			, DEPARTMENT                  
			, FUTURE1                     
			, FUTURE2                     
			, FUTURE3                     
			, FUTURE4                     
			, ERP_CCID                    
			, BUSINESS_TYPE               
			, TCS                         
			, TAX_CATEGORY                
			, TAX_CATEGORY_ID             
			, TDS_TAX_TYPE_CODE           
			, TDS_TAX_TYPE_ID             
			, TAX_RATE_NAME               
			, ERP_TAX_RATE_ID             
			, TAX_RATE_TAX_AMOUNT         
			, TAX_RECOVERABLE_OR_NOT      
			, CONTEXT_VALUE               
			, FLEX_FIELD_VALUE            
			, ATTRIBUTE10                 
			, ATTRIBUTE15                 
			, INVOICE_TAX_TYPE            
			, ERP_TAX_TYPE_ID             
			, REFERENCE_KEY1_INVOICE_NUM  
			, REFERENCE_KEY2_LINE_NUM     
			, REFERENCE_KEY3              
			, OPERATING_UNIT              
			, ERP_ORG_ID                  
			, PROCESS_FLAG                
			, ERROR_MSG                   
			, CREATED_BY                  
			, CREATION_DATE               
			, UPDATED_BY                  
			, LAST_UPDATE_DATE            
			, BATCH_ID              
			, RECORD_ID              
	FROM XXAU_AP_INV_WITH_GST_TDS_TBL@ebstohr
	WHERE 1=1
	AND PARTY_NAME = P_PARTY_NAME
	AND INVOICE_NUMBER = P_INVOICE_NUM
	AND OPERATING_UNIT = P_OPERATING_UNIT
	AND (BATCH_ID = P_BATCH_ID)
	AND (PROCESS_FLAG = 'N' OR PROCESS_FLAG IS NULL))
	;
	
		LC_INVOICE_TYPE VARCHAR2(100);
		LN_ACCT_PAY_CCID NUMBER;
		LN_RUNNING_LINE_AMT NUMBER:=0;
		LC_HDR_PRC_FLAG VARCHAR2(10);
		LC_HDR_ERROR_MSG VARCHAR2(4000);
		
	BEGIN
		FND_FILE.PUT_LINE(FND_FILE.LOG,'++++++++++ PROCESS STARTED ++++++++++');
				
		FND_FILE.PUT_LINE(FND_FILE.LOG,'++++++++++ HDR FOR LOOP STARTED ++++++++++');
		FOR REC_HDR IN CUR_HDR_DATA
		LOOP
			BEGIN
				REC_HDR.INVOICE_TYPE_LOOKUP_CODE:=NULL;
				REC_HDR.LEDGER_ID:=  NULL; 
				REC_HDR.ERP_ORG_ID:= NULL;
				REC_HDR.ERP_VENDOR_ID:= NULL;
				REC_HDR.VENDOR_SITE_ID:= NULL;
				REC_HDR.ACCTS_PAY_CC_ID := NULL;
				LC_HDR_PRC_FLAG := 'V';
				LC_HDR_ERROR_MSG := NULL;
				
				-- GL DATE AND INVOICE DATE
				IF REC_HDR.GL_DATE IS NULL OR REC_HDR.INVOICE_DATE IS NULL
				THEN 
					LC_HDR_PRC_FLAG := 'E';
					LC_HDR_ERROR_MSG :=  'GL Date or Invoice date cannot be null.';
				END IF;
				
				-- VALIDATE LOOKUP TYPE 
				BEGIN
					SELECT LOOKUP_CODE
						INTO REC_HDR.INVOICE_TYPE_LOOKUP_CODE
					FROM FND_LOOKUP_VALUES
						WHERE 1=1
						AND UPPER(MEANING) = UPPER(REC_HDR.INVOICE_TYPE)
						AND SYSDATE BETWEEN NVL(START_DATE_ACTIVE,TRUNC(SYSDATE)) AND NVL(END_DATE_ACTIVE, TRUNC(SYSDATE))+1
						AND LOOKUP_CODE <> 'STP INV OBJ PAYMENT'
						AND LOOKUP_TYPE = 'INVOICE TYPE'
						AND ENABLED_FLAG = 'Y'
					;
					FND_FILE.PUT_LINE(FND_FILE.LOG,'REC_HDR.INVOICE_TYPE_LOOKUP_CODE : '||REC_HDR.INVOICE_TYPE_LOOKUP_CODE);
				EXCEPTION
				WHEN OTHERS THEN
					REC_HDR.INVOICE_TYPE_LOOKUP_CODE := NULL;
					LC_HDR_PRC_FLAG := 'E';
					LC_HDR_ERROR_MSG := REG_ERR_MSG (LC_HDR_ERROR_MSG, 'Invoice Type Error.');
					FND_FILE.PUT_LINE(FND_FILE.LOG,'INVOICE_TYPE_LOOKUP_CODE :'||SQLCODE||' - '||SQLERRM);
				END;
				
				
				-- VALIDATING LEDGER ID AND ORG ID FROM ORGANIZATION NAME, OR SHORT CODE
				BEGIN
					SELECT SET_OF_BOOKS_ID, ORGANIZATION_ID
					INTO REC_HDR.LEDGER_ID, REC_HDR.ERP_ORG_ID
					FROM HR_OPERATING_UNITS
					WHERE 1=1
					AND UPPER(NAME) = UPPER(REC_HDR.OPERATING_UNIT)
					;
					FND_FILE.PUT_LINE(FND_FILE.LOG,'REC_HDR.LEDGER_ID : '||REC_HDR.LEDGER_ID||' - REC_HDR.ERP_ORG_ID : '||REC_HDR.ERP_ORG_ID);
				EXCEPTION
				WHEN OTHERS THEN
					REC_HDR.LEDGER_ID:=NULL; 
					REC_HDR.ERP_ORG_ID:=NULL;
					LC_HDR_PRC_FLAG := 'E';
					LC_HDR_ERROR_MSG := REG_ERR_MSG (LC_HDR_ERROR_MSG,' - Operating Unit Error.');
					FND_FILE.PUT_LINE(FND_FILE.LOG,'Operating :'||SQLCODE||' - '||SQLERRM);
				END;	

				-- VALIDATING VENDOR NAME 
				BEGIN
					SELECT VENDOR_ID
					INTO REC_HDR.ERP_VENDOR_ID
					FROM AP_SUPPLIERS
					WHERE 1=1
					AND UPPER(TRIM(VENDOR_NAME)) = TRIM(UPPER(REC_HDR.PARTY_NAME))
					AND SEGMENT1 = REC_HDR.VENDOR_CODE
					;
					FND_FILE.PUT_LINE(FND_FILE.LOG,'REC_HDR.ERP_VENDOR_ID : '||REC_HDR.ERP_VENDOR_ID);
				EXCEPTION
				WHEN OTHERS THEN
					REC_HDR.ERP_VENDOR_ID:=NULL;
					LC_HDR_PRC_FLAG := 'E';
					LC_HDR_ERROR_MSG := REG_ERR_MSG (LC_HDR_ERROR_MSG,'Vendor Error.');
					FND_FILE.PUT_LINE(FND_FILE.LOG,'PARTY_NAME : '||SQLCODE||' - '||SQLERRM);
				END;
				
				-- VALIDATING VENDOR SITE 
				BEGIN
					SELECT VENDOR_SITE_ID
					INTO REC_HDR.VENDOR_SITE_ID
					FROM AP_SUPPLIER_SITES_ALL
					WHERE 1=1
					AND UPPER(VENDOR_SITE_CODE) = UPPER(REC_HDR.VENDOR_SITE_CODE)
					AND VENDOR_ID = REC_HDR.ERP_VENDOR_ID
					;
					
					FND_FILE.PUT_LINE(FND_FILE.LOG,'REC_HDR.VENDOR_SITE_ID : '||REC_HDR.VENDOR_SITE_ID);
					
					-- Getting Libality Account ID 
					BEGIN
						SELECT ACCTS_PAY_CODE_COMBINATION_ID
						INTO REC_HDR.ACCTS_PAY_CC_ID
						FROM AP_SUPPLIER_SITES_ALL
						WHERE 1=1
						AND VENDOR_SITE_ID = REC_HDR.VENDOR_SITE_ID
						AND VENDOR_ID = REC_HDR.ERP_VENDOR_ID
						;
						
						FND_FILE.PUT_LINE(FND_FILE.LOG,'LIBALITY ACCOUNT : '||REC_HDR.ACCTS_PAY_CC_ID);
					EXCEPTION
					WHEN OTHERS THEN
						LC_HDR_PRC_FLAG := 'E';
						LC_HDR_ERROR_MSG := REG_ERR_MSG (LC_HDR_ERROR_MSG,'Libality Account not available.');
						FND_FILE.PUT_LINE(FND_FILE.LOG,'ACCTS_PAY_CODE_COMBINATION_ID: '||SQLCODE||' - '||SQLERRM);
					END;
					
				EXCEPTION
				WHEN OTHERS THEN
					LC_HDR_PRC_FLAG := 'E';
					LC_HDR_ERROR_MSG := REG_ERR_MSG (LC_HDR_ERROR_MSG, 'Vendor Site Error.');
					FND_FILE.PUT_LINE(FND_FILE.LOG,SQLCODE||' - '||SQLERRM);
				END;
							
				FND_FILE.PUT_LINE(FND_FILE.LOG,'++++++++++ LINE DATA ++++++++++');
				
				FOR REC_LINE IN CUR_LINE_DATA (REC_HDR.INVOICE_NUMBER  ,REC_HDR.OPERATING_UNIT, REC_HDR.PARTY_NAME)
				LOOP
				
					REC_LINE.PROCESS_FLAG := 'V';
					REC_LINE.ERROR_MSG := NULL;
					-- LINE TYPE VALIDATION
					BEGIN
						SELECT LOOKUP_CODE
						INTO REC_LINE.ERP_LINE_TYPE_CODE
							FROM FND_LOOKUP_VALUES
							WHERE 1=1
							AND UPPER(MEANING) = UPPER(REC_LINE.LINE_TYPE)
							AND LOOKUP_TYPE LIKE 'INVOICE LINE TYPE'
						;
					EXCEPTION WHEN OTHERS THEN
						REC_LINE.ERP_LINE_TYPE_CODE:=NULL;
						REC_LINE.PROCESS_FLAG := 'E';
						REC_LINE.ERROR_MSG := REG_ERR_MSG (REC_LINE.ERROR_MSG, 'Line Type Error.');
						FND_FILE.PUT_LINE(FND_FILE.LOG,'LINE TYPE VALIDATION :'||SQLCODE||' - '||SQLERRM);
					END;
					
					-- CODE OMBINATION VALIDATION
					BEGIN
					
						IF REC_HDR.ERP_ORG_ID = 386 
						THEN
							SELECT CODE_COMBINATION_ID
							  INTO REC_LINE.ERP_CCID
							FROM GL_CODE_COMBINATIONS
							WHERE     NVL (SEGMENT1, '999') =
									   NVL (REC_LINE.UNIT, '999')
								   AND NVL (SEGMENT3, '999') =
									   NVL (REC_LINE.LOCATION, '999')
								   AND NVL (SEGMENT4, '99') =
									   NVL (REC_LINE.DEPARTMENT, '99')
								   AND NVL (SEGMENT5, '999999') =
									   NVL (REC_LINE.NATURAL_ACCOUNT, '999999')
								   AND NVL (SEGMENT9, '999') =
									   NVL (REC_LINE.JOB_ACTIVITY, '999')
								   AND NVL (SEGMENT8, '99') =
									   NVL (REC_LINE.BUSINESS_TYPE, '99')
								   AND NVL (SEGMENT10, '99') =
									   NVL (REC_LINE.FUTURE1, '99')
								   AND NVL (SEGMENT11, '99') =
									   NVL (REC_LINE.FUTURE2, '99')
								   AND NVL (SEGMENT12, '99') =
									   NVL (REC_LINE.FUTURE3, '99')
								   AND NVL (SEGMENT13, '99') =
									   NVL (REC_LINE.FUTURE4, '99')
								   AND ENABLED_FLAG = 'Y'
									;	
						ELSIF REC_HDR.ERP_ORG_ID = 288
							THEN
								SELECT CODE_COMBINATION_ID
								  INTO REC_LINE.ERP_CCID
								FROM GL_CODE_COMBINATIONS
								WHERE     NVL (SEGMENT1, '999') =
										   NVL (REC_LINE.UNIT, '999')
									   AND NVL (SEGMENT3, '999') =
										   NVL (REC_LINE.LOCATION, '999')
									   AND NVL (SEGMENT8, '99') =
										   NVL (REC_LINE.BUSINESS_TYPE, '99')
									   AND NVL (SEGMENT4, '99') =
										   NVL (REC_LINE.DEPARTMENT, '99')
									   AND NVL (SEGMENT5, '999999') =
										   NVL (REC_LINE.NATURAL_ACCOUNT, '999999')
									   AND NVL (SEGMENT9, '999') =
										   NVL (REC_LINE.JOB_ACTIVITY, '999')
									   AND NVL (SEGMENT10, '99') =
										   NVL (REC_LINE.FUTURE1, '99')
									   AND NVL (SEGMENT11, '99') =
										   NVL (REC_LINE.FUTURE2, '99')
									   AND NVL (SEGMENT12, '99') =
										   NVL (REC_LINE.FUTURE3, '99')
									   AND NVL (SEGMENT13, '99') =
										   NVL (REC_LINE.FUTURE4, '99')
									   AND ENABLED_FLAG = 'Y'
										;
						END IF;
						
						
						/*						
						SELECT CODE_COMBINATION_ID
						  INTO REC_LINE.ERP_CCID
						FROM GL_CODE_COMBINATIONS_KFV
						WHERE     CONCATENATED_SEGMENTS = TO_CHAR(REC_LINE.UNIT||'.'||REC_LINE.LOCATION||'.'||REC_LINE.DEPARTMENT||'.'||REC_LINE.NATURAL_ACCOUNT
															||'.'||REC_LINE.JOB_ACTIVITY||'.'||REC_LINE.BUSINESS_TYPE||'.'||REC_LINE.FUTURE1||'.'||REC_LINE.FUTURE2
															||'.'||REC_LINE.FUTURE3||'.'||REC_LINE.FUTURE4)
								AND ENABLED_FLAG = 'Y'
								;
						*/								
					EXCEPTION
					WHEN OTHERS THEN
						REC_LINE.ERP_CCID:= NULL;
						REC_LINE.PROCESS_FLAG:= 'E';
						REC_LINE.ERROR_MSG:= REG_ERR_MSG (REC_LINE.ERROR_MSG, 'Code Combination Error.');
						FND_FILE.PUT_LINE(FND_FILE.LOG,'CODE_COMBINATION_ID :'||SQLCODE||' - '||SQLERRM);
					END;
					
					-- INVENTORY ORG ID AND LOCATION ID
					BEGIN
						SELECT INVENTORY_ORGANIZATION_ID, LOCATION_ID
						INTO REC_LINE.INV_ORGANIZATION_ID, REC_LINE.LOCATION_ID
						FROM TI_AU_LOCATIONS_V L
						WHERE L.SET_OF_BOOKS_ID = UPPER(REC_HDR.LEDGER_ID)
						AND L.ORGANIZATION_CODE = TO_CHAR (REC_LINE.UNIT)
						;
						FND_FILE.PUT_LINE(FND_FILE.LOG,'REC_HDR.INV_ORGANIZATION_ID : '||REC_LINE.INV_ORGANIZATION_ID||' - REC_LINE.LOCATION_ID : '||REC_LINE.LOCATION_ID);
					EXCEPTION
					WHEN OTHERS THEN
						REC_LINE.INV_ORGANIZATION_ID:=NULL; 
						REC_LINE.LOCATION_ID := NULL;
						REC_LINE.PROCESS_FLAG:= 'E';
						REC_LINE.ERROR_MSG:= REG_ERR_MSG (REC_LINE.ERROR_MSG,  'Inventory Org Error.');
						FND_FILE.PUT_LINE(FND_FILE.LOG,'INVENTORY :'||SQLCODE||' - '||SQLERRM);
					END;			
					
					/*-- TAX CATEGORY ID
					BEGIN
						SELECT TAX_CATEGORY_ID
						INTO REC_LINE.TAX_CATEGORY_ID
							FROM TI_GST_TAX_V 
							WHERE    1=1
							AND  UPPER (TAX_CATEGORY_NAME) = UPPER (REC_LINE.TAX_CATEGORY)
							 AND ORG_ID = REC_HDR.ERP_ORG_ID
							 ;
							FND_FILE.PUT_LINE(FND_FILE.LOG,'REC_HDR.ERP_TAX_CATEGORY_ID : '||REC_LINE.TAX_CATEGORY_ID);
					EXCEPTION
					WHEN OTHERS THEN
						--REC_HDR.PROCESS_FLAG := 'E';
						REC_LINE.ERP_TAX_CATEGORY_ID:=NULL;
						--REC_HDR.ERROR_MSG := REG_ERR_MSG (REC_HDR.ERROR_MSG, 'Tax Category Error.');
						FND_FILE.PUT_LINE(FND_FILE.LOG,SQLCODE||' - '||SQLERRM);
					END;
					
					-- TAX CATEGORY ID, TAX RATE NAME , TAX TYPE
					BEGIN
						SELECT TAX_CATEGORY_ID
								, TAX_RATE_ID
								, TAX_TYPE_ID
						INTO REC_LINE.TAX_CATEGORY_ID
						, REC_LINE.ERP_TAX_RATE_ID
						, REC_LINE.ERP_TAX_TYPE_ID
						FROM TI_GST_TAX_V
						WHERE   UPPER (TAX_CATEGORY_NAME) = UPPER (REC_LINE.TAX_CATEGORY)
								AND ORG_ID = REC_HDR.ERP_ORG_ID
								AND EXISTS (SELECT 1 FROM JAI_TAX_TYPES WHERE TAX_TYPE_NAME = REC_LINE.INVOICE_TAX_TYPE)
								AND EXISTS (SELECT 1 FROM JAI_TAX_RATES WHERE TAX_RATE_NAME = REC_LINE.TAX_RATE_NAME)
							 ;
							FND_FILE.PUT_LINE(FND_FILE.LOG,'REC_HDR.ERP_TAX_CATEGORY_ID : '||REC_HDR.ERP_TAX_CATEGORY_ID);
					EXCEPTION
					WHEN OTHERS THEN
						--REC_HDR.PROCESS_FLAG := 'E';
						REC_LINE.TAX_CATEGORY_ID:=NULL;
						REC_LINE.ERP_TAX_RATE_ID:=NULL;
						REC_LINE.ERP_TAX_TYPE_ID:=NULL;
						--REC_HDR.ERROR_MSG := REG_ERR_MSG (REC_HDR.ERROR_MSG, 'Tax Category Error.');
						FND_FILE.PUT_LINE(FND_FILE.LOG,SQLCODE||' - '||SQLERRM);
					END;
					*/	
					-- VALIDATE ATTRIBUTE 15 -- ATTRIBUTE10
					BEGIN
						SELECT FLEX_VALUE
						INTO REC_LINE.ATTRIBUTE10
						FROM FND_FLEX_VALUES_VL
						WHERE FLEX_VALUE_SET_ID = (SELECT FLEX_VALUE_SET_ID FROM FND_FLEX_VALUE_SETS WHERE FLEX_VALUE_SET_NAME = 'Invoice_Tax_Type')
						AND UPPER(FLEX_VALUE_MEANING) = UPPER(REC_LINE.FLEX_FIELD_VALUE);
						FND_FILE.PUT_LINE(FND_FILE.LOG,'REC_HDR.ERP_TAX_CATEGORY_ID : '||REC_LINE.ATTRIBUTE10);
					EXCEPTION
					WHEN OTHERS THEN
						--REC_LINE.PROCESS_FLAG := 'E';
						REC_LINE.ATTRIBUTE10:=NULL;
						--REC_LINE.ERROR_MSG := REG_ERR_MSG (REC_LINE.ERROR_MSG, 'Invoice Tax type Error.');
						FND_FILE.PUT_LINE(FND_FILE.LOG,'ATTRIBUTE10: '||SQLCODE||' - '||SQLERRM);
					END;					
					
					UPDATE XXAU_AP_INV_WITH_GST_TDS_TBL@ebstohr
					SET ERP_VENDOR_ID = REC_HDR.ERP_VENDOR_ID
						, LEDGER_ID = REC_HDR.LEDGER_ID
						, VENDOR_SITE_ID = REC_HDR.VENDOR_SITE_ID
						, INVOICE_TYPE_LOOKUP_CODE = REC_HDR.INVOICE_TYPE_LOOKUP_CODE
						, ERP_LINE_TYPE_CODE = REC_LINE.ERP_LINE_TYPE_CODE
						, ACCTS_PAY_CC_ID = REC_HDR.ACCTS_PAY_CC_ID
						, ERP_CCID = REC_LINE.ERP_CCID
						, INV_ORGANIZATION_ID = REC_LINE.INV_ORGANIZATION_ID
						, LOCATION_ID = REC_LINE.LOCATION_ID
						--, TAX_CATEGORY_ID= REC_LINE.TAX_CATEGORY_ID
						--, ERP_TAX_RATE_ID= REC_LINE.ERP_TAX_RATE_ID
						--, ERP_TAX_TYPE_ID= REC_LINE.ERP_TAX_TYPE_ID
						, ATTRIBUTE10 = REC_LINE.ATTRIBUTE10
						, ERP_ORG_ID = REC_HDR.ERP_ORG_ID
						, PROCESS_FLAG = REC_LINE.PROCESS_FLAG
						, ERROR_MSG= DECODE(LC_HDR_ERROR_MSG,NULL,'',LC_HDR_ERROR_MSG||'; ')|| REC_LINE.ERROR_MSG
						, UPDATED_BY = GN_USER_ID
						, LAST_UPDATE_DATE = SYSDATE
					WHERE INVOICE_NUMBER = REC_HDR.INVOICE_NUMBER
					AND RECORD_ID = REC_LINE.RECORD_ID
					AND GROUP_LINE_NUM = REC_LINE.GROUP_LINE_NUM
					AND OPERATING_UNIT = REC_HDR.OPERATING_UNIT
					AND BATCH_ID = P_BATCH_ID
					;
					
					--LN_RUNNING_LINE_AMT := LN_RUNNING_LINE_AMT+REC_LINE.LINE_AMOUNT;
					--FND_FILE.PUT_LINE(FND_FILE.LOG,'LN_RUNNING_LINE_AMT :'||LN_RUNNING_LINE_AMT);
				
				COMMIT;
				END LOOP;
				FND_FILE.PUT_LINE(FND_FILE.LOG,'++++++++++ LINE END ++++++++++');
				--FND_FILE.PUT_LINE(FND_FILE.LOG,'LN_RUNNING_LINE_AMT :'||LN_RUNNING_LINE_AMT);
				
				/*
				IF LN_RUNNING_LINE_AMT <> REC_HDR.INVOICE_AMOUNT
				THEN
					REC_HDR.PROCESS_FLAG := 'E';
					REC_HDR.ERROR_MSG 	 := REG_ERR_MSG (REC_HDR.ERROR_MSG, 'Invoice and Sum of line amount must be same.');
				END IF;
				*/
				
				/*
				UPDATE XXAU_AP_INV_H_WITH_GST_TDS_TBL
				SET INVOICE_TYPE_LOOKUP_CODE = REC_HDR.INVOICE_TYPE_LOOKUP_CODE
					, LEDGER_ID = REC_HDR.LEDGER_ID
					, ERP_ORG_ID = REC_HDR.ERP_ORG_ID
					, VENDOR_ID = REC_HDR.VENDOR_ID
					, VENDOR_SITE_ID = REC_HDR.VENDOR_SITE_ID
					, INV_ORGANIZATION_ID = REC_HDR.INV_ORGANIZATION_ID
					, LOCATION_ID = REC_HDR.LOCATION_ID
					, ERP_TAX_CATEGORY_ID = REC_HDR.ERP_TAX_CATEGORY_ID
					, ACCTS_PAY_CC_ID = REC_HDR.ACCTS_PAY_CC_ID
					, PROCESS_FLAG = REC_HDR.PROCESS_FLAG
					, ERROR_MSG = REC_HDR.ERROR_MSG
				WHERE 1=1
					AND PROCESS_FLAG = 'N'
					AND RECORD_ID = REC_HDR.RECORD_ID
					AND BATCH_ID = P_BATCH_ID
				;*/
			EXCEPTION WHEN OTHERS 
			THEN
			FND_FILE.PUT_LINE(FND_FILE.LOG,SQLCODE||' - '||SQLERRM);
			END;
		END LOOP;
		
	EXCEPTION
	WHEN OTHERS THEN 
		FND_FILE.PUT_LINE(FND_FILE.LOG,SQLCODE||'-'||SQLERRM);
	END VALIDATE_DATA;
	
	/*************************************************************************************************
     * Program Name : VALIDATE_DATA
     * Language     : PL/SQL
     * Description  : This a global procedure which is used for validating data before inserting data into Interface tables.
     * Parameters : 1. P_BATCH_ID => Number , It is Mandatory Parameter
     *
     * History      :
     * WHO              Version #   WHEN            WHAT
     * ===============  =========   =============   ====================================================
     * AKALA            1.0         23-APR-2026     Initial Version
     ***************************************************************************************************/
	
	PROCEDURE VALIDATE_DATA_AP (P_BATCH_ID IN NUMBER) 
	AS	
	CURSOR CUR_HDR_DATA IS
	(SELECT  INVOICE_NUMBER              
			, ERP_INVOICE_ID              
			, INVOICE_TYPE                
			, INVOICE_TYPE_LOOKUP_CODE    
			, LEDGER_ID                   
			, PARTY_NAME                  
			, VENDOR_CODE                 
			, ERP_VENDOR_ID               
			, VENDOR_SITE_CODE 
			, OPERATING_UNIT				
			, VENDOR_SITE_ID              
			, ACCTS_PAY_CC_ID             
			, TRUNC(GL_DATE) GL_DATE                     
			, TRUNC(INVOICE_DATE) INVOICE_DATE                
			, INVOICE_CURRENCY_CODE       
			, EXCHANGE_RATE
			, ERP_ORG_ID
			, SUM(LINE_AMOUNT) INVOICE_AMOUNT
	FROM XXAU_AP_INV_WITH_GST_TDS_TBL@ebstohr B
	WHERE 1=1
	AND (BATCH_ID = P_BATCH_ID)
	AND NOT EXISTS (SELECT 1
                            FROM AP_INVOICES_ALL AIA
                           WHERE     AIA.INVOICE_NUM = B.INVOICE_NUMBER
                                 AND TRUNC (GL_DATE) >= '01-FEB-2026'
                                 AND AIA.VENDOR_ID IN
                                         (SELECT VENDOR_ID
                                            FROM PO_VENDORS POV
                                           WHERE POV.SEGMENT1 = B.VENDOR_CODE)) -- AND AIA.SOURCE = 'INVOICE GATEWAY')
    AND NOT EXISTS  (SELECT 1
                            FROM AP_INVOICES_INTERFACE
                           WHERE INVOICE_NUM = B.INVOICE_NUMBER)
    AND NOT EXISTS  (SELECT 1
                            FROM AP_INVOICE_LINES_INTERFACE
                           WHERE INVOICE_ID IN
                                     (SELECT INVOICE_ID
                                        FROM AP_INVOICES_INTERFACE
                                       WHERE INVOICE_NUM = B.INVOICE_NUMBER))
    AND NOT EXISTS  (SELECT 1
                            FROM JAI_INTERFACE_LINES_ALL
                           WHERE     IMPORT_MODULE = 'AP'
                                 AND TRANSACTION_NUM = B.INVOICE_NUMBER)
    AND NOT EXISTS  (SELECT 1
                            FROM JAI_INTERFACE_TAX_LINES_ALL
                           WHERE     IMPORT_MODULE = 'AP'
                                 AND TRANSACTION_NUM = B.INVOICE_NUMBER)
	AND EXISTS  (SELECT 1
                            FROM TI_VENDOR_DETAILS_V C ---VIEW FOR THIRD PARTY REGISTRATION VENDOR SITE---
                           WHERE     C.VENDOR_CODE = B.VENDOR_CODE
								 AND C.UNIT 	 = B.UNIT
                                 AND C.VENDOR_SITE_CODE = B.VENDOR_SITE_CODE
                                 AND EXISTS (SELECT 1
															FROM HR_OPERATING_UNITS
															WHERE 1=1
															AND C.SET_OF_BOOKS_ID = SET_OF_BOOKS_ID
															AND UPPER(NAME) = UPPER(B.OPERATING_UNIT)))
	AND (PROCESS_FLAG = 'N' OR PROCESS_FLAG IS NULL)
	AND TAX_CATEGORY IS NULL
	GROUP BY  INVOICE_NUMBER              
			, INVOICE_TYPE                
			, LEDGER_ID                   
			, PARTY_NAME                  
			, VENDOR_CODE                 
			, VENDOR_SITE_CODE 
			, OPERATING_UNIT				
			, ACCTS_PAY_CC_ID             
			, TRUNC(GL_DATE)                     
			, TRUNC(INVOICE_DATE)                
			, EXCHANGE_RATE  
			, INVOICE_CURRENCY_CODE       
			, ERP_INVOICE_ID              
			, INVOICE_TYPE_LOOKUP_CODE    
			, ERP_VENDOR_ID               
			, VENDOR_SITE_ID
			, ERP_ORG_ID
	HAVING COUNT(1) = (SELECT COUNT(1) 
					FROM XXAU_AP_INV_WITH_GST_TDS_TBL@ebstohr 
					WHERE INVOICE_NUMBER = B.INVOICE_NUMBER 
					AND OPERATING_UNIT = B.OPERATING_UNIT 
					--AND TAX_CATEGORY IS NULL
					AND TRIM(UPPER(PARTY_NAME))= TRIM(UPPER(B.PARTY_NAME)))
					)           
	;
		
	CURSOR CUR_LINE_DATA (P_INVOICE_NUM VARCHAR2, P_OPERATING_UNIT VARCHAR2, P_PARTY_NAME VARCHAR2)IS
	(SELECT  ERP_INVOICE_LINE_ID         
			, GROUP_LINE_NUM              
			, LINE_TYPE                   
			, ERP_LINE_TYPE_CODE          
			, UNIT                        
			, JOB_ACTIVITY                    
			, LINE_AMOUNT                 
			, INV_ORGANIZATION_ID         
			, LOCATION_ID                 
			, HSNCODE                     
			, LINE_DESCRIPTION            
			, NATURAL_ACCOUNT             
			, LOCATION                    
			, DEPARTMENT                  
			, FUTURE1                     
			, FUTURE2                     
			, FUTURE3                     
			, FUTURE4                     
			, ERP_CCID                    
			, BUSINESS_TYPE               
			, TCS                         
			, TAX_CATEGORY                
			, TAX_CATEGORY_ID             
			, TDS_TAX_TYPE_CODE           
			, TDS_TAX_TYPE_ID             
			, TAX_RATE_NAME               
			, ERP_TAX_RATE_ID             
			, TAX_RATE_TAX_AMOUNT         
			, TAX_RECOVERABLE_OR_NOT      
			, CONTEXT_VALUE               
			, FLEX_FIELD_VALUE            
			, ATTRIBUTE10                 
			, ATTRIBUTE15                 
			, INVOICE_TAX_TYPE            
			, ERP_TAX_TYPE_ID             
			, REFERENCE_KEY1_INVOICE_NUM  
			, REFERENCE_KEY2_LINE_NUM     
			, REFERENCE_KEY3              
			, OPERATING_UNIT              
			, ERP_ORG_ID                  
			, PROCESS_FLAG                
			, ERROR_MSG                   
			, CREATED_BY                  
			, CREATION_DATE               
			, UPDATED_BY                  
			, LAST_UPDATE_DATE            
			, BATCH_ID              
			, RECORD_ID              
	FROM XXAU_AP_INV_WITH_GST_TDS_TBL@ebstohr
	WHERE 1=1
	AND TAX_CATEGORY IS NULL
	AND PARTY_NAME = P_PARTY_NAME
	AND INVOICE_NUMBER = P_INVOICE_NUM
	AND OPERATING_UNIT = P_OPERATING_UNIT
	AND (BATCH_ID = P_BATCH_ID)
	AND (PROCESS_FLAG = 'N' OR PROCESS_FLAG IS NULL))
	;
	
		LC_INVOICE_TYPE VARCHAR2(100);
		LN_ACCT_PAY_CCID NUMBER;
		LN_RUNNING_LINE_AMT NUMBER:=0;
		LC_HDR_PRC_FLAG VARCHAR2(10);
		LC_HDR_ERROR_MSG VARCHAR2(4000);
		
	BEGIN
		FND_FILE.PUT_LINE(FND_FILE.LOG,'++++++++++ PROCESS STARTED VALIDATE_DATA_AP ++++++++++');
				
		FND_FILE.PUT_LINE(FND_FILE.LOG,'++++++++++ HDR FOR LOOP STARTED ++++++++++');
		FOR REC_HDR IN CUR_HDR_DATA
		LOOP
			BEGIN
				REC_HDR.INVOICE_TYPE_LOOKUP_CODE:=NULL;
				REC_HDR.LEDGER_ID:=  NULL; 
				REC_HDR.ERP_ORG_ID:= NULL;
				REC_HDR.ERP_VENDOR_ID:= NULL;
				REC_HDR.VENDOR_SITE_ID:= NULL;
				REC_HDR.ACCTS_PAY_CC_ID := NULL;
				LC_HDR_PRC_FLAG := 'V';
				LC_HDR_ERROR_MSG := NULL;
				
				-- GL DATE AND INVOICE DATE
				IF REC_HDR.GL_DATE IS NULL OR REC_HDR.INVOICE_DATE IS NULL
				THEN 
					LC_HDR_PRC_FLAG := 'E';
					LC_HDR_ERROR_MSG :=  'GL Date or Invoice date cannot be null.';
				END IF;
				
				-- VALIDATE LOOKUP TYPE 
				BEGIN
					SELECT LOOKUP_CODE
						INTO REC_HDR.INVOICE_TYPE_LOOKUP_CODE
					FROM FND_LOOKUP_VALUES
						WHERE 1=1
						AND UPPER(MEANING) = UPPER(REC_HDR.INVOICE_TYPE)
						AND SYSDATE BETWEEN NVL(START_DATE_ACTIVE,TRUNC(SYSDATE)) AND NVL(END_DATE_ACTIVE, TRUNC(SYSDATE))+1
						AND LOOKUP_CODE <> 'STP INV OBJ PAYMENT'
						AND LOOKUP_TYPE = 'INVOICE TYPE'
						AND ENABLED_FLAG = 'Y'
					;
					FND_FILE.PUT_LINE(FND_FILE.LOG,'REC_HDR.INVOICE_TYPE_LOOKUP_CODE : '||REC_HDR.INVOICE_TYPE_LOOKUP_CODE);
				EXCEPTION
				WHEN OTHERS THEN
					REC_HDR.INVOICE_TYPE_LOOKUP_CODE := NULL;
					LC_HDR_PRC_FLAG := 'E';
					LC_HDR_ERROR_MSG := REG_ERR_MSG (LC_HDR_ERROR_MSG, 'Invoice Type Error.');
					FND_FILE.PUT_LINE(FND_FILE.LOG,'INVOICE_TYPE_LOOKUP_CODE :'||SQLCODE||' - '||SQLERRM);
				END;
				
				
				-- VALIDATING LEDGER ID AND ORG ID FROM ORGANIZATION NAME, OR SHORT CODE
				BEGIN
					SELECT SET_OF_BOOKS_ID, ORGANIZATION_ID
					INTO REC_HDR.LEDGER_ID, REC_HDR.ERP_ORG_ID
					FROM HR_OPERATING_UNITS
					WHERE 1=1
					AND UPPER(NAME) = UPPER(REC_HDR.OPERATING_UNIT)
					;
					FND_FILE.PUT_LINE(FND_FILE.LOG,'REC_HDR.LEDGER_ID : '||REC_HDR.LEDGER_ID||' - REC_HDR.ERP_ORG_ID : '||REC_HDR.ERP_ORG_ID);
				EXCEPTION
				WHEN OTHERS THEN
					REC_HDR.LEDGER_ID:=NULL; 
					REC_HDR.ERP_ORG_ID:=NULL;
					LC_HDR_PRC_FLAG := 'E';
					LC_HDR_ERROR_MSG := REG_ERR_MSG (LC_HDR_ERROR_MSG,' - Operating Unit Error.');
					FND_FILE.PUT_LINE(FND_FILE.LOG,'Operating :'||SQLCODE||' - '||SQLERRM);
				END;	

				-- VALIDATING VENDOR NAME 
				BEGIN
					SELECT VENDOR_ID
					INTO REC_HDR.ERP_VENDOR_ID
					FROM AP_SUPPLIERS
					WHERE 1=1
					AND UPPER(TRIM(VENDOR_NAME)) = TRIM(UPPER(REC_HDR.PARTY_NAME))
					AND SEGMENT1 = REC_HDR.VENDOR_CODE
					;
					FND_FILE.PUT_LINE(FND_FILE.LOG,'REC_HDR.ERP_VENDOR_ID : '||REC_HDR.ERP_VENDOR_ID);
				EXCEPTION
				WHEN OTHERS THEN
					REC_HDR.ERP_VENDOR_ID:=NULL;
					LC_HDR_PRC_FLAG := 'E';
					LC_HDR_ERROR_MSG := REG_ERR_MSG (LC_HDR_ERROR_MSG,'Vendor Error.');
					FND_FILE.PUT_LINE(FND_FILE.LOG,'PARTY_NAME : '||SQLCODE||' - '||SQLERRM);
				END;
				
				-- VALIDATING VENDOR SITE 
				BEGIN
					SELECT VENDOR_SITE_ID
					INTO REC_HDR.VENDOR_SITE_ID
					FROM AP_SUPPLIER_SITES_ALL
					WHERE 1=1
					AND UPPER(VENDOR_SITE_CODE) = UPPER(REC_HDR.VENDOR_SITE_CODE)
					AND VENDOR_ID = REC_HDR.ERP_VENDOR_ID
					;
					
					FND_FILE.PUT_LINE(FND_FILE.LOG,'REC_HDR.VENDOR_SITE_ID : '||REC_HDR.VENDOR_SITE_ID);
					
					-- Getting Libality Account ID 
					BEGIN
						SELECT ACCTS_PAY_CODE_COMBINATION_ID
						INTO REC_HDR.ACCTS_PAY_CC_ID
						FROM AP_SUPPLIER_SITES_ALL
						WHERE 1=1
						AND VENDOR_SITE_ID = REC_HDR.VENDOR_SITE_ID
						AND VENDOR_ID = REC_HDR.ERP_VENDOR_ID
						;
						
						FND_FILE.PUT_LINE(FND_FILE.LOG,'LIBALITY ACCOUNT : '||REC_HDR.ACCTS_PAY_CC_ID);
					EXCEPTION
					WHEN OTHERS THEN
						LC_HDR_PRC_FLAG := 'E';
						LC_HDR_ERROR_MSG := REG_ERR_MSG (LC_HDR_ERROR_MSG,'Libality Account not available.');
						FND_FILE.PUT_LINE(FND_FILE.LOG,'ACCTS_PAY_CODE_COMBINATION_ID: '||SQLCODE||' - '||SQLERRM);
					END;
					
				EXCEPTION
				WHEN OTHERS THEN
					LC_HDR_PRC_FLAG := 'E';
					LC_HDR_ERROR_MSG := REG_ERR_MSG (LC_HDR_ERROR_MSG, 'Vendor Site Error.');
					FND_FILE.PUT_LINE(FND_FILE.LOG,SQLCODE||' - '||SQLERRM);
				END;
							
				FND_FILE.PUT_LINE(FND_FILE.LOG,'++++++++++ LINE DATA ++++++++++');
				
				FOR REC_LINE IN CUR_LINE_DATA (REC_HDR.INVOICE_NUMBER  ,REC_HDR.OPERATING_UNIT, REC_HDR.PARTY_NAME)
				LOOP
				
					REC_LINE.PROCESS_FLAG := 'V';
					REC_LINE.ERROR_MSG := NULL;
					-- LINE TYPE VALIDATION
					BEGIN
						SELECT LOOKUP_CODE
						INTO REC_LINE.ERP_LINE_TYPE_CODE
							FROM FND_LOOKUP_VALUES
							WHERE 1=1
							AND UPPER(MEANING) = UPPER(REC_LINE.LINE_TYPE)
							AND LOOKUP_TYPE LIKE 'INVOICE LINE TYPE'
						;
					EXCEPTION WHEN OTHERS THEN
						REC_LINE.ERP_LINE_TYPE_CODE:=NULL;
						REC_LINE.PROCESS_FLAG := 'E';
						REC_LINE.ERROR_MSG := REG_ERR_MSG (REC_LINE.ERROR_MSG, 'Line Type Error.');
						FND_FILE.PUT_LINE(FND_FILE.LOG,'LINE TYPE VALIDATION :'||SQLCODE||' - '||SQLERRM);
					END;
					
					-- CODE OMBINATION VALIDATION
					BEGIN
							IF REC_HDR.ERP_ORG_ID = 386 
							THEN
								SELECT CODE_COMBINATION_ID
								  INTO REC_LINE.ERP_CCID
								FROM GL_CODE_COMBINATIONS
								WHERE     NVL (SEGMENT1, '999') =
										   NVL (REC_LINE.UNIT, '999')
									   AND NVL (SEGMENT3, '999') =
										   NVL (REC_LINE.LOCATION, '999')
									   AND NVL (SEGMENT4, '99') =
										   NVL (REC_LINE.DEPARTMENT, '99')
									   AND NVL (SEGMENT5, '999999') =
										   NVL (REC_LINE.NATURAL_ACCOUNT, '999999')
									   AND NVL (SEGMENT9, '999') =
										   NVL (REC_LINE.JOB_ACTIVITY, '999')
									   AND NVL (SEGMENT8, '99') =
										   NVL (REC_LINE.BUSINESS_TYPE, '99')
									   AND NVL (SEGMENT10, '99') =
										   NVL (REC_LINE.FUTURE1, '99')
									   AND NVL (SEGMENT11, '99') =
										   NVL (REC_LINE.FUTURE2, '99')
									   AND NVL (SEGMENT12, '99') =
										   NVL (REC_LINE.FUTURE3, '99')
									   AND NVL (SEGMENT13, '99') =
										   NVL (REC_LINE.FUTURE4, '99')
									   AND ENABLED_FLAG = 'Y'
										;	
							ELSIF REC_HDR.ERP_ORG_ID = 288
								THEN
									SELECT CODE_COMBINATION_ID
									  INTO REC_LINE.ERP_CCID
									FROM GL_CODE_COMBINATIONS
									WHERE     NVL (SEGMENT1, '999') =
											   NVL (REC_LINE.UNIT, '999')
										   AND NVL (SEGMENT3, '999') =
											   NVL (REC_LINE.LOCATION, '999')
										   AND NVL (SEGMENT8, '99') =
											   NVL (REC_LINE.BUSINESS_TYPE, '99')
										   AND NVL (SEGMENT4, '99') =
											   NVL (REC_LINE.DEPARTMENT, '99')
										   AND NVL (SEGMENT5, '999999') =
											   NVL (REC_LINE.NATURAL_ACCOUNT, '999999')
										   AND NVL (SEGMENT9, '999') =
											   NVL (REC_LINE.JOB_ACTIVITY, '999')
										   AND NVL (SEGMENT10, '99') =
											   NVL (REC_LINE.FUTURE1, '99')
										   AND NVL (SEGMENT11, '99') =
											   NVL (REC_LINE.FUTURE2, '99')
										   AND NVL (SEGMENT12, '99') =
											   NVL (REC_LINE.FUTURE3, '99')
										   AND NVL (SEGMENT13, '99') =
											   NVL (REC_LINE.FUTURE4, '99')
										   AND ENABLED_FLAG = 'Y'
											;
							END IF;
						
						/*						
						SELECT CODE_COMBINATION_ID
						  INTO REC_LINE.ERP_CCID
						FROM GL_CODE_COMBINATIONS_KFV
						WHERE     CONCATENATED_SEGMENTS = TO_CHAR(REC_LINE.UNIT||'.'||REC_LINE.LOCATION||'.'||REC_LINE.DEPARTMENT||'.'||REC_LINE.NATURAL_ACCOUNT
															||'.'||REC_LINE.JOB_ACTIVITY||'.'||REC_LINE.BUSINESS_TYPE||'.'||REC_LINE.FUTURE1||'.'||REC_LINE.FUTURE2
															||'.'||REC_LINE.FUTURE3||'.'||REC_LINE.FUTURE4)
								AND ENABLED_FLAG = 'Y'
								;
						*/								
					EXCEPTION
					WHEN OTHERS THEN
						REC_LINE.ERP_CCID:= NULL;
						REC_LINE.PROCESS_FLAG:= 'E';
						REC_LINE.ERROR_MSG:= REG_ERR_MSG (REC_LINE.ERROR_MSG, 'Code Combination Error.');
						FND_FILE.PUT_LINE(FND_FILE.LOG,'CODE_COMBINATION_ID :'||SQLCODE||' - '||SQLERRM);
					END;
					
					-- INVENTORY ORG ID AND LOCATION ID
					BEGIN
						SELECT INVENTORY_ORGANIZATION_ID, LOCATION_ID
						INTO REC_LINE.INV_ORGANIZATION_ID, REC_LINE.LOCATION_ID
						FROM TI_AU_LOCATIONS_V L
						WHERE L.SET_OF_BOOKS_ID = UPPER(REC_HDR.LEDGER_ID)
						AND L.ORGANIZATION_CODE = TO_CHAR (REC_LINE.UNIT)
						;
						FND_FILE.PUT_LINE(FND_FILE.LOG,'REC_HDR.INV_ORGANIZATION_ID : '||REC_LINE.INV_ORGANIZATION_ID||' - REC_LINE.LOCATION_ID : '||REC_LINE.LOCATION_ID);
					EXCEPTION
					WHEN OTHERS THEN
						REC_LINE.INV_ORGANIZATION_ID:=NULL; 
						REC_LINE.LOCATION_ID := NULL;
						REC_LINE.PROCESS_FLAG:= 'E';
						REC_LINE.ERROR_MSG:= REG_ERR_MSG (REC_LINE.ERROR_MSG,  'Inventory Org Error.');
						FND_FILE.PUT_LINE(FND_FILE.LOG,'INVENTORY :'||SQLCODE||' - '||SQLERRM);
					END;			
					
					/*-- TAX CATEGORY ID
					BEGIN
						SELECT TAX_CATEGORY_ID
						INTO REC_LINE.TAX_CATEGORY_ID
							FROM TI_GST_TAX_V 
							WHERE    1=1
							AND  UPPER (TAX_CATEGORY_NAME) = UPPER (REC_LINE.TAX_CATEGORY)
							 AND ORG_ID = REC_HDR.ERP_ORG_ID
							 ;
							FND_FILE.PUT_LINE(FND_FILE.LOG,'REC_HDR.ERP_TAX_CATEGORY_ID : '||REC_LINE.TAX_CATEGORY_ID);
					EXCEPTION
					WHEN OTHERS THEN
						--REC_HDR.PROCESS_FLAG := 'E';
						REC_LINE.ERP_TAX_CATEGORY_ID:=NULL;
						--REC_HDR.ERROR_MSG := REG_ERR_MSG (REC_HDR.ERROR_MSG, 'Tax Category Error.');
						FND_FILE.PUT_LINE(FND_FILE.LOG,SQLCODE||' - '||SQLERRM);
					END;
					
					-- TAX CATEGORY ID, TAX RATE NAME , TAX TYPE
					BEGIN
						SELECT TAX_CATEGORY_ID
								, TAX_RATE_ID
								, TAX_TYPE_ID
						INTO REC_LINE.TAX_CATEGORY_ID
						, REC_LINE.ERP_TAX_RATE_ID
						, REC_LINE.ERP_TAX_TYPE_ID
						FROM TI_GST_TAX_V
						WHERE   UPPER (TAX_CATEGORY_NAME) = UPPER (REC_LINE.TAX_CATEGORY)
								AND ORG_ID = REC_HDR.ERP_ORG_ID
								AND EXISTS (SELECT 1 FROM JAI_TAX_TYPES WHERE TAX_TYPE_NAME = REC_LINE.INVOICE_TAX_TYPE)
								AND EXISTS (SELECT 1 FROM JAI_TAX_RATES WHERE TAX_RATE_NAME = REC_LINE.TAX_RATE_NAME)
							 ;
							FND_FILE.PUT_LINE(FND_FILE.LOG,'REC_HDR.ERP_TAX_CATEGORY_ID : '||REC_HDR.ERP_TAX_CATEGORY_ID);
					EXCEPTION
					WHEN OTHERS THEN
						--REC_HDR.PROCESS_FLAG := 'E';
						REC_LINE.TAX_CATEGORY_ID:=NULL;
						REC_LINE.ERP_TAX_RATE_ID:=NULL;
						REC_LINE.ERP_TAX_TYPE_ID:=NULL;
						--REC_HDR.ERROR_MSG := REG_ERR_MSG (REC_HDR.ERROR_MSG, 'Tax Category Error.');
						FND_FILE.PUT_LINE(FND_FILE.LOG,SQLCODE||' - '||SQLERRM);
					END;
					*/	
					-- VALIDATE ATTRIBUTE 15 -- ATTRIBUTE10
					BEGIN
						SELECT FLEX_VALUE
						INTO REC_LINE.ATTRIBUTE10
						FROM FND_FLEX_VALUES_VL
						WHERE FLEX_VALUE_SET_ID = (SELECT FLEX_VALUE_SET_ID FROM FND_FLEX_VALUE_SETS WHERE FLEX_VALUE_SET_NAME = 'Invoice_Tax_Type')
						AND UPPER(FLEX_VALUE_MEANING) = UPPER(REC_LINE.FLEX_FIELD_VALUE);
						FND_FILE.PUT_LINE(FND_FILE.LOG,'REC_HDR.ERP_TAX_CATEGORY_ID : '||REC_LINE.ATTRIBUTE10);
					EXCEPTION
					WHEN OTHERS THEN
						--REC_LINE.PROCESS_FLAG := 'E';
						REC_LINE.ATTRIBUTE10:=NULL;
						--REC_LINE.ERROR_MSG := REG_ERR_MSG (REC_LINE.ERROR_MSG, 'Invoice Tax type Error.');
						FND_FILE.PUT_LINE(FND_FILE.LOG,'ATTRIBUTE10: '||SQLCODE||' - '||SQLERRM);
					END;					
					
					UPDATE XXAU_AP_INV_WITH_GST_TDS_TBL@ebstohr
					SET ERP_VENDOR_ID = REC_HDR.ERP_VENDOR_ID
						, LEDGER_ID = REC_HDR.LEDGER_ID
						, VENDOR_SITE_ID = REC_HDR.VENDOR_SITE_ID
						, INVOICE_TYPE_LOOKUP_CODE = REC_HDR.INVOICE_TYPE_LOOKUP_CODE
						, ERP_LINE_TYPE_CODE = REC_LINE.ERP_LINE_TYPE_CODE
						, ACCTS_PAY_CC_ID = REC_HDR.ACCTS_PAY_CC_ID
						, ERP_CCID = REC_LINE.ERP_CCID
						, INV_ORGANIZATION_ID = REC_LINE.INV_ORGANIZATION_ID
						, LOCATION_ID = REC_LINE.LOCATION_ID
						--, TAX_CATEGORY_ID= REC_LINE.TAX_CATEGORY_ID
						--, ERP_TAX_RATE_ID= REC_LINE.ERP_TAX_RATE_ID
						--, ERP_TAX_TYPE_ID= REC_LINE.ERP_TAX_TYPE_ID
						, ATTRIBUTE10 = REC_LINE.ATTRIBUTE10
						, ERP_ORG_ID = REC_HDR.ERP_ORG_ID
						, PROCESS_FLAG = REC_LINE.PROCESS_FLAG
						, ERROR_MSG= DECODE(LC_HDR_ERROR_MSG,NULL,'',LC_HDR_ERROR_MSG||'; ')|| REC_LINE.ERROR_MSG
						, UPDATED_BY = GN_USER_ID
						, LAST_UPDATE_DATE = SYSDATE
					WHERE INVOICE_NUMBER = REC_HDR.INVOICE_NUMBER
					AND RECORD_ID = REC_LINE.RECORD_ID
					AND GROUP_LINE_NUM = REC_LINE.GROUP_LINE_NUM
					AND OPERATING_UNIT = REC_HDR.OPERATING_UNIT
					AND BATCH_ID = P_BATCH_ID
					;
					
					--LN_RUNNING_LINE_AMT := LN_RUNNING_LINE_AMT+REC_LINE.LINE_AMOUNT;
					--FND_FILE.PUT_LINE(FND_FILE.LOG,'LN_RUNNING_LINE_AMT :'||LN_RUNNING_LINE_AMT);
				
				COMMIT;
				END LOOP;
				FND_FILE.PUT_LINE(FND_FILE.LOG,'++++++++++ LINE END ++++++++++');
				FND_FILE.PUT_LINE(FND_FILE.LOG,'LN_RUNNING_LINE_AMT :'||LN_RUNNING_LINE_AMT);
				
			EXCEPTION WHEN OTHERS 
			THEN
			FND_FILE.PUT_LINE(FND_FILE.LOG,SQLCODE||' - '||SQLERRM);
			END;
		END LOOP;
		
	EXCEPTION
	WHEN OTHERS THEN 
		FND_FILE.PUT_LINE(FND_FILE.LOG,SQLCODE||'-'||SQLERRM);
	END VALIDATE_DATA_AP;

    /*************************************************************************************************
     * Program Name : CREATE_ONLY_AP_INVOICES
     * Language     : PL/SQL
     * Description  : This a global procedure which is used as the main procedure of complete process for AP Invoice and Lines Creation.
     * Parameters 	: 1. P_BATCH_ID => Number , It is Mandatory Parameter
					  2. ERRBUFF => Varchar2, default parameter which is mandatory for concurrent program calling
					  3. RETCODE => Varchar2, default parameter which is mandatory for concurrent program calling
     *
     * History      :
     * WHO              Version #   WHEN            WHAT
     * ===============  =========   =============   ====================================================
     * AKALA            1.0         28-APR-2026     Initial Version
     ***************************************************************************************************/
		
	PROCEDURE CREATE_ONLY_AP_INVOICES (ERRBUFF OUT VARCHAR2,RETCODE OUT VARCHAR2, P_BATCH_ID IN NUMBER)
	AS
		BEGIN
		
			IF P_BATCH_ID IS NOT NULL
			THEN
				VALIDATE_DATA_AP (P_BATCH_ID); 		-- Validate all data for specific Batch ID
				CREATE_AP_INVOICES (P_BATCH_ID);	-- Load into Interface tables	
				MIGRATE_TO_ERP (P_BATCH_ID);		-- Run the Standard program : Payables Open Interface Import
				SHOW_DATA (P_BATCH_ID);				-- Update the status on Custom table and shows all invoices created in ERP
				VALIDATE_INV_IN_ERP(P_BATCH_ID); 				-- Validation program submission for distribution creation
			ELSE
				DBMS_OUTPUT.PUT_LINE('Please enter the Batch No.');
				FND_FILE.PUT_LINE(FND_FILE.LOG, 'Please enter the Batch No.');
			END IF;
			
	EXCEPTION
	WHEN OTHERS THEN 
		FND_FILE.PUT_LINE(FND_FILE.LOG,SQLCODE||'-'||SQLERRM);
	END CREATE_ONLY_AP_INVOICES;
	
    /*************************************************************************************************
     * Program Name : MAIN
     * Language     : PL/SQL
     * Description  : This a global procedure which is used as the main procedure of complete process for AP Invoice and Lines with tax Creation.
     * Parameters 	: 1. P_BATCH_ID => Number , It is Mandatory Parameter
					  2. ERRBUFF => Varchar2, default parameter which is mandatory for concurrent program calling
					  3. RETCODE => Varchar2, default parameter which is mandatory for concurrent program calling
     *
     * History      :
     * WHO              Version #   WHEN            WHAT
     * ===============  =========   =============   ====================================================
     * AKALA            1.0         23-APR-2026     Initial Version
     ***************************************************************************************************/

	PROCEDURE MAIN (ERRBUFF OUT VARCHAR2,RETCODE OUT VARCHAR2, P_BATCH_ID IN NUMBER)  
	AS
	BEGIN
	
		IF P_BATCH_ID IS NOT NULL THEN
		VALIDATE_DATA (P_BATCH_ID); -- Validate all Records
		FND_FILE.PUT_LINE(FND_FILE.LOG,'Validation Complete');
		
		LOAD_DATA_TO_INTERFACE (P_BATCH_ID);	-- Load into Interface tables	
		FND_FILE.PUT_LINE(FND_FILE.LOG,'Load to interface Complete');
		
		MIGRATE_TO_ERP (P_BATCH_ID);	-- Run the Standard program : Payables Open Interface Import
		FND_FILE.PUT_LINE(FND_FILE.LOG,'Migrate to ERP Complete');
		
		SHOW_DATA (P_BATCH_ID);		-- Update the status on Custom table and shows all invoices created in ERP
		FND_FILE.PUT_LINE(FND_FILE.LOG,'Data updated for process flag Complete');
		
		VALIDATE_INV_IN_ERP(P_BATCH_ID); 		-- Validation program submission for distribution creation
		FND_FILE.PUT_LINE(FND_FILE.LOG,'Validating ERP Invoice Complete');
		ELSE
			FND_FILE.PUT_LINE(FND_FILE.LOG,'Please enter the batch no..');
		END IF;
		
	EXCEPTION
	WHEN OTHERS THEN 
		FND_FILE.PUT_LINE(FND_FILE.LOG,SQLCODE||'-'||SQLERRM);
	END MAIN;
	
END XXAU_AP_INV_WITH_GST_TDS_PKG2;
/