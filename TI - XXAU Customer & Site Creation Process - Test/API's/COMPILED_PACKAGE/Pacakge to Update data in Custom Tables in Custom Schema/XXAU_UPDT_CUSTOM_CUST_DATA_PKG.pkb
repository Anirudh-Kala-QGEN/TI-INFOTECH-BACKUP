CREATE OR REPLACE PACKAGE BODY XXAU_UPDT_CUSTOM_CUST_DATA_PKG
IS 
    /*************************************************************************************************
    * Program Name : REG_ERR_MSG
    * Language     : PL/SQL
    * Description  : Function Used to rectify the Error messages.
    * History      -----------------------------------------------------------------------------------
	* Parameters   : REG_ERR_MSG   => IN PARAMETER , VARCHAR2
      N_MSG   => IN PARAMETER , VARCHAR2
    *
    * WHO              Version #   WHEN            WHAT
    * ===============  =========   =============   ====================================================
    * AKALA            1.0         21-APR-2026     Initial Version
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
     * Program Name : UPDATE_CUST_DETAILS
     * Language     : PL/SQL
     * Description  : Update the XXAU_CUSTOMER_DETAILS Table after complete process.
     * History      -----------------------------------------------------------------------------------
     * Parameters   :
     *
     * WHO              Version #   WHEN            WHAT
     * ===============  =========   =============   ====================================================
     * AKALA            1.0         20-APR-2026     Initial Version
     ***************************************************************************************************/
	PROCEDURE UPDATE_CUST_DETAILS
    AS
    BEGIN
        UPDATE XXAU_CUSTOMER_DETAILS A
           SET ERROR_MSZ =
                   (SELECT ERP_ERR_MSG
                      FROM AU_CUSTOMER_SHIP_TO
                     WHERE     AGENCY_ID = A.AGENCY_ID
                           AND CENTRE_NUMBER = A.CENTRE_NUMBER),
               PROCESS_FLAG =
                   (SELECT ERP_PROCESS_FLAG
                      FROM AU_CUSTOMER_SHIP_TO
                     WHERE     AGENCY_ID = A.AGENCY_ID
                           AND CENTRE_NUMBER = A.CENTRE_NUMBER)
         WHERE PROCESS_FLAG = 'P';
 
        COMMIT;
    EXCEPTION
        WHEN OTHERS
        THEN
            --FND_FILE.PUT_LINE (FND_FILE.LOG, SQLCODE || '-' || SQLERRM);
            DBMS_OUTPUT.PUT_LINE ( SQLCODE || '-' || SQLERRM);
    END; 
	 /*************************************************************************************************
     * Program Name : UPDT_CUST_WITH_SITES_MAST_NEW
     * Language     : PL/SQL
     * Description  : Update the AU_CUSTOMER_MASTER_NEW Table after complete process.
     * History      -----------------------------------------------------------------------------------
     * Parameters   :	P_CUST_ACCOUNT_ID IN NUMBER,
						P_ACCOUNT_NUMBER IN VARCHAR2,
						P_PARTY_ID IN NUMBER,
						P_PROCESS_FLAG IN VARCHAR2,
						P_ERR_MSG IN VARCHAR2,
						P_AGENCY_ID IN NUMBER
     *
     * WHO              Version #   WHEN            WHAT
     * ===============  =========   =============   ====================================================
     * AKALA            1.0         20-APR-2026     Initial Version
     ***************************************************************************************************/
 
	PROCEDURE UPDT_CUST_WITH_SITES_MAST_NEW (P_CUST_ACCOUNT_ID IN NUMBER,
											P_ACCOUNT_NUMBER IN VARCHAR2,
											P_PARTY_ID IN NUMBER,
											P_PROCESS_FLAG IN VARCHAR2,
											P_ERR_MSG IN VARCHAR2,
											P_AGENCY_ID IN NUMBER
											)
	AS
	BEGIN
		UPDATE AU_CUSTOMER_MASTER_NEW
		   SET ERP_CUSTOMER_ID = P_CUST_ACCOUNT_ID,
			   ERP_CUSTOMER_NUMBER = P_ACCOUNT_NUMBER,
			   ERP_PARTY_ID = P_PARTY_ID,
			   ERP_PROCESS_FLAG = P_PROCESS_FLAG,
			   ERP_ERR_MSG = (DECODE (ERP_ERR_MSG,NULL, '',ERP_ERR_MSG || '; ')|| P_ERR_MSG)
		 WHERE AGENCY_ID = P_AGENCY_ID;
		 COMMIT;
	EXCEPTION WHEN OTHERS THEN 
		DBMS_OUTPUT.PUT_LINE(SQLCODE||' - '||SQLERRM);
	END;
 
	 /*************************************************************************************************
     * Program Name : UPDATE_CUSTS_MAST_NEW
     * Language     : PL/SQL
     * Description  : Update the AU_CUSTOMER_MASTER_NEW Table.
     * History      -----------------------------------------------------------------------------------
     * Parameters   :	P_PROCESS_FLAG IN VARCHAR2,
						P_ERR_MSG IN VARCHAR2,
						P_AGENCY_ID IN NUMBER
     *
     * WHO              Version #   WHEN            WHAT
     * ===============  =========   =============   ====================================================
     * AKALA            1.0         20-APR-2026     Initial Version
     ***************************************************************************************************/
 
	PROCEDURE UPDATE_CUSTS_MAST_NEW (P_PROCESS_FLAG IN VARCHAR2,
									P_ERR_MSG IN VARCHAR2,
									P_AGENCY_ID IN NUMBER
									)
	AS
	BEGIN
		UPDATE AU_CUSTOMER_MASTER_NEW
                       SET ERP_PROCESS_FLAG = P_PROCESS_FLAG,
                           ERP_ERR_MSG = (DECODE (ERP_ERR_MSG,NULL, '',ERP_ERR_MSG || '; ')|| P_ERR_MSG)
                     WHERE AGENCY_ID = P_AGENCY_ID;
		COMMIT;
	EXCEPTION WHEN OTHERS THEN 
		DBMS_OUTPUT.PUT_LINE(SQLCODE||' - '||SQLERRM);
	END;
 
	 /*************************************************************************************************
     * Program Name : UPDATE_CUSTS_SHIP_SITES
     * Language     : PL/SQL
     * Description  : Update the AU_CUSTOMER_MASTER_NEW Table.
     * History      -----------------------------------------------------------------------------------
     * Parameters   :	P_ACCOUNT_NUMBER IN VARCHAR2, 
						P_CUST_ACCT_SITE_ID IN NUMBER,
						P_SITE_USE_ID IN NUMBER,
						P_CUST_ACCOUNT_ID IN NUMBER,
						P_PARTY_ID IN NUMBER,
						P_PROCESS_FLAG IN VARCHAR2,
						P_CCID IN NUMBER,
						P_ERR_MSG IN VARCHAR2,
						P_AGENCY_ID IN NUMBER,
						P_CENTRE_NUMBER IN VARCHAR2,
						P_MAIN_CENTRE_NUMBER IN VARCHAR2
     *
     * WHO              Version #   WHEN            WHAT
     * ===============  =========   =============   ====================================================
     * AKALA            1.0         20-APR-2026     Initial Version
     ***************************************************************************************************/
 
	PROCEDURE UPDATE_CUSTS_SHIP_SITES (P_ACCOUNT_NUMBER IN VARCHAR2, 
									P_CUST_ACCT_SITE_ID IN NUMBER,
									P_SITE_USE_ID IN NUMBER,
									P_CUST_ACCOUNT_ID IN NUMBER,
									P_PARTY_ID IN NUMBER,
									P_PROCESS_FLAG IN VARCHAR2,
									P_CCID IN NUMBER,
									P_ERR_MSG IN VARCHAR2,
									P_AGENCY_ID IN NUMBER,
									P_CENTRE_NUMBER IN VARCHAR2,
									P_MAIN_CENTRE_NUMBER IN VARCHAR2
									)
	AS
	BEGIN
		UPDATE AU_CUSTOMER_SHIP_TO
		   SET ERP_CUSTOMER_NUMBER = P_ACCOUNT_NUMBER,
			   ERP_CREATION_DATE = SYSDATE,
			   CUSTOMER_SHIP_ID = P_CUST_ACCT_SITE_ID,
			   ERP_SITE_USE_ID = P_SITE_USE_ID,
			   ERP_CUSTOMER_ID = P_CUST_ACCOUNT_ID,
			   ERP_PARTY_ID = P_PARTY_ID,
			   ERP_PROCESS_FLAG = P_PROCESS_FLAG,
			   CCID = P_CCID,
			   ERP_ERR_MSG = (DECODE (ERP_ERR_MSG,NULL, '',ERP_ERR_MSG || '; ')|| P_ERR_MSG)
		 WHERE     1 = 1
			   AND AGENCY_ID = P_AGENCY_ID
			   AND CENTRE_NUMBER = P_CENTRE_NUMBER
			   AND MAIN_CENTRE_NUMBER = P_MAIN_CENTRE_NUMBER
			   ;
 
		COMMIT;
	EXCEPTION WHEN OTHERS THEN 
		DBMS_OUTPUT.PUT_LINE(SQLCODE||' - '||SQLERRM);
	END;
 
	/*************************************************************************************************
     * Program Name : VALIDATE_REQUIRED
     * Language     : PL/SQL
     * Description  : Eleminating the records which do not have the mandatory columns availability.
     * History      -----------------------------------------------------------------------------------
	 * Parameters   :
     *
     * WHO              Version #   WHEN            WHAT
     * ===============  =========   =============   ====================================================
     * AKALA            1.0         01-APR-2026     Initial Version
     ***************************************************************************************************/
    PROCEDURE VALIDATE_REQUIRED
    AS
        CURSOR VAL_DATA IS
            (SELECT UNIT,
                    UNIT_NAME,
                    CUSTOMER_NAME,
                    CUSTOMER_CLASS,
                    CUSTOMER_TYPE,
                    ADDRESS1,
                    ADDRESS2,
                    ADDRESS3,
                    ADDRESS4,
                    STATE,
                    CITY,
                    PINCODE,
                    COUNTRY,
                    COUNTY,
                    STATION_NAME,
                    ACCOUNT_DESCRIPTION,
                    LOCATION1,
                    REC_ACCOUNT,
                    MOBILE_NO,
                    CONTACT_PERSON,
                    PAYMENT_TERMS,
                    PRIMARY_SITE_FALG,
                    GSTIN,
                    PAN,
                    THIRD_PARTY_SATE_CODE,
                    PROCESS_FLAG,
                    ERROR_MSZ,
                    THIRD_PARTY_REG_FLAG,
                    OLD_PARTY_ID,
                    OLD_CUSTOMER_ID,
                    AGENCY_ID,
                    CENTRE_NUMBER,
                    ABC_TYPE,
                    CREATION_DATE
               FROM XXAU_CUSTOMER_DETAILS A
              WHERE     1 = 1
                    AND (PROCESS_FLAG = 'N' OR PROCESS_FLAG IS NULL)
                    AND AGENCY_ID IN
                            (SELECT AGENCY_ID
                               FROM XXAU_AGENCY_APPROVAL_DETIALS
                              WHERE     TRUNC (CREATION_DATE) >=
                                        '01-OCT-2024'
                                    AND APPROVE_REJECT = 'A'
                                    AND AGREEMENT_FLAG = 'Y')
                    AND EXISTS
                            (SELECT 1
                               FROM AU_CUSTOMER_SHIP_TO
                              WHERE     AGENCY_ID = A.AGENCY_ID
                                    AND CENTRE_NUMBER = A.CENTRE_NUMBER)
			);
 
        LC_MSG   VARCHAR2 (4000);
    BEGIN
 
        FOR REC_DATA IN VAL_DATA
        LOOP
            LC_MSG := NULL;
            REC_DATA.PROCESS_FLAG := 'P';
 
            BEGIN
                -- Check Agency ID
                IF TRIM (REC_DATA.AGENCY_ID) IS NULL
                THEN
                    REC_DATA.PROCESS_FLAG := 'E';
                    LC_MSG := REG_ERR_MSG (NULL, 'Agency ID is required.');
                END IF;
 
                -- Check Centre Number
                IF TRIM (REC_DATA.CENTRE_NUMBER) IS NULL
                THEN
                    REC_DATA.PROCESS_FLAG := 'E';
                    LC_MSG :=
                        REG_ERR_MSG (LC_MSG, 'Centre Number is required.');
                END IF;
 
                -- Check Unit
                IF TRIM (REC_DATA.UNIT) IS NULL
                THEN
                    REC_DATA.PROCESS_FLAG := 'E';
                    LC_MSG := REG_ERR_MSG (LC_MSG, 'Unit is required.');
                END IF;
 
                --Check Customer Name
                IF TRIM (REC_DATA.CUSTOMER_NAME) IS NULL
                THEN
                    REC_DATA.PROCESS_FLAG := 'E';
                    LC_MSG :=
                        REG_ERR_MSG (LC_MSG, 'Customer Name is required.');
                END IF;
 
                -- Check Customer Type
                IF TRIM (REC_DATA.CUSTOMER_TYPE) IS NULL
                THEN
                    REC_DATA.PROCESS_FLAG := 'E';
                    LC_MSG :=
                        REG_ERR_MSG (LC_MSG, 'Customer Type is required.');
                END IF;
 
                -- Check Location1
                IF TRIM (REC_DATA.LOCATION1) IS NULL
                THEN
                    REC_DATA.PROCESS_FLAG := 'E';
                    LC_MSG := REG_ERR_MSG (LC_MSG, 'Location1 is required.');
                END IF;
 
                -- Check Station Name
                IF TRIM (REC_DATA.STATION_NAME) IS NULL
                THEN
                    REC_DATA.PROCESS_FLAG := 'E';
                    LC_MSG :=
                        REG_ERR_MSG (LC_MSG, 'Station Name is required.');
                END IF;
 
                -- Check Account Description
                IF TRIM (REC_DATA.ACCOUNT_DESCRIPTION) IS NULL
                THEN
                    REC_DATA.PROCESS_FLAG := 'E';
                    LC_MSG :=
                        REG_ERR_MSG (LC_MSG,
                                     'Account Description is required.');
                END IF;
 
                -- Check Country
                IF TRIM (REC_DATA.COUNTRY) IS NULL
                THEN
                    REC_DATA.PROCESS_FLAG := 'E';
                    LC_MSG := REG_ERR_MSG (LC_MSG, 'Country is required.');
                END IF;
 
                -- Check Code Combination Segment
                IF TRIM (REC_DATA.REC_ACCOUNT) IS NULL
                THEN
                    REC_DATA.PROCESS_FLAG := 'E';
                    LC_MSG :=
                        REG_ERR_MSG (
                            LC_MSG,
                            'REC_ACCOUNT (Code Combination Segment) is required.');
                END IF;
 
                -- Updating Customer Details Table for Error Message and Error Flag
                UPDATE XXAU_CUSTOMER_DETAILS
                   SET ERROR_MSZ = LC_MSG,
                       PROCESS_FLAG = REC_DATA.PROCESS_FLAG
                 WHERE     1 = 1
                       AND AGENCY_ID = REC_DATA.AGENCY_ID
                       AND CENTRE_NUMBER = REC_DATA.CENTRE_NUMBER;
 
                -- Updating Customer Ship To Table for Error Message and Error Flag
                /*
        UPDATE AU_CUSTOMER_SHIP_TO
        SET ERP_ERR_MSG = ERP_ERR_MSG||LC_MSG
        , ERP_PROCESS_FLAG = REC_DATA.PROCESS_FLAG
        WHERE 1=1
        AND AGENCY_ID = REC_DATA.AGENCY_ID
        AND CENTRE_NUMBER = REC_DATA.CENTRE_NUMBER
        ;
       */
 
                -- Updating Customer Master New Table for Error Message and Error Flag
                /*
        UPDATE AU_CUSTOMER_MASTER_NEW
        SET ERP_ERR_MSG = ERP_ERR_MSG || DECODE(TRIM(LC_MSG),NULL,'',LC_MSG||': For Centre Number - '||REC_DATA.CENTRE_NUMBER)--NVL2((REG_ERR_MSG(ERP_ERR_MSG,LC_MSG)),'',(REG_ERR_MSG(ERP_ERR_MSG,LC_MSG))||': Centre Number - '||REC_DATA.CENTRE_NUMBER)
        , ERP_PROCESS_FLAG = REC_DATA.PROCESS_FLAG
        WHERE 1=1
        AND AGENCY_ID = REC_DATA.AGENCY_ID
        ;
       */
 
                COMMIT;
            EXCEPTION
                WHEN OTHERS
                THEN
                    --FND_FILE.PUT_LINE (FND_FILE.LOG, SQLCODE || '-' || SQLERRM);
                    DBMS_OUTPUT.PUT_LINE ( SQLCODE || '-' || SQLERRM);
            END;
        END LOOP;
 
        --FND_FILE.PUT_LINE (FND_FILE.LOG, 'Validation Completed..');
        --FND_FILE.PUT_LINE (FND_FILE.LOG, RPAD ('*', 30, '*'));
    EXCEPTION
        WHEN OTHERS
        THEN
            --FND_FILE.PUT_LINE (FND_FILE.LOG, SQLCODE || ' - ' || SQLERRM);
			NULL;
    END VALIDATE_REQUIRED;
 
 
    /*************************************************************************************************
     * Program Name : LOAD_DATA
     * Language     : PL/SQL
     * Description  : To insert the data into the XXAU_CUSTOMER_DETAILS table
     * History      -----------------------------------------------------------------------------------
	* Parameters   :
     *
     * WHO              Version #   WHEN            WHAT
     * ===============  =========   =============   ====================================================
     * AKALA            1.0         20-APR-2026     Initial Version
     ***************************************************************************************************/
    PROCEDURE LOAD_DATA
    IS
        CURSOR CUR_LOAD IS
            (SELECT XXAU_INV_ORG.ORGANIZATION_CODE,
                    XXAU_INV_ORG.ORG_NAME,
                    XXAU_AAD.AGENCY_NAME,
                    NULL
                        CUSTOMER_CLASS,
                    DECODE (XXAU_AAD.PROUCT_NAME,
                            'Amar Ujala - Variant', 'Circulation Customers',
                            'Amar Ujala', 'Circulation Customers',
                            'Amar Ujala - Udaan', 'Udaan Customers',
                            'Amar Ujala - Safalta', 'NEW SAFALTA CUSTOMERS')
                        CUSTOMER_TYPE,
                    NVL (
                        (SELECT ADDRESS
                           FROM AUCUSTOM.AU_CUSTOMER_MASTER_ADVANCE
                          WHERE     1 = 1
                                AND AGENCY_ID = XXAU_AAD.AGENCY_ID
                                AND INV_ORG = XXAU_AAD.INV_ORG),
                        (SELECT ADDRESS
                           FROM AUCUSTOM.AU_CUSTOMER_MASTER_OCCUPA
                          WHERE     AGENCY_ID = XXAU_AAD.AGENCY_ID
                                AND INV_ORG = XXAU_AAD.INV_ORG))
                        ADDRESS,
                    NULL
                        ADDRESS2,
                    NULL
                        ADDRESS3,
                    NULL
                        ADDRESS4,
                    AU_CUST_SHIP_TO.STATE,
                    AU_CUST_SHIP_TO.CITY,
                    AU_CUST_SHIP_TO.POSTAL_CODE,
                    'INDIA'
                        COUNTRY,
                    AU_CUST_SHIP_TO.DISTRICT,
                    AU_CUST_SHIP_TO.NAME_OF_CENTRE
                        STATION_NAME,
                    AU_CUST_MST_NEW.DROP_POINT
                        ACCOUNT_DESCRIPTION,
                    AU_CUST_SHIP_TO.NAME_OF_CENTRE
                        LOCATION1,
                       XXAU_INV_ORG.ORGANIZATION_CODE
                    || '.9999.'
                    || XXAU_INV_ORG.ORGANIZATION_CODE
                    || '.102.205110.'
                    || AU_CUST_SHIP_TO.DAK_CODE
                    || '.999.999.999.999'
                        REC_ACCOUNT,
                    NVL (
                        (SELECT MOBILE_NO
                           FROM AUCUSTOM.AU_CUSTOMER_MASTER_ADVANCE
                          WHERE     AGENCY_ID = XXAU_AAD.AGENCY_ID
                                AND INV_ORG = XXAU_AAD.INV_ORG),
                        (SELECT MOBILE_NO
                           FROM AUCUSTOM.AU_CUSTOMER_AUTHORISE_PER
                          WHERE     AGENCY_ID = XXAU_AAD.AGENCY_ID
                                AND INV_ORG = XXAU_AAD.INV_ORG))
                        MOBILE_NO,
                    NVL (
                        (SELECT ENTITY_NAME
                           FROM AUCUSTOM.AU_CUSTOMER_MASTER_ADVANCE
                          WHERE     AGENCY_ID = XXAU_AAD.AGENCY_ID
                                AND INV_ORG = XXAU_AAD.INV_ORG),
                        (SELECT ENTITY_NAME
                           FROM AUCUSTOM.AU_CUSTOMER_AUTHORISE_PER
                          WHERE     AGENCY_ID = XXAU_AAD.AGENCY_ID
                                AND INV_ORG = XXAU_AAD.INV_ORG))
                        CONTACT_PERSON,
                    'Immediate '
                        PAYMENT_TERM,
                    DECODE (AU_CUST_SHIP_TO.PRIMARY_FLAG, 'Y', 'YES', 'NO')
                        PRIMARY_FLAG,
                    'Unregistered'
                        GSTIN,
                    NVL (
                        (SELECT PAN
                           FROM AUCUSTOM.AU_CUSTOMER_MASTER_ADVANCE
                          WHERE     AGENCY_ID = XXAU_AAD.AGENCY_ID
                                AND INV_ORG = XXAU_AAD.INV_ORG),
                        (SELECT PAN
                           FROM AUCUSTOM.AU_CUSTOMER_AUTHORISE_PER
                          WHERE     AGENCY_ID =  XXAU_AAD.AGENCY_ID
                                AND INV_ORG = XXAU_AAD.INV_ORG))
                        PAN,
                    (SELECT STATE_CODE
                       FROM AUCUSTOM.XXAU_AGENCY_STATE
                      WHERE DESCRIPTION = AU_CUST_SHIP_TO.STATE)
                        THIRD_PARTY_SATE_CODE,
                    'N'
                        X1,
                    NULL
                        X2,
                    'N'
                        X3,
                    DECODE (
                        XXAU_AAD.PROUCT_NAME,
                        'Amar Ujala - Udaan', AU_CUST_SHIP_TO.ERP_PARTY_ID,
                        'Amar Ujala - Safalta', AU_CUST_SHIP_TO.ERP_PARTY_ID,
                        AU_CUST_MST_NEW.erp_party_id)
                        ERP_PARTY_ID,
                    DECODE (
                        XXAU_AAD.PROUCT_NAME,
                        'Amar Ujala - Udaan', AU_CUST_SHIP_TO.ERP_CUSTOMER_ID,
                        'Amar Ujala - Safalta', AU_CUST_SHIP_TO.ERP_CUSTOMER_ID,
                        AU_CUST_MST_NEW.ERP_CUSTOMER_ID)
                        ERP_CUSTOMER_ID,
                    AU_CUST_SHIP_TO.AGENCY_ID,
                    AU_CUST_SHIP_TO.CENTRE_NUMBER,
                    DECODE (AU_CUST_MST_NEW.AGENCY_AREA_TYPE,
                            'D.HQ UPC', 2,
                            1)
                        ABC_AUDIT,
                    SYSDATE
                        CREATION_DATE
               FROM AUCUSTOM.XXAU_AGENCY_APPROVAL_DETIALS XXAU_AAD,
                    AUCUSTOM.AU_CUSTOMER_SHIP_TO         AU_CUST_SHIP_TO,
                    AUCUSTOM.XXAU_INV_ORGANIZATION        XXAU_INV_ORG,
                    AUCUSTOM.AU_CUSTOMER_MASTER_NEW      AU_CUST_MST_NEW
              WHERE     XXAU_AAD.AGENCY_ID = AU_CUST_SHIP_TO.AGENCY_ID
                    AND XXAU_AAD.INV_ORG = AU_CUST_SHIP_TO.INV_ORG
                    AND AU_CUST_SHIP_TO.INV_ORG = XXAU_INV_ORG.INV_ORG_ID
                    AND XXAU_AAD.CENTRE_NUMBER =
                        AU_CUST_SHIP_TO.CENTRE_NUMBER
                    AND XXAU_AAD.INV_ORG = AU_CUST_MST_NEW.INV_ORG
                    AND XXAU_AAD.AGENCY_ID = AU_CUST_MST_NEW.AGENCY_ID
                    AND XXAU_AAD.INV_ORG = AU_CUST_SHIP_TO.INV_ORG
                    AND XXAU_AAD.APPROVE_REJECT = 'A'
                    -- AND XXAU_AAD.AGENCY_ID = NVL(P_AGENCY_ID, XXAU_AAD.AGENCY_ID)
                    --             AND XXAU_AAD.AGENCY_ID = 6074637
                    AND NVL (AU_CUST_SHIP_TO.APPROVE_FLAG, 'N') = 'N'
                    AND AU_CUST_SHIP_TO.ERP_SITE_USE_ID IS NULL
                    AND NOT EXISTS
                            (SELECT 'Y'
                               FROM AUCUSTOM.XXAU_CUSTOMER_DETAILS
                              WHERE     AGENCY_ID = AU_CUST_SHIP_TO.AGENCY_ID
                                    AND CENTRE_NUMBER =
                                        AU_CUST_SHIP_TO.CENTRE_NUMBER)
                    AND SYSDATE BETWEEN AU_CUST_SHIP_TO.EFFECTIVE_START_DATE
                                    AND AU_CUST_SHIP_TO.EFFECTIVE_END_DATE
                    AND SYSDATE BETWEEN AU_CUST_MST_NEW.EFFECTIVE_START_DATE
                                    AND AU_CUST_MST_NEW.EFFECTIVE_END_DATE);
 
        TYPE DATA_TBL IS TABLE OF CUR_LOAD%ROWTYPE
            INDEX BY PLS_INTEGER;
 
        CUR_TBL           DATA_TBL;
 
        LC_ERR            VARCHAR2 (4000);
        BULK_EXCEPTIONS   EXCEPTION;
        PRAGMA EXCEPTION_INIT (BULK_EXCEPTIONS, -24381);
    BEGIN
        OPEN CUR_LOAD;
 
        LOOP
            BEGIN
                FETCH CUR_LOAD BULK COLLECT INTO CUR_TBL LIMIT 1000;
 
                EXIT WHEN CUR_TBL.COUNT = 0;
 
                FORALL I IN CUR_TBL.FIRST .. CUR_TBL.LAST SAVE EXCEPTIONS
                    INSERT INTO AUCUSTOM.XXAU_CUSTOMER_DETAILS(
                                    UNIT,
                                    UNIT_NAME,
                                    CUSTOMER_NAME,
                                    CUSTOMER_CLASS,
                                    CUSTOMER_TYPE,
                                    ADDRESS1,
                                    ADDRESS2,
                                    ADDRESS3,
                                    ADDRESS4,
                                    STATE,
                                    CITY,
                                    PINCODE,
                                    COUNTRY,
                                    COUNTY,
                                    STATION_NAME,
                                    ACCOUNT_DESCRIPTION,
                                    LOCATION1,
                                    REC_ACCOUNT,
                                    MOBILE_NO,
                                    CONTACT_PERSON,
                                    PAYMENT_TERMS,
                                    PRIMARY_SITE_FALG,
                                    GSTIN,
                                    PAN,
                                    THIRD_PARTY_SATE_CODE,
                                    PROCESS_FLAG,
                                    ERROR_MSZ,
                                    THIRD_PARTY_REG_FLAG,
                                    OLD_PARTY_ID,
                                    OLD_CUSTOMER_ID,
                                    AGENCY_ID,
                                    CENTRE_NUMBER,
                                    ABC_TYPE,
                                    CREATION_DATE)
                         VALUES (CUR_TBL (I).ORGANIZATION_CODE,
                                 CUR_TBL (I).ORG_NAME,
                                 CUR_TBL (I).AGENCY_NAME,
                                 CUR_TBL (I).CUSTOMER_CLASS,
                                 CUR_TBL (I).CUSTOMER_TYPE,
                                 CUR_TBL (I).ADDRESS,
                                 CUR_TBL (I).ADDRESS2,
                                 CUR_TBL (I).ADDRESS3,
                                 CUR_TBL (I).ADDRESS4,
                                 CUR_TBL (I).STATE,
                                 CUR_TBL (I).CITY,
                                 CUR_TBL (I).POSTAL_CODE,
                                 CUR_TBL (I).COUNTRY,
                                 CUR_TBL (I).DISTRICT,
                                 CUR_TBL (I).STATION_NAME,
                                 CUR_TBL (I).ACCOUNT_DESCRIPTION,
                                 CUR_TBL (I).LOCATION1,
                                 CUR_TBL (I).REC_ACCOUNT,
                                 CUR_TBL (I).MOBILE_NO,
                                 CUR_TBL (I).CONTACT_PERSON,
                                 CUR_TBL (I).PAYMENT_TERM,
                                 CUR_TBL (I).PRIMARY_FLAG,
                                 CUR_TBL (I).GSTIN,
                                 CUR_TBL (I).PAN,
                                 CUR_TBL (I).THIRD_PARTY_SATE_CODE,
                                 CUR_TBL (I).X1,
                                 CUR_TBL (I).X2,
                                 CUR_TBL (I).X3,
                                 CUR_TBL (I).ERP_PARTY_ID,
                                 CUR_TBL (I).ERP_CUSTOMER_ID,
                                 CUR_TBL (I).AGENCY_ID,
                                 CUR_TBL (I).CENTRE_NUMBER,
                                 CUR_TBL (I).ABC_AUDIT,
                                 CUR_TBL (I).CREATION_DATE);
 
                COMMIT;
            EXCEPTION
                WHEN BULK_EXCEPTIONS
                THEN
                    FOR I IN 1 .. SQL%BULK_EXCEPTIONS.COUNT
                    LOOP
                        LC_ERR :=
                               SQL%BULK_EXCEPTIONS (I).ERROR_INDEX
                            || ' - '
                            || SQL%BULK_EXCEPTIONS (I).ERROR_CODE;
                        /*FND_FILE.PUT_LINE (FND_FILE.LOG,'Error in Bulk Collect : '|| i|| ' - '|| LC_ERR);*/
                        DBMS_OUTPUT.PUT_LINE ('Error in Bulk Collect : '|| i|| ' - '|| LC_ERR);
                    END LOOP;
                WHEN OTHERS
                THEN
                   /* FND_FILE.PUT_LINE (FND_FILE.LOG,'Error in Bulk Collect : '|| SQLCODE|| ' - '|| SQLERRM);*/
                    DBMS_OUTPUT.PUT_LINE ('Error in Bulk Collect : '|| SQLCODE|| ' - '|| SQLERRM);
            END;
        END LOOP;
 
       -- FND_FILE.PUT_LINE (FND_FILE.LOG,'LOAD_DATA PROCEDURE COMPLETE : ' || SQLCODE || ' - ' || SQLERRM);
       -- FND_FILE.PUT_LINE (FND_FILE.LOG, RPAD ('+', 25, '+'));
    EXCEPTION
        WHEN OTHERS
        THEN
           -- FND_FILE.PUT_LINE (FND_FILE.LOG, SQLCODE || ' - ' || SQLERRM);
            DBMS_OUTPUT.PUT_LINE ( SQLCODE || ' - ' || SQLERRM);
    END LOAD_DATA;
 
END XXAU_UPDT_CUSTOM_CUST_DATA_PKG;