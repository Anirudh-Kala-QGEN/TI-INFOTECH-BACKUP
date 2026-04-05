CREATE OR REPLACE PACKAGE BODY APPS.XXAU_COMP_RCPT_CREATION_PKG
IS
    /***************************************************************************************************
     * Global Variables : Declaration and Initialization
     ***************************************************************************************************/
    /*************************************************************************************************
     *                 Copy Rights Reserved ? Ti Infotech- 2026
     *
     * $Header: @(#)
     * Program Name : XXAU_COMP_RCPT_CREATION_PKG (Body)
     * Language     : PL/SQL
     * Description  : Process to insert the Composite Receipt Data into AR_CASH_RECEIPTS_ALL for Dummy Bank And Actual Bank.
     * History      :
     *
     * WHO              Version #   WHEN            WHAT
     * ===============  =========   =============   ====================================================
     * AKALA            1.0         12-FEB-2026      Initial Version
  ***************************************************************************************************/



    /*************************************************************************************************
     * Program Name : PRAGMA_COMMIT
     * Language     : PL/SQL
     * Description  : This processor store the Error Message and Status with CONS_RCPT_NO as CONC_RCPT_ID and COMPOSITE_RECEIPT_ID as COMPOSITE_RECEIPT_ID
     * History      :
  * Parameters : 1. P_PROCESS_FLAG => E,P,S (Error, Processed, Success)
  *      2. P_PROCESS_MESSAGE => Any Message String
  *      3. P_CONS_RCPT_NO => Composite Receipt No -> CONS_RCPT_NO
  *      4. P_COMPOSITE_RECEIPT_ID => COMPOSITE_RECEIPT_ID
     *
     * WHO              Version #   WHEN            WHAT
     * ===============  =========   =============   ====================================================
     * AKALA            1.0         12-FEB-2026     Initial Version
     ***************************************************************************************************/

    PROCEDURE PRAGMA_COMMIT (P_PROCESS_FLAG           VARCHAR2,
                             P_PROCESS_MESSAGE        VARCHAR2,
                             P_CONS_RCPT_NO           NUMBER,
                             P_COMPOSITE_RECEIPT_ID   NUMBER)
    AS
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        INSERT INTO XXAU_AR_TRNSP_RCPT_ERR (CONC_RCPT_ID,
                                            COMPOSITE_RECEIPT_ID,
                                            STATUS,
                                            ERROR_MESSAGE)
             VALUES (P_CONS_RCPT_NO,
                     P_COMPOSITE_RECEIPT_ID,
                     P_PROCESS_FLAG,
                     P_PROCESS_MESSAGE);

        IF P_COMPOSITE_RECEIPT_ID IS NULL
        THEN
            UPDATE XXAU_AR_TRNSP_RCPT_ERR
               SET STATUS = P_PROCESS_FLAG, ERROR_MESSAGE = ERROR_MESSAGE||'; '||P_PROCESS_MESSAGE
             WHERE     1 = 1
                   AND COMPOSITE_RECEIPT_ID IS NOT NULL
                   AND CONC_RCPT_ID = P_CONS_RCPT_NO;
        END IF;

        COMMIT;
	EXCEPTION
	WHEN OTHERS THEN
	FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in PRAGMA_COMMIT : '||SQLCODE||'-'||SQLERRM);
    END PRAGMA_COMMIT;

    /*************************************************************************************************
     * Program Name : AFTER_PROCESS
     * Language     : PL/SQL
     * Description  : This is for Updating the Stagging table with Error Message and the status. This is the Private procedure.
     * History      :
	 * Parameters :
     *
     * WHO              Version #   WHEN            WHAT
     * ===============  =========   =============   ====================================================
     * AKALA            1.0         12-FEB-2026     Initial Version
	 * AKALA			1.1			17-MAR-2026		Updated code for fixing the Error table bug.
     ***************************************************************************************************/

    PROCEDURE AFTER_PROCESS
    AS
    BEGIN
        /* -- Commented by AKALA due to a bug on 17-MAR-2026
		UPDATE ADDB.ADDB_XXA_AR_TRANS_ERP_RCPT@ebstohr A --XXAU_AR_TRANS_ERP_RCPT_T
           SET PROCESS_FLAG =
                   (SELECT STATUS
                      FROM XXAU_AR_TRNSP_RCPT_ERR
                     WHERE COMPOSITE_RECEIPT_ID = A.COMPOSITE_RECEIPT_ID),
               PROCESS_MESSAGE =
                      (CASE WHEN UPPER(PROCESS_MESSAGE) LIKE '%SUCCESS%' THEN NULL ELSE PROCESS_MESSAGE END) 
                   || '-'
                   || (SELECT ERROR_MESSAGE
                         FROM XXAU_AR_TRNSP_RCPT_ERR
                        WHERE COMPOSITE_RECEIPT_ID = A.COMPOSITE_RECEIPT_ID)
         WHERE     1 = 1
               AND COMPOSITE_RECEIPT_ID IS NOT NULL
               AND CONS_RCPT_NO IS NOT NULL
			   AND EXISTS (SELECT 1 FROM XXAU_AR_TRNSP_RCPT_ERR WHERE COMPOSITE_RECEIPT_ID = A.COMPOSITE_RECEIPT_ID );
		*/
			
		-- Added by AKALA on 17-MAR-2026 to fix the bug.
		UPDATE ADDB.ADDB_XXA_AR_TRANS_ERP_RCPT@ebstohr  A --XXAU_AR_TRANS_ERP_RCPT_T
           SET PROCESS_FLAG =
                   (SELECT STATUS
                         FROM XXAU_AR_TRNSP_RCPT_ERR
                        WHERE ROWNUM < 2 AND (COMPOSITE_RECEIPT_ID = A.COMPOSITE_RECEIPT_ID OR COMPOSITE_RECEIPT_ID IS NULL) AND CONC_RCPT_ID = A.CONS_RCPT_NO),
               PROCESS_MESSAGE =
                      (CASE WHEN UPPER(PROCESS_MESSAGE) LIKE '%SUCCESS%' THEN NULL ELSE PROCESS_MESSAGE END) 
                   || '-'
                   || (SELECT ERROR_MESSAGE
                         FROM XXAU_AR_TRNSP_RCPT_ERR
                        WHERE ROWNUM < 2 AND (COMPOSITE_RECEIPT_ID = A.COMPOSITE_RECEIPT_ID OR COMPOSITE_RECEIPT_ID IS NULL) AND CONC_RCPT_ID = A.CONS_RCPT_NO)
         WHERE     1 = 1
               AND COMPOSITE_RECEIPT_ID IS NOT NULL
               AND CONS_RCPT_NO IS NOT NULL
			   AND EXISTS (SELECT 1 FROM XXAU_AR_TRNSP_RCPT_ERR WHERE COMPOSITE_RECEIPT_ID = A.COMPOSITE_RECEIPT_ID OR CONC_RCPT_ID = A.CONS_RCPT_NO)
			   ;


        COMMIT;
		FND_FILE.PUT_LINE(FND_FILE.LOG,RPAD('-',20,'-')||CHR(10)||'Process Complete');
	EXCEPTION
	WHEN OTHERS THEN
	FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in AFTER_PROCESS : '||SQLCODE||'-'||SQLERRM);
    END AFTER_PROCESS;

    /*************************************************************************************************
     * Program Name : ENTER_RECORDS
     * Language     : PL/SQL
     * Description  : This is for entering the Stagging table processed data after validation to the API - AR_RECEIPT_API_PUB
       and storing the data into the base table on completion of process.
     * History      :
  * Parameters :
     *
     * WHO              Version #   WHEN            WHAT
     * ===============  =========   =============   ====================================================
     * AKALA            1.0         12-FEB-2026     Initial Version
	 * AKALA			1.1			16-FEB-2026		Code changed according to requirement. Added ROLLBACK 
	 *												to remove all records if any of them get into error
	 * AKALA			1.2			13-MAR-2026		Added a new API AR_RECEIPT_API_PUB.CREATE_MISC for 
	 *												Dummy Bank with Cash Clearing Activity accroding to ATTRIBUTE11
	 * 												and added lookup for correct value.
     ***************************************************************************************************/

    PROCEDURE ENTER_RECORDS
    AS
        CURSOR CUR_CONS_RCPT_NO IS -- MAIN BANK TRANSACTION; WHICH WILL HAVE THE SUM(PARTY_AMOUNT) OF SAME CONS_RCPT_NO
              SELECT CONS_RCPT_NO,
                     RECEIPT_METHOD_ID,
                     ATTRIBUTE_CATEGORY,
                     ATTRIBUTE1,
                     ATTRIBUTE2,
                     ATTRIBUTE3,
                     ATTRIBUTE4,
                     ATTRIBUTE5,
                     ATTRIBUTE6,
                     ATTRIBUTE7,
                     ATTRIBUTE8,
                     BANK_ACC_ID, 
                     PROCESS_FLAG
                FROM ADDB.ADDB_XXA_AR_TRANS_ERP_RCPT@ebstohr XATERT --XXAU_AR_TRANS_ERP_RCPT_T
               WHERE     1 = 1
                     AND (SELECT COUNT (1)
                            FROM ADDB.ADDB_XXA_AR_TRANS_ERP_RCPT@ebstohr  --XXAU_AR_TRANS_ERP_RCPT_T
                           WHERE CONS_RCPT_NO = XATERT.CONS_RCPT_NO) =
                         (SELECT COUNT (1)
                            FROM ADDB.ADDB_XXA_AR_TRANS_ERP_RCPT@ebstohr -- XXAU_AR_TRANS_ERP_RCPT_T
                           WHERE     PROCESS_FLAG = 'P'
                                 AND CONS_RCPT_NO = XATERT.CONS_RCPT_NO)
                     AND CONS_RCPT_NO IS NOT NULL
                     AND PROCESS_FLAG = 'P'
            GROUP BY CONS_RCPT_NO,
                     RECEIPT_METHOD_ID,
                     ATTRIBUTE_CATEGORY,
                     ATTRIBUTE1,
                     ATTRIBUTE2,
                     ATTRIBUTE3,
                     ATTRIBUTE4,
                     ATTRIBUTE5,
                     ATTRIBUTE6,
                     ATTRIBUTE7,
                     ATTRIBUTE8,
                     BANK_ACC_ID,
                     PROCESS_FLAG;

        CURSOR RCPT_CUR (P_CONS_RCPT_NO VARCHAR2)
        IS                        -- REACIPT RECORDS FOR THE SAME CONS_RCPT_NO
            SELECT COMPOSITE_RECEIPT_ID,
                   PARTY_NUMBER,
                   PARTY_NAME,
                   PARTY_LOCATION,
                   RECEIPT_NUMBER,
                   PARTY_AMT,
                   RECEIPT_DATE,
                   PROCESS_DATE12,
                   BANK_ACC_ID,
                   BANK_ACC_NUMBER,
                   BANK_ACC_NAME,
                   RECEIPT_METHOD_ID,
                   CONS_RCPT_NO,
                   ERP_CUSTOMER_NUMBER,
                   ATTRIBUTE_CATEGORY,
                   ATTRIBUTE1,
                   ATTRIBUTE2,
                   ATTRIBUTE3,
                   ATTRIBUTE4,
                   ATTRIBUTE5,
                   ATTRIBUTE6,
                   ATTRIBUTE7,
                   ATTRIBUTE8,
                   ATTRIBUTE9,
                   ATTRIBUTE10,
                   ATTRIBUTE11,
                   ATTRIBUTE12,
                   ATTRIBUTE13,
                   ATTRIBUTE14,
                   ATTRIBUTE15,
                   PROCESS_FLAG,
                   PROCESS_MESSAGE,
				   PROV_RECPTDT
              FROM ADDB.ADDB_XXA_AR_TRANS_ERP_RCPT@ebstohr  --XXAU_AR_TRANS_ERP_RCPT_T
             WHERE     1 = 1
                   AND PROCESS_FLAG = 'P'
                   AND CONS_RCPT_NO = P_CONS_RCPT_NO;

        L_RETURN_STATUS            VARCHAR2 (1);
        L_MSG_COUNT                NUMBER;
        L_MSG_DATA                 VARCHAR2 (2000);
        L_CR_ID                    NUMBER;

        -- DUMMY ACCOUNT PARAMETERS (REPLACE WITH YOUR ACTUAL IDS)
        L_BANK_ACCT_ID             NUMBER := NULL; -- ID OF YOUR DUMMY BANK ACCOUNT
        L_RECEIPT_METH_ID          NUMBER;        -- ID OF YOUR RECEIPT METHOD
        L_CUST_ID                  NUMBER;                      -- CUSTOMER ID
        L_SITE_USE_ID              NUMBER;             -- CUSTOMER SITE USE ID
        L_ORG_ID                   NUMBER := FND_PROFILE.VALUE ('ORG_ID'); -- OPERATING UNIT ID

        LN_INT_RCPT_NO             NUMBER := 0;
        LN_TOTAL_RCPT_AMT          NUMBER := 0;
        LN_msg_index_out           NUMBER;
        --LN_CURRENT_AMT NUMBER := 0;
        LN_RECEIPT_METHOD_ID_REC   NUMBER;


        LC_DATA                    VARCHAR2 (4000);
        l_cash_receipt_id          NUMBER;
        L_CASH_RECEIPT_NUM         VARCHAR2 (100);

        LN_RECEIVABLES_TRX_ID      NUMBER;

        L_ATTRIBUTE_REC            AR_RECEIPT_API_PUB.ATTRIBUTE_REC_TYPE;
        L_ATTRIBUTE_DATA           AR_RECEIPT_API_PUB.ATTRIBUTE_REC_TYPE;

        LC_ERROR                   VARCHAR2 (4000); -- LC_ERROR ADDB.ADDB_XXA_AR_TRANS_ERP_RCPT.process_message@ebstohr%TYPE;
        LC_DUMMY                   VARCHAR2 (4000); -- LC_ERROR ADDB.ADDB_XXA_AR_TRANS_ERP_RCPT.process_message@ebstohr%TYPE;

        LC_RECE_TRX_NAME           VARCHAR2 (100);
        LC_COMMENTS_H              AR_CASH_RECEIPTS_ALL.COMMENTS%TYPE;

        REMIT_BANK_ACCT_USE_ID     NUMBER;
        P_USER_ID                  NUMBER := FND_PROFILE.VALUE ('USER_ID');
        P_RESP_ID                  NUMBER := FND_PROFILE.VALUE ('RESP_ID');
        P_RESP_APPL_ID             NUMBER
                                       := FND_PROFILE.VALUE ('RESP_APPL_ID');
        P_SEPRATER                 VARCHAR2 (100);
        L_MSG_DATA_R               VARCHAR2 (2000);
        LC_FLAG_H                  VARCHAR2 (100);
		LD_RECEIPT_DATE			   DATE;
		LN_ACTIVITY				   VARCHAR2(2000);
		L2_CASH_RECEIPT_NUM        VARCHAR2(2000);
    BEGIN
        MO_GLOBAL.INIT ('AR');
        FND_GLOBAL.APPS_INITIALIZE (
            USER_ID        => NVL (P_USER_ID, 2482),
            RESP_ID        => NVL (P_RESP_ID, 20678),
            RESP_APPL_ID   => NVL (P_RESP_APPL_ID, 222));

        MO_GLOBAL.SET_POLICY_CONTEXT ('S', NVL (L_ORG_ID, 288)); --Amar Ujala Publications Limited

        FND_FILE.PUT_LINE(FND_FILE.LOG,'--- INSIDE ENTER_RECORDS ---');

        FOR I IN CUR_CONS_RCPT_NO
        LOOP
            L_CASH_RECEIPT_ID := NULL;
            L_ATTRIBUTE_REC.ATTRIBUTE_CATEGORY  := I.ATTRIBUTE_CATEGORY;
            L_ATTRIBUTE_REC.ATTRIBUTE1 := I.ATTRIBUTE1;
            L_ATTRIBUTE_REC.ATTRIBUTE2 := I.ATTRIBUTE2;
            L_ATTRIBUTE_REC.ATTRIBUTE3 := I.ATTRIBUTE3;
            L_ATTRIBUTE_REC.ATTRIBUTE4 := I.ATTRIBUTE4;
            L_ATTRIBUTE_REC.ATTRIBUTE5 := I.ATTRIBUTE5;
            L_ATTRIBUTE_REC.ATTRIBUTE6 := I.ATTRIBUTE6;
			--L_ATTRIBUTE_REC.ATTRIBUTE7 := I.ATTRIBUTE7;
            --L_ATTRIBUTE_REC.ATTRIBUTE8 := I.ATTRIBUTE8;
            --L_ATTRIBUTE_REC.ATTRIBUTE9 := NULL;
            --L_ATTRIBUTE_REC.ATTRIBUTE10 := NULL;
            --L_ATTRIBUTE_REC.ATTRIBUTE11 := NULL;
            --L_ATTRIBUTE_REC.ATTRIBUTE12 := NULL;
            --L_ATTRIBUTE_REC.ATTRIBUTE13 := NULL;
            --L_ATTRIBUTE_REC.ATTRIBUTE14 := NULL;
            --L_ATTRIBUTE_REC.ATTRIBUTE15 := NULL; -- provisional date
            LC_COMMENTS_H := NULL;
			

            FOR J IN RCPT_CUR (I.CONS_RCPT_NO)
            LOOP
                BEGIN
					LD_RECEIPT_DATE:=J.RECEIPT_DATE;
                    LC_ERROR := NULL;
                    J.PROCESS_FLAG := 'S';
                    LN_INT_RCPT_NO := LN_INT_RCPT_NO + 1;
                    --LN_CURRENT_AMT:= J.PARTY_AMT;
                    LC_ERROR := J.PROCESS_MESSAGE;
                    -- ASSIGNING ATTRIBUTE VALUES
                    L_ATTRIBUTE_DATA.ATTRIBUTE_CATEGORY := J.ATTRIBUTE_CATEGORY;
                    L_ATTRIBUTE_DATA.ATTRIBUTE1 := J.ATTRIBUTE1;
                    L_ATTRIBUTE_DATA.ATTRIBUTE2 := J.ATTRIBUTE2;
                    L_ATTRIBUTE_DATA.ATTRIBUTE3 := J.ATTRIBUTE3;
                    L_ATTRIBUTE_DATA.ATTRIBUTE4 := J.ATTRIBUTE4;
                    L_ATTRIBUTE_DATA.ATTRIBUTE5 := J.ATTRIBUTE5;
                    L_ATTRIBUTE_DATA.ATTRIBUTE6 := J.ATTRIBUTE6;
                    --L_ATTRIBUTE_DATA.ATTRIBUTE7 := J.ATTRIBUTE7;
                    --L_ATTRIBUTE_DATA.ATTRIBUTE8 := J.ATTRIBUTE8;
                    --L_ATTRIBUTE_DATA.ATTRIBUTE9 := J.ATTRIBUTE9;
                    L_ATTRIBUTE_DATA.ATTRIBUTE9 := J.ATTRIBUTE11;
                    L_ATTRIBUTE_DATA.ATTRIBUTE10 := J.ATTRIBUTE10;
                    --L_ATTRIBUTE_DATA.ATTRIBUTE11 := J.ATTRIBUTE11;
                    L_ATTRIBUTE_DATA.ATTRIBUTE12 := J.ATTRIBUTE12;
                    --L_ATTRIBUTE_DATA.ATTRIBUTE13 := J.ATTRIBUTE13;
                    L_ATTRIBUTE_DATA.ATTRIBUTE14 := J.ATTRIBUTE14;
                    --L_ATTRIBUTE_DATA.ATTRIBUTE15 := J.ATTRIBUTE15;
                    L_ATTRIBUTE_DATA.ATTRIBUTE15 := J.PROV_RECPTDT; -- provisional  date = PROV_RECPTDT

                    -- FOR CORRECT ACTIVITY -- ADDDED ON 13-MAR-2026 BY AKALA
					BEGIN
						SELECT AR_REC_TRX_A.RECEIVABLES_TRX_ID
						INTO LN_ACTIVITY
						FROM FND_LOOKUP_VALUES FLV
						, AR_RECEIVABLES_TRX_ALL AR_REC_TRX_A
						WHERE 1=1
						AND AR_REC_TRX_A.NAME = FLV.MEANING
						AND LOOKUP_CODE = SUBSTR(J.ATTRIBUTE11,1,3)
						AND LOOKUP_TYPE = 'XXAU_UNIT_CASH_CLEARING';
					EXCEPTION 
						WHEN OTHERS 
						THEN LN_ACTIVITY:=NULL;
						J.PROCESS_FLAG := 'E';
						LC_ERROR  := LC_ERROR||'Cash Clearing is not defined for ORG Code: '||SUBSTR(J.ATTRIBUTE11,1,3);
					END;
					
					-- FOR CORRECT DUMMY RECEIPT METHOD ID -- ADDDED ON 12-FEB-2026 BY AKALA
                    BEGIN
                        SELECT CUSTOMER_ID
                          INTO L_CUST_ID
                          FROM AR_CUSTOMERS
                         WHERE CUSTOMER_NUMBER = J.ERP_CUSTOMER_NUMBER;
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            L_CUST_ID := NULL;
                            J.PROCESS_FLAG := 'E';
                            LC_ERROR :=
                                   LC_ERROR
                                || '; Error in customer:'
                                || J.ERP_CUSTOMER_NUMBER
                                || '; '
                                || SQLCODE
                                || '-'
                                || SQLERRM
                                || '; ';
                            FND_FILE.PUT_LINE(FND_FILE.LOG,
                                   'Customer ID fetching error FOR : CUSTOMER NUMBER'
                                || J.ERP_CUSTOMER_NUMBER
                                || '; '
                                || SQLCODE
                                || '-'
                                || SQLERRM
                                || '; ');
                    END;

                -- FOR DUMMY BANK ACCORDING TO ATTRIBUTE11
                /*LC_DUMMY :=
                       'DUMMY BANK '
                    || REGEXP_REPLACE (J.BANK_ACC_NAME,
                                       '\s*cash',
                                       '',
                                       1,
                                       0,
                                       'i');*/ -- Oommented by AKALA, CASH is not required
				
				-- Added for Dummy bank according to ORG Code from Attribute11 on 9-MAR-2026
				LC_DUMMY := SUBSTR(J.ATTRIBUTE11,1,3)||'%\_DUMMY%'; 		   
							

                -- FOR CORRECT DUMMY RECEIPT METHOD ID -- ADDDED ON 12-FEB-2026 BY AKALA
                BEGIN
                    SELECT RECEIPT_METHOD_ID
                      INTO LN_RECEIPT_METHOD_ID_REC
                      FROM AR_RECEIPT_METHODS
                     WHERE     1 = 1
                           AND UPPER (NAME) LIKE UPPER (LC_DUMMY) ESCAPE '\'
                           AND REGEXP_LIKE (NAME, '[^-]');
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            LN_RECEIPT_METHOD_ID_REC := NULL;
                            J.PROCESS_FLAG := 'E';
                            LC_ERROR :=
                                   LC_ERROR
                                || 'Receipt Method error: '
                                || LC_DUMMY
                                || '; '
                                || SQLCODE
                                || '-'
                                || SQLERRM
                                || '; ';
                            FND_FILE.PUT_LINE(FND_FILE.LOG,
                                   'Receipt Method ID fetching error FOR BANK_ACC_NAME: '
                                || J.BANK_ACC_NAME
                                || '; '
                                || SQLCODE
                                || '-'
                                || SQLERRM
                                || '; ');
                    END;

                    --FND_FILE.PUT_LINE(FND_FILE.LOG,'CONC RCPT NO : '|| I.CONS_RCPT_NO|| ' . '|| LN_INT_RCPT_NO|| ' : Data  - '|| J.PARTY_NUMBER|| ' - '|| J.PARTY_NAME|| ' - '|| J.PARTY_LOCATION|| ' - '|| J.RECEIPT_NUMBER|| ' - '|| J.PARTY_AMT|| ' - '|| J.ATTRIBUTE9|| ' - '|| J.ATTRIBUTE11|| ' - '|| J.ERP_CUSTOMER_NUMBER);

                    IF J.PROCESS_FLAG <> 'E'
                    THEN
                        --FND_MSG_PUB.INITIALIZE;
                        -- Call AR Receipt API for different customers under same bank
                        AR_RECEIPT_API_PUB.CREATE_CASH (
                            p_api_version         => 1.0,
                            p_init_msg_list       => FND_API.G_TRUE,
                            p_commit              => FND_API.G_FALSE, -- Commit the receipt
                            p_validation_level    => FND_API.G_VALID_LEVEL_FULL,
                            -- Mandatory Fields
                            p_receipt_number      =>
                                TO_CHAR (
                                       'C'
                                    || I.CONS_RCPT_NO
                                    || '.'
                                    || LN_INT_RCPT_NO),      -- receipt num ->
                            p_amount              => J.PARTY_AMT,         -- 2
                            p_currency_code       => 'INR',            --'INR'
                            p_receipt_date        => J.RECEIPT_DATE,
                            p_gl_date             => J.RECEIPT_DATE,
                            p_customer_id         => l_cust_id,
                            p_comments            =>
                                TO_CHAR (
                                       'Composite Receipt Number: C'
                                    || I.CONS_RCPT_NO),
                            p_receipt_method_id   => LN_RECEIPT_METHOD_ID_REC,
                            --p_remittance_bank_account_id => l_bank_acct_id, -- Dummy Bank Here -> AR_CASH_RECEIPTS_ALL -> AR_RECEIPT_METHOD_ACCOUNTS_ALL -> CE_BANK_ACCOUNTS
                            -- ATTRIBUTE ENTRY
                            p_attribute_rec       => L_ATTRIBUTE_DATA,
                            -- Output Parameters
                            x_return_status       => l_return_status,
                            x_msg_count           => l_msg_count,
                            x_msg_data            => l_msg_data,
                            p_cr_id               => l_cr_id);
                        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'JUST AFTER LINE''S API L_MSG_DATA : '|| l_msg_data||', Dummy Bank Receipt ID : '||l_cr_id||', CONC RCPT NO : '|| I.CONS_RCPT_NO|| ' . '|| LN_INT_RCPT_NO);

                        IF l_return_status <> FND_API.G_RET_STS_SUCCESS
                        THEN
							FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'ERROR OCCURS AT LINE CREATION: '|| l_msg_data||', Dummy Bank Receipt ID : '||l_cr_id||', CONC RCPT NO : '|| I.CONS_RCPT_NO|| ' . '|| LN_INT_RCPT_NO);
                            J.PROCESS_FLAG := l_return_status;
                            LC_ERROR := LC_ERROR || ' : ' || l_msg_data;
							PRAGMA_COMMIT ('E',J.PROCESS_MESSAGE || l_msg_data,I.CONS_RCPT_NO,J.COMPOSITE_RECEIPT_ID);
							LC_COMMENTS_H:=NULL;
							EXIT;
                        ELSIF l_return_status = FND_API.G_RET_STS_SUCCESS
                        THEN
                            LN_TOTAL_RCPT_AMT := LN_TOTAL_RCPT_AMT + J.PARTY_AMT;
                            LC_RECE_TRX_NAME := SUBSTR (J.ATTRIBUTE11, 1, 3)|| '%MISC%RECEIPTS';

                            BEGIN
                                SELECT DECODE (NVL (LENGTH (LC_COMMENTS_H), 0),0, '',', ')
                                  INTO P_SEPRATER
                                  FROM DUAL;
                            END;

                            LC_COMMENTS_H := LC_COMMENTS_H || P_SEPRATER|| TO_CHAR ('C'|| I.CONS_RCPT_NO|| '.'|| LN_INT_RCPT_NO);

                            -- UPDATING PROCESS FLAG FOR SUCCESS RECORDS -- ADDDED ON 12-FEB-2026 BY AKALA
                            PRAGMA_COMMIT (J.PROCESS_FLAG,J.PROCESS_MESSAGE || LC_ERROR,I.CONS_RCPT_NO,J.COMPOSITE_RECEIPT_ID);
                        --COMMIT;
                        END IF;
                    ELSE
                        ROLLBACK; -- REMOVE ALL ENTRIES FROM AR_CASH_RECEIPTS_ALL

                        -- FOR ERROR AND MESSAGE IN STAGGING TABLE -- ADDDED ON 12-FEB-2026 BY AKALA
                        PRAGMA_COMMIT (J.PROCESS_FLAG,J.PROCESS_MESSAGE || LC_ERROR,I.CONS_RCPT_NO,J.COMPOSITE_RECEIPT_ID);
                        LC_COMMENTS_H := NULL;
                        EXIT;
                    END IF;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in PARAMETERISED CURSOR: '|| SQLCODE|| ' - '|| SQLERRM);
                        LN_INT_RCPT_NO := 0;
                        ROLLBACK;

                        PRAGMA_COMMIT (J.PROCESS_FLAG,J.PROCESS_MESSAGE || LC_ERROR,I.CONS_RCPT_NO,J.COMPOSITE_RECEIPT_ID);

                        LC_RECE_TRX_NAME := NULL;
                        LC_COMMENTS_H := NULL;
                        EXIT;

                        LC_ERROR := NULL;
                END;
            END LOOP;

            --FND_FILE.PUT_LINE(FND_FILE.LOG,   'LC_COMMENTS_H : '|| LC_COMMENTS_H|| ' FOR RECEIPT NUM :'|| 'C'|| I.CONS_RCPT_NO|| ' BECAUSE OF '|| LC_ERROR);

			-- Added by AKALA on 14-MAR-2026, API to create DUMMY BANK MISC Receipt as Activity Cash Clearing with Total Amount in negative
			
			FND_FILE.PUT_LINE(FND_FILE.LOG,'LC_COMMENTS_H :'||LC_COMMENTS_H);
			
			-- Added by AKALA on 13-MAR-2026, Condition : IF all the Lines has entered successfully 
			-- then create a misc receipt with Dummy bank and activity as Cash Clearing according to ORG Code
            IF NVL (LENGTH (TRIM (LC_COMMENTS_H)), 0) <> 0
            THEN
                LC_FLAG_H := 'S';
				
                --FND_FILE.PUT_LINE(FND_FILE.LOG,'LC_FLAG_H : '|| LC_FLAG_H|| ' FOR RECEIPT NUM :'|| 'C'|| I.CONS_RCPT_NO|| ' BECAUSE OF '|| L_MSG_DATA_R);

                IF LC_FLAG_H <> 'E'
                THEN
                    FND_MSG_PUB.INITIALIZE;
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'INSIDE API FOR: ' || 'C' || I.CONS_RCPT_NO);
                                        
					FND_FILE.PUT_LINE(FND_FILE.LOG,'L_CASH_RECEIPT_NUM : '|| L_CASH_RECEIPT_NUM|| ' LN_RECEIVABLES_TRX_ID: '|| LN_RECEIVABLES_TRX_ID|| ' FOR LC_RECE_TRX_NAME :'|| LC_RECE_TRX_NAME);
					
					LN_INT_RCPT_NO:=LN_INT_RCPT_NO + 1;
                    L_CASH_RECEIPT_NUM := 'C' || I.CONS_RCPT_NO||'.'||LN_INT_RCPT_NO;
					
					AR_RECEIPT_API_PUB.CREATE_MISC (
                        p_api_version          => 1.0,
                        p_init_msg_list        => FND_API.G_TRUE,
                        p_commit               => FND_API.G_FALSE,
                        p_validation_level     => FND_API.G_VALID_LEVEL_FULL,
                        x_return_status        => l_return_status,
                        x_msg_count            => l_msg_count,
                        x_msg_data             => l_msg_data,
                        p_currency_code        => 'INR',
                        p_amount               => LN_TOTAL_RCPT_AMT*-1, -- AMOUNT in -ve of total Amount
                        p_receipt_date         => TRUNC (LD_RECEIPT_DATE), -- Receipt date from table
                        p_gl_date              => TRUNC (LD_RECEIPT_DATE), -- GL date = Receipt date from table
                        p_receipt_method_id    => LN_RECEIPT_METHOD_ID_REC, -- Dummy Bank Receipt Method ID
                        p_activity             => NULL, -- NULL because receivable_trx_id has high precedence over it.
                        p_remittance_bank_account_id   => REMIT_BANK_ACCT_USE_ID, 
                        p_receivables_trx_id   => LN_ACTIVITY, -- Cash Clearing Activity ID
                        --p_receivables_trx_id   => LN_RECEIVABLES_TRX_ID,
                        p_comments             => TO_CHAR ('Composite Receipt Number: C'|| I.CONS_RCPT_NO),
                        -- ATTRIBUTE ENTRY
                        p_attribute_record     => L_ATTRIBUTE_REC,
                        p_misc_receipt_id      => L_CASH_RECEIPT_ID,
                        p_org_id               => l_org_id,
                        p_receipt_number       => L_CASH_RECEIPT_NUM);
                    FND_FILE.PUT_LINE(FND_FILE.LOG,
                           'x_msg_count: '
                        || l_msg_count
                        || ' l_return_status :'
                        || l_return_status
                        || ' l_msg_data : '
                        || l_msg_data);
					FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Cash Receipt ID for dummy misc : '||L_CASH_RECEIPT_ID||', Receipt Number: '||L_CASH_RECEIPT_NUM);

                    IF l_return_status <> FND_API.G_RET_STS_SUCCESS
                    THEN
                        FOR i IN 1 .. l_msg_count
                        LOOP
                            FND_MSG_PUB.GET (p_msg_index       => FND_MSG_PUB.G_NEXT,p_encoded         => 'F',p_data            => l_msg_data,p_msg_index_out   => LN_msg_index_out);
                            
							FND_FILE.PUT_LINE(FND_FILE.LOG,'A. Message '|| i|| ' : '|| l_msg_data);

                            LC_DATA :=
                                FND_MSG_PUB.GET (
                                    p_msg_index   => FND_MSG_PUB.G_NEXT,
                                    p_encoded     => 'F');
                            
							FND_FILE.PUT_LINE(FND_FILE.LOG,'B. Message '|| i|| ' : '|| LC_DATA);
                        END LOOP;
						LC_FLAG_H := 'E';

                        ROLLBACK; -- ROLLBACK ALL ENTERIES DUE TO COMPOSITE RECEIPT CREATION FOR ALL LINES
						I.PROCESS_FLAG:='E';
						LC_COMMENTS_H := NULL;

                        -- COMMITING THE ERROR STATUS AND MESSAGE TO THE STAGGING TABLE
                        PRAGMA_COMMIT ('E','Error while creating MISC Composite Receipt: '||l_msg_data||', '|| L_MSG_DATA_R|| ' '|| LC_DATA,I.CONS_RCPT_NO,NULL);
                    --COMMIT;

                    ELSIF l_return_status = FND_API.G_RET_STS_SUCCESS
                    THEN
						I.PROCESS_FLAG := 'S';
						LC_FLAG_H := 'S';
						LC_COMMENTS_H := LC_COMMENTS_H || ', '|| TO_CHAR ('C'|| I.CONS_RCPT_NO|| '.'|| LN_INT_RCPT_NO);
						FND_FILE.PUT_LINE(FND_FILE.LOG,'COMBINED RECEIPT CREATED...');
                    END IF;
                ELSE
                    PRAGMA_COMMIT ('E',
                                   'Error COMP RCPT: ' ||l_msg_data||', '|| L_MSG_DATA_R,
                                   I.CONS_RCPT_NO,
                                   NULL);
					I.PROCESS_FLAG:='E';
					LC_FLAG_H := 'E';
					LC_COMMENTS_H := NULL;
                    ROLLBACK;
                END IF;
            END IF;
			
			-- Added by AKALA on 14-MAR-2026, API to Create the Combined Receipt with Original Bank as MISC with Cash Clearing Activity
			-- If all the above records entered successfully then create the final receipt.
			L_CASH_RECEIPT_NUM:=NULL;
			L_CASH_RECEIPT_ID:=NULL;
			IF LC_FLAG_H <> 'E' AND NVL (LENGTH (TRIM (LC_COMMENTS_H)), 0) <> 0
                THEN
                    FND_MSG_PUB.INITIALIZE;
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'INSIDE API FOR: ' || 'C' || I.CONS_RCPT_NO);
                    
					L_CASH_RECEIPT_NUM := 'C' || I.CONS_RCPT_NO;
                    
					FND_FILE.PUT_LINE(FND_FILE.LOG,'L_CASH_RECEIPT_NUM : '|| L_CASH_RECEIPT_NUM|| ' LN_RECEIVABLES_TRX_ID: '|| LN_RECEIVABLES_TRX_ID|| ' FOR LC_RECE_TRX_NAME :'|| LC_RECE_TRX_NAME);
					
					--LN_INT_RCPT_NO:=LN_INT_RCPT_NO + 1;
                    
					AR_RECEIPT_API_PUB.CREATE_MISC (
                        p_api_version          => 1.0,
                        p_init_msg_list        => FND_API.G_TRUE,
                        p_commit               => FND_API.G_FALSE,
                        p_validation_level     => FND_API.G_VALID_LEVEL_FULL,
                        x_return_status        => l_return_status,
                        x_msg_count            => l_msg_count,
                        x_msg_data             => l_msg_data,
                        p_currency_code        => 'INR',
                        p_amount               => LN_TOTAL_RCPT_AMT, -- AMOUNT ?
                        p_receipt_date         => TRUNC (LD_RECEIPT_DATE), -- WHAT SHOULD BE THE RECEIPT DATE
                        p_gl_date              => TRUNC (LD_RECEIPT_DATE), -- WHAT SHOULD BE THE GL_DATE
                        p_receipt_method_id    => I.RECEIPT_METHOD_ID, -- (SELECT RECEIPT_METHOD_ID FROM ADDB.ADDB_XXA_AR_TRANS_ERP_RCPT WHERE CONS_RCPT_NO = 12;)
                        p_activity             => NULL,
                        p_remittance_bank_account_id   => REMIT_BANK_ACCT_USE_ID,
                        p_receivables_trx_id   => LN_ACTIVITY,
                        --p_receivables_trx_id   => LN_RECEIVABLES_TRX_ID,
                        p_comments             => LC_COMMENTS_H,
                        -- ATTRIBUTE ENTRY
                        p_attribute_record     => L_ATTRIBUTE_REC,
                        p_misc_receipt_id      => L_CASH_RECEIPT_ID,
                        p_org_id               => l_org_id,
                        p_receipt_number       => L_CASH_RECEIPT_NUM);
                    FND_FILE.PUT_LINE(FND_FILE.LOG,
                           'x_msg_count: '
                        || l_msg_count
                        || ' l_return_status :'
                        || l_return_status
                        || ' l_msg_data : '
                        || l_msg_data);
					FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Combined Cash Receipt ID for Original Reeipt Method -> misc : '||L_CASH_RECEIPT_ID||', Receipt Number: '||L_CASH_RECEIPT_NUM);
                    IF l_return_status <> FND_API.G_RET_STS_SUCCESS
                    THEN
                        FOR i IN 1 .. l_msg_count
                        LOOP
                            FND_MSG_PUB.GET (p_msg_index       => FND_MSG_PUB.G_NEXT,p_encoded         => 'F',p_data            => l_msg_data,p_msg_index_out   => LN_msg_index_out);
                            
							FND_FILE.PUT_LINE(FND_FILE.LOG,'A. Message '|| i|| ' : '|| l_msg_data|| ',  LN_MSG_INDEX_OUT : '|| LN_MSG_INDEX_OUT);

                            LC_DATA :=
                                FND_MSG_PUB.GET (
                                    p_msg_index   => FND_MSG_PUB.G_NEXT,
                                    p_encoded     => 'F');
                            
							FND_FILE.PUT_LINE(FND_FILE.LOG,'B. Message '|| i|| ' : '|| LC_DATA|| ',  LN_MSG_INDEX_OUT : '|| LN_MSG_INDEX_OUT);
                        END LOOP;

                        ROLLBACK; -- ROLLBACK ALL ENTERIES DUE TO COMPOSITE RECEIPT CREATION FOR ALL LINES
						I.PROCESS_FLAG:='E';

                        -- COMMITING THE ERROR STATUS AND MESSAGE TO THE STAGGING TABLE
                        PRAGMA_COMMIT ('E','Error while creating MISC Composite Receipt'|| L_MSG_DATA_R|| ' '|| LC_DATA,I.CONS_RCPT_NO,NULL);
                    --COMMIT;

                    ELSIF l_return_status = FND_API.G_RET_STS_SUCCESS
                    THEN
						I.PROCESS_FLAG := 'S';
						FND_FILE.PUT_LINE(FND_FILE.LOG,'COMBINED RECEIPT CREATED...');
                        UPDATE ADDB.ADDB_XXA_AR_TRANS_ERP_RCPT@ebstohr --XXAU_AR_TRANS_ERP_RCPT_T
                           SET PROCESS_FLAG = I.PROCESS_FLAG,
                               PROCESS_MESSAGE =
                                      'SUCCESS; COMPOSITE RECEIPT NO. : '
                                   || L_CASH_RECEIPT_NUM
                         WHERE 1 = 1 AND CONS_RCPT_NO = I.CONS_RCPT_NO;

                        PRAGMA_COMMIT (
                            'S',
                            'SUCCESS; COMPOSITE RECEIPT NO. : ' || L_CASH_RECEIPT_NUM,
                            I.CONS_RCPT_NO,
                            NULL);

                        COMMIT;                          -- COMMIT ALL RECORDS
                    END IF;
                ELSE
                    PRAGMA_COMMIT ('E',
                                   'Error COMP RCPT: ' || l_msg_data||', '||L_MSG_DATA_R,
                                   I.CONS_RCPT_NO,
                                   NULL);
					I.PROCESS_FLAG:='E';
                    ROLLBACK;
                END IF;

            L_CASH_RECEIPT_NUM := NULL;
            FND_FILE.PUT_LINE(FND_FILE.LOG,
                'L_CASH_RECEIPT_ID : ' || l_cash_receipt_id);
            LN_INT_RCPT_NO := 0;
            LN_TOTAL_RCPT_AMT := 0;
        END LOOP;
    EXCEPTION
        WHEN OTHERS
        THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,
                   'Error in ENTER_RECORDS Procedure: '
                || SQLCODE
                || ' '
                || SQLERRM);
    END ENTER_RECORDS;

    /*************************************************************************************************
     * Program Name : VALIDATION_REQUIRED
     * Language     : PL/SQL
     * Description  : This is for validating the Stagging table data so that the required values should not
       create any API Error.
     * History      :
  * Parameters :
     *
     * WHO              Version #   WHEN            WHAT
     * ===============  =========   =============   ====================================================
     * AKALA            1.0         12-FEB-2026     Initial Version
	 * AKALA			1.1			19-FEB-2026		Commented all the value set validations because of 
	 * 												different types of Value set. Need to check the valueset 
	 * 												and re-write the validations.
	 * AKALA 			1.2			12-MAR-2026 	Removed the records having Cash Bank from Attribute7
     ***************************************************************************************************/

    PROCEDURE VALIDATION_REQUIRED
    AS
        CURSOR CUR_REC IS
            SELECT COMPOSITE_RECEIPT_ID,
                   SERIAL_NUMBER,
                   PARTY_NUMBER,
                   PARTY_NAME,
                   PARTY_LOCATION,
                   RECEIPT_NUMBER,
                   PARTY_AMT,
                   ATTRIBUTE_CATEGORY,
                   ATTRIBUTE1,
                   ATTRIBUTE2,
                   ATTRIBUTE3,
                   ATTRIBUTE4,
                   ATTRIBUTE5,
                   ATTRIBUTE6,
                   ATTRIBUTE7,
                   ATTRIBUTE8,
                   ATTRIBUTE9,
                   ATTRIBUTE10,
                   ATTRIBUTE11,
                   ATTRIBUTE12,
                   ATTRIBUTE13,
                   ATTRIBUTE14,
                   ATTRIBUTE15,
                   PROCESS_FLAG,
                   PROCESS_MESSAGE,
                   PROCESS_DATE,
                   CREATED_BY,
                   CREATION_DATE,
                   LAST_UPDATED_BY,
                   LAST_UPDATE_DATE,
                   COMMENTS,
                   PROCESS_DATE12,
                   RECEIPT_DATE,
                   CHNO,
                   BANK_ACC_ID,
                   BANK_ACC_NUMBER,
                   BANK_ACC_NAME,
                   DOCTYPE,
                   REF_RECEIPTNO,
                   REF_RECEIPTDT,
                   REF_DOCTYPE,
                   SECURITY_FLAG,
                   CONS_TYPE,
                   CONS_RCPT_NO,
                   CHEQUE_BOUNCE_REASON,
                   RECEIPT_METHOD_ID,
                   PROV_RECPTDT,
                   ERP_CUSTOMER_NUMBER
              FROM ADDB.ADDB_XXA_AR_TRANS_ERP_RCPT@ebstohr  --XXAU_AR_TRANS_ERP_RCPT_T
             WHERE     1 = 1
                   AND UPPER(ATTRIBUTE7) NOT LIKE '%CASH%' -- Added by AKALA on 12-MAR-2026 to remove the Cash Banks
                   AND PROCESS_FLAG IS NULL
