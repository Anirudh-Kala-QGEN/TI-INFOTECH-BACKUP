CREATE OR REPLACE PACKAGE BODY XXAU_AP_INV_WITH_GST_TDS_PKG
IS
	
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
	
	PROCEDURE MIGRATE_TO_ERP (P_BATCH_ID NUMBER)
	AS
		GN_CP_REQUEST_ID FND_CONCURRENT_REQUESTS.REQUEST_ID%TYPE;
	BEGIN
		GN_CP_REQUEST_ID:=0;
		FND_GLOBAL.APPS_INITIALIZE (2482, 200, 20639);
        MO_GLOBAL.INIT ('AR');
        FND_CLIENT_INFO.SET_ORG_CONTEXT (288);
		MO_GLOBAL.SET_POLICY_CONTEXT('S', 288);
		
		GN_CP_REQUEST_ID := FND_REQUEST.SUBMIT_REQUEST (
                      APPLICATION   => 'AP'
                    , PROGRAM       => 'APXIIMPT'
					, DESCRIPTION   => NULL 
                    , START_TIME    => SYSDATE
                    , SUB_REQUEST	=> FALSE
					, ARGUMENT1 	=> NULL
					, ARGUMENT2 	=> 'INVOICE GATEWAY'
					, ARGUMENT3 	=> NULL
					, ARGUMENT4 	=> '123'
					, ARGUMENT5 	=> NULL
					, ARGUMENT6 	=> NULL
					, ARGUMENT7 	=> NULL
					, ARGUMENT8 	=> 'N'
					, ARGUMENT9 	=> 'N'
					, ARGUMENT10 	=> 'N'
					, ARGUMENT11 	=> 'N'
					, ARGUMENT12 	=> '1000'
					, ARGUMENT13 	=> '2482'
					, ARGUMENT14 	=> '125879567'
					, ARGUMENT15 	=> 'N'
                    );

            COMMIT;
		DBMS_OUTPUT.PUT_LINE('GN_CP_REQUEST_ID :'||GN_CP_REQUEST_ID);
		IF GN_CP_REQUEST_ID <> 0
		THEN 
			DBMS_OUTPUT.PUT_LINE('GN_CP_REQUEST_ID :'||GN_CP_REQUEST_ID);
		ELSE
			DBMS_OUTPUT.PUT_LINE('Unable to submit program.');
		END IF;
		
	EXCEPTION WHEN OTHERS THEN
		DBMS_OUTPUT.PUT_LINE(SQLCODE||' - '||SQLERRM);
	END;

	PROCEDURE LOAD_DATA_TO_INTERFACE (P_BATCH_ID NUMBER)
	AS
	CURSOR CUR_HDR_DATA IS
		(SELECT *		
			FROM XXAU_AP_INV_H_WITH_GST_TDS_TBL
			WHERE 1=1
			AND BATCH_ID = P_BATCH_ID
			AND PROCESS_FLAG = 'S')
		;
		
		CURSOR CUR_LINE_DATA (P_INVOICE_NUM VARCHAR2,P_RECORD_ID NUMBER)IS
		(SELECT *          
			FROM XXAU_AP_INV_L_WITH_GST_TDS_TBL
			WHERE 1=1
			AND INVOICE_NUM = P_INVOICE_NUM
			AND H_RECORD_ID = P_RECORD_ID
			AND BATCH_ID = P_BATCH_ID
			AND PROCESS_FLAG = 'S')
		;
	LN_LINE_NUMBER NUMBER;
	LN_INVOICE_ID NUMBER;
	LN_AP_LINE_ID NUMBER;
	
	BEGIN
		DBMS_OUTPUT.PUT_LINE(' LOADING DATA TO INTERFACE TABLES... ');
		FOR REC_HDR IN CUR_HDR_DATA
		LOOP
			BEGIN
			
				SELECT AP_INVOICES_INTERFACE_S.NEXTVAL
				  INTO LN_INVOICE_ID
				FROM DUAL;
				/*DBMS_OUTPUT.PUT_LINE(1
                             ||'-'||REC_HDR.INVOICE_NUM
                             ||'-'||REC_HDR.INVOICE_AMOUNT
                             ||'-'||NVL (REC_HDR.INVOICE_CURRENCY_CODE, 'INR')
                             ||'-'||REC_HDR.GL_DATE
                             ||'-'||'INVOICE GATEWAY'
                             ||'-'||REC_HDR.ERP_ORG_ID
                             ||'-'||REC_HDR.INVOICE_TYPE_LOOKUP_CODE
                             ||'-'||REC_HDR.INVOICE_DATE
                             ||'-'||REC_HDR.VENDOR_ID
                             ||'-'||REC_HDR.VENDOR_SITE_ID
                             ||'-'||'GST+TDS IMPORT'
                             ||'-'||SYSDATE
                             ||'-'||GN_USER_ID
                             ||'-'||GN_USER_ID
                             ||'-'||SYSDATE
                             ||'-'||GN_USER_ID
                             ||'-'||'Y'
                             ||'-'||REC_HDR.INVOICE_NUM
                             ||'-'||1
                             ||'-'||'OFI TAX IMPORT'
                             ||'-'||REC_HDR.ACCTS_PAY_CC_ID
                             ||'-'||'CHECK'
                             ||'-'||'AP_INDUS_API');*/
				
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
                             REC_HDR.INVOICE_NUM,
                             REC_HDR.INVOICE_AMOUNT,
                             NVL (REC_HDR.INVOICE_CURRENCY_CODE, 'INR'),
                             REC_HDR.GL_DATE,
                             'INVOICE GATEWAY',
                             REC_HDR.ERP_ORG_ID,
                             REC_HDR.INVOICE_TYPE_LOOKUP_CODE, --'STANDARD',
                             REC_HDR.INVOICE_DATE,                   --SYSDATE
                             REC_HDR.VENDOR_ID,
                             REC_HDR.VENDOR_SITE_ID,
                             'GST+TDS IMPORT',
                             SYSDATE,
                             GN_USER_ID,
                             GN_USER_ID,
                             SYSDATE,
                             GN_USER_ID,
                             'Y',
                             REC_HDR.INVOICE_NUM,
                             1,
                             'OFI TAX IMPORT',
                             REC_HDR.ACCTS_PAY_CC_ID,
                             'CHECK',
                             'AP_INDUS_API')
							 ;
				
				LN_LINE_NUMBER := 1; 
				FOR REC_LINE IN CUR_LINE_DATA  (REC_HDR.INVOICE_NUM  ,REC_HDR.RECORD_ID)
				LOOP
					BEGIN     
						
						SELECT AP_INVOICE_LINES_INTERFACE_S.NEXTVAL
						INTO LN_AP_LINE_ID
						FROM DUAL;
						
						/*DBMS_OUTPUT.PUT_LINE(
							 1
                             ||' - '||LN_AP_LINE_ID
                             ||' - '||LN_LINE_NUMBER
                             ||' - '||REC_LINE.GROUP_LINE_NUM
                             ||' - '||REC_LINE.ERP_LINE_TYPE_CODE --'ITEM'
                             ||' - '||REC_LINE.LINE_AMOUNT
                             ||' - '||REC_LINE.LINE_DESCRIPTION
                             ||' - '||REC_LINE.GL_DATE
                             ||' - '||REC_LINE.ERP_ORG_ID
                             ||' - '||SYSDATE
                             ||' - '||GN_USER_ID
                             ||' - '||GN_USER_ID
                             ||' - '||SYSDATE
                             ||' - '||GN_USER_ID
                             ||' - '||REC_LINE.ERP_CCID
                             ||' - '||REC_HDR.INVOICE_NUM
                             ||' - '||LN_LINE_NUMBER
                             ||' - '||'OFI TAX IMPORT'
                             ||' - '||REC_LINE.CONTEXT_VALUE
                             ||' - '||REC_LINE.INVOICE_TAX_TYPE
                             ||' - '||'AP_INDUS_API')
							 ;
						*/
						
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
								TAX_RATE_ID,
                                ATTRIBUTE15)
						 VALUES (LN_INVOICE_ID,
								 LN_AP_LINE_ID,
								 LN_LINE_NUMBER,
								 REC_LINE.GROUP_LINE_NUM,
								 REC_LINE.ERP_LINE_TYPE_CODE , --'ITEM',
								 REC_LINE.LINE_AMOUNT,
								 REC_LINE.LINE_DESCRIPTION,
								 REC_LINE.GL_DATE,
								 REC_LINE.ERP_ORG_ID,
								 SYSDATE,
								 GN_USER_ID,
								 GN_USER_ID,
								 SYSDATE,
								 GN_USER_ID,
								 REC_LINE.ERP_CCID,
								 REC_HDR.INVOICE_NUM,
								 LN_LINE_NUMBER,
								 'OFI TAX IMPORT',
								 REC_LINE.CONTEXT_VALUE,
								 REC_LINE.INVOICE_TAX_TYPE,
								 REC_LINE.ERP_TAX_RATE_ID,
								 'AP_INDUS_API');
						
					LN_LINE_NUMBER := LN_LINE_NUMBER + 1;
					DBMS_OUTPUT.PUT_LINE('LN_INVOICE_ID : '||LN_INVOICE_ID||'; LN_AP_LINE_ID: '||LN_AP_LINE_ID);
					EXCEPTION
					WHEN OTHERS THEN
					 DBMS_OUTPUT.PUT_LINE(SQLCODE||' - '||SQLERRM);
					END;
				END LOOP;
			
			EXCEPTION
			WHEN OTHERS THEN
			DBMS_OUTPUT.PUT_LINE(SQLCODE||' - '||SQLERRM);
			END;
			COMMIT;
		END LOOP;
	EXCEPTION
	WHEN OTHERS THEN
		DBMS_OUTPUT.PUT_LINE(SQLCODE||' - '||SQLERRM);
	END;

	PROCEDURE VALIDATE_DATA (P_BATCH_ID IN NUMBER) 
	AS
		
	CURSOR CUR_HDR_DATA IS
		(SELECT *	
				/*RECORD_ID                 
			,	INVOICE_NUM               
			,	INVOICE_ID                
			,	INVOICE_TYPE              
			,	INVOICE_TYPE_LOOKUP_CODE  
			,	LEDGER_ID                 
			,	VENDOR_NAME               
			,	VENDOR_CODE               
			,	VENDOR_ID                 
			,	VENDOR_SITE_CODE          
			,	VENDOR_SITE_ID            
			,	GL_DATE                   
			,	INVOICE_DATE              
			,	INVOICE_CURRENCY_CODE     
			,	EXCHANGE_RATE             
			,	UNIT_CODE                 
			,	DEFAULT_1                 
			,	INVOICE_AMOUNT            
			,	INV_ORGANIZATION_ID       
			,	LOCATION_ID               
			,	HSN_CODE                  
			,	TAX_CATEGORY              
			,	ERP_TAX_CATEGORY_ID       
			,	ORGANIZATION_NAME         
			,	SHORT_CODE                
			,	ERP_ORG_ID                
			,	PROCESS_FLAG              
			,	ERROR_MSG                 
			,	CREATED_BY                
			,	CREATION_DATE             
			,	UPDATED_BY                
			,	LAST_UPDATE_DATE          
			,	BATCH_ID   */		
		FROM XXAU_AP_INV_H_WITH_GST_TDS_TBL
		WHERE 1=1
		AND BATCH_ID = P_BATCH_ID
		AND PROCESS_FLAG = 'N')
		;
		
		CURSOR CUR_LINE_DATA (P_INVOICE_NUM VARCHAR2,P_RECORD_ID NUMBER)IS
		(SELECT *
		/*BATCH_ID                    
				,	LAST_UPDATE_DATE            
                ,	UPDATED_BY                  
                ,	CREATION_DATE               
                ,	CREATED_BY                  
                ,	ERROR_MSG                   
                ,	PROCESS_FLAG                
                ,	ERP_ORG_ID                  
                ,	SHORT_CODE                  
                ,	ORGANIZATION_NAME           
                ,	REFERENCE_KEY3              
                ,	REFERENCE_KEY2_LINE_NUM     
                ,	REFERENCE_KEY1_INVOICE_NUM  
                ,	ATTRIBUTE15                 
                ,	ERP_TAX_TYPE_ID             
                ,	INVOICE_TAX_TYPE            
                ,	CONTEXT_VALUE               
                ,	TAX_RECOVERABLE_OR_NOT      
                ,	ERP_TAX_RATE_ID             
                ,	TAX_RATE_NAME               
                ,	TAX_RATE_TAX_AMOUNT         
                ,	HSN_CODE                    
                ,	TAX_CATEGORY_ID             
                ,	TAX_CATEGORY  
				,	LINE_TYPE
				,	ERP_LINE_TYPE_CODE
                ,	ERP_CCID                    
                ,	FUTURE4                     
                ,	FUTURE3                     
                ,	FUTURE2                     
                ,	FUTURE1                     
                ,	DEFAULT_1                   
                ,	BUSINESS_TYPE               
                ,	NATURAL_ACCOUNT             
                ,	DEPARTMENT                  
                ,	LOCATION                    
                ,	UNIT                        
                ,	GROUP_LINE_NUM              
                ,	ERP_LINE_NUM                
                ,	INVOICE_DATE                
                ,	GL_DATE                     
                ,	LINE_DESCRIPTION            
                ,	LINE_AMOUNT                 
                ,	ERP_INVOICE_LINE_ID         
                ,	ERP_INVOICE_ID              
                ,	INVOICE_NUM                 
                ,	H_RECORD_ID                 
                ,	RECORD_ID     */            
		FROM XXAU_AP_INV_L_WITH_GST_TDS_TBL
		WHERE 1=1
		AND INVOICE_NUM = P_INVOICE_NUM
		AND H_RECORD_ID = P_RECORD_ID
		AND BATCH_ID = P_BATCH_ID
		AND PROCESS_FLAG = 'N')
		;
		
		LC_INVOICE_TYPE VARCHAR2(100);
		LN_ACCT_PAY_CCID NUMBER;
		LN_RUNNING_LINE_AMT NUMBER:=0;
		
		
	BEGIN
		DBMS_OUTPUT.PUT_LINE('++++++++++ PROCESS STARTED ++++++++++');
		UPDATE XXAU_AP_INV_H_WITH_GST_TDS_TBL A
		SET PROCESS_FLAG = 'E'
		, ERROR_MSG = 'No lines available for invoice : '||A.INVOICE_NUM
		WHERE (NOT EXISTS (SELECT 1 
						FROM XXAU_AP_INV_L_WITH_GST_TDS_TBL
						WHERE 1=1
						AND INVOICE_NUM = A.INVOICE_NUM
						AND H_RECORD_ID = A.RECORD_ID
						AND BATCH_ID = A.BATCH_ID
						AND PROCESS_FLAG = 'N') 
		OR INVOICE_NUM IS NULL)
		AND BATCH_ID = P_BATCH_ID
		;
		
		COMMIT;
		
		UPDATE XXAU_AP_INV_L_WITH_GST_TDS_TBL A
		SET PROCESS_FLAG = 'E'
		, ERROR_MSG = 'No header available.'
		WHERE (NOT EXISTS (SELECT 1 
							FROM XXAU_AP_INV_H_WITH_GST_TDS_TBL
							WHERE 1=1
							AND INVOICE_NUM = A.INVOICE_NUM
							AND  RECORD_ID= A.H_RECORD_ID
							AND BATCH_ID = A.BATCH_ID
							AND PROCESS_FLAG = 'N')
			OR INVOICE_NUM IS NULL)
			AND BATCH_ID = P_BATCH_ID
			;
		
		COMMIT;
		
		DBMS_OUTPUT.PUT_LINE('++++++++++ HDR FOR LOOP STARTED ++++++++++');
		FOR REC_HDR IN CUR_HDR_DATA
		LOOP
			BEGIN
				REC_HDR.INVOICE_TYPE_LOOKUP_CODE:=NULL;
				REC_HDR.LEDGER_ID:=  NULL; 
				REC_HDR.ERP_ORG_ID:= NULL;
				REC_HDR.VENDOR_ID:= NULL;
				REC_HDR.VENDOR_SITE_ID:= NULL;
				REC_HDR.INV_ORGANIZATION_ID:= NULL;
				REC_HDR.LOCATION_ID:= NULL;
				REC_HDR.ERP_TAX_CATEGORY_ID:= NULL;
				REC_HDR.PROCESS_FLAG := 'S';
				REC_HDR.ERROR_MSG := NULL;
				LN_ACCT_PAY_CCID := NULL;
				LN_RUNNING_LINE_AMT:=0;
				
				-- GL DATE AND INVOICE DATE
				IF REC_HDR.GL_DATE IS NULL OR REC_HDR.INVOICE_DATE IS NULL
				THEN 
					REC_HDR.PROCESS_FLAG := 'E';
					REC_HDR.ERROR_MSG := REG_ERR_MSG (REC_HDR.ERROR_MSG, 'GL Date or Invoice date cannot be null.');
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
					DBMS_OUTPUT.PUT_LINE('REC_HDR.INVOICE_TYPE_LOOKUP_CODE : '||REC_HDR.INVOICE_TYPE_LOOKUP_CODE);
				EXCEPTION
				WHEN OTHERS THEN
					REC_HDR.PROCESS_FLAG := 'E';
					REC_HDR.INVOICE_TYPE_LOOKUP_CODE := NULL;
					REC_HDR.ERROR_MSG := REG_ERR_MSG (REC_HDR.ERROR_MSG, 'Invoice Type Error.');
					DBMS_OUTPUT.PUT_LINE(SQLCODE||' - '||SQLERRM);
				END;
				
				
				-- VALIDATING LEDGER ID AND ORG ID FROM ORGANIZATION NAME, OR SHORT CODE
				BEGIN
					SELECT SET_OF_BOOKS_ID, ORGANIZATION_ID
					INTO REC_HDR.LEDGER_ID, REC_HDR.ERP_ORG_ID
					FROM HR_OPERATING_UNITS
					WHERE 1=1
					AND (NAME = REC_HDR.ORGANIZATION_NAME OR SHORT_CODE = REC_HDR.SHORT_CODE)
					;
					DBMS_OUTPUT.PUT_LINE('REC_HDR.LEDGER_ID : '||REC_HDR.LEDGER_ID||' - REC_HDR.ERP_ORG_ID : '||REC_HDR.ERP_ORG_ID);
				EXCEPTION
				WHEN OTHERS THEN
					REC_HDR.PROCESS_FLAG := 'E';
					REC_HDR.LEDGER_ID:=NULL; 
					REC_HDR.ERP_ORG_ID:=NULL;
					REC_HDR.ERROR_MSG := REG_ERR_MSG (REC_HDR.ERROR_MSG, ' - Operating Unit Error.');
					DBMS_OUTPUT.PUT_LINE(SQLCODE||' - '||SQLERRM);
				END;	

				-- VALIDATING VENDOR NAME 
				BEGIN
					SELECT VENDOR_ID
					INTO REC_HDR.VENDOR_ID
					FROM AP_SUPPLIERS
					WHERE 1=1
					AND UPPER(VENDOR_NAME) = UPPER(REC_HDR.VENDOR_NAME)
					AND SEGMENT1 = REC_HDR.VENDOR_CODE
					;
					DBMS_OUTPUT.PUT_LINE('REC_HDR.VENDOR_ID : '||REC_HDR.VENDOR_ID);
				EXCEPTION
				WHEN OTHERS THEN
					REC_HDR.PROCESS_FLAG := 'E';
					REC_HDR.VENDOR_ID:=NULL;
					REC_HDR.ERROR_MSG := REG_ERR_MSG (REC_HDR.ERROR_MSG, 'Vendor Error.');
					DBMS_OUTPUT.PUT_LINE(SQLCODE||' - '||SQLERRM);
				END;
				
				-- VALIDATING VENDOR SITE 
				BEGIN
					SELECT VENDOR_SITE_ID
					INTO REC_HDR.VENDOR_SITE_ID
					FROM AP_SUPPLIER_SITES_ALL
					WHERE 1=1
					AND UPPER(VENDOR_SITE_CODE) = UPPER(REC_HDR.VENDOR_SITE_CODE)
					AND VENDOR_ID = REC_HDR.VENDOR_ID
					;
					
					DBMS_OUTPUT.PUT_LINE('REC_HDR.VENDOR_SITE_ID : '||REC_HDR.VENDOR_SITE_ID);
					
					-- Getting Libality Account ID 
					BEGIN
						SELECT ACCTS_PAY_CODE_COMBINATION_ID
						INTO REC_HDR.ACCTS_PAY_CC_ID
						FROM AP_SUPPLIER_SITES_ALL
						WHERE 1=1
						AND VENDOR_SITE_ID = REC_HDR.VENDOR_SITE_ID
						AND VENDOR_ID = REC_HDR.VENDOR_ID
						;
						
						DBMS_OUTPUT.PUT_LINE('LIBALITY ACCOUNT : '||REC_HDR.ACCTS_PAY_CC_ID);
					EXCEPTION
					WHEN OTHERS THEN
						REC_HDR.PROCESS_FLAG := 'E';
						REC_HDR.ACCTS_PAY_CC_ID:= NULL;
						REC_HDR.ERROR_MSG := REG_ERR_MSG (REC_HDR.ERROR_MSG, 'Libality Account not available.');
						DBMS_OUTPUT.PUT_LINE(SQLCODE||' - '||SQLERRM);
					END;
					
				EXCEPTION
				WHEN OTHERS THEN
					REC_HDR.PROCESS_FLAG := 'E';
					REC_HDR.VENDOR_SITE_ID:=NULL;
					REC_HDR.ERROR_MSG := REG_ERR_MSG (REC_HDR.ERROR_MSG, 'Vendor Site Error.');
					DBMS_OUTPUT.PUT_LINE(SQLCODE||' - '||SQLERRM);
				END;
				
				-- INVENTORY ORG ID AND LOCATION ID
				BEGIN
					SELECT INVENTORY_ORGANIZATION_ID, LOCATION_ID
					INTO REC_HDR.INV_ORGANIZATION_ID, REC_HDR.LOCATION_ID
					FROM TI_AU_LOCATIONS_V L
					WHERE L.SET_OF_BOOKS_ID = UPPER(REC_HDR.LEDGER_ID)
					AND L.ORGANIZATION_CODE = TO_CHAR (REC_HDR.UNIT_CODE)
					;
					DBMS_OUTPUT.PUT_LINE('REC_HDR.INV_ORGANIZATION_ID : '||REC_HDR.INV_ORGANIZATION_ID||' - REC_HDR.LOCATION_ID : '||REC_HDR.LOCATION_ID);
				EXCEPTION
				WHEN OTHERS THEN
					REC_HDR.PROCESS_FLAG := 'E';
					REC_HDR.INV_ORGANIZATION_ID:=NULL; 
					REC_HDR.LOCATION_ID := NULL;
					REC_HDR.ERROR_MSG := REG_ERR_MSG (REC_HDR.ERROR_MSG, 'Inventory Org Error.');
					DBMS_OUTPUT.PUT_LINE(SQLCODE||' - '||SQLERRM);
				END;			
				
				-- TAX CATEGORY ID
				BEGIN
					SELECT TAX_CATEGORY_ID
					INTO REC_HDR.ERP_TAX_CATEGORY_ID
						FROM TI_GST_TAX_V 
						WHERE    1=1
						AND  UPPER (TAX_CATEGORY_NAME) = UPPER (REC_HDR.TAX_CATEGORY)
						 AND ORG_ID = REC_HDR.ERP_ORG_ID
						 ;
						DBMS_OUTPUT.PUT_LINE('REC_HDR.ERP_TAX_CATEGORY_ID : '||REC_HDR.ERP_TAX_CATEGORY_ID);
				EXCEPTION
				WHEN OTHERS THEN
					--REC_HDR.PROCESS_FLAG := 'E';
					REC_HDR.ERP_TAX_CATEGORY_ID:=NULL;
					--REC_HDR.ERROR_MSG := REG_ERR_MSG (REC_HDR.ERROR_MSG, 'Tax Category Error.');
					DBMS_OUTPUT.PUT_LINE(SQLCODE||' - '||SQLERRM);
				END;
				
				DBMS_OUTPUT.PUT_LINE('++++++++++ LINE DATA ++++++++++');
				
				FOR REC_LINE IN CUR_LINE_DATA (REC_HDR.INVOICE_NUM  ,REC_HDR.RECORD_ID)
				LOOP
				
					REC_LINE.PROCESS_FLAG := 'S';
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
					END;
					
					-- CODE OMBINATION VALIDATION
					BEGIN
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
								   NVL (REC_LINE.DEFAULT_1, '999')
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
					EXCEPTION
					WHEN OTHERS THEN
						REC_LINE.ERP_CCID:= NULL;
						REC_LINE.PROCESS_FLAG:= 'E';
						REC_LINE.ERROR_MSG:= REG_ERR_MSG (REC_LINE.ERROR_MSG, 'Code Combination Error.');
					END;
					
					IF (REC_LINE.ORGANIZATION_NAME = REC_HDR.ORGANIZATION_NAME AND REC_LINE.SHORT_CODE = REC_HDR.SHORT_CODE)
						THEN
							REC_LINE.ERP_ORG_ID:=REC_HDR.ERP_ORG_ID;
					ELSE
						REC_LINE.ERP_ORG_ID:=NULL;
						REC_LINE.PROCESS_FLAG := 'E';
						REC_LINE.ERROR_MSG := 'Operating Unit must be same for line and header.';
					END IF;	
					
					-- GL DATE AND INVOICE DATE
					IF REC_LINE.GL_DATE IS NULL OR REC_LINE.INVOICE_DATE IS NULL
					THEN 
						REC_LINE.PROCESS_FLAG := 'E';
						REC_LINE.ERROR_MSG := REG_ERR_MSG (REC_LINE.ERROR_MSG, 'GL Date or Invoice date cannot be null.');
					END IF;
					
					-- TAX CATEGORY ID, TAX RATE NAME , TAX TYPE
					BEGIN
						SELECT TAX_CATEGORY_ID
								, TAX_RATE_ID
								, TAX_TYPE_ID
								 --TAX_TYPE_CODE,
								 --RECOVERABLE_FLAG,
								 --RATE_PERCENTAGE,
								 --TAX_RATE_NAME,
						INTO REC_LINE.TAX_CATEGORY_ID
						, REC_LINE.ERP_TAX_RATE_ID
						, REC_LINE.ERP_TAX_TYPE_ID
						FROM TI_GST_TAX_V
						WHERE   UPPER (TAX_CATEGORY_NAME) = UPPER (REC_LINE.TAX_CATEGORY)
								AND ORG_ID = REC_HDR.ERP_ORG_ID
								AND EXISTS (SELECT 1 FROM JAI_TAX_TYPES WHERE TAX_TYPE_NAME = REC_LINE.INVOICE_TAX_TYPE)
								AND EXISTS (SELECT 1 FROM JAI_TAX_RATES WHERE TAX_RATE_NAME = REC_LINE.TAX_RATE_NAME)
							 ;
							DBMS_OUTPUT.PUT_LINE('REC_HDR.ERP_TAX_CATEGORY_ID : '||REC_HDR.ERP_TAX_CATEGORY_ID);
					EXCEPTION
					WHEN OTHERS THEN
						--REC_HDR.PROCESS_FLAG := 'E';
						REC_LINE.TAX_CATEGORY_ID:=NULL;
						REC_LINE.ERP_TAX_RATE_ID:=NULL;
						REC_LINE.ERP_TAX_TYPE_ID:=NULL;
						--REC_HDR.ERROR_MSG := REG_ERR_MSG (REC_HDR.ERROR_MSG, 'Tax Category Error.');
						DBMS_OUTPUT.PUT_LINE(SQLCODE||' - '||SQLERRM);
					END;
							
					-- VALIDATE ATTRIBUTE 15 -- ATTRIBUTE10
					BEGIN
						SELECT FLEX_VALUE
						INTO REC_LINE.ATTRIBUTE10
						FROM FND_FLEX_VALUES_VL
						WHERE FLEX_VALUE_SET_ID = (SELECT FLEX_VALUE_SET_ID FROM FND_FLEX_VALUE_SETS WHERE FLEX_VALUE_SET_NAME = 'Invoice_Tax_Type')
						AND UPPER(FLEX_VALUE_MEANING) = UPPER(REC_LINE.FLEX_VALUE_MEANING);
						DBMS_OUTPUT.PUT_LINE('REC_HDR.ERP_TAX_CATEGORY_ID : '||REC_HDR.ERP_TAX_CATEGORY_ID);
					EXCEPTION
					WHEN OTHERS THEN
						REC_LINE.PROCESS_FLAG := 'E';
						REC_LINE.ATTRIBUTE10:=NULL;
						REC_LINE.ERROR_MSG := REG_ERR_MSG (REC_LINE.ERROR_MSG, 'Invoice Tax type Error.');
						DBMS_OUTPUT.PUT_LINE(SQLCODE||' - '||SQLERRM);
					END;					
					
					UPDATE XXAU_AP_INV_L_WITH_GST_TDS_TBL
					SET ERP_LINE_TYPE_CODE = REC_LINE.ERP_LINE_TYPE_CODE
						, ERP_CCID = REC_LINE.ERP_CCID
						, TAX_CATEGORY_ID= REC_LINE.TAX_CATEGORY_ID
						, ERP_TAX_RATE_ID= REC_LINE.ERP_TAX_RATE_ID
						, ERP_TAX_TYPE_ID= REC_LINE.ERP_TAX_TYPE_ID
						, ERP_ORG_ID= REC_LINE.ERP_ORG_ID
						, ATTRIBUTE10 = REC_LINE.ATTRIBUTE10
						, PROCESS_FLAG= REC_LINE.PROCESS_FLAG
						, ERROR_MSG= REC_LINE.ERROR_MSG
						, UPDATED_BY = -1
						, LAST_UPDATE_DATE = SYSDATE
					WHERE RECORD_ID = REC_LINE.RECORD_ID
					AND H_RECORD_ID = REC_HDR.RECORD_ID
					;
					
					LN_RUNNING_LINE_AMT := LN_RUNNING_LINE_AMT+REC_LINE.LINE_AMOUNT;
					DBMS_OUTPUT.PUT_LINE('LN_RUNNING_LINE_AMT :'||LN_RUNNING_LINE_AMT);
					
				END LOOP;
				DBMS_OUTPUT.PUT_LINE('++++++++++ LINE END ++++++++++');
				DBMS_OUTPUT.PUT_LINE('LN_RUNNING_LINE_AMT :'||LN_RUNNING_LINE_AMT);
				
				IF LN_RUNNING_LINE_AMT <> REC_HDR.INVOICE_AMOUNT
				THEN
					REC_HDR.PROCESS_FLAG := 'E';
					REC_HDR.ERROR_MSG 	 := REG_ERR_MSG (REC_HDR.ERROR_MSG, 'Invoice and Sum of line amount must be same.');
				END IF;
				
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
				;
				
				COMMIT;
			EXCEPTION WHEN OTHERS 
			THEN
			DBMS_OUTPUT.PUT_LINE(SQLCODE||' - '||SQLERRM);
			END;
		END LOOP;
		
	EXCEPTION
	WHEN OTHERS THEN 
		DBMS_OUTPUT.PUT_LINE(SQLCODE||'-'||SQLERRM);
	END VALIDATE_DATA;
	
	/*PROCEDURE MAIN (P_BATCH_ID IN NUMBER) 
	AS
	BEGIN
				
		DBMS_OUTPUT.PUT_LINE('WORKING...');
		
	EXCEPTION
	WHEN OTHERS THEN 
		DBMS_OUTPUT.PUT_LINE(SQLCODE||'-'||SQLERRM);
	END;*/
	
END XXAU_AP_INV_WITH_GST_TDS_PKG;