--                   AND CONS_RCPT_NO = 33
                   AND CONS_RCPT_NO IS NOT NULL
                   ;

        LC_RECE_TRX_NAME           VARCHAR2 (100) := NULL;
        LC_ERROR                   VARCHAR2 (4000) := NULL;
        LC_DUMMY                   VARCHAR2 (4000) := NULL;
        LN_RECEIVABLES_TRX_ID      NUMBER;
        REMIT_BANK_ACCT_USE_ID     NUMBER;
        LN_RECEIPT_METHOD_ID_REC   NUMBER;
        L_CUST_ID                  NUMBER;
    BEGIN
        FND_FILE.PUT_LINE(FND_FILE.LOG,'INSIDE VALIDATION_REQUIRED ....... ');
		
		
        FOR J IN CUR_REC
        LOOP
		FND_FILE.PUT_LINE(FND_FILE.LOG,'INSIDE LOOP ....... ');
            J.PROCESS_FLAG := 'P';
            LC_ERROR := NULL;

            BEGIN
                -- FOR CORRECT ERP CUSTOMER ID -- ADDDED ON 12-FEB-2026 BY AKALA
                BEGIN
                    SELECT CUSTOMER_ID
                      INTO L_CUST_ID
                      FROM AR_CUSTOMERS
                     WHERE CUSTOMER_NUMBER = J.ERP_CUSTOMER_NUMBER;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        L_CUST_ID := NULL;
                        J.PROCESS_FLAG := 'E';
                        LC_ERROR :=
                               LC_ERROR
                            || '; Invalid Cust#:'
                            || J.ERP_CUSTOMER_NUMBER;
                        FND_FILE.PUT_LINE(FND_FILE.LOG,
                               'Customer ID fetching error FOR : CUSTOMER NUMBER'
                            || J.ERP_CUSTOMER_NUMBER
                            || '; '
                            || SQLCODE
                            || '-'
                            || SQLERRM
                            || '; ');
                END;


                -- FOR VALIDATING VALUE OF ATTRIBUTE7 WITH VALUESET ATTACHED ON AR_CASH_RECEIPTS_ALL.ATTRIBUTE7 -- ADDDED ON 12-FEB-2026 BY AKALA
                /*
    BEGIN
     SELECT FLEX_VALUE
     INTO J.ATTRIBUTE7
     FROM FND_FLEX_VALUES
     WHERE 1=1
     AND SYSDATE < NVL(END_DATE_ACTIVE,SYSDATE+1)
     AND ENABLED_FLAG = 'Y'
     AND FLEX_VALUE_SET_ID = (SELECT FLEX_VALUE_SET_ID
            FROM FND_FLEX_VALUE_SETS A
            WHERE FLEX_VALUE_SET_NAME =  'XXA_BANK_NAME')
     AND FLEX_VALUE = TRIM(J.ATTRIBUTE7);
    EXCEPTION WHEN OTHERS THEN
     J.ATTRIBUTE7 := NULL;
     J.PROCESS_FLAG := 'E';
     LC_ERROR:=LC_ERROR||'XXA_BANK_NAME VALUESET error: '||J.ATTRIBUTE7||'; '||SQLCODE||'-'||SQLERRM||'; ';
     FND_FILE.PUT_LINE(FND_FILE.LOG,'Receipt Method ID fetching error FOR ATTRIBUTE7: '||J.ATTRIBUTE7||'; '||SQLCODE||'-'||SQLERRM||'; ');
    END;
    */


                -- FOR VALIDATING VALUE OF ATTRIBUTE8 WITH VALUESET ATTACHED ON AR_CASH_RECEIPTS_ALL.ATTRIBUTE8 -- ADDDED ON 12-FEB-2026 BY AKALA
                /*
    BEGIN
     SELECT FLEX_VALUE
     INTO J.ATTRIBUTE8
     FROM FND_FLEX_VALUES
     WHERE 1=1
     AND SYSDATE < NVL(END_DATE_ACTIVE,SYSDATE+1)
     AND ENABLED_FLAG = 'Y'
     AND FLEX_VALUE_SET_ID = (SELECT FLEX_VALUE_SET_ID
            FROM FND_FLEX_VALUE_SETS A
            WHERE FLEX_VALUE_SET_NAME =  'XXA_BANK_ACCOUNT_NUMBER')
     AND FLEX_VALUE = TRIM(J.ATTRIBUTE8);
    EXCEPTION WHEN OTHERS THEN
     J.ATTRIBUTE8 := NULL;
     J.PROCESS_FLAG := 'E';
     LC_ERROR:=LC_ERROR||'XXA_BANK_ACCOUNT_NUMBER VALUESET Error: '||J.ATTRIBUTE8||'; '||SQLCODE||'-'||SQLERRM||'; ';
     FND_FILE.PUT_LINE(FND_FILE.LOG,'XXA_BANK_ACCOUNT_NUMBER VALUESET Error FOR ATTRIBUTE8: '||J.ATTRIBUTE8||'; '||SQLCODE||'-'||SQLERRM||'; ');
    END;
    */

                -- FOR VALIDATING VALUE OF ATTRIBUTE14 WITH VALUESET ATTACHED ON AR_CASH_RECEIPTS_ALL.ATTRIBUTE14 -- ADDDED ON 12-FEB-2026 BY AKALA
                /*
    BEGIN
     SELECT FLEX_VALUE
     INTO J.ATTRIBUTE14
     FROM FND_FLEX_VALUES
     WHERE 1=1
     AND SYSDATE < NVL(END_DATE_ACTIVE,SYSDATE+1)
     AND ENABLED_FLAG = 'Y'
     AND FLEX_VALUE_SET_ID = (SELECT FLEX_VALUE_SET_ID
            FROM FND_FLEX_VALUE_SETS A
            WHERE FLEX_VALUE_SET_NAME =  'XXA_Prov_Receipt')
     AND FLEX_VALUE = TRIM(J.ATTRIBUTE14);
    EXCEPTION WHEN OTHERS THEN
     J.ATTRIBUTE14 := NULL;
     J.PROCESS_FLAG := 'E';
     LC_ERROR:=LC_ERROR||'XXA_Prov_Receipt VALUESET Error: '||J.ATTRIBUTE14||'; '||SQLCODE||'-'||SQLERRM||'; ';
     FND_FILE.PUT_LINE(FND_FILE.LOG,'XXA_Prov_Receipt VALUESET Error FOR ATTRIBUTE14: '||J.ATTRIBUTE14||'; '||SQLCODE||'-'||SQLERRM||'; ');
    END;
    */

                -- FOR VALIDATING VALUE OF ATTRIBUTE2 WITH VALUESET ATTACHED ON AR_CASH_RECEIPTS_ALL.ATTRIBUTE2 -- ADDDED ON 12-FEB-2026 BY AKALA
                /*
    BEGIN
     SELECT FLEX_VALUE
     INTO J.ATTRIBUTE2
     FROM FND_FLEX_VALUES
     WHERE 1=1
     AND SYSDATE < NVL(END_DATE_ACTIVE,SYSDATE+1)
     AND ENABLED_FLAG = 'Y'
     AND FLEX_VALUE_SET_ID = (SELECT FLEX_VALUE_SET_ID
            FROM FND_FLEX_VALUE_SETS A
            WHERE FLEX_VALUE_SET_NAME =  'XXAU_CHECK_LOCAL')
     AND FLEX_VALUE = TRIM(J.ATTRIBUTE2);
    EXCEPTION WHEN OTHERS THEN
     J.ATTRIBUTE2 := NULL;
     J.PROCESS_FLAG := 'E';
     LC_ERROR:=LC_ERROR||'XXAU_CHECK_LOCAL VALUESET error: '||J.ATTRIBUTE2||'; '||SQLCODE||'-'||SQLERRM||'; ';
     FND_FILE.PUT_LINE(FND_FILE.LOG,'XXAU_CHECK_LOCAL VALUESET error FOR ATTRIBUTE2: '||J.ATTRIBUTE2||'; '||SQLCODE||'-'||SQLERRM||'; ');
    END;
    */

                -- FOR VALIDATING VALUE OF ATTRIBUTE3 WITH VALUESET ATTACHED ON AR_CASH_RECEIPTS_ALL.ATTRIBUTE3 -- ADDDED ON 12-FEB-2026 BY AKALA
                /*
    BEGIN
     SELECT FLEX_VALUE
     INTO J.ATTRIBUTE3
     FROM FND_FLEX_VALUES
     WHERE 1=1
     AND SYSDATE < NVL(END_DATE_ACTIVE,SYSDATE+1)
     AND ENABLED_FLAG = 'Y'
     AND FLEX_VALUE_SET_ID = (SELECT FLEX_VALUE_SET_ID
            FROM FND_FLEX_VALUE_SETS A
            WHERE FLEX_VALUE_SET_NAME =  'AR_SRS_YES_NO')
     AND FLEX_VALUE = TRIM(J.ATTRIBUTE3);
    EXCEPTION WHEN OTHERS THEN
     J.ATTRIBUTE3 := NULL;
     J.PROCESS_FLAG := 'E';
     LC_ERROR:=LC_ERROR||'AR_SRS_YES_NO VALUESET error: '||J.ATTRIBUTE3||'; '||SQLCODE||'-'||SQLERRM||'; ';
     FND_FILE.PUT_LINE(FND_FILE.LOG,'AR_SRS_YES_NO VALUESET error FOR ATTRIBUTE3: '||J.ATTRIBUTE3||'; '||SQLCODE||'-'||SQLERRM||'; ');
    END;
    */

                -- FOR VALIDATING VALUE OF ATTRIBUTE4 WITH VALUESET ATTACHED ON AR_CASH_RECEIPTS_ALL.ATTRIBUTE4 -- ADDDED ON 12-FEB-2026 BY AKALA
                /*
    BEGIN
     SELECT FLEX_VALUE
     INTO J.ATTRIBUTE4
     FROM FND_FLEX_VALUES
     WHERE 1=1
     AND SYSDATE < NVL(END_DATE_ACTIVE,SYSDATE+1)
     AND ENABLED_FLAG = 'Y'
     AND FLEX_VALUE_SET_ID = (SELECT FLEX_VALUE_SET_ID
            FROM FND_FLEX_VALUE_SETS A
            WHERE FLEX_VALUE_SET_NAME =  'AR_SRS_YES_NO')
     AND FLEX_VALUE = TRIM(ATTRIBUTE4);
    EXCEPTION WHEN OTHERS THEN
     J.ATTRIBUTE4 := NULL;
     J.PROCESS_FLAG := 'E';
     LC_ERROR:=LC_ERROR||'AR_SRS_YES_NO VALUESET error: '||J.ATTRIBUTE4||'; '||SQLCODE||'-'||SQLERRM||'; ';
     FND_FILE.PUT_LINE(FND_FILE.LOG,'AR_SRS_YES_NO VALUESET error FOR ATTRIBUTE4: '||J.ATTRIBUTE4||'; '||SQLCODE||'-'||SQLERRM||'; ');
    END;
    */

                -- FOR VALIDATING VALUE OF ATTRIBUTE5 WITH VALUESET ATTACHED ON AR_CASH_RECEIPTS_ALL.ATTRIBUTE5 -- ADDDED ON 12-FEB-2026 BY AKALA
                /*
    BEGIN
     SELECT FLEX_VALUE
     INTO J.ATTRIBUTE5
     FROM FND_FLEX_VALUES
     WHERE 1=1
     AND SYSDATE < NVL(END_DATE_ACTIVE,SYSDATE+1)
     AND ENABLED_FLAG = 'Y'
     AND FLEX_VALUE_SET_ID = (SELECT FLEX_VALUE_SET_ID
            FROM FND_FLEX_VALUE_SETS A
            WHERE FLEX_VALUE_SET_NAME =  'AR_SRS_YES_NO')
     AND FLEX_VALUE = TRIM(ATTRIBUTE5);
    EXCEPTION WHEN OTHERS THEN
     J.ATTRIBUTE5 := NULL;
     J.PROCESS_FLAG := 'E';
     LC_ERROR:=LC_ERROR||'AR_SRS_YES_NO VALUESET error: '||J.ATTRIBUTE5||'; '||SQLCODE||'-'||SQLERRM||'; ';
     FND_FILE.PUT_LINE(FND_FILE.LOG,'AR_SRS_YES_NO VALUESET error FOR ATTRIBUTE5: '||J.ATTRIBUTE5||'; '||SQLCODE||'-'||SQLERRM||'; ');
    END;
    */

                -- FOR VALIDATING VALUE OF ATTRIBUTE6 WITH VALUESET ATTACHED ON AR_CASH_RECEIPTS_ALL.ATTRIBUTE6 -- ADDDED ON 12-FEB-2026 BY AKALA
                /*
    BEGIN
     SELECT FLEX_VALUE
     INTO J.ATTRIBUTE6
     FROM FND_FLEX_VALUES
     WHERE 1=1
     AND SYSDATE < NVL(END_DATE_ACTIVE,SYSDATE+1)
     AND ENABLED_FLAG = 'Y'
     AND FLEX_VALUE_SET_ID = (SELECT FLEX_VALUE_SET_ID
            FROM FND_FLEX_VALUE_SETS A
            WHERE FLEX_VALUE_SET_NAME =  'AR_SRS_YES_NO')
     AND FLEX_VALUE = TRIM(ATTRIBUTE6);
    EXCEPTION WHEN OTHERS THEN
     J.ATTRIBUTE6 := NULL;
     J.PROCESS_FLAG := 'E';
     LC_ERROR:=LC_ERROR||'AR_SRS_YES_NO VALUESET error: '||J.ATTRIBUTE6||'; '||SQLCODE||'-'||SQLERRM||'; ';
     FND_FILE.PUT_LINE(FND_FILE.LOG,'AR_SRS_YES_NO VALUESET error FOR ATTRIBUTE6: '||J.ATTRIBUTE6||'; '||SQLCODE||'-'||SQLERRM||'; ');
    END;
    */

                -- FOR DUMMY BANK ACCORDING TO ATTRIBUTE11
                /*LC_DUMMY :=
                       'DUMMY BANK '
                    || REGEXP_REPLACE (J.BANK_ACC_NAME,
                                       '\s*cash',
                                       '',
                                       1,
                                       0,
                                       'i');*/ -- Oommented by AKALA, CASH is not required
					LC_DUMMY := SUBSTR(J.ATTRIBUTE11,1,3)||'%\_DUMMY%'; 		   
							

                -- FOR CORRECT DUMMY RECEIPT METHOD ID -- ADDDED ON 12-FEB-2026 BY AKALA
                BEGIN
                    SELECT RECEIPT_METHOD_ID
                      INTO LN_RECEIPT_METHOD_ID_REC
                      FROM AR_RECEIPT_METHODS
                     WHERE     1 = 1
                           AND UPPER (NAME) LIKE UPPER (LC_DUMMY) ESCAPE '\'
                           AND REGEXP_LIKE (NAME, '[^-]');

                EXCEPTION
                    WHEN OTHERS
                    THEN
                        LN_RECEIPT_METHOD_ID_REC := NULL;
                        J.PROCESS_FLAG := 'E';
                        LC_ERROR :=
                               LC_ERROR
                            || 'Receipt Method error: '
                            || LC_DUMMY
                            || '; '
                            || SQLCODE
                            || '-'
                            || SQLERRM
                            || '; ';
                        FND_FILE.PUT_LINE(FND_FILE.LOG,
                               'Receipt Method ID fetching error FOR ATTRIBUTE7: '
                            || J.ATTRIBUTE7
                            || '; '
                            || SQLCODE
                            || '-'
                            || SQLERRM
                            || '; ');
                END;

                -- VALIDATING THE RECEIVABLES_TRX_ID FOR ATTRIBUTE11
                LC_RECE_TRX_NAME :=
                    SUBSTR (J.ATTRIBUTE11, 1, 3) || '%MISC%RECEIPTS';

                BEGIN
                    SELECT RECEIVABLES_TRX_ID
                      INTO LN_RECEIVABLES_TRX_ID
                      FROM AR_RECEIVABLES_TRX_ALL
                     WHERE UPPER (NAME) LIKE LC_RECE_TRX_NAME;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        LN_RECEIVABLES_TRX_ID := NULL;
                        J.PROCESS_FLAG := 'E';
                        LC_ERROR :=
                               LC_ERROR
                            || 'RECEIVABLES_TRX_ID error: '
                            || LC_RECE_TRX_NAME
                            || '; '
                            || SQLCODE
                            || '-'
                            || SQLERRM
                            || '; ';
                        FND_FILE.PUT_LINE(FND_FILE.LOG,
                               'RECEIVABLES_TRX_ID fetching error FOR LC_RECE_TRX_NAME AT ATTRIBUTE9: '
                            || J.ATTRIBUTE9
                            || '; '
                            || SQLCODE
                            || '-'
                            || SQLERRM
                            || '; ');
                END;

                -- VALIDATING REMITANCE BANK ACCOUNT USE ID
                BEGIN
                    SELECT BANK_ACCT_USE_ID
                      INTO REMIT_BANK_ACCT_USE_ID
                      FROM CE_BANK_ACCT_USES_ALL
                     WHERE BANK_ACCOUNT_ID = J.BANK_ACC_ID;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        REMIT_BANK_ACCT_USE_ID := NULL;
                        J.PROCESS_FLAG := 'E';
                        LC_ERROR :=
                               LC_ERROR
                            || 'REMIT_BANK_ACCT_USE_ID error: '
                            || REMIT_BANK_ACCT_USE_ID
                            || '; '
                            || SQLCODE
                            || '-'
                            || SQLERRM
                            || '; ';
                        FND_FILE.PUT_LINE(FND_FILE.LOG,
                               'REMIT_BANK_ACCT_USE_ID fetching error FOR REMIT_BANK_ACCT_USE_ID AT BANK_ACC_ID: '
                            || J.BANK_ACC_ID
                            || '; '
                            || SQLCODE
                            || '-'
                            || SQLERRM
                            || '; ');
                END;
				
				-- INSERTING DATA TO ERROR table
				/*PRAGMA_COMMIT (J.PROCESS_FLAG,
                                           J.PROCESS_MESSAGE || LC_ERROR,
                                           J.CONS_RCPT_NO,
                                           J.COMPOSITE_RECEIPT_ID);*/
				
                -- UPDATING THE STATUS FROM NULL TO E, P
                UPDATE ADDB.ADDB_XXA_AR_TRANS_ERP_RCPT@ebstohr --XXAU_AR_TRANS_ERP_RCPT_T
                   SET PROCESS_FLAG = J.PROCESS_FLAG,
                       PROCESS_MESSAGE = J.PROCESS_MESSAGE || LC_ERROR
                 WHERE     1 = 1
                       AND COMPOSITE_RECEIPT_ID = J.COMPOSITE_RECEIPT_ID;

                COMMIT;
            EXCEPTION
                WHEN OTHERS
                THEN
                    LC_ERROR :=
                           LC_ERROR
                        || ' - '
                        || SQLCODE
                        || '-'
                        || SQLERRM
                        || '; ';

                    UPDATE ADDB.ADDB_XXA_AR_TRANS_ERP_RCPT@ebstohr --XXAU_AR_TRANS_ERP_RCPT_T
                       SET PROCESS_FLAG = 'E',
                           PROCESS_MESSAGE = J.PROCESS_MESSAGE || LC_ERROR
                     WHERE     1 = 1
                           AND COMPOSITE_RECEIPT_ID = J.COMPOSITE_RECEIPT_ID;
					
					/*PRAGMA_COMMIT (J.PROCESS_FLAG,
                                           J.PROCESS_MESSAGE || LC_ERROR,
                                           J.CONS_RCPT_NO,
                                           J.COMPOSITE_RECEIPT_ID);*/
                    COMMIT;
            END;
        END LOOP;
    EXCEPTION
        WHEN OTHERS
        THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,
                   'Error in VALIDATION_REQUIRED Procedure: '
                || SQLCODE
                || ' '
                || SQLERRM
                || '; ');
    END VALIDATION_REQUIRED;


    /*************************************************************************************************
     * Program Name : MAIN
     * Language     : PL/SQL
     * Description  : MAIN Procedure is used for calling all the other objects.
     * History      :
     *
     * WHO              Version #   WHEN            WHAT
     * ===============  =========   =============   ====================================================
     * AKALA            1.0         12-FEB-2026      Initial Version
     ***************************************************************************************************/

    PROCEDURE MAIN (P_ERRBUF OUT VARCHAR2, P_RETCODE OUT VARCHAR2)
    AS
    BEGIN
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Calling VALIDATION_REQUIRED');
        VALIDATION_REQUIRED;     -- should be enabled; disble only for testing

        /*UPDATE ADDB.ADDB_XXA_AR_TRANS_ERP_RCPT@ebstohr --XXAU_AR_TRANS_ERP_RCPT_T
		  SET PROCESS_FLAG = 'P'
		  WHERE CONS_RCPT_NO IS NOT NULL;*/

        COMMIT;

        FND_FILE.PUT_LINE(FND_FILE.LOG,
            '------------------------------------------------');
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Calling ENTER_RECORDS');
        ENTER_RECORDS;


        FND_FILE.PUT_LINE(FND_FILE.LOG,
            '------------------------------------------------');
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Calling AFTER_PROCESS');
        AFTER_PROCESS;

    EXCEPTION
        WHEN OTHERS
        THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,
                   'Error in MAIN Procedure: '
                || SQLCODE
                || ' '
                || SQLERRM
                || '; ');
    END MAIN;
END XXAU_COMP_RCPT_CREATION_PKG;
/