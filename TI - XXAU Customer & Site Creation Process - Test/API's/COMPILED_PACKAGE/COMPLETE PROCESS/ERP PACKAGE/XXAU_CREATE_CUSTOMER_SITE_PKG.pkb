CREATE OR REPLACE PACKAGE BODY APPS.XXAU_CREATE_CUSTOMER_SITE_PKG
IS
    /*************************************************************************************************
     *                 Copy Rights Reserved ? Ti Infotech- 2026
     *
     * $Header: @(#)
     * Program Name : XXAU_CREATE_CUSTOMER_SITE_PKG (Body)
     * Language     : PL/SQL
     * Description  : Process to Customer, SHIP_TO Sites, Party , Party Site and Location
     * History      :
     *
     * WHO              Version #   WHEN            WHAT
     * ===============  =========   =============   ======================================================================================
     * AKALA            1.0         01-APR-2026      Initial Version -> Create Procedure (MAIN, VALIDATE_REQUIRED AND CREATE_CUSTOMERS_SITES)
     * AKALA            1.1         02-APR-2026      Updated Version -> Create Procedure (CREATE_CUSTOMER_AND_SITES
																						  , CREATE_PARTY
																						  and CREATE_CUST_ACCOUNT)
     * AKALA            1.2         06-APR-2026      Updated Version -> Create Procedure (CREATE_LOCATION
																						  , CREATE_CUST_SITE_USES
																						  and CREATE_PARTY_SITE)
     * AKALA            1.3         07-APR-2026      Updated Version -> Create Procedure (CREATE_CONTACT_POINT_SITE_LVL
																						  , CREATE_SAFALTA_CUST_AND_SITES
																						  and CREATE_CUST_ACCT_SITE)
     * AKALA            1.4         08-APR-2026      Updated Version -> Create Procedure 	1. CREATED CREATE_CODE_COMBINATION
																							2. (Update conditions in CREATE_CUSTOMER_SITES
																								, CREATE_CUSTOMER_AND_SITES
																								and CREATE_SAFALTA_CUST_AND_SITES FOR CODE COMBINATION)
     * AKALA            1.5         09-APR-2026      Updated Version -> 1. Create Procedure CREATE_CONTACT_ORG
																		2. (Updated code for:
																		   1. CREATE_CUST_SITE_USES
																		   2. CREATE_CUST_ACCT_SITE
																		   3. CREATE_CUST_ACCOUNT
																		   4. CREATE_PARTY_SITE
																		   5. CREATE_LOCATION
																		   6. CREATE_SAFALTA_CUST_AND_SITES
																		   7. CREATE_CUSTOMER_AND_SITES
																		   8. CREATE_CUSTOMERS_SITES)
     * AKALA            1.6         13-APR-2026      Updated Version -> 1.Create a function REG_ERR_MSG for error message to remove extra punctuation marks.
																		2.Create Procedure UPDATE_CUST_DETAILS to update the status in the xxau_customer_details table
  ************************************************************************************************************************************/

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
    * AKALA            1.0         13-APR-2026     Initial Version
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
     * AKALA            1.0         13-APR-2026     Initial Version
     * AKALA            1.2         20-APR-2026     Updated for Package update; It will update directly into the Custom's base table
     ***************************************************************************************************/
    PROCEDURE UPDATE_CUST_DETAILS
    AS
    BEGIN
        /* -- Commented by AKALA on 20-APR-2026,
		UPDATE XXAU_CUSTOMER_DETAILS@ebstohr A
           SET ERROR_MSZ =
                   (SELECT ERP_ERR_MSG
                      FROM AU_CUSTOMER_SHIP_TO@ebstohr
                     WHERE     AGENCY_ID = A.AGENCY_ID
                           AND CENTRE_NUMBER = A.CENTRE_NUMBER),
               PROCESS_FLAG =
                   (SELECT ERP_PROCESS_FLAG
                      FROM AU_CUSTOMER_SHIP_TO@ebstohr
                     WHERE     AGENCY_ID = A.AGENCY_ID
                           AND CENTRE_NUMBER = A.CENTRE_NUMBER)
         WHERE PROCESS_FLAG = 'P';
		 */
		 -- Added by AKALA on 20-APR-2026 for updating the XXAU_CUSTOMER_DETAILS custom table for flag and message.
		
		XXAU_UPDT_CUSTOM_CUST_DATA_PKG.UPDATE_CUST_DETAILS@EBSTOHR;
		 
        COMMIT;
    EXCEPTION
        WHEN OTHERS
        THEN
            FND_FILE.PUT_LINE (FND_FILE.LOG, SQLCODE || '-' || SQLERRM);
    END; 

    /*************************************************************************************************
    * Program Name : CREATE_CODE_COMBINATION
    * Language     : PL/SQL
    * Description  : Creates the CODE COMBINATION ID; GET if code combination already exists.
    * History      -----------------------------------------------------------------------------------
	* Parameters   : P_ORG_ID    => IN PARAMETER , NUMBER
      P_INV_ORG   => IN PARAMETER , NUMBER
      P_AGENCY_ID  => IN PARAMETER , NUMBER
      P_CENTRE_NUMBER  => IN PARAMETER , VARCHAR2
      P_AGENCY_NAME  => IN PARAMETER , VARCHAR2
      P_CCID    => OUT PARAMETER , NUMBER
      P_MSG    => OUT PARAMETER , VARCHAR2 (FOR ERROR MESSAGE)
    *
    * WHO              Version #   WHEN            WHAT
    * ===============  =========   =============   ====================================================
    * AKALA            1.0         08-APR-2026     Initial Version
    ***************************************************************************************************/

    PROCEDURE CREATE_CODE_COMBINATION (P_ORG_ID          IN     NUMBER,
                                       P_INV_ORG         IN     NUMBER,
                                       P_AGENCY_ID       IN     NUMBER,
                                       P_CENTRE_NUMBER   IN     VARCHAR2,
                                       P_AGENCY_NAME     IN     VARCHAR2,
                                       P_CCID               OUT NUMBER,
                                       P_MSG                OUT VARCHAR2)
    AS
        LN_CCID               GL_CODE_COMBINATIONS.CODE_COMBINATION_ID%TYPE;
        LC_CONCATE_SEGMENTS   GL_CODE_COMBINATIONS_KFV.CONCATENATED_SEGMENTS%TYPE;
        LN_CHART_OF_ACCT_ID   NUMBER;
    BEGIN
        FND_FILE.PUT_LINE (FND_FILE.LOG, RPAD ('=', 25, '='));
        FND_FILE.PUT_LINE (FND_FILE.LOG, 'CREATE_CODE_COMBINATION');
        FND_FILE.PUT_LINE (FND_FILE.LOG, RPAD ('=', 25, '='));

        BEGIN
            SELECT CHART_OF_ACCOUNTS_ID
              INTO LN_CHART_OF_ACCT_ID
              FROM ORG_ORGANIZATION_DEFINITIONS
             WHERE OPERATING_UNIT = P_ORG_ID AND ORGANIZATION_ID = P_INV_ORG;
        EXCEPTION
            WHEN OTHERS
            THEN
                BEGIN
                    SELECT CHART_OF_ACCOUNTS_ID
                      INTO LN_CHART_OF_ACCT_ID
                      FROM GL_SETS_OF_BOOKS
                     WHERE SET_OF_BOOKS_ID =
                           FND_PROFILE.VALUE ('GL_SET_OF_BKS_ID');
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        LN_CHART_OF_ACCT_ID := -1;
                        P_CCID := -1;
                        P_MSG := 'Cannot find Chart Accounts ID.';
                        FND_FILE.PUT_LINE (FND_FILE.LOG,
                                           SQLCODE || '-' || SQLERRM);
                        FND_FILE.PUT_LINE (FND_FILE.LOG, P_MSG);
                END;
        END;


        IF LN_CHART_OF_ACCT_ID > 0
        THEN
            BEGIN
                SELECT A.REC_ACCOUNT
                  INTO LC_CONCATE_SEGMENTS
                  FROM XXAU_CUSTOMER_DETAILS@ebstohr   A,
                       AU_CUSTOMER_MASTER_NEW@ebstohr  B,
                       AU_CUSTOMER_SHIP_TO@ebstohr     C
                 WHERE     1 = 1
                       AND B.AGENCY_ID = C.AGENCY_ID
                       AND A.CUSTOMER_NAME = B.AGENCY_NAME
                       AND A.ADDRESS1 = C.ADDRESS
                       AND A.PINCODE = C.POSTAL_CODE
                       AND A.CITY = C.CITY
                       AND A.STATE = C.STATE
                       AND A.STATION_NAME = C.NAME_OF_CENTRE
                       AND A.AGENCY_ID = P_AGENCY_ID
                       AND C.CENTRE_NUMBER = P_CENTRE_NUMBER
                       AND A.CUSTOMER_NAME = P_AGENCY_NAME;

                P_CCID :=
                    FND_FLEX_EXT.get_ccid ('SQLGL',
                                           'GL#',
                                           LN_CHART_OF_ACCT_ID,
                                           TO_CHAR (SYSDATE, 'DD-MON-YYYY'),
                                           LC_CONCATE_SEGMENTS);

                IF P_CCID <= 0
                THEN
                    P_MSG :=
                        P_MSG || '- Not able to create Code Combination.';
                    P_CCID := -1;
                END IF;

                FND_FILE.PUT_LINE (FND_FILE.LOG,
                                   'CODE_COMBINATION_ID : ' || P_CCID);
            EXCEPTION
                WHEN OTHERS
                THEN
                    P_CCID := -1;
                    LN_CHART_OF_ACCT_ID := -1;
                    P_MSG :=
                           P_MSG
                        || ' - '
                        || 'Customer REC_ACCOUNT is not available in XXAU_CUSTOMER_DETAILS@ebstohr.';
            END;
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            LN_CHART_OF_ACCT_ID := -1;
            P_CCID := -1;
    END CREATE_CODE_COMBINATION;

    /*************************************************************************************************
    * Program Name : CREATE_CONTACT_ORG
    * Language     : PL/SQL
    * Description  : Creates the Org Contact
    * History      -----------------------------------------------------------------------------------
	* Parameters   : P_PARTY_ID    => IN PARAMETER , NUMBER
      P_CONTACT_PERSON   => IN PARAMETER , VARCHAR2
      P_MSG    => OUT PARAMETER , VARCHAR2 (FOR ERROR MESSAGE)
    *
    * WHO              Version #   WHEN            WHAT
    * ===============  =========   =============   ====================================================
    * AKALA            1.0         08-APR-2026     Initial Version
    ***************************************************************************************************/
    PROCEDURE CREATE_CONTACT_ORG (P_PARTY_ID         IN     NUMBER,
                                  P_CONTACT_PERSON   IN     VARCHAR2,
                                  P_MSG                 OUT VARCHAR2)
    AS
        LV_ORG_CONTACT_REC   HZ_PARTY_CONTACT_V2PUB.ORG_CONTACT_REC_TYPE;
        LV_PERSON_REC        HZ_PARTY_V2PUB.PERSON_REC_TYPE;
        LV1_PARTY_ID         NUMBER;
        LV1_PARTY_NUMBER     VARCHAR2 (1000);
        LV2_PARTY_NUMBER     VARCHAR2 (1000);
        LV1_PROFILE_ID       NUMBER;
        X_RETURN_STATUS      VARCHAR2 (100);
        X_MSG_COUNT          NUMBER;
        X_MSG_DATA           VARCHAR2 (100);
        X_PARTY_ID           NUMBER;
        LV2_ORG_CONTACT_ID   NUMBER;
        LV_MSG_INDEX_OUT     NUMBER;
        LV_API_MESSAGE       VARCHAR2 (4000);
        LV2_PARTY_REL_ID     NUMBER;
        LV2_PARTY_ID         NUMBER;
    BEGIN
	
		FND_GLOBAL.APPS_INITIALIZE (GN_USER_ID, GN_RESP_ID, GN_RESP_APPL_ID);
        MO_GLOBAL.INIT ('AR');
        FND_CLIENT_INFO.SET_ORG_CONTEXT (GN_ORG_ID);
		MO_GLOBAL.SET_POLICY_CONTEXT('S', 288);
		
        FND_FILE.PUT_LINE (FND_FILE.LOG, 'enter contact person creation');
        LV2_ORG_CONTACT_ID := 0;
        FND_FILE.PUT_LINE (FND_FILE.LOG,
                           'lv2_org_contact_id' || LV2_ORG_CONTACT_ID);

        LV_PERSON_REC.PERSON_FIRST_NAME := P_CONTACT_PERSON; --CREATE_CUSTOMER_REC.CONTACT_PERSON;
        LV_PERSON_REC.PERSON_LAST_NAME := '1';
        LV_PERSON_REC.PARTY_REC.STATUS := 'A';
        LV_PERSON_REC.CREATED_BY_MODULE := 'BO_API';
        --
        HZ_PARTY_V2PUB.CREATE_PERSON (
            P_INIT_MSG_LIST   => APPS.FND_API.G_FALSE,
            P_PERSON_REC      => LV_PERSON_REC,
            X_PARTY_ID        => LV1_PARTY_ID,
            X_PARTY_NUMBER    => LV1_PARTY_NUMBER,
            X_PROFILE_ID      => LV1_PROFILE_ID,
            X_RETURN_STATUS   => X_RETURN_STATUS,
            X_MSG_COUNT       => X_MSG_COUNT,
            X_MSG_DATA        => X_MSG_DATA);

        --
        --Capturing error if not success
        --
        IF X_RETURN_STATUS <> APPS.FND_API.G_RET_STS_SUCCESS
        THEN
            FOR I IN 1 .. FND_MSG_PUB.COUNT_MSG
            LOOP
                FND_MSG_PUB.GET (P_MSG_INDEX       => I,
                                 P_ENCODED         => APPS.FND_API.G_FALSE,
                                 P_DATA            => X_MSG_DATA,
                                 P_MSG_INDEX_OUT   => LV_MSG_INDEX_OUT);

                LV_API_MESSAGE := LV_API_MESSAGE || ' ~ ' || X_MSG_DATA;
                FND_FILE.PUT_LINE (FND_FILE.LOG, 'Error: ' || LV_API_MESSAGE);
            END LOOP;

            P_MSG := LV_API_MESSAGE;
        ELSIF (x_return_status = apps.fnd_api.g_ret_sts_success)
        THEN
            fnd_file.put_line (fnd_file.LOG, '***************************');
            fnd_file.put_line (fnd_file.LOG, 'Output information ....');
            fnd_file.put_line (fnd_file.LOG, 'Success');
            fnd_file.put_line (fnd_file.LOG,
                               'contact person id : ' || LV1_PARTY_ID);
            fnd_file.put_line (fnd_file.LOG, '***************************');
        END IF;

        LV_ORG_CONTACT_REC.PARTY_REL_REC.RELATIONSHIP_CODE := 'CONTACT_OF';
        LV_ORG_CONTACT_REC.PARTY_REL_REC.RELATIONSHIP_TYPE := 'CONTACT';
        LV_ORG_CONTACT_REC.PARTY_REL_REC.SUBJECT_ID := LV1_PARTY_ID;
        LV_ORG_CONTACT_REC.PARTY_REL_REC.SUBJECT_TYPE := 'PERSON';
        LV_ORG_CONTACT_REC.PARTY_REL_REC.SUBJECT_TABLE_NAME := 'HZ_PARTIES';
        LV_ORG_CONTACT_REC.PARTY_REL_REC.OBJECT_TYPE := 'ORGANIZATION';
        LV_ORG_CONTACT_REC.PARTY_REL_REC.OBJECT_ID := P_PARTY_ID;
        --<< THIS IS HZ_PARTIES.PARTY_ID OF THE CUSTOMER (MAIN ORGANIZATION/PARTY)>>
        LV_ORG_CONTACT_REC.PARTY_REL_REC.OBJECT_TABLE_NAME := 'HZ_PARTIES';
        LV_ORG_CONTACT_REC.PARTY_REL_REC.START_DATE := SYSDATE;
        LV_ORG_CONTACT_REC.CREATED_BY_MODULE := 'BO_API';
        HZ_PARTY_CONTACT_V2PUB.CREATE_ORG_CONTACT (
            P_INIT_MSG_LIST     => FND_API.G_TRUE,
            P_ORG_CONTACT_REC   => LV_ORG_CONTACT_REC,
            X_ORG_CONTACT_ID    => LV2_ORG_CONTACT_ID,
            X_PARTY_REL_ID      => LV2_PARTY_REL_ID,
            X_PARTY_ID          => LV2_PARTY_ID,
            X_PARTY_NUMBER      => LV2_PARTY_NUMBER,
            X_RETURN_STATUS     => X_RETURN_STATUS,
            X_MSG_COUNT         => X_MSG_COUNT,
            X_MSG_DATA          => X_MSG_DATA);

        IF X_RETURN_STATUS <> FND_API.G_RET_STS_SUCCESS
        THEN
            LV_API_MESSAGE := NULL;

            FOR I IN 1 .. FND_MSG_PUB.COUNT_MSG
            LOOP
                FND_MSG_PUB.GET (P_MSG_INDEX       => I,
                                 P_ENCODED         => FND_API.G_FALSE,
                                 P_DATA            => X_MSG_DATA,
                                 P_MSG_INDEX_OUT   => LV_MSG_INDEX_OUT);

                LV_API_MESSAGE := LV_API_MESSAGE || ' ~ ' || X_MSG_DATA;
            END LOOP;

            P_MSG := P_MSG || ';' || LV_API_MESSAGE;
            fnd_file.put_line (fnd_file.LOG, 'Error: ' || lv_api_message);
        ELSIF (x_return_status = fnd_api.g_ret_sts_success)
        THEN
            fnd_file.put_line (fnd_file.LOG, '***************************');
            fnd_file.put_line (fnd_file.LOG, 'Output information ....');
            fnd_file.put_line (fnd_file.LOG, 'Success');
            fnd_file.put_line (fnd_file.LOG,
                               'lv_org_contact_id: ' || lv2_org_contact_id);
            fnd_file.put_line (fnd_file.LOG, 'lv_party_id: ' || lv2_party_id);
            fnd_file.put_line (fnd_file.LOG,
                               'lv_party_rel_id: ' || lv2_party_rel_id);
            fnd_file.put_line (fnd_file.LOG, '***************************');
            COMMIT;
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            FND_FILE.PUT_LINE (FND_FILE.LOG, SQLCODE || '-' || SQLERRM);
    END;

    /*************************************************************************************************
    * Program Name : CREATE_CONTACT_POINT_SITE_LVL
    * Language     : PL/SQL
    * Description  : Creates the final Customer contact point details according to site level for Email and Phone
    * History      -----------------------------------------------------------------------------------
	* Parameters   : P_PARTY_SITE_ID    => IN PARAMETER, NUMBER
      P_PHONE      => IN PARAMETER , NUMBER
      P_EMAIL     => IN PARAMETER , VARCHAR2
      P_TABLE      => IN PARAMETER ,VARCHAR (HZ_PARTIES , HZ_PARTY_SITES)
      P_PHONE_CONTACT_POINT_ID  => OUT PARAMETER , NUMBER
      P_EMAIL_CONTACT_POINT_ID  => OUT PARAMETER , NUMBER
      P_MSG      => OUT PARAMETER , VARCHAR2 (FOR ERROR MESSAGE)
    *
    * WHO              Version #   WHEN            WHAT
    * ===============  =========   =============   ====================================================
    * AKALA            1.0         07-APR-2026     Initial Version
    ***************************************************************************************************/
    PROCEDURE CREATE_CONTACT_POINT_SITE_LVL (
        P_PARTY_SITE_ID            IN     NUMBER,
        P_PHONE                    IN     NUMBER,
        P_EMAIL                    IN     VARCHAR2,
        P_TABLE                    IN     VARCHAR2,
        P_PHONE_CONTACT_POINT_ID      OUT NUMBER,
        P_EMAIL_CONTACT_POINT_ID      OUT NUMBER,
        P_MSG                         OUT VARCHAR2)
    AS
        L_CONTACT_POINT_REC         HZ_CONTACT_POINT_V2PUB.CONTACT_POINT_REC_TYPE;
        L_EDI_REC                   HZ_CONTACT_POINT_V2PUB.EDI_REC_TYPE;
        L_EMAIL_REC                 HZ_CONTACT_POINT_V2PUB.EMAIL_REC_TYPE;
        L_PHONE_REC                 HZ_CONTACT_POINT_V2PUB.PHONE_REC_TYPE;
        L_TELEX_REC                 HZ_CONTACT_POINT_V2PUB.TELEX_REC_TYPE;
        L_WEB_REC                   HZ_CONTACT_POINT_V2PUB.WEB_REC_TYPE;
        LN_PHONE_CONTACT_POINT_ID   HZ_CONTACT_POINTS.CONTACT_POINT_ID%TYPE;
        LN_EMAIL_CONTACT_POINT_ID   HZ_CONTACT_POINTS.CONTACT_POINT_ID%TYPE;
        L_RETURN_STATUS             VARCHAR2 (100);
        L_MSG_COUNT                 NUMBER;
        L_MSG_DATA                  VARCHAR2 (2000);
    BEGIN
        DBMS_OUTPUT.ENABLE (BUFFER_SIZE => NULL);
        --INITIATE THE EBS ENVIRONMENT FOR API PROCESSING
        FND_GLOBAL.APPS_INITIALIZE (GN_USER_ID, GN_RESP_ID, GN_RESP_APPL_ID);
        MO_GLOBAL.INIT ('AR');
        FND_CLIENT_INFO.SET_ORG_CONTEXT (GN_ORG_ID);
		MO_GLOBAL.SET_POLICY_CONTEXT('S', 288);
        
		
        P_MSG := NULL;
		-- INITIALIZING THE MANDATORY API PARAMETERS
			-- TO CREATE PHONE CONTACT POINT ACCORDING TO SITE
        IF TRIM (P_PHONE) IS NOT NULL
        THEN
            --CONTACT RECORD
            L_CONTACT_POINT_REC.CONTACT_POINT_TYPE := 'PHONE';
            L_CONTACT_POINT_REC.OWNER_TABLE_NAME := P_TABLE;
            L_CONTACT_POINT_REC.OWNER_TABLE_ID := P_PARTY_SITE_ID;
            L_CONTACT_POINT_REC.PRIMARY_FLAG := 'Y';
            L_CONTACT_POINT_REC.CONTACT_POINT_PURPOSE := 'BUSINESS';
            L_CONTACT_POINT_REC.CREATED_BY_MODULE := 'BO_API';
            --PHONE RECORD
            L_PHONE_REC.PHONE_COUNTRY_CODE := '91';
            L_PHONE_REC.PHONE_NUMBER := P_PHONE;
            L_PHONE_REC.PHONE_LINE_TYPE := 'MOBILE';
            --Calling hz_contact_point_v2pub.create_contact_point
            FND_FILE.PUT_LINE (
                FND_FILE.LOG,
                'Calling hz_contact_point_v2pub.create_contact_point api');
            HZ_CONTACT_POINT_V2PUB.CREATE_CONTACT_POINT (
                P_INIT_MSG_LIST       => FND_API.G_TRUE,
                P_CONTACT_POINT_REC   => L_CONTACT_POINT_REC,
                P_EDI_REC             => L_EDI_REC,
                --P_EMAIL_REC          => L_EMAIL_REC,
                P_PHONE_REC           => L_PHONE_REC,
                P_TELEX_REC           => L_TELEX_REC,
                P_WEB_REC             => L_WEB_REC,
                X_CONTACT_POINT_ID    => LN_PHONE_CONTACT_POINT_ID,
                X_RETURN_STATUS       => L_RETURN_STATUS,
                X_MSG_COUNT           => L_MSG_COUNT,
                X_MSG_DATA            => L_MSG_DATA);

            IF L_RETURN_STATUS = 'S'
            THEN
                FND_FILE.PUT_LINE (FND_FILE.LOG,
                                   'Contact Point Creation is Successful ');
                FND_FILE.PUT_LINE (
                    FND_FILE.LOG,
                    'contact_point_id = ' || LN_PHONE_CONTACT_POINT_ID);
                P_PHONE_CONTACT_POINT_ID := LN_PHONE_CONTACT_POINT_ID;
                COMMIT;
            ELSE
                FND_FILE.PUT_LINE (
                    FND_FILE.LOG,
                    'Contact Point Creation failed:' || L_MSG_DATA);

                FOR i IN 1 .. L_MSG_COUNT
                LOOP
                    L_MSG_DATA :=
                        FND_MSG_PUB.GET (P_MSG_INDEX => I, P_ENCODED => 'F');
                    FND_FILE.PUT_LINE (FND_FILE.LOG, I || ') ' || L_MSG_DATA);
                    P_MSG := P_MSG || '; ' || L_MSG_DATA;
                END LOOP;

                FND_FILE.PUT_LINE (
                    FND_FILE.LOG,
                    'Contact Point Creation failed:' || L_MSG_DATA);
                P_EMAIL_CONTACT_POINT_ID := -1;
                ROLLBACK;
            END IF;
        ELSE
            P_PHONE_CONTACT_POINT_ID := -1;
        END IF;

        FND_FILE.PUT_LINE (FND_FILE.LOG, RPAD ('-', 25, '-'));

        -- TO CREATE EMAIL CONTACT POINT ACCORDING TO SITE LEVEL
        IF TRIM (P_EMAIL) IS NOT NULL
        THEN
            L_CONTACT_POINT_REC.CONTACT_POINT_TYPE := 'EMAIL';
            L_CONTACT_POINT_REC.OWNER_TABLE_NAME := P_TABLE;
            L_CONTACT_POINT_REC.OWNER_TABLE_ID := P_PARTY_SITE_ID;
            L_CONTACT_POINT_REC.PRIMARY_FLAG := 'Y';
            L_CONTACT_POINT_REC.CONTACT_POINT_PURPOSE := 'BUSINESS';
            L_CONTACT_POINT_REC.CREATED_BY_MODULE := 'BO_API';
            --EMAIL RECORD
            L_EMAIL_REC.EMAIL_FORMAT := 'MAILHTML';
            L_EMAIL_REC.EMAIL_ADDRESS := P_EMAIL;
            --Calling hz_contact_point_v2pub.create_contact_point
            FND_FILE.PUT_LINE (
                FND_FILE.LOG,
                'Calling hz_contact_point_v2pub.create_contact_point api');
            HZ_CONTACT_POINT_V2PUB.CREATE_CONTACT_POINT (
                P_INIT_MSG_LIST       => FND_API.G_TRUE,
                P_CONTACT_POINT_REC   => L_CONTACT_POINT_REC,
                P_EDI_REC             => L_EDI_REC,
                P_EMAIL_REC           => L_EMAIL_REC,
                --P_PHONE_REC          => L_PHONE_REC,
                P_TELEX_REC           => L_TELEX_REC,
                P_WEB_REC             => L_WEB_REC,
                X_CONTACT_POINT_ID    => LN_EMAIL_CONTACT_POINT_ID,
                X_RETURN_STATUS       => L_RETURN_STATUS,
                X_MSG_COUNT           => L_MSG_COUNT,
                X_MSG_DATA            => L_MSG_DATA);

            IF L_RETURN_STATUS = 'S'
            THEN
                FND_FILE.PUT_LINE (
                    FND_FILE.LOG,
                    'EMAIL : Contact Point Creation is Successful ');
                FND_FILE.PUT_LINE (
                    FND_FILE.LOG,
                    'Contact_point_id = ' || LN_EMAIL_CONTACT_POINT_ID);
                P_EMAIL_CONTACT_POINT_ID := LN_EMAIL_CONTACT_POINT_ID;
                COMMIT;
            ELSE
                FND_FILE.PUT_LINE (
                    FND_FILE.LOG,
                    'EMAIL : Contact Point Creation failed:' || L_MSG_DATA);

                FOR i IN 1 .. L_MSG_COUNT
                LOOP
                    L_MSG_DATA :=
                        FND_MSG_PUB.GET (P_MSG_INDEX => I, P_ENCODED => 'F');
                    FND_FILE.PUT_LINE (FND_FILE.LOG, I || ') ' || L_MSG_DATA);
                    P_MSG := P_MSG || '; ' || L_MSG_DATA;
                END LOOP;

                FND_FILE.PUT_LINE (
                    FND_FILE.LOG,
                    'EMAIL : Contact Point Creation failed:' || L_MSG_DATA);
                P_EMAIL_CONTACT_POINT_ID := -1;
                ROLLBACK;
            END IF;
        ELSE
            P_EMAIL_CONTACT_POINT_ID := -1;
        END IF;

        FND_FILE.PUT_LINE (FND_FILE.LOG, 'Contact Point Creation Complete');
        FND_FILE.PUT_LINE (FND_FILE.LOG, RPAD ('-', 25, '-'));
    END CREATE_CONTACT_POINT_SITE_LVL;

    /*************************************************************************************************
    * Program Name : CREATE_CUST_SITE_USES
    * Language     : PL/SQL
    * Description  : Creates the final Customer Site Use as SHIP_TO
    * History      -----------------------------------------------------------------------------------
	* Parameters   : P_CUST_ACCT_SITE_ID   => IN PARAMETER, NUMBER
      P_SITE_USE_CODE    => IN PARAMETER (EITHER SHIP_TO OR BILL_TO) , VARCHAR2
      P_CUSTOMER_TYPE   => IN PARAMETER , VARCHAR2
      P_CENTRE_NUMBER   => IN PARAMETER , VARCHAR2
      P_PRIMARY_FLAG   => IN PARAMETER , VARCHAR2
      P_PAYMENT_TERMS   => IN PARAMETER , VARCHAR2
      P_REC_ACCOUNT    => IN PARAMETER , VARCHAR2
      P_LOCATION    => IN PARAMETER LOCATION NAME , VARCHAR2
      P_SITE_USE_ID    => OUT PARAMETER , NUMBER (FOR ERP SITE_USE_ID)
      P_MSG      => OUT PARAMETER , VARCHAR2 (FOR ERROR MESSAGE)
    *
    * WHO              Version #   WHEN            WHAT
    * ===============  =========   =============   ====================================================
    * AKALA            1.0         06-APR-2026    	Initial Version
    * AKALA            1.1         07-APR-2026     	Update code for already existing Site Uses
													for Specific Location of specific customer
    * AKALA            1.2         09-APR-2026     	Added paramter  P_CUSTOMER_TYPE, P_PRIMARY_FLAG, P_PAYMENT_TERMS,
													P_REC_ACCOUNT.
													Added logic to create the Code Combination
													Added logic to get the payment terms
    * AKALA            1.2         10-APR-2026     	1. Commented the L_CUST_SITE_USE_REC.GL_ID_REC because of SHIP_TO site creation
													2. Added P_CCID to send back the CODE_COMBINATION_ID if it is available or created
    ***************************************************************************************************/
    PROCEDURE CREATE_CUST_SITE_USES (P_CUST_ACCT_SITE_ID   IN     NUMBER,
                                     P_SITE_USE_CODE       IN     VARCHAR2,
                                     P_CUSTOMER_TYPE       IN     VARCHAR2,
                                     P_LOCATION            IN     VARCHAR2,
                                     P_CENTRE_NUMBER       IN     VARCHAR2,
                                     P_PRIMARY_FLAG        IN     VARCHAR2,
                                     P_PAYMENT_TERMS       IN     VARCHAR2,
                                     P_REC_ACCOUNT         IN     VARCHAR2,
                                     P_SITE_USE_ID            OUT NUMBER,
                                     P_CCID                   OUT NUMBER,
                                     P_MSG                    OUT VARCHAR2)
    AS
        L_CUST_SITE_USE_REC      HZ_CUST_ACCOUNT_SITE_V2PUB.CUST_SITE_USE_REC_TYPE;
        L_CUSTOMER_PROFILE_REC   HZ_CUSTOMER_PROFILE_V2PUB.CUSTOMER_PROFILE_REC_TYPE;
        L_SITE_USE_ID            HZ_CUST_SITE_USES.SITE_USE_ID%TYPE;
        L_RETURN_STATUS          VARCHAR2 (100);
        L_MSG_COUNT              NUMBER;
        L_MSG_DATA               VARCHAR2 (2000);
        LN_TERM_ID               NUMBER;
        LN_GL_CODE_ID            NUMBER;
        LN_ID_FLEX_NUM           NUMBER;
        LC_STATUS                VARCHAR2 (2000);
        LB_STATUS                BOOLEAN;
    BEGIN
        -- PAYMENT TERMS
        LN_TERM_ID := NULL;
        LN_GL_CODE_ID := -1;

        IF P_PAYMENT_TERMS IS NOT NULL
        THEN
            BEGIN
                SELECT TERM_ID
                  INTO LN_TERM_ID
                  FROM APPS.RA_TERMS
                 WHERE UPPER (NAME) = UPPER (TRIM (P_PAYMENT_TERMS)); --CREATE_SITE_REC.PAYMENT_TERMS;
            EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                    LN_TERM_ID := NULL;
                WHEN OTHERS
                THEN
                    LN_TERM_ID := NULL;
            END;
        END IF;

        -- CODE COMBINATIONS
        BEGIN
            SELECT CODE_COMBINATION_ID
              INTO LN_GL_CODE_ID
              FROM APPS.GL_CODE_COMBINATIONS_KFV X
             WHERE X.CONCATENATED_SEGMENTS = P_REC_ACCOUNT; --CREATE_SITE_REC.REC_ACCOUNT;
        EXCEPTION
            WHEN OTHERS
            THEN
                BEGIN
                    BEGIN
                        SELECT ID_FLEX_NUM
                          INTO LN_ID_FLEX_NUM
                          FROM APPS.FND_ID_FLEX_STRUCTURES
                         WHERE     ID_FLEX_CODE = 'GL#'
                               AND ID_FLEX_STRUCTURE_CODE =
                                   'AUPL_CHART_OF_ACCOUNT';
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            LN_ID_FLEX_NUM := NULL;
                    END;

                    LB_STATUS :=
                        FND_FLEX_KEYVAL.VALIDATE_SEGS (
                            OPERATION          => 'CREATE_COMBINATION',
                            APPL_SHORT_NAME    => 'SQLGL',
                            KEY_FLEX_CODE      => 'GL#',
                            STRUCTURE_NUMBER   => TO_NUMBER (LN_ID_FLEX_NUM),
                            CONCAT_SEGMENTS    => TO_CHAR (P_REC_ACCOUNT) --CREATE_SITE_REC.REC_ACCOUNT
                                                                         ,
                            VALUES_OR_IDS      => 'V',
                            VALIDATION_DATE    => SYSDATE,
                            RESP_APPL_ID       => GN_RESP_APPL_ID,
                            RESP_ID            => GN_RESP_ID,
                            USER_ID            => GN_USER_ID);

                    BEGIN
                        SELECT CODE_COMBINATION_ID
                          INTO LN_GL_CODE_ID
                          FROM GL_CODE_COMBINATIONS_KFV A
                         WHERE CONCATENATED_SEGMENTS = P_REC_ACCOUNT --CREATE_SITE_REC.REC_ACCOUNT;
                                                                    ;
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            LN_GL_CODE_ID := -1;
                    END;
                END;
        END;

        P_CCID := LN_GL_CODE_ID;
		
		FND_GLOBAL.APPS_INITIALIZE (GN_USER_ID, GN_RESP_ID, GN_RESP_APPL_ID);
        MO_GLOBAL.INIT ('AR');
        --FND_CLIENT_INFO.SET_ORG_CONTEXT (GN_ORG_ID);
        MO_GLOBAL.SET_POLICY_CONTEXT ('S', GN_ORG_ID);
		
        L_CUST_SITE_USE_REC.SITE_USE_CODE := 'SHIP_TO';
        L_CUST_SITE_USE_REC.ATTRIBUTE_CATEGORY := P_CUSTOMER_TYPE; --CREATE_CUSTOMER_REC.CUSTOMER_TYPE;
        L_CUST_SITE_USE_REC.CUST_ACCT_SITE_ID := P_CUST_ACCT_SITE_ID;
        L_CUST_SITE_USE_REC.CREATED_BY_MODULE := 'BO_API';
        L_CUST_SITE_USE_REC.ORG_ID := GN_ORG_ID;
        L_CUST_SITE_USE_REC.PRIMARY_FLAG := P_PRIMARY_FLAG; --CREATE_SITE_REC.PRIMARY_FLAG;
        L_CUST_SITE_USE_REC.LOCATION := P_LOCATION; --CREATE_SITE_REC.LOCATION1;
        L_CUSTOMER_PROFILE_REC.STANDARD_TERMS := LN_TERM_ID;
        L_CUST_SITE_USE_REC.ATTRIBUTE25 := P_CENTRE_NUMBER; --CREATE_SITE_REC.CENTRE_NUMBER;

        -- L_CUST_SITE_USE_REC.GL_ID_REC := LN_GL_CODE_ID; --Commented on 10-APR-2026, for SHIP_TO sites

        HZ_CUST_ACCOUNT_SITE_V2PUB.CREATE_CUST_SITE_USE (
            P_INIT_MSG_LIST          => FND_API.G_TRUE,
            P_CUST_SITE_USE_REC      => L_CUST_SITE_USE_REC,
            P_CUSTOMER_PROFILE_REC   => L_CUSTOMER_PROFILE_REC,
            P_CREATE_PROFILE         => FND_API.G_TRUE,
            P_CREATE_PROFILE_AMT     => FND_API.G_TRUE,
            X_SITE_USE_ID            => L_SITE_USE_ID,
            X_RETURN_STATUS          => L_RETURN_STATUS,
            X_MSG_COUNT              => L_MSG_COUNT,
            X_MSG_DATA               => L_MSG_DATA);

        FND_FILE.PUT_LINE (FND_FILE.LOG,
                           'L_RETURN_STATUS = ' || L_RETURN_STATUS);

        IF L_RETURN_STATUS = 'S'
        THEN
            FND_FILE.PUT_LINE (FND_FILE.LOG,
                               'Cust Site Use Creation is Successful ');
            FND_FILE.PUT_LINE (FND_FILE.LOG,
                               'site_use_id = ' || L_SITE_USE_ID);
            COMMIT;
        ELSE
            --FND_FILE.PUT_LINE(FND_FILE.LOG,'Cust Site Use Creation failed:'||l_msg_data);
            FOR i IN 1 .. L_MSG_COUNT
            LOOP
                l_msg_data :=
                    FND_MSG_PUB.get (p_msg_index => i, p_encoded => 'F');
                FND_FILE.PUT_LINE (FND_FILE.LOG, i || ') ' || l_msg_data);
                P_MSG := P_MSG || l_msg_data || '; ';
            END LOOP;

            -- STATE - Added on 07-APR-2026, to assign the already exists site use id
            BEGIN
                SELECT SITE_USE_ID
                  INTO L_SITE_USE_ID
                  FROM HZ_CUST_SITE_USES_ALL
                 WHERE     1 = 1
                       AND UPPER (P_MSG) LIKE
                               '%LOCATION ALREADY EXISTS FOR THIS BUSINESS PURPOSE AND CUSTOMER%'
                       AND LOCATION = P_LOCATION
                       AND SITE_USE_CODE = 'SHIP_TO'
                       AND EXISTS
                               (SELECT 1
                                  FROM HZ_CUST_ACCOUNTS        HCA,
                                       HZ_CUST_ACCT_SITES_ALL  HCASA
                                 WHERE     1 = 1
                                       AND HCA.CUST_ACCOUNT_ID =
                                           HCASA.CUST_ACCOUNT_ID
                                       AND HCASA.CUST_ACCT_SITE_ID =
                                           P_CUST_ACCT_SITE_ID);

                COMMIT;
            EXCEPTION
                WHEN OTHERS
                THEN
                    ROLLBACK;
                    L_SITE_USE_ID := -1;
            END;
        END IF;

        P_SITE_USE_ID := L_SITE_USE_ID;
    EXCEPTION
        WHEN OTHERS
        THEN
            FND_FILE.PUT_LINE (FND_FILE.LOG, SQLCODE || ' - ' || SQLERRM);
            P_SITE_USE_ID := -1;
    END CREATE_CUST_SITE_USES;


    /*************************************************************************************************
     * Program Name : CREATE_CUST_ACCT_SITE
     * Language     : PL/SQL
     * Description  : Creates the Customer Site.
     * History      -----------------------------------------------------------------------------------
	 * Parameters   : P_CUST_ACCOUNT_ID   => IN PARAMETER , NUMBER
       P_PARTY_SITE_ID    => IN PARAMETER , NUMBER
       P_CUSTOMER_TYPE    => IN VARCHAR2 , NUMBER
       P_CUST_ACCT_SITE_ID   => OUT PARAMETER , NUMBER (FOR ERP CUST_ACCT_SITE_ID)
       P_MSG      => OUT PARAMETER , VARCHAR2 (FOR ERROR MESSAGE)
     *
     * WHO              Version #   WHEN            WHAT
     * ===============  =========   =============   ====================================================
     * AKALA            1.0         07-APR-2026     Initial Version
     * AKALA            1.0         09-APR-2026     Added P_CUSTOMER_TYPE parameter
     ***************************************************************************************************/
    PROCEDURE CREATE_CUST_ACCT_SITE (P_CUST_ACCOUNT_ID     IN     NUMBER,
                                     P_PARTY_SITE_ID       IN     NUMBER,
                                     P_CUSTOMER_TYPE       IN     VARCHAR2,
                                     P_CUST_ACCT_SITE_ID      OUT NUMBER,
                                     P_MSG                    OUT VARCHAR2)
    AS
        L_CUST_ACCT_SITE_REC   HZ_CUST_ACCOUNT_SITE_V2PUB.CUST_ACCT_SITE_REC_TYPE;
        L_CUST_ACCT_SITE_ID    HZ_CUST_ACCT_SITES.CUST_ACCT_SITE_ID%TYPE;
        L_RETURN_STATUS        VARCHAR2 (100);
        L_MSG_COUNT            NUMBER;
        L_MSG_DATA             VARCHAR2 (2000);
    BEGIN
        DBMS_OUTPUT.ENABLE (buffer_size => NULL);
        P_MSG := NULL;
        FND_FILE.PUT_LINE (FND_FILE.LOG, RPAD ('-', 25, '-'));
        --Initiate the EBS Environment for API processing
		FND_GLOBAL.APPS_INITIALIZE (GN_USER_ID, GN_RESP_ID, GN_RESP_APPL_ID);
        MO_GLOBAL.INIT ('AR');
        --FND_CLIENT_INFO.SET_ORG_CONTEXT (GN_ORG_ID);
        MO_GLOBAL.SET_POLICY_CONTEXT ('S', GN_ORG_ID);

        L_CUST_ACCT_SITE_REC.CUST_ACCOUNT_ID := P_CUST_ACCOUNT_ID;
        L_CUST_ACCT_SITE_REC.PARTY_SITE_ID := P_PARTY_SITE_ID;
        L_CUST_ACCT_SITE_REC.CREATED_BY_MODULE := 'BO_API';
        L_CUST_ACCT_SITE_REC.ATTRIBUTE_CATEGORY := P_CUSTOMER_TYPE; --CREATE_CUSTOMER_REC.CUSTOMER_TYPE;
        L_CUST_ACCT_SITE_REC.ORG_ID := GN_ORG_ID;

        HZ_CUST_ACCOUNT_SITE_V2PUB.CREATE_CUST_ACCT_SITE (
            P_INIT_MSG_LIST        => FND_API.G_TRUE,
            P_CUST_ACCT_SITE_REC   => L_CUST_ACCT_SITE_REC,
            X_CUST_ACCT_SITE_ID    => L_CUST_ACCT_SITE_ID,
            X_RETURN_STATUS        => L_RETURN_STATUS,
            X_MSG_COUNT            => L_MSG_COUNT,
            X_MSG_DATA             => L_MSG_DATA);

        IF L_RETURN_STATUS = 'S'
        THEN
            FND_FILE.PUT_LINE (FND_FILE.LOG,
                               'Cust Acct Site Creation is Successful ');
            FND_FILE.PUT_LINE (FND_FILE.LOG,
                               'Cust Acct Site Id = ' || l_cust_acct_site_id);
            COMMIT;
        ELSE
            FOR i IN 1 .. l_msg_count
            LOOP
                l_msg_data :=
                    FND_MSG_PUB.get (p_msg_index => i, p_encoded => 'F');
                FND_FILE.PUT_LINE (FND_FILE.LOG, i || ') ' || l_msg_data);
                P_MSG := P_MSG || l_msg_data || '; ';
            END LOOP;

            ROLLBACK;
            L_CUST_ACCT_SITE_ID := -1;
        --FND_FILE.PUT_LINE(FND_FILE.LOG,'Cust Acct Site Creation failed:'||l_msg_data);
        END IF;

        --FND_FILE.PUT_LINE(FND_FILE.LOG,'Cust Acct Site Creation Complete');
        P_CUST_ACCT_SITE_ID := L_CUST_ACCT_SITE_ID;
    EXCEPTION
        WHEN OTHERS
        THEN
            FND_FILE.PUT_LINE (FND_FILE.LOG, SQLCODE || ' - ' || SQLERRM);
            P_CUST_ACCT_SITE_ID := -1;
    END CREATE_CUST_ACCT_SITE;


    /*************************************************************************************************
     * Program Name : CREATE_CUST_ACCOUNT
     * Language     : PL/SQL
     * Description  : Creates the Customer and it's profile in HZ_ORGANIZATION_PROFILES Base table;
       (if Party Id is not available then It will creates the Party as well).
     * History      -----------------------------------------------------------------------------------
  * Parameters   : P_ORGANIZATION_NAME   => IN PARAMETER , VARCHAR2
       P_ACCOUNT_NAME    => IN PARAMETER , VARCHAR2
       P_ABC_TYPE     => IN PARAMETER , VARCHAR2
       P_AGENCY_ID     => IN PARAMETER , NUMBER
       P_CUSTOMER_TYPE    => IN PARAMETER , VARCHAR2
       P_CUSTOMER_CLASS_CODE  => IN PARAMETER , VARCHAR2
       P_UNIT      => IN PARAMETER , VARCHAR2
       P_PARTY_ID     => IN OUT PARAMETER , NUMBER
       P_CUST_ACCOUNT_ID   => OUT PARAMETER , NUMBER (FOR ERP CUST_ACCOUNT_ID)
       P_PARTY_NUMBER    => OUT PARAMETER , VARCHAR2 (FOR ERP PARTY_NUMBER)
       P_PROFILE_ID     => OUT PARAMETER , NUMBER (FOR ERP PROFILE_ID)
       P_ACCOUNT_NUMBER    => OUT PARAMETER , VARCHAR2 (FOR ERP ACCOUNT_NUMBER)
       P_MSG      => OUT PARAMETER , VARCHAR2 (FOR ERROR MESSAGE)
     *
     * WHO              Version #   WHEN            WHAT
     * ===============  =========   =============   ====================================================
     * AKALA            1.0         02-APR-2026     Initial Version
     * AKALA            1.1         09-APR-2026     Added paramters P_ABC_TYPE,  P_AGENCY_ID, P_CUSTOMER_TYPE,
													P_CUSTOMER_CLASS_CODE, P_UNIT
     * AKALA            1.2         13-APR-2026     Updated code to create the new customer if the customer already
													exists with the old name by concatenating  " ( New )" at the end of the customer name.
     ***************************************************************************************************/
    PROCEDURE CREATE_CUST_ACCOUNT (P_ORGANIZATION_NAME     IN     VARCHAR2,
                                   P_ACCOUNT_NAME          IN     VARCHAR2,
                                   P_ABC_TYPE              IN     VARCHAR2,
                                   P_AGENCY_ID             IN     NUMBER,
                                   P_CUSTOMER_TYPE         IN     VARCHAR2,
                                   P_CUSTOMER_CLASS_CODE   IN     VARCHAR2,
                                   P_UNIT                  IN     VARCHAR2,
                                   P_PARTY_ID              IN OUT NUMBER,
                                   P_CUST_ACCOUNT_ID          OUT NUMBER,
                                   P_PARTY_NUMBER             OUT VARCHAR2,
                                   P_PROFILE_ID               OUT NUMBER,
                                   P_ACCOUNT_NUMBER           OUT VARCHAR2,
                                   P_MSG                      OUT VARCHAR2)
    AS
        CUSTACCCOUNTREC   HZ_CUST_ACCOUNT_V2PUB.CUST_ACCOUNT_REC_TYPE;
        CUSTPROFILEREC    HZ_CUSTOMER_PROFILE_V2PUB.CUSTOMER_PROFILE_REC_TYPE;
        CUSTORGREC        HZ_PARTY_V2PUB.ORGANIZATION_REC_TYPE;
        CUSTPARTYREC      HZ_PARTY_V2PUB.PARTY_REC_TYPE;

        LC_PARTY_NUMBER   HZ_PARTIES.PARTY_NUMBER%TYPE;
        X_RETURN_STATUS   VARCHAR2 (100);
        X_MSG_COUNT       NUMBER;
        X_MSG_DATA        VARCHAR2 (4000);
    BEGIN
        P_ACCOUNT_NUMBER := NULL;
        P_PARTY_ID := NULL;
        P_CUST_ACCOUNT_ID := NULL;
		
		FND_GLOBAL.APPS_INITIALIZE (GN_USER_ID, GN_RESP_ID, GN_RESP_APPL_ID);
        MO_GLOBAL.INIT ('AR');
        --FND_CLIENT_INFO.SET_ORG_CONTEXT (GN_ORG_ID);
        MO_GLOBAL.SET_POLICY_CONTEXT ('S', GN_ORG_ID);

        CUSTACCCOUNTREC.ACCOUNT_NAME := P_ACCOUNT_NAME; --CREATE_CUSTOMER_REC.ACCOUNT_DESCRIPTION; -- CURSOR CREATE_CUST
        CUSTACCCOUNTREC.ATTRIBUTE19 := P_AGENCY_ID; --CREATE_CUSTOMER_REC.AGENCY_ID;
        CUSTACCCOUNTREC.ATTRIBUTE20 :=
            TO_CHAR (SYSDATE, 'DD-MON-YYYY HH24:MI:SS');
        CUSTACCCOUNTREC.ATTRIBUTE10 := P_ABC_TYPE; --CREATE_CUSTOMER_REC.ABC_TYPE;
        CUSTACCCOUNTREC.STATUS := 'A';
        CUSTACCCOUNTREC.ATTRIBUTE_CATEGORY := P_CUSTOMER_TYPE; --CREATE_CUSTOMER_REC.CUSTOMER_TYPE;
        CUSTACCCOUNTREC.CUSTOMER_TYPE := 'R';
        CUSTACCCOUNTREC.CUSTOMER_CLASS_CODE := P_CUSTOMER_CLASS_CODE; --CREATE_CUSTOMER_REC.CUSTOMER_CLASS_CODE;
        CUSTACCCOUNTREC.CREATED_BY_MODULE := 'BO_API';

        CUSTPARTYREC.STATUS := 'A';
        CUSTORGREC.ORGANIZATION_NAME := P_ORGANIZATION_NAME; --CREATE_CUSTOMER_REC.CUSTOMER_NAME;
        CUSTORGREC.PARTY_REC.ATTRIBUTE_CATEGORY := P_CUSTOMER_TYPE; --CREATE_CUSTOMER_REC.CUSTOMER_TYPE;
        CUSTORGREC.PARTY_REC.STATUS := 'A';
        CUSTORGREC.PARTY_REC.ATTRIBUTE20 := P_UNIT; --MAIN_UNIT1.UNIT; -- CURSOR MAIN_UNIT
        CUSTORGREC.PARTY_REC.ATTRIBUTE19 := P_ACCOUNT_NAME; --CREATE_CUSTOMER_REC.ACCOUNT_DESCRIPTION;
        CUSTORGREC.CREATED_BY_MODULE := 'BO_API';
        CUSTORGREC.PARTY_REC := CUSTPARTYREC;
        /*API to create customer account, party and customer profile*/
        HZ_CUST_ACCOUNT_V2PUB.CREATE_CUST_ACCOUNT (
            P_INIT_MSG_LIST          => 'T',
            P_CUST_ACCOUNT_REC       => CUSTACCCOUNTREC,
            P_ORGANIZATION_REC       => CUSTORGREC,
            P_CUSTOMER_PROFILE_REC   => CUSTPROFILEREC,
            P_CREATE_PROFILE_AMT     => 'F',
            X_CUST_ACCOUNT_ID        => P_CUST_ACCOUNT_ID,
            X_ACCOUNT_NUMBER         => P_ACCOUNT_NUMBER,
            X_PARTY_ID               => P_PARTY_ID,
            X_PARTY_NUMBER           => LC_PARTY_NUMBER,
            X_PROFILE_ID             => P_PROFILE_ID,
            X_RETURN_STATUS          => X_RETURN_STATUS,
            X_MSG_COUNT              => X_MSG_COUNT,
            X_MSG_DATA               => X_MSG_DATA);

        IF X_RETURN_STATUS = 'S'
        THEN
            FND_FILE.PUT_LINE (
                FND_FILE.LOG,
                'Creation of Party of Type Organization and customer account is Successful');
            FND_FILE.PUT_LINE (FND_FILE.LOG,
                               'x_cust_account_id :' || P_CUST_ACCOUNT_ID);
            FND_FILE.PUT_LINE (FND_FILE.LOG,
                               'x_account_number :' || P_ACCOUNT_NUMBER);
            FND_FILE.PUT_LINE (FND_FILE.LOG, 'x_party_id :' || P_PARTY_ID);
            FND_FILE.PUT_LINE (FND_FILE.LOG,
                               'x_party_number :' || LC_PARTY_NUMBER);
            FND_FILE.PUT_LINE (FND_FILE.LOG,
                               'x_profile_id :' || P_PROFILE_ID);
            COMMIT;
        ELSE
            FND_FILE.PUT_LINE (
                FND_FILE.LOG,
                   'Creation of Party of Type Organization and customer account failed:'
                || X_MSG_DATA);

            FOR i IN 1 .. X_MSG_COUNT
            LOOP
                X_MSG_DATA :=
                    FND_MSG_PUB.get (p_msg_index => i, p_encoded => 'F');
                FND_FILE.PUT_LINE (FND_FILE.LOG, i || ') ' || X_MSG_DATA);
                P_MSG := P_MSG || X_MSG_DATA || '; ';
            END LOOP;

            ROLLBACK;
            FND_FILE.PUT_LINE (FND_FILE.LOG, 'p_msg :) ' || P_MSG);
            FND_FILE.PUT_LINE (FND_FILE.LOG, 'p_msg complete...');
            P_CUST_ACCOUNT_ID := -1;

            -- Logic Added if Customer is Already exists then Append the name with - ' ( New )'
            IF UPPER (P_MSG) LIKE '%UNIQUE%CONSTRAINT%VIOLATED%'
            THEN
                BEGIN
                    P_ACCOUNT_NUMBER := NULL;
                    P_PARTY_ID := NULL;
                    P_CUST_ACCOUNT_ID := NULL;
                    P_MSG := NULL;

                    FND_FILE.PUT_LINE (FND_FILE.LOG,
                                       'Inside Exception : CUST_ACCOUNTS');

                    CUSTACCCOUNTREC.ACCOUNT_NAME :=
                        P_ACCOUNT_NAME || ' ( New )'; --CREATE_CUSTOMER_REC.ACCOUNT_DESCRIPTION; -- CURSOR CREATE_CUST
                    CUSTACCCOUNTREC.ATTRIBUTE19 := P_AGENCY_ID; --CREATE_CUSTOMER_REC.AGENCY_ID;
                    CUSTACCCOUNTREC.ATTRIBUTE20 :=
                        TO_CHAR (SYSDATE, 'DD-MON-YYYY HH24:MI:SS');
                    CUSTACCCOUNTREC.ATTRIBUTE10 := P_ABC_TYPE; --CREATE_CUSTOMER_REC.ABC_TYPE;
                    CUSTACCCOUNTREC.STATUS := 'A';
                    CUSTACCCOUNTREC.ATTRIBUTE_CATEGORY := P_CUSTOMER_TYPE; --CREATE_CUSTOMER_REC.CUSTOMER_TYPE;
                    CUSTACCCOUNTREC.CUSTOMER_TYPE := 'R';
                    CUSTACCCOUNTREC.CUSTOMER_CLASS_CODE :=
                        P_CUSTOMER_CLASS_CODE; --CREATE_CUSTOMER_REC.CUSTOMER_CLASS_CODE;
                    CUSTACCCOUNTREC.CREATED_BY_MODULE := 'BO_API';

                    CUSTPARTYREC.STATUS := 'A';
                    CUSTORGREC.ORGANIZATION_NAME :=
                        P_ORGANIZATION_NAME || ' ( New )'; --CREATE_CUSTOMER_REC.CUSTOMER_NAME;
                    CUSTORGREC.PARTY_REC.ATTRIBUTE_CATEGORY :=
                        P_CUSTOMER_TYPE;  --CREATE_CUSTOMER_REC.CUSTOMER_TYPE;
                    CUSTORGREC.PARTY_REC.STATUS := 'A';
                    CUSTORGREC.PARTY_REC.ATTRIBUTE20 := P_UNIT; --MAIN_UNIT1.UNIT; -- CURSOR MAIN_UNIT
                    CUSTORGREC.PARTY_REC.ATTRIBUTE19 :=
                        P_ACCOUNT_NAME || ' ( New )'; --CREATE_CUSTOMER_REC.ACCOUNT_DESCRIPTION;
                    CUSTORGREC.CREATED_BY_MODULE := 'BO_API';
                    CUSTORGREC.PARTY_REC := CUSTPARTYREC;
                    /*API to create customer account, party and customer profile*/
                    HZ_CUST_ACCOUNT_V2PUB.CREATE_CUST_ACCOUNT (
                        P_INIT_MSG_LIST          => 'T',
                        P_CUST_ACCOUNT_REC       => CUSTACCCOUNTREC,
                        P_ORGANIZATION_REC       => CUSTORGREC,
                        P_CUSTOMER_PROFILE_REC   => CUSTPROFILEREC,
                        P_CREATE_PROFILE_AMT     => 'F',
                        X_CUST_ACCOUNT_ID        => P_CUST_ACCOUNT_ID,
                        X_ACCOUNT_NUMBER         => P_ACCOUNT_NUMBER,
                        X_PARTY_ID               => P_PARTY_ID,
                        X_PARTY_NUMBER           => LC_PARTY_NUMBER,
                        X_PROFILE_ID             => P_PROFILE_ID,
                        X_RETURN_STATUS          => X_RETURN_STATUS,
                        X_MSG_COUNT              => X_MSG_COUNT,
                        X_MSG_DATA               => X_MSG_DATA);

                    IF X_RETURN_STATUS = 'S'
                    THEN
                        FND_FILE.PUT_LINE (
                            FND_FILE.LOG,
                            'Creation of Party of Type Organization and customer account is Successful');
                        FND_FILE.PUT_LINE (
                            FND_FILE.LOG,
                            'x_cust_account_id :' || P_CUST_ACCOUNT_ID);
                        FND_FILE.PUT_LINE (
                            FND_FILE.LOG,
                            'x_account_number :' || P_ACCOUNT_NUMBER);
                        FND_FILE.PUT_LINE (FND_FILE.LOG,
                                           'x_party_id :' || P_PARTY_ID);
                        FND_FILE.PUT_LINE (
                            FND_FILE.LOG,
                            'x_party_number :' || LC_PARTY_NUMBER);
                        FND_FILE.PUT_LINE (FND_FILE.LOG,
                                           'x_profile_id :' || P_PROFILE_ID);
                        COMMIT;
                    ELSE
                        FND_FILE.PUT_LINE (
                            FND_FILE.LOG,
                               'Creation of Party of Type Organization and customer account failed:'
                            || X_MSG_DATA);

                        FOR i IN 1 .. X_MSG_COUNT
                        LOOP
                            X_MSG_DATA :=
                                FND_MSG_PUB.get (p_msg_index   => i,
                                                 p_encoded     => 'F');
                            FND_FILE.PUT_LINE (FND_FILE.LOG,
                                               i || ') ' || X_MSG_DATA);
                            P_MSG := P_MSG || X_MSG_DATA || '; ';
                        END LOOP;

                        ROLLBACK;
                        P_CUST_ACCOUNT_ID := -1;
                        ROLLBACK;
                    END IF;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        FND_FILE.PUT_LINE (FND_FILE.LOG,
                                           SQLCODE || ' - ' || SQLERRM);
                        P_CUST_ACCOUNT_ID := -1;
                END;
            END IF;

            ROLLBACK;
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            FND_FILE.PUT_LINE (FND_FILE.LOG, SQLCODE || ' - ' || SQLERRM);
            P_CUST_ACCOUNT_ID := -1;
    END CREATE_CUST_ACCOUNT;


    /*************************************************************************************************
     * Program Name : CREATE_PARTY_SITE
     * Language     : PL/SQL
     * Description  : Creates Party Sites.
     * History      -----------------------------------------------------------------------------------
	 * Parameters   : P_PARTY_ID     => IN PARAMETER , NUMBER
       P_LOCATION_ID    => IN PARAMETER , NUMBER
       P_CUSTOMER_TYPE    => IN PARAMETER , VARCHAR2
       P_STATION_NAME    => IN PARAMETER , VARCHAR2
       P_PARTY_SITE_ID    => OUT PARAMETER , NUMBER (FOR ERP PARTY_SITE_ID)
       P_PARTY_SITE_NUM    => OUT PARAMETER , VARCHAR2 (FOR ERP PARTY_SITE_NUMBER)
       P_MSG      => OUT PARAMETER , VARCHAR2 (FOR ERROR MESSAGE)
     *
     * WHO              Version #   WHEN            WHAT
     * ===============  =========   =============   ====================================================
     * AKALA            1.0         06-APR-2026     Initial Version
     * AKALA            1.1         09-APR-2026     Added parameters for Customer Type and Station Name
     ***************************************************************************************************/
    PROCEDURE CREATE_PARTY_SITE (P_PARTY_ID         IN     NUMBER,
                                 P_LOCATION_ID      IN     NUMBER,
                                 P_CUSTOMER_TYPE    IN     VARCHAR2,
                                 P_STATION_NAME     IN     VARCHAR2,
                                 P_PARTY_SITE_ID       OUT NUMBER,
                                 P_PARTY_SITE_NUM      OUT VARCHAR2,
                                 P_MSG                 OUT VARCHAR2)
    AS
        L_PARTY_SITE_REC      HZ_PARTY_SITE_V2PUB.PARTY_SITE_REC_TYPE;
        L_PARTY_SITE_ID       HZ_PARTY_SITES.PARTY_SITE_ID%TYPE;
        L_PARTY_SITE_NUMBER   HZ_PARTY_SITES.PARTY_SITE_NUMBER%TYPE;
        L_RETURN_STATUS       VARCHAR2 (100);
        L_MSG_COUNT           NUMBER;
        L_MSG_DATA            VARCHAR2 (2000);
    BEGIN
        P_MSG := NULL;
        FND_FILE.PUT_LINE (FND_FILE.LOG, RPAD ('-', 25, '-'));
        --Initiate the EBS Environment for API processing
		FND_GLOBAL.APPS_INITIALIZE (GN_USER_ID, GN_RESP_ID, GN_RESP_APPL_ID);
        MO_GLOBAL.INIT ('AR');
        --FND_CLIENT_INFO.SET_ORG_CONTEXT (GN_ORG_ID);
        MO_GLOBAL.SET_POLICY_CONTEXT ('S', GN_ORG_ID);

        L_PARTY_SITE_REC.PARTY_ID := P_PARTY_ID;
        L_PARTY_SITE_REC.LOCATION_ID := P_LOCATION_ID;

        L_PARTY_SITE_REC.STATUS := 'A';
        L_PARTY_SITE_REC.ATTRIBUTE_CATEGORY := P_CUSTOMER_TYPE; --CREATE_CUSTOMER_REC.CUSTOMER_TYPE;
        L_PARTY_SITE_REC.PARTY_SITE_NAME := P_STATION_NAME; --CREATE_SITE_REC.STATION_NAME;
        L_PARTY_SITE_REC.CREATED_BY_MODULE := 'BO_API';

        HZ_PARTY_SITE_V2PUB.CREATE_PARTY_SITE (
            P_INIT_MSG_LIST       => FND_API.G_TRUE,
            P_PARTY_SITE_REC      => L_PARTY_SITE_REC,
            X_PARTY_SITE_ID       => L_PARTY_SITE_ID,
            X_PARTY_SITE_NUMBER   => L_PARTY_SITE_NUMBER,
            X_RETURN_STATUS       => L_RETURN_STATUS,
            X_MSG_COUNT           => L_MSG_COUNT,
            X_MSG_DATA            => L_MSG_DATA);

        FND_FILE.PUT_LINE (FND_FILE.LOG,
                           'API Status      :- ' || L_RETURN_STATUS);

        IF L_RETURN_STATUS = 'S'
        THEN
            FND_FILE.PUT_LINE (FND_FILE.LOG,
                               'Party Site Creation is Successful ');
            FND_FILE.PUT_LINE (FND_FILE.LOG,
                               'Party Site Number = ' || L_PARTY_SITE_NUMBER);
            FND_FILE.PUT_LINE (FND_FILE.LOG,
                               'Party Site Id = ' || L_PARTY_SITE_ID);
            COMMIT;
        ELSE
            FOR i IN 1 .. L_MSG_COUNT
            LOOP
                l_msg_data :=
                    FND_MSG_PUB.get (p_msg_index => i, p_encoded => 'F');
                FND_FILE.PUT_LINE (FND_FILE.LOG, i || ') ' || l_msg_data);
                P_MSG := P_MSG || l_msg_data || '; ';
            END LOOP;

            ROLLBACK;
            L_PARTY_SITE_ID := -1;
        END IF;

        P_PARTY_SITE_ID := L_PARTY_SITE_ID;
    EXCEPTION
        WHEN OTHERS
        THEN
            FND_FILE.PUT_LINE (FND_FILE.LOG, SQLCODE || ' - ' || SQLERRM);
            P_PARTY_SITE_ID := -1;
    END CREATE_PARTY_SITE;


    /*************************************************************************************************
     * Program Name : CREATE_PARTY
     * Language     : PL/SQL
     * Description  : Creates Party.
     * History      -----------------------------------------------------------------------------------
	 * Parameters   : P_ORGANIZATION_NAME  => IN PARAMETER , VARCHAR2
       P_PARTY_ID    => OUT PARAMETER , NUMBER (FOR ERP PARTY_ID)
       P_PARTY_NUMBER   => OUT PARAMETER , NUMBER (FOR ERP PARTY_NUMBER)
       P_PROFILE_ID    => OUT PARAMETER , NUMBER (FOR ERP PROFILE_ID)
       P_MSG     => OUT PARAMETER , VARCHAR2 (FOR ERROR MESSAGE)
     *
     * WHO              Version #   WHEN            WHAT
     * ===============  =========   =============   ====================================================
     * AKALA            1.0         2-APR-2026     Initial Version
     ***************************************************************************************************/
    PROCEDURE CREATE_PARTY (P_ORGANIZATION_NAME   IN     VARCHAR2,
                            P_PARTY_ID               OUT NUMBER,
                            P_PARTY_NUMBER           OUT VARCHAR2,
                            P_PROFILE_ID             OUT NUMBER,
                            P_MSG                    OUT VARCHAR2)
    AS
        L_ORGANIZATION_REC   HZ_PARTY_V2PUB.ORGANIZATION_REC_TYPE;
        L_PARTY_ID           HZ_PARTIES.PARTY_ID%TYPE;
        L_PARTY_NUMBER       HZ_PARTIES.PARTY_NUMBER%TYPE;
        L_PROFILE_ID         HZ_ORGANIZATION_PROFILES.ORGANIZATION_PROFILE_ID%TYPE;
        L_RETURN_STATUS      VARCHAR2 (100);
        L_MSG_COUNT          NUMBER;
        L_MSG_DATA           VARCHAR2 (2000);
    BEGIN
        DBMS_OUTPUT.ENABLE (buffer_size => NULL);
        P_MSG := NULL;
        FND_FILE.PUT_LINE (FND_FILE.LOG, RPAD ('-', 25, '-'));
        --Initiate the EBS Environment for API processing
		FND_GLOBAL.APPS_INITIALIZE (GN_USER_ID, GN_RESP_ID, GN_RESP_APPL_ID);
        MO_GLOBAL.INIT ('AR');
        --FND_CLIENT_INFO.SET_ORG_CONTEXT (GN_ORG_ID);
        MO_GLOBAL.SET_POLICY_CONTEXT ('S', GN_ORG_ID);
		
		-- API Parameters initialization...
        L_ORGANIZATION_REC.ORGANIZATION_NAME := P_ORGANIZATION_NAME; --'XYZ Corporation Dummy';
        L_ORGANIZATION_REC.CREATED_BY_MODULE := 'HZ_CPUI';
        --FND_FILE.PUT_LINE(FND_FILE.LOG,'Calling hz_party_v2pub.create_organization API');
        --Call hz_party_v2pub.create_organization
        hz_party_v2pub.create_organization (
            p_init_msg_list      => FND_API.G_TRUE,
            p_organization_rec   => l_organization_rec,
            x_return_status      => l_return_status,
            x_msg_count          => l_msg_count,
            x_msg_data           => l_msg_data,
            x_party_id           => l_party_id,
            x_party_number       => l_party_number,
            x_profile_id         => l_profile_id);

        IF l_return_status = 'S'
        THEN
            FND_FILE.PUT_LINE (FND_FILE.LOG,
                               'Organization Creation is Successful ');
            FND_FILE.PUT_LINE (FND_FILE.LOG,
                               'Party Id         =' || l_party_id);
            FND_FILE.PUT_LINE (FND_FILE.LOG,
                               'Party Number     =' || l_party_number);
            FND_FILE.PUT_LINE (FND_FILE.LOG,
                               'Profile Id       =' || l_profile_id);
            P_PARTY_NUMBER := l_party_number;
            P_PROFILE_ID := l_profile_id;
            COMMIT;
        ELSE
            FND_FILE.PUT_LINE (
                FND_FILE.LOG,
                'Creation of Organization failed:' || l_msg_data);

            FOR i IN 1 .. l_msg_count
            LOOP
                l_msg_data :=
                    FND_MSG_PUB.get (p_msg_index => i, p_encoded => 'F');
                FND_FILE.PUT_LINE (FND_FILE.LOG, i || ') ' || l_msg_data);
                P_MSG := P_MSG || L_MSG_DATA || '; ';
            END LOOP;

            ROLLBACK;
            L_PARTY_ID := -1;
        END IF;

        P_PARTY_ID := L_PARTY_ID;
    EXCEPTION
        WHEN OTHERS
        THEN
            FND_FILE.PUT_LINE (FND_FILE.LOG, SQLCODE || ' - ' || SQLERRM);
            P_PARTY_ID := -1;
    END CREATE_PARTY;


    /*************************************************************************************************
     * Program Name : CREATE_LOCATION
     * Language     : PL/SQL
     * Description  : Creates Location.
     * History      -----------------------------------------------------------------------------------
  * Parameters   : P_ADDRESS1   => IN PARAMETER , VARCHAR2
  *                P_ADDRESS2   => IN PARAMETER , VARCHAR2
  *                P_ADDRESS3   => IN PARAMETER , VARCHAR2
  *                P_ADDRESS4   => IN PARAMETER , VARCHAR2
  *                P_CITY    => IN PARAMETER , VARCHAR2
  *                P_POSTAL_CODE  => IN PARAMETER , NUMBER
  *                P_STATE    => IN PARAMETER , VARCHAR2
  *                P_COUNTY    => IN PARAMETER , VARCHAR2
  *                P_COUNTRY   => IN PARAMETER , VARCHAR2
  *                P_LOCATION1   => IN PARAMETER , VARCHAR2
       P_LOCATION_ID  => OUT PARAMETER , NUMBER (FOR ERP LOCATION_ID)
       P_MSG    => OUT PARAMETER , VARCHAR2 (FOR ERROR MESSAGE)
     *
     * WHO              Version #   WHEN            WHAT
     * ===============  =========   =============   ====================================================
     * AKALA            1.0         06-APR-2026     Initial Version
     * AKALA            1.2         09-APR-2026     Added a paramter P_LOCATION1 for accurate location name
     ***************************************************************************************************/
    PROCEDURE CREATE_LOCATION (P_ADDRESS1      IN     VARCHAR2,
                               P_ADDRESS2      IN     VARCHAR2,
                               P_ADDRESS3      IN     VARCHAR2,
                               P_ADDRESS4      IN     VARCHAR2,
                               P_CITY          IN     VARCHAR2,
                               P_POSTAL_CODE   IN     NUMBER,
                               P_STATE         IN     VARCHAR2,
                               P_COUNTY        IN     VARCHAR2,
                               P_COUNTRY       IN     VARCHAR2,
                               P_LOCATION1     IN     VARCHAR2,
                               P_LOCATION_ID      OUT NUMBER,
                               P_MSG              OUT VARCHAR2)
    IS
        L_LOCATION_REC    HZ_LOCATION_V2PUB.LOCATION_REC_TYPE;
        X_RETURN_STATUS   VARCHAR2 (100);
        X_MSG_COUNT       NUMBER;
        X_MSG_DATA        VARCHAR2 (4000);
        L_MSG_DATA        VARCHAR2 (4000);
    BEGIN
        P_MSG := NULL;
        FND_FILE.PUT_LINE (FND_FILE.LOG, RPAD ('-', 25, '-'));
        --INITIATE THE EBS ENVIRONMENT FOR API PROCESSING
		FND_GLOBAL.APPS_INITIALIZE (GN_USER_ID, GN_RESP_ID, GN_RESP_APPL_ID);
        MO_GLOBAL.INIT ('AR');
        --FND_CLIENT_INFO.SET_ORG_CONTEXT (GN_ORG_ID);
        MO_GLOBAL.SET_POLICY_CONTEXT ('S', GN_ORG_ID);

		-- API Parameter initialization ..
        L_LOCATION_REC.ADDRESS1 := P_ADDRESS1;     --CREATE_SITE_REC.ADDRESS1;
        L_LOCATION_REC.ADDRESS2 := P_ADDRESS2;     --CREATE_SITE_REC.ADDRESS2;
        L_LOCATION_REC.ADDRESS3 := P_ADDRESS3;     --CREATE_SITE_REC.ADDRESS3;
        L_LOCATION_REC.ADDRESS4 := P_ADDRESS4;     --CREATE_SITE_REC.ADDRESS4;
        L_LOCATION_REC.CITY := P_CITY;                 --CREATE_SITE_REC.CITY;
        L_LOCATION_REC.POSTAL_CODE := P_POSTAL_CODE; --CREATE_SITE_REC.POSTAL_CODE;
        L_LOCATION_REC.STATE := P_STATE;              --CREATE_SITE_REC.STATE;
        L_LOCATION_REC.COUNTRY := P_COUNTRY;        --CREATE_SITE_REC.COUNTRY;
        L_LOCATION_REC.CREATED_BY_MODULE := 'BO_API';
        L_LOCATION_REC.DESCRIPTION := P_LOCATION1; --CREATE_SITE_REC.LOCATION1;
        L_LOCATION_REC.COUNTY := P_COUNTY;           --CREATE_SITE_REC.COUNTY;
        HZ_LOCATION_V2PUB.CREATE_LOCATION (
            P_INIT_MSG_LIST   => FND_API.G_TRUE,
            P_LOCATION_REC    => L_LOCATION_REC,
            X_LOCATION_ID     => P_LOCATION_ID,
            X_RETURN_STATUS   => X_RETURN_STATUS,
            X_MSG_COUNT       => X_MSG_COUNT,
            X_MSG_DATA        => X_MSG_DATA);

        FND_FILE.PUT_LINE (FND_FILE.LOG,
                           'API Status      :- ' || x_return_status);

        IF X_RETURN_STATUS = 'S'
        THEN
            FND_FILE.PUT_LINE (FND_FILE.LOG,
                               'Location Creation is Successful ');
            FND_FILE.PUT_LINE (FND_FILE.LOG,
                               'Location Id = ' || P_LOCATION_ID);
            COMMIT;
        ELSE
            FOR i IN 1 .. X_MSG_COUNT
            LOOP
                L_MSG_DATA :=
                    FND_MSG_PUB.GET (P_MSG_INDEX => I, P_ENCODED => 'F');
                FND_FILE.PUT_LINE (FND_FILE.LOG, I || ') ' || L_MSG_DATA);
                P_MSG := P_MSG || L_MSG_DATA || '; ';
            END LOOP;

            ROLLBACK;
            P_LOCATION_ID := -1;
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            P_LOCATION_ID := -1;
            FND_FILE.PUT_LINE (FND_FILE.LOG, SQLCODE || ' - ' || SQLERRM);
    END CREATE_LOCATION;


    /*************************************************************************************************
     * Program Name : CREATE_SAFALTA_CUST_AND_SITES
     * Language     : PL/SQL
     * Description  : Creates Customer and Sites only for Safalta Prouct.
     * History      -----------------------------------------------------------------------------------
	* Parameters   :
     *
     * WHO              Version #   WHEN            WHAT
     * ===============  =========   =============   ====================================================
     * AKALA            1.0         07-APR-2026     Initial Version
     * AKALA            1.1         08-APR-2026     1. Updated for Creation customer account according to the Name of Center
													2. Added logic for CREATE_CODE_COMBINATION
	 * AKALA            1.2         09-APR-2026     Updated the logic according to XXAU_CUSTOMER_DETAILS@ebstohr TABLE
	 * AKALA            1.3         10-APR-2026     1. Added variable LN_CCID_S for Code Combination ID fetched while creating Site Uses
													2. Update the logic to create or get CCID if it is not created inside CREATE_CUST_SITE_USE
	 * AKALA            1.4         20-APR-2026     Updated the logic according to Package to Update data into Custom TABLE
	 * AKALA            1.5         21-APR-2026     Updated the logic for error message, removed Decode;
     ***************************************************************************************************/
    PROCEDURE CREATE_SAFALTA_CUST_AND_SITES
    AS
        LN_LOCATION_ID              HZ_LOCATIONS.LOCATION_ID%TYPE;
        LN_LOC_ID                   HZ_LOCATIONS.LOCATION_ID%TYPE;
        LN_PARTY_ID                 HZ_PARTIES.PARTY_ID%TYPE;
        LN_PARTY_SITE_ID            HZ_PARTY_SITES.PARTY_SITE_ID%TYPE;
        LN_CUST_ACCOUNT_ID          HZ_CUST_ACCOUNTS.CUST_ACCOUNT_ID%TYPE;
        LN_ACCOUNT_NUMBER           HZ_CUST_ACCOUNTS.ACCOUNT_NUMBER%TYPE;
        LN_CUST_ACCT_SITE_ID        HZ_CUST_ACCT_SITES_ALL.CUST_ACCT_SITE_ID%TYPE;
        LN_SITE_USE_ID              HZ_CUST_SITE_USES_ALL.SITE_USE_ID%TYPE;

        CURSOR C1 IS
            (SELECT DISTINCT
                    CUSTOMER_NAME,
                    B.UNIT,
                    B.CUSTOMER_TYPE,
                    B.CUSTOMER_CLASS
                        CUSTOMER_CLASS_CODE,
                    B.MOBILE_NO,
                    B.CONTACT_PERSON,
                    NVL (B.ACCOUNT_DESCRIPTION, B.CUSTOMER_NAME)
                        ACCOUNT_DESCRIPTION,
                    B.ABC_TYPE,
                    B.OLD_PARTY_ID,
                    B.OLD_CUSTOMER_ID,
                    B.AGENCY_ID,
                    A.AGENCY_NAME,
                    A.ERP_PROCESS_FLAG,
                    A.ERP_ERR_MSG
               FROM AU_CUSTOMER_MASTER_NEW@ebstohr  A,
                    XXAU_CUSTOMER_DETAILS@ebstohr  B
              WHERE     A.AGENCY_ID IN
                            (SELECT AGENCY_ID
                               FROM XXAU_AGENCY_APPROVAL_DETIALS@ebstohr
                              WHERE     TRUNC (CREATION_DATE) >=
                                        '01-OCT-2024'
                                    AND APPROVE_REJECT = 'A'
                                    AND AGREEMENT_FLAG = 'Y')
                    --AND A.ERP_PARTY_ID IS NULL
                    --AND A.ERP_CUSTOMER_NUMBER IS NULL
                    --AND A.ERP_CUSTOMER_ID IS NULL
                    AND A.AGENCY_ID = B.AGENCY_ID
                    AND EXISTS
                            (SELECT 1
                               FROM AU_CUSTOMER_SHIP_TO@ebstohr
                              WHERE     AGENCY_ID = A.AGENCY_ID
                                    AND UPPER (PROUCT_NAME) LIKE '%SAFALTA%'
                                    AND ERP_CUSTOMER_NUMBER IS NULL
                                    AND ERP_SITE_USE_ID IS NULL)
                    AND B.CUSTOMER_TYPE LIKE '%SAFALTA%'
                    AND B.PROCESS_FLAG = 'P');

        CURSOR C2 (P_AGENCY_ID      NUMBER,
                   P_CUST_NAME      VARCHAR2,
                   P_UNIT           VARCHAR2,
                   P_CUST_TYPE      VARCHAR2,
                   P_ACCOUNT_DESC   VARCHAR2)
        IS
            (SELECT A.AGENCY_ID,
                    A.CENTRE_NUMBER,
                    A.MAIN_CENTRE_NUMBER,
                    A.INV_ORG,
                    A.ORG_ID,
                    A.MOBILE_NO,
                    A.EMAIL,
                    B.CUSTOMER_NAME,
                    B.UNIT,
                    B.CUSTOMER_TYPE,
                    B.CUSTOMER_CLASS
                        CUSTOMER_CALSS_CODE,
                    B.ADDRESS1,
                    B.ADDRESS2,
                    B.ADDRESS3,
                    B.ADDRESS4,
                    B.CITY,
                    B.STATE,
                    DECODE (UPPER (B.COUNTRY),
                            'INDIA', 'IN',
                            UPPER (B.COUNTRY))
                        COUNTRY,
                    B.COUNTY,
                    B.LOCATION1,
                    B.STATION_NAME,
                    A.NAME_OF_CENTRE,
                    B.PINCODE
                        POSTAL_CODE,
                    'SHIP_TO'
                        SITE_USE_CODE,
                    DECODE (UPPER (B.PRIMARY_SITE_FALG), 'YES', 'Y', 'N')
                        PRIMARY_FLAG,
                    'A'
                        STATUS,
                    B.REC_ACCOUNT,
                    B.PAYMENT_TERMS,
                    A.ERP_PROCESS_FLAG,
                    A.ERP_ERR_MSG,
                    A.CCID
               FROM AU_CUSTOMER_SHIP_TO@ebstohr A
			   , XXAU_CUSTOMER_DETAILS@ebstohr B
              WHERE     A.AGENCY_ID IN
                            (SELECT AGENCY_ID
                               FROM XXAU_AGENCY_APPROVAL_DETIALS@ebstohr
                              WHERE     TRUNC (CREATION_DATE) >=
                                        '01-OCT-2024'
                                    AND APPROVE_REJECT = 'A'
                                    AND AGREEMENT_FLAG = 'Y')
                    AND UPPER (PROUCT_NAME) LIKE '%SAFALTA%'
                    AND A.AGENCY_ID = B.AGENCY_ID
                    AND A.CENTRE_NUMBER = B.CENTRE_NUMBER -- Added to reduce the number of lines; on 13-APR-2026
                    AND CUSTOMER_SHIP_ID IS NULL
                    AND ERP_PARTY_ID IS NULL
                    AND ERP_SITE_USE_ID IS NULL
                    AND ERP_CUSTOMER_NUMBER IS NULL
                    AND ERP_CUSTOMER_ID IS NULL
                    AND B.CUSTOMER_TYPE LIKE '%SAFALTA%'
					AND A.ERP_PROCESS_FLAG IS NULL
                    AND A.AGENCY_ID = P_AGENCY_ID
                    AND B.CUSTOMER_TYPE = P_CUST_TYPE
                    AND B.UNIT = P_UNIT
                    AND B.CUSTOMER_NAME = P_CUST_NAME
                    AND B.ACCOUNT_DESCRIPTION = P_ACCOUNT_DESC
                    AND B.PROCESS_FLAG = 'P');

        LC_MSG                      VARCHAR2 (4000);
        LC_ERR_MSG                  VARCHAR2 (4000);
        LC_ACCOUNT_NUMBER           VARCHAR2 (200);
        LC_PARTY_NUMBER             VARCHAR2 (200);
        LC_PARTY_SITE_NUM           VARCHAR2 (200);
        LN_PROFILE_ID               NUMBER;
        LN_CCID                     NUMBER; -- Added by AKALA on 08-APR-2026 for CODE_COMBINATION_ID
        LN_CCID_S                   NUMBER; -- Added by AKALA on 08-APR-2026 for CODE_COMBINATION_ID
        LN_PHONE_CONTACT_POINT_ID   NUMBER;
        LN_EMAIL_CONTACT_POINT_ID   NUMBER;
    BEGIN
        FND_FILE.PUT_LINE (FND_FILE.LOG, RPAD ('*', 30, '*'));
        FND_FILE.PUT_LINE (FND_FILE.LOG, 'In CREATE_SAFALTA_CUST_AND_SITES');

        FOR I IN C1
        LOOP
            FND_FILE.PUT_LINE (FND_FILE.LOG, RPAD ('+', 25, '+'));

            FOR J IN C2 (P_AGENCY_ID      => I.AGENCY_ID,
                         P_CUST_NAME      => I.CUSTOMER_NAME,
                         P_UNIT           => I.UNIT,
                         P_CUST_TYPE      => I.CUSTOMER_TYPE,
                         P_ACCOUNT_DESC   => I.ACCOUNT_DESCRIPTION)
            LOOP
                LN_CUST_ACCOUNT_ID := -1;
                LN_LOCATION_ID := -1;
                LN_PARTY_ID := -1;
                LN_PARTY_SITE_ID := -1;
                LN_CUST_ACCT_SITE_ID := -1;
                LN_SITE_USE_ID := -1;
                I.ERP_ERR_MSG := NULL;
                I.ERP_PROCESS_FLAG := 'S';
                J.ERP_ERR_MSG := NULL;
                J.ERP_PROCESS_FLAG := 'S';
                LN_CCID := NULL;

                BEGIN
                    CREATE_CUST_ACCOUNT (
                        P_ORGANIZATION_NAME     =>
                            I.CUSTOMER_NAME || '- New Safalta Unit',
                        P_ACCOUNT_NAME          => I.ACCOUNT_DESCRIPTION,
                        P_ABC_TYPE              => I.ABC_TYPE,
                        P_AGENCY_ID             => I.AGENCY_ID,
                        P_CUSTOMER_TYPE         => I.CUSTOMER_TYPE,
                        P_CUSTOMER_CLASS_CODE   => I.CUSTOMER_CLASS_CODE,
                        P_UNIT                  => I.UNIT,
                        P_PARTY_ID              => LN_PARTY_ID,
                        P_CUST_ACCOUNT_ID       => LN_CUST_ACCOUNT_ID,
                        P_PARTY_NUMBER          => LC_PARTY_NUMBER,
                        P_PROFILE_ID            => LN_PROFILE_ID,
                        P_ACCOUNT_NUMBER        => LC_ACCOUNT_NUMBER,
                        P_MSG                   => LC_MSG);

                    LC_ERR_MSG := LC_MSG;
                    J.ERP_ERR_MSG := REG_ERR_MSG (J.ERP_ERR_MSG, LC_MSG);

                    FND_FILE.PUT_LINE (
                        FND_FILE.LOG,
                           'LN_CUST_ACCOUNT_ID: '
                        || LN_CUST_ACCOUNT_ID
                        || '; PARTY_ID: '
                        || LN_PARTY_ID);

                    IF LN_CUST_ACCOUNT_ID > 0 AND LN_PARTY_ID > 0
                    THEN
                        BEGIN
                            -- Resetting the Variables For Correct Values And Updation
                            BEGIN
                                SELECT LOCATION_ID
                                  INTO LN_LOCATION_ID
                                  FROM HZ_LOCATIONS
                                 WHERE     1 = 1
                                       AND ADDRESS1 = J.ADDRESS1
                                       AND CITY = J.CITY
                                       AND DESCRIPTION = J.NAME_OF_CENTRE --J.LOCATION1
                                                                         ;
                            EXCEPTION
                                WHEN OTHERS
                                THEN
                                    CREATE_LOCATION (
                                        P_ADDRESS1      => J.ADDRESS1,
                                        P_ADDRESS2      => J.ADDRESS2,
                                        P_ADDRESS3      => J.ADDRESS3,
                                        P_ADDRESS4      => J.ADDRESS4,
                                        P_CITY          => J.CITY,
                                        P_POSTAL_CODE   => J.POSTAL_CODE,
                                        P_STATE         => J.STATE,
                                        P_COUNTY        => J.COUNTY,
                                        P_COUNTRY       => J.COUNTRY,
                                        P_LOCATION1     => J.NAME_OF_CENTRE --J.LOCATION1
                                                                           ,
                                        P_LOCATION_ID   => LN_LOCATION_ID,
                                        P_MSG           => LC_MSG);
                                    J.ERP_ERR_MSG :=
                                        REG_ERR_MSG (J.ERP_ERR_MSG, LC_MSG);
                            END;

                            IF LN_LOCATION_ID > 0
                            THEN
                                BEGIN
                                    SELECT PARTY_SITE_ID
                                      INTO LN_PARTY_SITE_ID
                                      FROM HZ_PARTY_SITES
                                     WHERE     1 = 1
                                           AND PARTY_ID = LN_PARTY_ID
                                           AND LOCATION_ID = LN_LOCATION_ID
                                           AND PARTY_SITE_NAME =
                                               J.STATION_NAME;
                                EXCEPTION
                                    WHEN OTHERS
                                    THEN
                                        CREATE_PARTY_SITE (
                                            P_PARTY_ID         => LN_PARTY_ID,
                                            P_LOCATION_ID      => LN_LOCATION_ID,
                                            P_CUSTOMER_TYPE    =>
                                                I.CUSTOMER_TYPE,
                                            P_STATION_NAME     => J.STATION_NAME,
                                            P_PARTY_SITE_ID    =>
                                                LN_PARTY_SITE_ID,
                                            P_PARTY_SITE_NUM   =>
                                                LC_PARTY_SITE_NUM,
                                            P_MSG              => LC_MSG);
                                        J.ERP_ERR_MSG :=
                                            REG_ERR_MSG (J.ERP_ERR_MSG,
                                                         LC_MSG);
                                END;
                            ELSE
                                J.ERP_PROCESS_FLAG := 'E';
                                J.ERP_ERR_MSG :=
                                    REG_ERR_MSG (
                                        J.ERP_ERR_MSG,
                                           'Location Error for: Party ID - '
                                        || LN_PARTY_ID
                                        || ', Location1 - '
                                        || J.LOCATION1
                                        || ', NAME_OF_CENTRE - '
                                        || J.NAME_OF_CENTRE);
                            END IF;

                            -- Creating Customer Account Site
                            IF LN_PARTY_SITE_ID > 0
                            THEN
                                BEGIN
                                    SELECT CUST_ACCT_SITE_ID
                                      INTO LN_CUST_ACCT_SITE_ID
                                      FROM HZ_CUST_ACCT_SITES_ALL
                                     WHERE     1 = 1
                                           AND CUST_ACCOUNT_ID =
                                               LN_CUST_ACCOUNT_ID
                                           AND PARTY_SITE_ID =
                                               LN_PARTY_SITE_ID;
                                EXCEPTION
                                    WHEN OTHERS
                                    THEN
                                        CREATE_CUST_ACCT_SITE (
                                            P_CUST_ACCOUNT_ID   =>
                                                LN_CUST_ACCOUNT_ID,
                                            P_PARTY_SITE_ID   =>
                                                LN_PARTY_SITE_ID,
                                            P_CUSTOMER_TYPE   =>
                                                I.CUSTOMER_TYPE,
                                            P_CUST_ACCT_SITE_ID   =>
                                                LN_CUST_ACCT_SITE_ID,
                                            P_MSG   => LC_MSG);
                                        J.ERP_ERR_MSG :=
                                            REG_ERR_MSG (J.ERP_ERR_MSG,
                                                         LC_MSG);
                                END;
                            ELSE
                                J.ERP_PROCESS_FLAG := 'E';
                                J.ERP_ERR_MSG :=
                                    REG_ERR_MSG (
                                        J.ERP_ERR_MSG,
                                           'Party Site Error for : Station Name - '
                                        || J.STATION_NAME
                                        || ', Party ID - '
                                        || LN_PARTY_ID
                                        || ', Location ID - '
                                        || LN_LOCATION_ID);
                            END IF;


                            IF LN_CUST_ACCT_SITE_ID > 0
                            THEN
                                CREATE_CUST_SITE_USES (
                                    P_CUST_ACCT_SITE_ID   =>
                                        LN_CUST_ACCT_SITE_ID,
                                    P_SITE_USE_CODE   => 'SHIP_TO',
                                    P_CUSTOMER_TYPE   => I.CUSTOMER_TYPE,
                                    P_LOCATION        => J.NAME_OF_CENTRE --J.LOCATION1
                                                                         ,
                                    P_CENTRE_NUMBER   => J.CENTRE_NUMBER,
                                    P_PRIMARY_FLAG    => J.PRIMARY_FLAG,
                                    P_PAYMENT_TERMS   => J.PAYMENT_TERMS,
                                    P_REC_ACCOUNT     => J.REC_ACCOUNT,
                                    P_SITE_USE_ID     => LN_SITE_USE_ID,
                                    P_CCID            => LN_CCID_S -- Added to retrive the CODE_COMBINATION_ID
                                                                  ,
                                    P_MSG             => LC_MSG);
                                J.ERP_ERR_MSG :=
                                    REG_ERR_MSG (J.ERP_ERR_MSG, LC_MSG);

                                IF LN_SITE_USE_ID < 0
                                THEN
                                    J.ERP_PROCESS_FLAG := 'E';
                                    J.ERP_ERR_MSG :=
                                        REG_ERR_MSG (
                                            J.ERP_ERR_MSG,
                                               'Site Use Error for : Location1 - '
                                            || J.LOCATION1
                                            || ', Center Number - '
                                            || J.CENTRE_NUMBER);
                                END IF;

                                CREATE_CONTACT_ORG (
                                    P_PARTY_ID         => LN_PARTY_ID,
                                    P_CONTACT_PERSON   => I.CONTACT_PERSON,
                                    P_MSG              => LC_MSG);
                                J.ERP_ERR_MSG :=
                                    REG_ERR_MSG (J.ERP_ERR_MSG, LC_MSG);
                                -- start: Creating Contact Point -- Added on 07-APR-2026
                                CREATE_CONTACT_POINT_SITE_LVL (
                                    P_PARTY_SITE_ID            => LN_PARTY_SITE_ID,
                                    P_PHONE                    => J.MOBILE_NO,
                                    P_EMAIL                    => J.EMAIL,
                                    P_TABLE                    => 'HZ_PARTY_SITES',
                                    P_PHONE_CONTACT_POINT_ID   =>
                                        LN_PHONE_CONTACT_POINT_ID,
                                    P_EMAIL_CONTACT_POINT_ID   =>
                                        LN_EMAIL_CONTACT_POINT_ID,
                                    P_MSG                      => LC_MSG);
                                J.ERP_ERR_MSG :=
                                    REG_ERR_MSG (J.ERP_ERR_MSG, LC_MSG);

                                IF LN_PHONE_CONTACT_POINT_ID < 0
                                THEN
                                    FND_FILE.PUT_LINE (
                                        FND_FILE.LOG,
                                           'Cannot create Phone Cotact Point : '
                                        || J.MOBILE_NO);
                                END IF;

                                IF LN_EMAIL_CONTACT_POINT_ID < 0
                                THEN
                                    FND_FILE.PUT_LINE (
                                        FND_FILE.LOG,
                                           'Cannot create Email Cotact Point : '
                                        || J.EMAIL);
                                END IF;

                                -- end : Added Email and Phone contact points on 07-APR-2026

                                FND_FILE.PUT_LINE (FND_FILE.LOG,
                                                   RPAD ('_', 25, '_'));
                                LN_CCID := -1;

                                --Start:  Added by AKALA on 10-APR-2026, create or get CCID if it is not created inside CREATE_CUST_SITE_USE
                                IF LN_CCID_S < 0
                                THEN
                                    BEGIN
                                        SELECT CODE_COMBINATION_ID
                                          INTO LN_CCID
                                          FROM GL_CODE_COMBINATIONS_KFV
                                         WHERE CONCATENATED_SEGMENTS =
                                               J.REC_ACCOUNT;
                                    EXCEPTION
                                        WHEN OTHERS
                                        THEN
                                            --Start:  Added by AKALA on 08-APR-2026, to create or get CCID
                                            CREATE_CODE_COMBINATION (
                                                P_ORG_ID        => J.ORG_ID,
                                                P_INV_ORG       => J.INV_ORG,
                                                P_AGENCY_ID     => J.AGENCY_ID,
                                                P_CENTRE_NUMBER   =>
                                                    J.CENTRE_NUMBER,
                                                P_AGENCY_NAME   =>
                                                    I.AGENCY_NAME,
                                                P_CCID          => LN_CCID,
                                                P_MSG           => LC_MSG);
                                            J.ERP_ERR_MSG :=
                                                REG_ERR_MSG (J.ERP_ERR_MSG,
                                                             LC_MSG);
                                            FND_FILE.PUT_LINE (
                                                FND_FILE.LOG,
                                                   'Retrived Code Combination ID : '
                                                || LN_CCID);
                                    -- END :  Added by AKALA on 08-APR-2026, to create or get CCID
                                    END;
                                ELSE
                                    LN_CCID := LN_CCID_S;
                                END IF;

                                -- END :  Added by AKALA on 10-APR-2026, to create or get CCID before creating the SITE USES


                                LC_ERR_MSG := LC_ERR_MSG || '-' || LC_MSG;
                            ELSE
                                J.ERP_PROCESS_FLAG := 'E';
                                J.ERP_ERR_MSG :=
                                    REG_ERR_MSG (
                                        J.ERP_ERR_MSG,
                                           'Cust Acct Site Error for : CUST_ACCOUNT_ID - '
                                        || LN_CUST_ACCOUNT_ID
                                        || ', PARTY_SITE_ID - '
                                        || LN_PARTY_SITE_ID);
                            END IF;

                            -- Updating AU_CUSTOMER_SHIP_TO@ebstohr on Successful Creation of every Site and Uses

							-- Added by AKALA on 20-APR-2026; because the new package is created to update data in AU_CUSTOMER_SHIP_TO base tables.
							XXAU_UPDT_CUSTOM_CUST_DATA_PKG.UPDATE_CUSTS_SHIP_SITES@EBSTOHR( P_ACCOUNT_NUMBER => LC_ACCOUNT_NUMBER, 
																							P_CUST_ACCT_SITE_ID => LN_CUST_ACCT_SITE_ID,
																							P_SITE_USE_ID => LN_SITE_USE_ID,
																							P_CUST_ACCOUNT_ID => LN_CUST_ACCOUNT_ID,
																							P_PARTY_ID => LN_PARTY_ID,
																							P_PROCESS_FLAG => J.ERP_PROCESS_FLAG,
																							P_CCID => LN_CCID,
																							P_ERR_MSG => J.ERP_ERR_MSG ,
																							P_AGENCY_ID => J.AGENCY_ID,
																							P_CENTRE_NUMBER => J.CENTRE_NUMBER,
																							P_MAIN_CENTRE_NUMBER => J.MAIN_CENTRE_NUMBER
									);
							COMMIT;
							
							/* Commented by AKALA on 20-APR-2026;
                            UPDATE AU_CUSTOMER_SHIP_TO@ebstohr
                               SET ERP_CUSTOMER_NUMBER = LC_ACCOUNT_NUMBER,
                                   ERP_CREATION_DATE = SYSDATE,
                                   CUSTOMER_SHIP_ID = LN_CUST_ACCT_SITE_ID,
                                   ERP_SITE_USE_ID = LN_SITE_USE_ID,
                                   ERP_CUSTOMER_ID = LN_CUST_ACCOUNT_ID,
                                   ERP_PARTY_ID = LN_PARTY_ID,
                                   ERP_PROCESS_FLAG = J.ERP_PROCESS_FLAG,
                                   CCID = LN_CCID,
                                   ERP_ERR_MSG =
                                          DECODE (ERP_ERR_MSG,
                                                  NULL, '',
                                                  ERP_ERR_MSG || '; ')
                                       || J.ERP_ERR_MSG
                             WHERE     1 = 1
                                   AND AGENCY_ID = J.AGENCY_ID
                                   AND CENTRE_NUMBER = J.CENTRE_NUMBER
                                   AND MAIN_CENTRE_NUMBER =
                                       J.MAIN_CENTRE_NUMBER;

                            COMMIT;
							*/

                            FND_FILE.PUT_LINE (
                                FND_FILE.LOG,
                                   'LN_CUST_ACCOUNT_ID: '
                                || LN_CUST_ACCOUNT_ID
                                || '; PARTY_ID: '
                                || LN_PARTY_ID
                                || '; LN_LOCATION_ID: '
                                || LN_LOCATION_ID
                                || '; LN_PARTY_SITE_ID: '
                                || LN_PARTY_SITE_ID
                                || '; LN_CUST_ACCT_SITE_ID: '
                                || LN_CUST_ACCT_SITE_ID
                                || '; LN_SITE_USE_ID: '
                                || LN_SITE_USE_ID);
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                FND_FILE.PUT_LINE (
                                    FND_FILE.LOG,
                                    SQLCODE || ' - ' || SQLERRM);
                        END;

                        FND_FILE.PUT_LINE (FND_FILE.LOG, RPAD ('*', 25, '*'));
                    ELSE
                        FND_FILE.PUT_LINE (
                            FND_FILE.LOG,
                               'LN_CUST_ACCOUNT_ID: '
                            || LN_CUST_ACCOUNT_ID
                            || '; PARTY_ID: '
                            || LN_PARTY_ID
                            || '; Msg : '
                            || LC_MSG);
                        J.ERP_PROCESS_FLAG := 'E';
                        J.ERP_ERR_MSG :=
                            REG_ERR_MSG (
                                J.ERP_ERR_MSG,
                                   'Customer Creation Error for : Center Number - '
                                || J.CENTRE_NUMBER);

                    /*    	-- Added by AKALA on 14-APR-2026
							-- Commented by AKALA on 20-APR-2026
                        UPDATE AU_CUSTOMER_SHIP_TO@ebstohr
                           SET ERP_CUSTOMER_NUMBER = LC_ACCOUNT_NUMBER,
                               ERP_CREATION_DATE = SYSDATE,
                               CUSTOMER_SHIP_ID = LN_CUST_ACCT_SITE_ID,
                               ERP_SITE_USE_ID = LN_SITE_USE_ID,
                               ERP_CUSTOMER_ID = LN_CUST_ACCOUNT_ID,
                               ERP_PARTY_ID = LN_PARTY_ID,
                               ERP_PROCESS_FLAG = J.ERP_PROCESS_FLAG,
                               CCID = LN_CCID,
                               ERP_ERR_MSG =
                                      DECODE (ERP_ERR_MSG,
                                              NULL, '',
                                              ERP_ERR_MSG || '; ')
                                   || J.ERP_ERR_MSG
                         WHERE     1 = 1
                               AND AGENCY_ID = J.AGENCY_ID
                               AND CENTRE_NUMBER = J.CENTRE_NUMBER
                               AND MAIN_CENTRE_NUMBER = J.MAIN_CENTRE_NUMBER;
					*/
							   
					-- Added by AKALA on 20-APR-2026; because the new package is created to update data in AU_CUSTOMER_SHIP_TO base tables.
					XXAU_UPDT_CUSTOM_CUST_DATA_PKG.UPDATE_CUSTS_SHIP_SITES@EBSTOHR( P_ACCOUNT_NUMBER => LC_ACCOUNT_NUMBER, 
																					P_CUST_ACCT_SITE_ID => LN_CUST_ACCT_SITE_ID,
																					P_SITE_USE_ID => LN_SITE_USE_ID,
																					P_CUST_ACCOUNT_ID => LN_CUST_ACCOUNT_ID,
																					P_PARTY_ID => LN_PARTY_ID,
																					P_PROCESS_FLAG => J.ERP_PROCESS_FLAG,
																					P_CCID => LN_CCID,
																					P_ERR_MSG => J.ERP_ERR_MSG ,
																					P_AGENCY_ID => J.AGENCY_ID,
																					P_CENTRE_NUMBER => J.CENTRE_NUMBER,
																					P_MAIN_CENTRE_NUMBER => J.MAIN_CENTRE_NUMBER
							);
					COMMIT;
							   
							   
                    /*UPDATE AU_CUSTOMER_MASTER_NEW@ebstohr
						  SET ERP_CUSTOMER_ID = LN_CUST_ACCOUNT_ID
						  , ERP_CUSTOMER_NUMBER = LN_ACCOUNT_NUMBER
						  , ERP_PARTY_ID = LN_PARTY_ID
						  , ERP_PROCESS_FLAG = I.ERP_PROCESS_FLAG
						  , ERP_ERR_MSG = DECODE(ERP_ERR_MSG,NULL,'',ERP_ERR_MSG||'; ')||I.ERP_ERR_MSG
						 WHERE AGENCY_ID = I.AGENCY_ID ;*/

                    END IF;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        FND_FILE.PUT_LINE (FND_FILE.LOG,
                                           SQLCODE || ' - ' || SQLERRM);
                END;
            END LOOP;

			/*
            UPDATE AU_CUSTOMER_MASTER_NEW@ebstohr
               SET ERP_CUSTOMER_ID = LN_CUST_ACCOUNT_ID,
                   ERP_CUSTOMER_NUMBER = LN_ACCOUNT_NUMBER,
                   ERP_PARTY_ID = LN_PARTY_ID,
                   ERP_PROCESS_FLAG = I.ERP_PROCESS_FLAG,
                   ERP_ERR_MSG =
                          DECODE (ERP_ERR_MSG, NULL, '', ERP_ERR_MSG || '; ')
                       || I.ERP_ERR_MSG
             WHERE AGENCY_ID = I.AGENCY_ID;

            COMMIT;
			*/
			
            FND_FILE.PUT_LINE (
                FND_FILE.LOG,
                   'LN_CUST_ACCOUNT_ID: '
                || LN_CUST_ACCOUNT_ID
                || '; PARTY_ID: '
                || LN_PARTY_ID
                || '; Msg : '
                || LC_MSG);
            FND_FILE.PUT_LINE (
                FND_FILE.LOG,
                'LN_LOCATION_ID: ' || LN_LOCATION_ID || '; Msg : ' || LC_MSG);
            FND_FILE.PUT_LINE (
                FND_FILE.LOG,
                   'LN_PARTY_SITE_ID: '
                || LN_PARTY_SITE_ID
                || '; Msg : '
                || LC_MSG);
            FND_FILE.PUT_LINE (
                FND_FILE.LOG,
                   'LN_CUST_ACCT_SITE_ID: '
                || LN_CUST_ACCT_SITE_ID
                || '; Msg : '
                || LC_MSG);
            FND_FILE.PUT_LINE (
                FND_FILE.LOG,
                'LN_SITE_USE_ID: ' || LN_SITE_USE_ID || '; Msg : ' || LC_MSG);
            FND_FILE.PUT_LINE (FND_FILE.LOG, RPAD ('*', 25, '*'));
            FND_FILE.PUT_LINE (
                FND_FILE.LOG,
                'Loop for Agency ID: ' || I.AGENCY_ID || ' is completed.');
            FND_FILE.PUT_LINE (FND_FILE.LOG, RPAD ('*', 25, '*'));
        END LOOP;
    EXCEPTION
        WHEN OTHERS
        THEN
            FND_FILE.PUT_LINE (FND_FILE.LOG, SQLCODE || ' - ' || SQLERRM);
    END CREATE_SAFALTA_CUST_AND_SITES;

    /*************************************************************************************************
     * Program Name : CREATE_CUSTOMER_AND_SITES
     * Language     : PL/SQL
     * Description  : Creates Customer and Sites other than Safalta Prouct.
     * History      -----------------------------------------------------------------------------------
	 * Parameters   :
     *
     * WHO              Version #   WHEN            WHAT
     * ===============  =========   =============   ====================================================
     * AKALA            1.0         02-APR-2026     Initial Version
     * AKALA            1.1         08-APR-2026     1. Upgraded code for EMAIL and PHONE creation in ERP
													2. Added logic for CREATE_CODE_COMBINATION
     * AKALA            1.2         09-APR-2026     Updated the logic according to XXAU_CUSTOMER_DETAILS@ebstohr TABLE
	 * AKALA            1.3         10-APR-2026     1. Added variable LN_CCID_S for Code Combination ID fetched while creating Site Uses
													2. Update the logic to create or get CCID if it is not created inside CREATE_CUST_SITE_USE
	 * AKALA            1.4         20-APR-2026     Updated the logic according to Package to Update data into Custom TABLE
	 * AKALA            1.5         21-APR-2026     Updated the logic for error message, removed Decode;
     ***************************************************************************************************/
    PROCEDURE CREATE_CUSTOMER_AND_SITES
    AS
        LN_LOCATION_ID              HZ_LOCATIONS.LOCATION_ID%TYPE;
        LN_LOC_ID                   HZ_LOCATIONS.LOCATION_ID%TYPE;
        LN_PARTY_ID                 HZ_PARTIES.PARTY_ID%TYPE;
        LN_PARTY_SITE_ID            HZ_PARTY_SITES.PARTY_SITE_ID%TYPE;
        LN_CUST_ACCOUNT_ID          HZ_CUST_ACCOUNTS.CUST_ACCOUNT_ID%TYPE;
        LN_ACCOUNT_NUMBER           HZ_CUST_ACCOUNTS.ACCOUNT_NUMBER%TYPE;
        LN_CUST_ACCT_SITE_ID        HZ_CUST_ACCT_SITES_ALL.CUST_ACCT_SITE_ID%TYPE;
        LN_SITE_USE_ID              HZ_CUST_SITE_USES_ALL.SITE_USE_ID%TYPE;

        CURSOR C1 IS
            (SELECT DISTINCT
                    CUSTOMER_NAME,
                    B.UNIT,
                    B.CUSTOMER_TYPE,
                    B.CUSTOMER_CLASS
                        CUSTOMER_CLASS_CODE,
                    B.MOBILE_NO,
                    B.CONTACT_PERSON,
                    NVL (B.ACCOUNT_DESCRIPTION, B.CUSTOMER_NAME)
                        ACCOUNT_DESCRIPTION,
                    B.ABC_TYPE,
                    B.OLD_PARTY_ID,
                    B.OLD_CUSTOMER_ID,
                    B.AGENCY_ID,
                    A.AGENCY_NAME,
                    A.ERP_PROCESS_FLAG,
                    A.ERP_ERR_MSG
               FROM AU_CUSTOMER_MASTER_NEW@ebstohr  A,
                    XXAU_CUSTOMER_DETAILS@ebstohr   B
              WHERE     A.AGENCY_ID IN
                            (SELECT AGENCY_ID
                               FROM XXAU_AGENCY_APPROVAL_DETIALS@ebstohr
                              WHERE     TRUNC (CREATION_DATE) >=
                                        '01-OCT-2024'
                                    AND APPROVE_REJECT = 'A'
                                    AND AGREEMENT_FLAG = 'Y')
                    AND A.ERP_PARTY_ID IS NULL
                    AND A.ERP_CUSTOMER_NUMBER IS NULL
                    AND A.ERP_CUSTOMER_ID IS NULL
                    AND A.AGENCY_ID = B.AGENCY_ID
                    AND EXISTS
                            (SELECT 1
                               FROM AU_CUSTOMER_SHIP_TO@ebstohr
                              WHERE     AGENCY_ID = A.AGENCY_ID
                                    AND UPPER (PROUCT_NAME) NOT LIKE
                                            '%SAFALTA%'
                                    AND ERP_CUSTOMER_NUMBER IS NULL
                                    AND ERP_SITE_USE_ID IS NULL)
                    AND B.CUSTOMER_TYPE NOT LIKE '%SAFALTA%'
                    AND B.PROCESS_FLAG = 'P');

        CURSOR C2 (P_AGENCY_ID      NUMBER,
                   P_CUST_NAME      VARCHAR2,
                   P_UNIT           VARCHAR2,
                   P_CUST_TYPE      VARCHAR2,
                   P_ACCOUNT_DESC   VARCHAR2)
        IS
            (SELECT A.AGENCY_ID,
                    A.CENTRE_NUMBER,
                    A.MAIN_CENTRE_NUMBER,
                    A.INV_ORG,
                    A.ORG_ID,
                    A.MOBILE_NO,
                    A.EMAIL,
                    B.CUSTOMER_NAME,
                    B.UNIT,
                    B.CUSTOMER_TYPE,
                    B.CUSTOMER_CLASS
                        CUSTOMER_CALSS_CODE,
                    B.ADDRESS1,
                    B.ADDRESS2,
                    B.ADDRESS3,
                    B.ADDRESS4,
                    B.CITY,
                    B.STATE,
                    DECODE (UPPER (B.COUNTRY),
                            'INDIA', 'IN',
                            UPPER (B.COUNTRY))
                        COUNTRY,
                    B.COUNTY,
                    B.LOCATION1,
                    B.STATION_NAME,
                    A.NAME_OF_CENTRE,
                    B.PINCODE
                        POSTAL_CODE,
                    'SHIP_TO'
                        SITE_USE_CODE,
                    DECODE (UPPER (B.PRIMARY_SITE_FALG), 'YES', 'Y', 'N')
                        PRIMARY_FLAG,
                    'A'
                        STATUS,
                    B.REC_ACCOUNT,
                    B.PAYMENT_TERMS,
                    A.ERP_PROCESS_FLAG,
                    A.ERP_ERR_MSG,
                    A.CCID
               FROM AU_CUSTOMER_SHIP_TO@ebstohr A
			   , XXAU_CUSTOMER_DETAILS@ebstohr B
              WHERE     A.AGENCY_ID IN
                            (SELECT AGENCY_ID
                               FROM XXAU_AGENCY_APPROVAL_DETIALS@ebstohr
                              WHERE     TRUNC (CREATION_DATE) >=
                                        '01-OCT-2024'
                                    AND APPROVE_REJECT = 'A'
                                    AND AGREEMENT_FLAG = 'Y')
                    AND UPPER (PROUCT_NAME) NOT LIKE '%SAFALTA%'
                    AND A.AGENCY_ID = B.AGENCY_ID
                    AND A.CENTRE_NUMBER = B.CENTRE_NUMBER -- Added to reduce the number of lines; on 13-APR-2026
                    AND CUSTOMER_SHIP_ID IS NULL
                    AND ERP_PARTY_ID IS NULL
                    AND ERP_SITE_USE_ID IS NULL
                    AND ERP_CUSTOMER_NUMBER IS NULL
                    AND ERP_CUSTOMER_ID IS NULL
                    AND B.CUSTOMER_TYPE NOT LIKE '%SAFALTA%'
					AND A.ERP_PROCESS_FLAG IS NULL
                    AND B.PROCESS_FLAG = 'P'
                    AND A.AGENCY_ID = P_AGENCY_ID
                    AND B.CUSTOMER_TYPE = P_CUST_TYPE
                    AND B.UNIT = P_UNIT
                    AND B.CUSTOMER_NAME = P_CUST_NAME
                    AND B.ACCOUNT_DESCRIPTION = P_ACCOUNT_DESC
					);

        LC_MSG                      VARCHAR2 (4000);
        LC_ERR_MSG                  VARCHAR2 (4000);
        LC_ACCOUNT_NUMBER           VARCHAR2 (200);
        LC_PARTY_NUMBER             VARCHAR2 (200);
        LC_PARTY_SITE_NUM           VARCHAR2 (200);
        LN_PROFILE_ID               NUMBER;
        LN_CCID                     NUMBER; -- Added by AKALA on 08-APR-2026 for CODE_COMBINATION_ID
        LN_CCID_S                   NUMBER; -- Added by AKALA on 10-APR-2026 for CODE_COMBINATION_ID
        LN_PHONE_CONTACT_POINT_ID   NUMBER;
        LN_EMAIL_CONTACT_POINT_ID   NUMBER;
    BEGIN
        FND_FILE.PUT_LINE (FND_FILE.LOG, RPAD ('*', 30, '*'));
        FND_FILE.PUT_LINE (FND_FILE.LOG, 'In CREATE_CUSTOMER_AND_SITES');

        FOR I IN C1
        LOOP
            LN_LOCATION_ID := NULL;
            LN_PARTY_ID := NULL;
            I.ERP_ERR_MSG := NULL;
            I.ERP_PROCESS_FLAG := 'S';
            FND_FILE.PUT_LINE (FND_FILE.LOG, RPAD ('+', 25, '+'));

            BEGIN
                CREATE_CUST_ACCOUNT (
                    P_ORGANIZATION_NAME     => I.CUSTOMER_NAME,
                    P_ACCOUNT_NAME          => I.ACCOUNT_DESCRIPTION,
                    P_ABC_TYPE              => I.ABC_TYPE,
                    P_AGENCY_ID             => I.AGENCY_ID,
                    P_CUSTOMER_TYPE         => I.CUSTOMER_TYPE,
                    P_CUSTOMER_CLASS_CODE   => I.CUSTOMER_CLASS_CODE,
                    P_UNIT                  => I.UNIT,
                    P_PARTY_ID              => LN_PARTY_ID,
                    P_CUST_ACCOUNT_ID       => LN_CUST_ACCOUNT_ID,
                    P_PARTY_NUMBER          => LC_PARTY_NUMBER,
                    P_PROFILE_ID            => LN_PROFILE_ID,
                    P_ACCOUNT_NUMBER        => LC_ACCOUNT_NUMBER,
                    P_MSG                   => LC_MSG);

                LC_ERR_MSG := LC_MSG;
                I.ERP_ERR_MSG := REG_ERR_MSG (I.ERP_ERR_MSG, LC_MSG);

                FND_FILE.PUT_LINE (
                    FND_FILE.LOG,
                       'LN_CUST_ACCOUNT_ID: '
                    || LN_CUST_ACCOUNT_ID
                    || '; PARTY_ID: '
                    || LN_PARTY_ID);
					
                IF LN_CUST_ACCOUNT_ID > 0 AND LN_PARTY_ID > 0
                THEN
                    FOR J IN C2 (P_AGENCY_ID      => I.AGENCY_ID,
                                 P_CUST_NAME      => I.CUSTOMER_NAME,
                                 P_UNIT           => I.UNIT,
                                 P_CUST_TYPE      => I.CUSTOMER_TYPE,
                                 P_ACCOUNT_DESC   => I.ACCOUNT_DESCRIPTION)
                    LOOP
                        BEGIN
                            -- Resetting the Variables For Correct Values And Updation
                            LN_LOCATION_ID := -1;
                            LN_PARTY_SITE_ID := -1;
                            LN_CUST_ACCT_SITE_ID := -1;
                            LN_SITE_USE_ID := -1;
                            J.ERP_ERR_MSG := NULL;
                            J.ERP_PROCESS_FLAG := 'S';

                            BEGIN
                                SELECT LOCATION_ID
                                  INTO LN_LOCATION_ID
                                  FROM HZ_LOCATIONS
                                 WHERE     1 = 1
                                       AND ADDRESS1 = J.ADDRESS1
                                       AND CITY = J.CITY
                                       AND DESCRIPTION = J.NAME_OF_CENTRE --J.LOCATION1
                                                                         ;
                            EXCEPTION
                                WHEN OTHERS
                                THEN
                                    CREATE_LOCATION (
                                        P_ADDRESS1      => J.ADDRESS1,
                                        P_ADDRESS2      => J.ADDRESS2,
                                        P_ADDRESS3      => J.ADDRESS3,
                                        P_ADDRESS4      => J.ADDRESS4,
                                        P_CITY          => J.CITY,
                                        P_POSTAL_CODE   => J.POSTAL_CODE,
                                        P_STATE         => J.STATE,
                                        P_COUNTY        => J.COUNTY,
                                        P_COUNTRY       => J.COUNTRY,
                                        P_LOCATION1     => J.NAME_OF_CENTRE --J.LOCATION1
                                                                           ,
                                        P_LOCATION_ID   => LN_LOCATION_ID,
                                        P_MSG           => LC_MSG);
                                    J.ERP_ERR_MSG :=
                                        REG_ERR_MSG (J.ERP_ERR_MSG, LC_MSG);
                            END;

                            IF LN_LOCATION_ID > 0
                            THEN
                                BEGIN
                                    SELECT PARTY_SITE_ID
                                      INTO LN_PARTY_SITE_ID
                                      FROM HZ_PARTY_SITES
                                     WHERE     1 = 1
                                           AND PARTY_ID = LN_PARTY_ID
                                           AND LOCATION_ID = LN_LOCATION_ID
                                           AND PARTY_SITE_NAME =
                                               J.STATION_NAME;
                                EXCEPTION
                                    WHEN OTHERS
                                    THEN
                                        CREATE_PARTY_SITE (
                                            P_PARTY_ID         => LN_PARTY_ID,
                                            P_LOCATION_ID      => LN_LOCATION_ID,
                                            P_CUSTOMER_TYPE    =>
                                                I.CUSTOMER_TYPE,
                                            P_STATION_NAME     => J.STATION_NAME,
                                            P_PARTY_SITE_ID    =>
                                                LN_PARTY_SITE_ID,
                                            P_PARTY_SITE_NUM   =>
                                                LC_PARTY_SITE_NUM,
                                            P_MSG              => LC_MSG);
                                        J.ERP_ERR_MSG :=
                                            REG_ERR_MSG (J.ERP_ERR_MSG,
                                                         LC_MSG);
                                END;
                            ELSE
                                J.ERP_PROCESS_FLAG := 'E';
                                J.ERP_ERR_MSG :=
                                    REG_ERR_MSG (
                                        J.ERP_ERR_MSG,
                                           'Location Error for: Party ID - '
                                        || LN_PARTY_ID
                                        || ', Location1 - '
                                        || J.LOCATION1
                                        || ', J.NAME_OF_CENTRE - '
                                        || J.NAME_OF_CENTRE);
                            END IF;

                            -- Creating Customer Account Site
                            IF LN_PARTY_SITE_ID > 0
                            THEN
                                BEGIN
                                    SELECT CUST_ACCT_SITE_ID
                                      INTO LN_CUST_ACCT_SITE_ID
                                      FROM HZ_CUST_ACCT_SITES_ALL
                                     WHERE     1 = 1
                                           AND CUST_ACCOUNT_ID =
                                               LN_CUST_ACCOUNT_ID
                                           AND PARTY_SITE_ID =
                                               LN_PARTY_SITE_ID;
                                EXCEPTION
                                    WHEN OTHERS
                                    THEN
                                        CREATE_CUST_ACCT_SITE (
                                            P_CUST_ACCOUNT_ID   =>
                                                LN_CUST_ACCOUNT_ID,
                                            P_PARTY_SITE_ID   =>
                                                LN_PARTY_SITE_ID,
                                            P_CUSTOMER_TYPE   =>
                                                I.CUSTOMER_TYPE,
                                            P_CUST_ACCT_SITE_ID   =>
                                                LN_CUST_ACCT_SITE_ID,
                                            P_MSG   => LC_MSG);
                                        J.ERP_ERR_MSG :=
                                            REG_ERR_MSG (J.ERP_ERR_MSG,
                                                         LC_MSG);
                                END;
                            ELSE
                                J.ERP_PROCESS_FLAG := 'E';
                                J.ERP_ERR_MSG :=
                                    REG_ERR_MSG (
                                        J.ERP_ERR_MSG,
                                           'Party Site Error for : Station Name - '
                                        || J.STATION_NAME
                                        || ', Party ID - '
                                        || LN_PARTY_ID
                                        || ', Location ID - '
                                        || LN_LOCATION_ID);
                            END IF;


                            IF LN_CUST_ACCT_SITE_ID > 0
                            THEN
                                CREATE_CUST_SITE_USES (
                                    P_CUST_ACCT_SITE_ID   =>
                                        LN_CUST_ACCT_SITE_ID,
                                    P_SITE_USE_CODE   => 'SHIP_TO',
                                    P_CUSTOMER_TYPE   => I.CUSTOMER_TYPE,
                                    P_LOCATION        => J.NAME_OF_CENTRE --J.LOCATION1
                                                                         ,
                                    P_CENTRE_NUMBER   => J.CENTRE_NUMBER,
                                    P_PRIMARY_FLAG    => J.PRIMARY_FLAG,
                                    P_PAYMENT_TERMS   => J.PAYMENT_TERMS,
                                    P_REC_ACCOUNT     => J.REC_ACCOUNT,
                                    P_SITE_USE_ID     => LN_SITE_USE_ID,
                                    P_CCID            => LN_CCID_S -- Added to retrive the CODE_COMBINATION_ID
                                                                  ,
                                    P_MSG             => LC_MSG);
                                J.ERP_ERR_MSG :=
                                    REG_ERR_MSG (J.ERP_ERR_MSG, LC_MSG);

                                IF LN_SITE_USE_ID < 0
                                THEN
                                    J.ERP_PROCESS_FLAG := 'E';
                                    J.ERP_ERR_MSG :=
                                        REG_ERR_MSG (
                                            J.ERP_ERR_MSG,
                                               'Site Use Error for : Location1 - '
                                            || J.LOCATION1
                                            || ', Center Number - '
                                            || J.CENTRE_NUMBER
                                            || ', NAME_OF_CENTRE - '
                                            || J.NAME_OF_CENTRE);
                                END IF;

                                CREATE_CONTACT_ORG (
                                    P_PARTY_ID         => LN_PARTY_ID,
                                    P_CONTACT_PERSON   => I.CONTACT_PERSON,
                                    P_MSG              => LC_MSG);

                                -- start: Creating Contact Point -- Added on 07-APR-2026
                                CREATE_CONTACT_POINT_SITE_LVL (
                                    P_PARTY_SITE_ID            => LN_PARTY_SITE_ID,
                                    P_PHONE                    => J.MOBILE_NO,
                                    P_EMAIL                    => J.EMAIL,
                                    P_TABLE                    => 'HZ_PARTY_SITES',
                                    P_PHONE_CONTACT_POINT_ID   =>
                                        LN_PHONE_CONTACT_POINT_ID,
                                    P_EMAIL_CONTACT_POINT_ID   =>
                                        LN_EMAIL_CONTACT_POINT_ID,
                                    P_MSG                      => LC_MSG);

                                IF LN_PHONE_CONTACT_POINT_ID < 0
                                THEN
                                    FND_FILE.PUT_LINE (
                                        FND_FILE.LOG,
                                           'Cannot create Phone Cotact Point : '
                                        || J.MOBILE_NO);
                                END IF;

                                IF LN_EMAIL_CONTACT_POINT_ID < 0
                                THEN
                                    FND_FILE.PUT_LINE (
                                        FND_FILE.LOG,
                                           'Cannot create Email Cotact Point : '
                                        || J.EMAIL);
                                END IF;

                                -- end : Added Email and Phone contact points on 07-APR-2026

                                FND_FILE.PUT_LINE (FND_FILE.LOG,
                                                   RPAD ('_', 25, '_'));
                                LN_CCID := -1;

                                --Start:  Added by AKALA on 10-APR-2026, to create or get CCID if it is not created inside CREATE_CUST_SITE_USE
                                IF LN_CCID_S < 0
                                THEN
                                    BEGIN
                                        SELECT CODE_COMBINATION_ID
                                          INTO LN_CCID
                                          FROM GL_CODE_COMBINATIONS_KFV
                                         WHERE CONCATENATED_SEGMENTS =
                                               J.REC_ACCOUNT;
                                    EXCEPTION
                                        WHEN OTHERS
                                        THEN
                                            --Start:  Added by AKALA on 08-APR-2026, create or get CCID
                                            CREATE_CODE_COMBINATION (
                                                P_ORG_ID        => J.ORG_ID,
                                                P_INV_ORG       => J.INV_ORG,
                                                P_AGENCY_ID     => J.AGENCY_ID,
                                                P_CENTRE_NUMBER   =>
                                                    J.CENTRE_NUMBER,
                                                P_AGENCY_NAME   =>
                                                    I.AGENCY_NAME,
                                                P_CCID          => LN_CCID,
                                                P_MSG           => LC_MSG);
                                            FND_FILE.PUT_LINE (
                                                FND_FILE.LOG,
                                                   'Retrived Code Combination ID : '
                                                || LN_CCID);
                                    -- END :  Added by AKALA on 08-APR-2026, to create or get CCID
                                    END;
                                ELSE
                                    LN_CCID := LN_CCID_S;
                                END IF;

                                -- END :  Added by AKALA on 10-APR-2026, to create or get CCID before creating the SITE USES

                                LC_ERR_MSG := LC_ERR_MSG || '-' || LC_MSG;
                            ELSE
                                J.ERP_PROCESS_FLAG := 'E';
                                J.ERP_ERR_MSG :=
                                    REG_ERR_MSG (
                                        J.ERP_ERR_MSG,
                                           'Cust Acct Site Error for : CUST_ACCOUNT_ID - '
                                        || LN_CUST_ACCOUNT_ID
                                        || ', PARTY_SITE_ID - '
                                        || LN_PARTY_SITE_ID);
                            END IF;

                            /*comment by AKALA, on 20-APR-2026
                            UPDATE AU_CUSTOMER_SHIP_TO@ebstohr
                               SET ERP_CUSTOMER_NUMBER = LC_ACCOUNT_NUMBER,
                                   ERP_CREATION_DATE = SYSDATE,
                                   CUSTOMER_SHIP_ID = LN_CUST_ACCT_SITE_ID,
                                   ERP_SITE_USE_ID = LN_SITE_USE_ID,
                                   ERP_CUSTOMER_ID = LN_CUST_ACCOUNT_ID,
                                   ERP_PARTY_ID = LN_PARTY_ID,
                                   ERP_PROCESS_FLAG = J.ERP_PROCESS_FLAG,
                                   CCID = LN_CCID,
                                   ERP_ERR_MSG =
                                          DECODE (ERP_ERR_MSG,
                                                  NULL, '',
                                                  ERP_ERR_MSG || '; ')
                                       || J.ERP_ERR_MSG
                             WHERE     1 = 1
                                   AND AGENCY_ID = J.AGENCY_ID
                                   AND CENTRE_NUMBER = J.CENTRE_NUMBER
                                   AND MAIN_CENTRE_NUMBER =
                                       J.MAIN_CENTRE_NUMBER;

                            COMMIT;
							*/
							
							-- Updating AU_CUSTOMER_SHIP_TO@ebstohr on Successful Creation of every Site and Uses	
							
							-- Added by AKALA on 20-APR-2026; because the new package is created to update data in AU_CUSTOMER_SHIP_TO base tables.
							XXAU_UPDT_CUSTOM_CUST_DATA_PKG.UPDATE_CUSTS_SHIP_SITES@EBSTOHR( P_ACCOUNT_NUMBER => LC_ACCOUNT_NUMBER, 
																							P_CUST_ACCT_SITE_ID => LN_CUST_ACCT_SITE_ID,
																							P_SITE_USE_ID => LN_SITE_USE_ID,
																							P_CUST_ACCOUNT_ID => LN_CUST_ACCOUNT_ID,
																							P_PARTY_ID => LN_PARTY_ID,
																							P_PROCESS_FLAG => J.ERP_PROCESS_FLAG,
																							P_CCID => LN_CCID,
																							P_ERR_MSG => J.ERP_ERR_MSG ,
																							P_AGENCY_ID => J.AGENCY_ID,
																							P_CENTRE_NUMBER => J.CENTRE_NUMBER,
																							P_MAIN_CENTRE_NUMBER => J.MAIN_CENTRE_NUMBER
									);
							COMMIT;

                            FND_FILE.PUT_LINE (
                                FND_FILE.LOG,
                                   'LN_CUST_ACCOUNT_ID: '
                                || LN_CUST_ACCOUNT_ID
                                || '; PARTY_ID: '
                                || LN_PARTY_ID
                                || '; LN_LOCATION_ID: '
                                || LN_LOCATION_ID
                                || '; LN_PARTY_SITE_ID: '
                                || LN_PARTY_SITE_ID
                                || '; LN_CUST_ACCT_SITE_ID: '
                                || LN_CUST_ACCT_SITE_ID
                                || '; LN_SITE_USE_ID: '
                                || LN_SITE_USE_ID);
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                FND_FILE.PUT_LINE (
                                    FND_FILE.LOG,
                                    SQLCODE || ' - ' || SQLERRM);
                        END;

                        FND_FILE.PUT_LINE (FND_FILE.LOG, RPAD ('*', 25, '*'));
                    END LOOP;
                ELSE
                    FND_FILE.PUT_LINE (
                        FND_FILE.LOG,
                           'LN_CUST_ACCOUNT_ID: '
                        || LN_CUST_ACCOUNT_ID
                        || '; PARTY_ID: '
                        || LN_PARTY_ID
                        || '; Msg : '
                        || LC_MSG);
                    I.ERP_ERR_MSG :=
                        REG_ERR_MSG (I.ERP_ERR_MSG,
                                     ' Cust Account and Party Error.');
                    I.ERP_PROCESS_FLAG := 'E';

					/* -- Commented by AKALA on 20-APR-2026
                    UPDATE AU_CUSTOMER_MASTER_NEW@ebstohr
                       SET ERP_CUSTOMER_ID = LN_CUST_ACCOUNT_ID,
                           ERP_CUSTOMER_NUMBER = LC_ACCOUNT_NUMBER,
                           ERP_PARTY_ID = LN_PARTY_ID,
                           ERP_PROCESS_FLAG = I.ERP_PROCESS_FLAG,
                           ERP_ERR_MSG = 
                                  DECODE (ERP_ERR_MSG,
                                          NULL, '',
                                          ERP_ERR_MSG || '; ')
                               || I.ERP_ERR_MSG
                     WHERE AGENCY_ID = I.AGENCY_ID;
					 */
					 
					 -- Added by AKALA on 20-APR-2026, to update the data in AU_CUSTOMER_MASTER_NEW custom table.
					 XXAU_UPDT_CUSTOM_CUST_DATA_PKG.UPDT_CUST_WITH_SITES_MAST_NEW@EBSTOHR (P_CUST_ACCOUNT_ID => LN_CUST_ACCOUNT_ID,
																							P_ACCOUNT_NUMBER => LC_ACCOUNT_NUMBER,
																							P_PARTY_ID => LN_PARTY_ID,
																							P_PROCESS_FLAG => I.ERP_PROCESS_FLAG,
																							P_ERR_MSG => I.ERP_ERR_MSG,
																							P_AGENCY_ID => I.AGENCY_ID
																							);
					 COMMIT;
					 
                END IF;
            EXCEPTION
                WHEN OTHERS
                THEN
                    FND_FILE.PUT_LINE (FND_FILE.LOG,
                                       SQLCODE || ' - ' || SQLERRM);
            END;

            IF I.ERP_PROCESS_FLAG = 'S'
            THEN
                /* -- Commented by AKALA on 20-APR-2026, 
				UPDATE AU_CUSTOMER_MASTER_NEW@ebstohr
                   SET ERP_CUSTOMER_ID = LN_CUST_ACCOUNT_ID,
                       ERP_CUSTOMER_NUMBER = LC_ACCOUNT_NUMBER,
                       ERP_PARTY_ID = LN_PARTY_ID,
                       ERP_PROCESS_FLAG = I.ERP_PROCESS_FLAG,
                       ERP_ERR_MSG =
                              DECODE (ERP_ERR_MSG,
                                      NULL, '',
                                      ERP_ERR_MSG || '; ')
                           || I.ERP_ERR_MSG
                 WHERE AGENCY_ID = I.AGENCY_ID;
				 */
				 
			-- Added by AKALA on 20-APR-2026, to update the data in AU_CUSTOMER_MASTER_NEW custom table.
			 XXAU_UPDT_CUSTOM_CUST_DATA_PKG.UPDT_CUST_WITH_SITES_MAST_NEW@EBSTOHR (P_CUST_ACCOUNT_ID => LN_CUST_ACCOUNT_ID,
																					P_ACCOUNT_NUMBER => LC_ACCOUNT_NUMBER,
																					P_PARTY_ID => LN_PARTY_ID,
																					P_PROCESS_FLAG => I.ERP_PROCESS_FLAG,
																					P_ERR_MSG => I.ERP_ERR_MSG,
																					P_AGENCY_ID => I.AGENCY_ID
																					);

                COMMIT;
            END IF;

            FND_FILE.PUT_LINE (
                FND_FILE.LOG,
                   'LN_CUST_ACCOUNT_ID: '
                || LN_CUST_ACCOUNT_ID
                || '; PARTY_ID: '
                || LN_PARTY_ID
                || '; Msg : '
                || LC_MSG);
            FND_FILE.PUT_LINE (
                FND_FILE.LOG,
                'LN_LOCATION_ID: ' || LN_LOCATION_ID || '; Msg : ' || LC_MSG);
            FND_FILE.PUT_LINE (
                FND_FILE.LOG,
                   'LN_PARTY_SITE_ID: '
                || LN_PARTY_SITE_ID
                || '; Msg : '
                || LC_MSG);
            FND_FILE.PUT_LINE (
                FND_FILE.LOG,
                   'LN_CUST_ACCT_SITE_ID: '
                || LN_CUST_ACCT_SITE_ID
                || '; Msg : '
                || LC_MSG);
            FND_FILE.PUT_LINE (
                FND_FILE.LOG,
                'LN_SITE_USE_ID: ' || LN_SITE_USE_ID || '; Msg : ' || LC_MSG);
            FND_FILE.PUT_LINE (FND_FILE.LOG, RPAD ('*', 25, '*'));
            FND_FILE.PUT_LINE (
                FND_FILE.LOG,
                'Loop for Agency ID: ' || I.AGENCY_ID || ' is completed.');
            FND_FILE.PUT_LINE (FND_FILE.LOG, RPAD ('*', 25, '*'));
        END LOOP;
    EXCEPTION
        WHEN OTHERS
        THEN
            FND_FILE.PUT_LINE (FND_FILE.LOG, SQLCODE || ' - ' || SQLERRM);
    END CREATE_CUSTOMER_AND_SITES;

    /*************************************************************************************************
     * Program Name : CREATE_CUSTOMERS_SITES
     * Language     : PL/SQL
     * Description  : Creates Customer's Sites other than Safalta Prouct which have their customer available in ERP.
     * History      -----------------------------------------------------------------------------------
  * Parameters   :
     *
     * WHO              Version #   WHEN            WHAT
     * ===============  =========   =============   ====================================================
     * AKALA            1.0         01-APR-2026     Initial Version
     * AKALA            1.2         08-APR-2026     1. Updated the code for creating Email and phone contact points
													2. Added logic for CREATE_CODE_COMBINATION
	 * AKALA            1.3         09-APR-2026     Updated the logic according to XXAU_CUSTOMER_DETAILS@ebstohr TABLE
	 * AKALA            1.3         10-APR-2026     1. Added variable LN_CCID_S for Code Combination ID fetched while creating Site Uses
													2. Update the logic to create or get CCID if it is not created inside CREATE_CUST_SITE_USE
	 * AKALA            1.4         20-APR-2026     Updated the logic according to Package to Update data into Custom TABLE
	 * AKALA            1.5         21-APR-2026     Updated the logic for error message, removed Decode;
     ***************************************************************************************************/
    PROCEDURE CREATE_CUSTOMERS_SITES
    AS
        LN_LOCATION_ID              HZ_LOCATIONS.LOCATION_ID%TYPE;
        LN_LOC_ID                   HZ_LOCATIONS.LOCATION_ID%TYPE;
        LN_PARTY_ID                 HZ_PARTIES.PARTY_ID%TYPE;
        LN_PARTY_SITE_ID            HZ_PARTY_SITES.PARTY_SITE_ID%TYPE;
        LN_CUST_ACCOUNT_ID          HZ_CUST_ACCOUNTS.CUST_ACCOUNT_ID%TYPE;
        LN_ACCOUNT_NUMBER           HZ_CUST_ACCOUNTS.ACCOUNT_NUMBER%TYPE;
        LN_CUST_ACCT_SITE_ID        HZ_CUST_ACCT_SITES_ALL.CUST_ACCT_SITE_ID%TYPE;
        LN_SITE_USE_ID              HZ_CUST_SITE_USES_ALL.SITE_USE_ID%TYPE;

        CURSOR C1 IS
            (SELECT DISTINCT
                    CUSTOMER_NAME,
                    B.UNIT,
                    B.CUSTOMER_TYPE,
                    B.CUSTOMER_CLASS
                        CUSTOMER_CLASS_CODE,
                    B.MOBILE_NO,
                    B.CONTACT_PERSON,
                    NVL (B.ACCOUNT_DESCRIPTION, B.CUSTOMER_NAME)
                        ACCOUNT_DESCRIPTION,
                    B.ABC_TYPE,
                    B.OLD_PARTY_ID,
                    B.OLD_CUSTOMER_ID,
                    B.AGENCY_ID,
                    A.AGENCY_NAME,
                    A.ERP_PROCESS_FLAG,
                    A.ERP_ERR_MSG,
                    A.ERP_CUSTOMER_NUMBER,
                    A.ERP_CUSTOMER_ID,
                    A.ERP_PARTY_ID
               FROM AU_CUSTOMER_MASTER_NEW@ebstohr A
                   , XXAU_CUSTOMER_DETAILS@ebstohr   B
              WHERE     A.AGENCY_ID IN
                            (SELECT AGENCY_ID
                               FROM XXAU_AGENCY_APPROVAL_DETIALS@ebstohr
                              WHERE     TRUNC (CREATION_DATE) >=
                                        '01-OCT-2024'
                                    AND APPROVE_REJECT = 'A'
                                    AND AGREEMENT_FLAG = 'Y')
                    AND A.ERP_PARTY_ID IS NOT NULL
                    AND A.ERP_CUSTOMER_NUMBER IS NOT NULL
                    AND A.ERP_CUSTOMER_ID IS NOT NULL
                    AND A.AGENCY_ID = B.AGENCY_ID
                    AND EXISTS
                            (SELECT 1
                               FROM AU_CUSTOMER_SHIP_TO@ebstohr
                              WHERE     AGENCY_ID = A.AGENCY_ID
                                    AND UPPER (PROUCT_NAME) NOT LIKE
                                            '%SAFALTA%'
                                    AND ERP_CUSTOMER_NUMBER IS NULL
                                    AND ERP_SITE_USE_ID IS NULL)
                    AND B.CUSTOMER_TYPE NOT LIKE '%SAFALTA%'
                    AND B.PROCESS_FLAG = 'P');

        CURSOR C2 (P_AGENCY_ID      NUMBER,
                   P_CUST_NAME      VARCHAR2,
                   P_UNIT           VARCHAR2,
                   P_CUST_TYPE      VARCHAR2,
                   P_ACCOUNT_DESC   VARCHAR2)
        IS
            (SELECT A.AGENCY_ID,
                    A.CENTRE_NUMBER,
                    A.MAIN_CENTRE_NUMBER,
                    A.INV_ORG,
                    A.ORG_ID,
                    A.MOBILE_NO,
                    A.EMAIL,
                    B.CUSTOMER_NAME,
                    B.UNIT,
                    B.CUSTOMER_TYPE,
                    B.CUSTOMER_CLASS
                        CUSTOMER_CALSS_CODE,
                    B.ADDRESS1,
                    B.ADDRESS2,
                    B.ADDRESS3,
                    B.ADDRESS4,
                    B.CITY,
                    B.STATE,
                    DECODE (UPPER (B.COUNTRY),
                            'INDIA', 'IN',
                            UPPER (B.COUNTRY))
                        COUNTRY,
                    B.COUNTY,
                    B.LOCATION1,
                    B.STATION_NAME,
                    A.NAME_OF_CENTRE,
                    B.PINCODE
                        POSTAL_CODE,
                    'SHIP_TO'
                        SITE_USE_CODE,
                    DECODE (UPPER (B.PRIMARY_SITE_FALG), 'YES', 'Y', 'N')
                        PRIMARY_FLAG,
                    'A'
                        STATUS,
                    B.REC_ACCOUNT,
                    B.PAYMENT_TERMS,
                    A.ERP_PROCESS_FLAG,
                    A.ERP_ERR_MSG,
                    A.CCID
               FROM AU_CUSTOMER_SHIP_TO@ebstohr A
			   , XXAU_CUSTOMER_DETAILS@ebstohr B
              WHERE     A.AGENCY_ID IN
                            (SELECT AGENCY_ID
                               FROM XXAU_AGENCY_APPROVAL_DETIALS@ebstohr
                              WHERE     TRUNC (CREATION_DATE) >=
                                        '01-OCT-2024'
                                    AND APPROVE_REJECT = 'A'
                                    AND AGREEMENT_FLAG = 'Y')
                    AND UPPER (PROUCT_NAME) NOT LIKE '%SAFALTA%'
                    AND A.AGENCY_ID = B.AGENCY_ID
                    AND A.CENTRE_NUMBER = B.CENTRE_NUMBER -- Added to reduce the number of lines; on 13-APR-2026
                    AND CUSTOMER_SHIP_ID IS NULL
                    AND ERP_PARTY_ID IS NULL
                    AND ERP_SITE_USE_ID IS NULL
                    AND ERP_CUSTOMER_NUMBER IS NULL
                    AND ERP_CUSTOMER_ID IS NULL
                    AND B.CUSTOMER_TYPE NOT LIKE '%SAFALTA%'
					AND A.ERP_PROCESS_FLAG IS NULL
                    AND A.AGENCY_ID = P_AGENCY_ID
                    AND B.CUSTOMER_TYPE = P_CUST_TYPE
                    AND B.UNIT = P_UNIT
                    AND B.CUSTOMER_NAME = P_CUST_NAME
                    AND B.ACCOUNT_DESCRIPTION = P_ACCOUNT_DESC
                    AND B.PROCESS_FLAG = 'P');

        LC_MSG                      VARCHAR2 (4000);
        LC_ERR_MSG                  VARCHAR2 (4000);
        LC_ACCOUNT_NUMBER           VARCHAR2 (200);
        LC_PARTY_NUMBER             VARCHAR2 (200);
        LC_PARTY_SITE_NUM           VARCHAR2 (200);
        LN_PROFILE_ID               NUMBER;
        LN_CCID                     NUMBER; -- Added by AKALA on 08-APR-2026 for CODE_COMBINATION_ID
        LN_CCID_S                   NUMBER; -- Added by AKALA on 10-APR-2026 for CODE_COMBINATION_ID
        LN_PHONE_CONTACT_POINT_ID   NUMBER;
        LN_EMAIL_CONTACT_POINT_ID   NUMBER;
    BEGIN
        FND_FILE.PUT_LINE (FND_FILE.LOG, RPAD ('*', 30, '*'));
        FND_FILE.PUT_LINE (FND_FILE.LOG, 'In CREATE_CUSTOMERS_SITES');

        FOR I IN C1
        LOOP
            LN_LOCATION_ID := NULL;
            LN_PARTY_ID := NULL;
            I.ERP_ERR_MSG := NULL;
            I.ERP_PROCESS_FLAG := 'S';
            FND_FILE.PUT_LINE (FND_FILE.LOG, RPAD ('+', 25, '+'));

            BEGIN
                BEGIN
                    SELECT CUST_ACCOUNT_ID, ACCOUNT_NUMBER, PARTY_ID
                      INTO LN_CUST_ACCOUNT_ID, LC_ACCOUNT_NUMBER, LN_PARTY_ID
                      FROM HZ_CUST_ACCOUNTS
                     WHERE     CUST_ACCOUNT_ID = I.ERP_CUSTOMER_ID
                           AND PARTY_ID = I.ERP_PARTY_ID;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        LN_CUST_ACCOUNT_ID := -1;
                        LC_ACCOUNT_NUMBER := NULL;
                        LN_PARTY_ID := -1;
                        I.ERP_ERR_MSG :=
                            REG_ERR_MSG (
                                I.ERP_ERR_MSG,
                                   'ERP Customer not available : '
                                || I.ERP_CUSTOMER_NUMBER);
                        I.ERP_PROCESS_FLAG := 'E';
                END;

                FND_FILE.PUT_LINE (
                    FND_FILE.LOG,
                       'LN_CUST_ACCOUNT_ID: '
                    || LN_CUST_ACCOUNT_ID
                    || '; PARTY_ID: '
                    || LN_PARTY_ID);

                IF LN_CUST_ACCOUNT_ID > 0 AND LN_PARTY_ID > 0
                THEN
                    FOR J IN C2 (P_AGENCY_ID      => I.AGENCY_ID,
                                 P_CUST_NAME      => I.CUSTOMER_NAME,
                                 P_UNIT           => I.UNIT,
                                 P_CUST_TYPE      => I.CUSTOMER_TYPE,
                                 P_ACCOUNT_DESC   => I.ACCOUNT_DESCRIPTION)
                    LOOP
                        BEGIN
                            -- Resetting the Variables For Correct Values And Updation
                            LN_LOCATION_ID := -1;
                            LN_PARTY_SITE_ID := -1;
                            LN_CUST_ACCT_SITE_ID := -1;
                            LN_SITE_USE_ID := -1;
                            J.ERP_ERR_MSG := NULL;
                            J.ERP_PROCESS_FLAG := 'S';

                            BEGIN
                                SELECT LOCATION_ID
                                  INTO LN_LOCATION_ID
                                  FROM HZ_LOCATIONS
                                 WHERE     1 = 1
                                       AND ADDRESS1 = J.ADDRESS1
                                       AND CITY = J.CITY
                                       AND DESCRIPTION = J.NAME_OF_CENTRE --J.LOCATION1
                                                                         ;
                            EXCEPTION
                                WHEN OTHERS
                                THEN
                                    CREATE_LOCATION (
                                        P_ADDRESS1      => J.ADDRESS1,
                                        P_ADDRESS2      => J.ADDRESS2,
                                        P_ADDRESS3      => J.ADDRESS3,
                                        P_ADDRESS4      => J.ADDRESS4,
                                        P_CITY          => J.CITY,
                                        P_POSTAL_CODE   => J.POSTAL_CODE,
                                        P_STATE         => J.STATE,
                                        P_COUNTY        => J.COUNTY,
                                        P_COUNTRY       => J.COUNTRY,
                                        P_LOCATION1     => J.NAME_OF_CENTRE --J.LOCATION1
                                                                           ,
                                        P_LOCATION_ID   => LN_LOCATION_ID,
                                        P_MSG           => LC_MSG);
                                    J.ERP_ERR_MSG :=
                                        REG_ERR_MSG (J.ERP_ERR_MSG, LC_MSG);
                            END;

                            IF LN_LOCATION_ID > 0
                            THEN
                                BEGIN
                                    SELECT PARTY_SITE_ID
                                      INTO LN_PARTY_SITE_ID
                                      FROM HZ_PARTY_SITES
                                     WHERE     1 = 1
                                           AND PARTY_ID = LN_PARTY_ID
                                           AND LOCATION_ID = LN_LOCATION_ID
                                           AND PARTY_SITE_NAME =
                                               J.STATION_NAME;
                                EXCEPTION
                                    WHEN OTHERS
                                    THEN
                                        CREATE_PARTY_SITE (
                                            P_PARTY_ID         => LN_PARTY_ID,
                                            P_LOCATION_ID      => LN_LOCATION_ID,
                                            P_CUSTOMER_TYPE    =>
                                                I.CUSTOMER_TYPE,
                                            P_STATION_NAME     => J.STATION_NAME,
                                            P_PARTY_SITE_ID    =>
                                                LN_PARTY_SITE_ID,
                                            P_PARTY_SITE_NUM   =>
                                                LC_PARTY_SITE_NUM,
                                            P_MSG              => LC_MSG);
                                        J.ERP_ERR_MSG :=
                                            REG_ERR_MSG (J.ERP_ERR_MSG,
                                                         LC_MSG);
                                END;
                            ELSE
                                J.ERP_PROCESS_FLAG := 'E';
                                J.ERP_ERR_MSG :=
                                    REG_ERR_MSG (
                                        J.ERP_ERR_MSG,
                                           'Location is not available/created for location1 :'
                                        || J.LOCATION1);
                            END IF;

                            -- Creating Customer Account Site
                            IF LN_PARTY_SITE_ID > 0
                            THEN
                                BEGIN
                                    SELECT CUST_ACCT_SITE_ID
                                      INTO LN_CUST_ACCT_SITE_ID
                                      FROM HZ_CUST_ACCT_SITES_ALL
                                     WHERE     1 = 1
                                           AND CUST_ACCOUNT_ID =
                                               LN_CUST_ACCOUNT_ID
                                           AND PARTY_SITE_ID =
                                               LN_PARTY_SITE_ID;
                                EXCEPTION
                                    WHEN OTHERS
                                    THEN
                                        CREATE_CUST_ACCT_SITE (
                                            P_CUST_ACCOUNT_ID   =>
                                                LN_CUST_ACCOUNT_ID,
                                            P_PARTY_SITE_ID   =>
                                                LN_PARTY_SITE_ID,
                                            P_CUSTOMER_TYPE   =>
                                                I.CUSTOMER_TYPE,
                                            P_CUST_ACCT_SITE_ID   =>
                                                LN_CUST_ACCT_SITE_ID,
                                            P_MSG   => LC_MSG);
                                        J.ERP_ERR_MSG :=
                                            REG_ERR_MSG (J.ERP_ERR_MSG,
                                                         LC_MSG);
                                END;
                            ELSE
                                J.ERP_PROCESS_FLAG := 'E';
                                J.ERP_ERR_MSG :=
                                    REG_ERR_MSG (
                                        J.ERP_ERR_MSG,
                                           'Party Site Error for STATION_NAME: '
                                        || J.STATION_NAME
                                        || ', Party ID: '
                                        || LN_PARTY_ID
                                        || ', Location ID:'
                                        || LN_LOCATION_ID);
                            END IF;


                            IF LN_CUST_ACCT_SITE_ID > 0
                            THEN
                                CREATE_CUST_SITE_USES (
                                    P_CUST_ACCT_SITE_ID   =>
                                        LN_CUST_ACCT_SITE_ID,
                                    P_SITE_USE_CODE   => 'SHIP_TO',
                                    P_CUSTOMER_TYPE   => I.CUSTOMER_TYPE,
                                    P_LOCATION        => J.NAME_OF_CENTRE --J.LOCATION1
                                                                         ,
                                    P_CENTRE_NUMBER   => J.CENTRE_NUMBER,
                                    P_PRIMARY_FLAG    => J.PRIMARY_FLAG,
                                    P_PAYMENT_TERMS   => J.PAYMENT_TERMS,
                                    P_REC_ACCOUNT     => J.REC_ACCOUNT,
                                    P_SITE_USE_ID     => LN_SITE_USE_ID,
                                    P_CCID            => LN_CCID_S -- Added to retrive the CODE_COMBINATION_ID
                                                                  ,
                                    P_MSG             => LC_MSG);

                                IF LN_SITE_USE_ID < 0
                                THEN
                                    J.ERP_PROCESS_FLAG := 'E';
                                    J.ERP_ERR_MSG :=
                                        REG_ERR_MSG (J.ERP_ERR_MSG, LC_MSG);
                                END IF;

                                CREATE_CONTACT_ORG (
                                    P_PARTY_ID         => LN_PARTY_ID,
                                    P_CONTACT_PERSON   => I.CONTACT_PERSON,
                                    P_MSG              => LC_MSG);

                                -- start: Creating Contact Point -- Added on 07-APR-2026
                                CREATE_CONTACT_POINT_SITE_LVL (
                                    P_PARTY_SITE_ID            => LN_PARTY_SITE_ID,
                                    P_PHONE                    => J.MOBILE_NO,
                                    P_EMAIL                    => J.EMAIL,
                                    P_TABLE                    => 'HZ_PARTY_SITES',
                                    P_PHONE_CONTACT_POINT_ID   =>
                                        LN_PHONE_CONTACT_POINT_ID,
                                    P_EMAIL_CONTACT_POINT_ID   =>
                                        LN_EMAIL_CONTACT_POINT_ID,
                                    P_MSG                      => LC_MSG);

                                IF LN_PHONE_CONTACT_POINT_ID < 0
                                THEN
                                    FND_FILE.PUT_LINE (
                                        FND_FILE.LOG,
                                           'Cannot create Phone Cotact Point : '
                                        || J.MOBILE_NO);
                                END IF;

                                IF LN_EMAIL_CONTACT_POINT_ID < 0
                                THEN
                                    FND_FILE.PUT_LINE (
                                        FND_FILE.LOG,
                                           'Cannot create Email Cotact Point : '
                                        || J.EMAIL);
                                END IF;

                                -- end : Added Email and Phone contact points on 07-APR-2026

                                FND_FILE.PUT_LINE (FND_FILE.LOG,
                                                   RPAD ('_', 25, '_'));
                                LN_CCID := -1;

                                --Start:  Added by AKALA on 10-APR-2026, create or get CCID if it is not created inside CREATE_CUST_SITE_USE
                                IF LN_CCID_S < 0
                                THEN
                                    BEGIN
                                        SELECT CODE_COMBINATION_ID
                                          INTO LN_CCID
                                          FROM GL_CODE_COMBINATIONS_KFV
                                         WHERE CONCATENATED_SEGMENTS =
                                               J.REC_ACCOUNT;
                                    EXCEPTION
                                        WHEN OTHERS
                                        THEN
                                            --Start:  Added by AKALA on 08-APR-2026, to create or get CCID
                                            CREATE_CODE_COMBINATION (
                                                P_ORG_ID        => J.ORG_ID,
                                                P_INV_ORG       => J.INV_ORG,
                                                P_AGENCY_ID     => J.AGENCY_ID,
                                                P_CENTRE_NUMBER   =>
                                                    J.CENTRE_NUMBER,
                                                P_AGENCY_NAME   =>
                                                    I.AGENCY_NAME,
                                                P_CCID          => LN_CCID,
                                                P_MSG           => LC_MSG);
                                            FND_FILE.PUT_LINE (
                                                FND_FILE.LOG,
                                                   'Retrived Code Combination ID : '
                                                || LN_CCID);
                                    -- END :  Added by AKALA on 08-APR-2026, to create or get CCID
                                    END;
                                ELSE
                                    LN_CCID := LN_CCID_S;
                                END IF;

                                -- END :  Added by AKALA on 10-APR-2026, to create or get CCID before creating the SITE USES

                                LC_ERR_MSG := LC_ERR_MSG || '-' || LC_MSG;
                            ELSE
                                J.ERP_PROCESS_FLAG := 'E';
                                J.ERP_ERR_MSG :=
                                    REG_ERR_MSG (
                                        J.ERP_ERR_MSG,
                                           'CUST SITE ACCT error : CUST_ACCOUNT_ID - '
                                        || LN_CUST_ACCOUNT_ID
                                        || ', PARTY_SITE_ID - '
                                        || LN_PARTY_SITE_ID);
                            END IF;

                           /*UPDATE AU_CUSTOMER_SHIP_TO@ebstohr -- Commented by AKALA on 20-APR-2026; 
                               SET ERP_CUSTOMER_NUMBER = LC_ACCOUNT_NUMBER,
                                   ERP_CREATION_DATE = SYSDATE,
                                   CUSTOMER_SHIP_ID = LN_CUST_ACCT_SITE_ID,
                                   ERP_SITE_USE_ID = LN_SITE_USE_ID,
                                   ERP_CUSTOMER_ID = LN_CUST_ACCOUNT_ID,
                                   ERP_PARTY_ID = LN_PARTY_ID,
                                   ERP_PROCESS_FLAG = J.ERP_PROCESS_FLAG,
                                   CCID = LN_CCID,
                                   ERP_ERR_MSG =
                                          DECODE (ERP_ERR_MSG,
                                                  NULL, '',
                                                  ERP_ERR_MSG || '; ')
                                       || J.ERP_ERR_MSG
                             WHERE     1 = 1
                                   AND AGENCY_ID = J.AGENCY_ID
                                   AND CENTRE_NUMBER = J.CENTRE_NUMBER
                                   AND MAIN_CENTRE_NUMBER =
                                       J.MAIN_CENTRE_NUMBER;

                            COMMIT;
							*/
							FND_FILE.PUT_LINE (
                                FND_FILE.LOG,
                                   'LN_CUST_ACCOUNT_ID: '
                                || LN_CUST_ACCOUNT_ID
                                || '; PARTY_ID: '
                                || LN_PARTY_ID
                                || '; LN_LOCATION_ID: '
                                || LN_LOCATION_ID
                                || '; LN_PARTY_SITE_ID: '
                                || LN_PARTY_SITE_ID
                                || '; LN_CUST_ACCT_SITE_ID: '
                                || LN_CUST_ACCT_SITE_ID
                                || '; LN_SITE_USE_ID: '
                                || LN_SITE_USE_ID);
								
							-- Updating AU_CUSTOMER_SHIP_TO@ebstohr on Successful Creation of every Site and Uses	
							
							-- Added by AKALA on 20-APR-2026; because the new package is created to update data in AU_CUSTOMER_SHIP_TO base tables.
							XXAU_UPDT_CUSTOM_CUST_DATA_PKG.UPDATE_CUSTS_SHIP_SITES@EBSTOHR( P_ACCOUNT_NUMBER => LC_ACCOUNT_NUMBER, 
																							P_CUST_ACCT_SITE_ID => LN_CUST_ACCT_SITE_ID,
																							P_SITE_USE_ID => LN_SITE_USE_ID,
																							P_CUST_ACCOUNT_ID => LN_CUST_ACCOUNT_ID,
																							P_PARTY_ID => LN_PARTY_ID,
																							P_PROCESS_FLAG => J.ERP_PROCESS_FLAG,
																							P_CCID => LN_CCID,
																							P_ERR_MSG => J.ERP_ERR_MSG ,
																							P_AGENCY_ID => J.AGENCY_ID,
																							P_CENTRE_NUMBER => J.CENTRE_NUMBER,
																							P_MAIN_CENTRE_NUMBER => J.MAIN_CENTRE_NUMBER
																							);
							COMMIT;
							
							
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                FND_FILE.PUT_LINE (
                                    FND_FILE.LOG,
                                    SQLCODE || ' - ' || SQLERRM);
                        END;

                        FND_FILE.PUT_LINE (FND_FILE.LOG, RPAD ('*', 25, '*'));
                    END LOOP;
                ELSE
                    FND_FILE.PUT_LINE (
                        FND_FILE.LOG,
                           'LN_CUST_ACCOUNT_ID: '
                        || LN_CUST_ACCOUNT_ID
                        || '; PARTY_ID: '
                        || LN_PARTY_ID
                        || '; Msg : '
                        || LC_MSG);
                    I.ERP_PROCESS_FLAG := 'E';

					/* -- Commented by AKALA, on 20-APR-2026
                    UPDATE AU_CUSTOMER_MASTER_NEW@ebstohr
                       SET ERP_PROCESS_FLAG = I.ERP_PROCESS_FLAG,
                           ERP_ERR_MSG =
                                  DECODE (ERP_ERR_MSG,
                                          NULL, '',
                                          ERP_ERR_MSG || '; ')
                               || I.ERP_ERR_MSG
                     WHERE AGENCY_ID = I.AGENCY_ID;
					 */
					 
					 
					 -- Added by AKALA on 20-APR-2026; because the new package is created to update data in AU_CUSTOMER_MASTER_NEW base table.
					 XXAU_UPDT_CUSTOM_CUST_DATA_PKG.UPDATE_CUSTS_MAST_NEW@EBSTOHR (P_PROCESS_FLAG => I.ERP_PROCESS_FLAG,
									P_ERR_MSG => I.ERP_ERR_MSG,
									P_AGENCY_ID => I.AGENCY_ID
									);
					 COMMIT;
					 
                END IF;
            EXCEPTION
                WHEN OTHERS
                THEN
                    FND_FILE.PUT_LINE (FND_FILE.LOG,
                                       SQLCODE || ' - ' || SQLERRM);
            END;

            /* -- Commented by AKALA, on 20-APR-2026
			UPDATE AU_CUSTOMER_MASTER_NEW@ebstohr
			SET ERP_PROCESS_FLAG = I.ERP_PROCESS_FLAG
			 , ERP_ERR_MSG = DECODE(ERP_ERR_MSG,NULL,'',ERP_ERR_MSG||'; ')||I.ERP_ERR_MSG
			WHERE AGENCY_ID = I.AGENCY_ID ;

			COMMIT;
			*/
			
			-- Added by AKALA on 20-APR-2026; because the new package is created to update data in AU_CUSTOMER_MASTER_NEW base table.
			XXAU_UPDT_CUSTOM_CUST_DATA_PKG.UPDATE_CUSTS_MAST_NEW@EBSTOHR (P_PROCESS_FLAG => I.ERP_PROCESS_FLAG,
							P_ERR_MSG => I.ERP_ERR_MSG,
							P_AGENCY_ID => I.AGENCY_ID
							);
			COMMIT;
			
            FND_FILE.PUT_LINE (
                FND_FILE.LOG,
                   'LN_CUST_ACCOUNT_ID: '
                || LN_CUST_ACCOUNT_ID
                || '; PARTY_ID: '
                || LN_PARTY_ID
                || '; Msg : '
                || LC_MSG);
            FND_FILE.PUT_LINE (
                FND_FILE.LOG,
                'LN_LOCATION_ID: ' || LN_LOCATION_ID || '; Msg : ' || LC_MSG);
            FND_FILE.PUT_LINE (
                FND_FILE.LOG,
                   'LN_PARTY_SITE_ID: '
                || LN_PARTY_SITE_ID
                || '; Msg : '
                || LC_MSG);
            FND_FILE.PUT_LINE (
                FND_FILE.LOG,
                   'LN_CUST_ACCT_SITE_ID: '
                || LN_CUST_ACCT_SITE_ID
                || '; Msg : '
                || LC_MSG);
            FND_FILE.PUT_LINE (
                FND_FILE.LOG,
                'LN_SITE_USE_ID: ' || LN_SITE_USE_ID || '; Msg : ' || LC_MSG);
            FND_FILE.PUT_LINE (FND_FILE.LOG, RPAD ('*', 25, '*'));
            FND_FILE.PUT_LINE (
                FND_FILE.LOG,
                'Loop for Agency ID: ' || I.AGENCY_ID || ' is completed.');
            FND_FILE.PUT_LINE (FND_FILE.LOG, RPAD ('*', 25, '*'));
        END LOOP;
    EXCEPTION
        WHEN OTHERS
        THEN
            FND_FILE.PUT_LINE (FND_FILE.LOG, SQLCODE || ' - ' || SQLERRM);
    END CREATE_CUSTOMERS_SITES;

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
     * AKALA            2.0         20-APR-2026     upgraded version for custom schema PACKAGE
     ***************************************************************************************************/
    PROCEDURE VALIDATE_REQUIRED
    AS
    BEGIN
        FND_FILE.PUT_LINE (FND_FILE.LOG, 'In APPS VALIDATE_REQUIRED');
        FND_FILE.PUT_LINE (FND_FILE.LOG, 'GN_USER_ID: ' || GN_USER_ID);
        FND_FILE.PUT_LINE (FND_FILE.LOG, 'GN_ORG_ID: ' || GN_ORG_ID);
        FND_FILE.PUT_LINE (FND_FILE.LOG, 'GN_RESP_ID: ' || GN_RESP_ID);
        FND_FILE.PUT_LINE (FND_FILE.LOG, 'GN_RESP_APPL_ID: ' || GN_RESP_APPL_ID);

        FND_FILE.PUT_LINE (FND_FILE.LOG, RPAD ('*', 30, '*'));
        FND_FILE.PUT_LINE (FND_FILE.LOG, 'In Validation Started..');

		XXAU_UPDT_CUSTOM_CUST_DATA_PKG.VALIDATE_REQUIRED@EBSTOHR;
		COMMIT;
		
        FND_FILE.PUT_LINE (FND_FILE.LOG, 'Validation Completed..');
        FND_FILE.PUT_LINE (FND_FILE.LOG, RPAD ('*', 30, '*'));
    EXCEPTION
        WHEN OTHERS
        THEN
            FND_FILE.PUT_LINE (FND_FILE.LOG, SQLCODE || ' - ' || SQLERRM);
    END VALIDATE_REQUIRED;

    /*************************************************************************************************
     * Program Name : LOAD_DATA
     * Language     : PL/SQL
     * Description  : To insert the data into the XXAU_CUSTOMER_DETAILS@ebstohr table
     * History      -----------------------------------------------------------------------------------
  * Parameters   :
     *
     * WHO              Version #   WHEN            WHAT
     * ===============  =========   =============   ====================================================
     * AKALA            1.0         10-APR-2026     Initial Version
     * AKALA            2.0         20-APR-2026     upgraded version for custom schema PACKAGE
     ***************************************************************************************************/
    PROCEDURE LOAD_DATA
		IS
    BEGIN
       XXAU_UPDT_CUSTOM_CUST_DATA_PKG.LOAD_DATA@EBSTOHR;
       COMMIT;
	   
	   FND_FILE.PUT_LINE (
            FND_FILE.LOG,
            'LOAD_DATA PROCEDURE COMPLETE : ' || SQLCODE || ' - ' || SQLERRM);
        FND_FILE.PUT_LINE (FND_FILE.LOG, RPAD ('+', 25, '+'));
    EXCEPTION
        WHEN OTHERS
        THEN
            FND_FILE.PUT_LINE (FND_FILE.LOG, SQLCODE || ' - ' || SQLERRM);
    END LOAD_DATA;


    /***************************************************************************************************
     * Program Name : MAIN
     * Language     : PL/SQL
     * Description  : Starting of the process.
     * History      -----------------------------------------------------------------------------------
  * Parameters   : ERRBUFF => OUT PARAMETER,VARCHAR2 - MANDATORY FOR CONCURRENT PROGRAM
       RETCODE => OUT PARAMETER,VARCHAR2 - MANDATORY FOR CONCURRENT PROGRAM
     *
     * WHO              Version #   WHEN            WHAT
     * ===============  =========   =============   ====================================================
     * AKALA            1.0         01-APR-2026     Initial Version
     * AKALA            1.1         13-APR-2026     Enter new procedure LOAD_DATA
     ***************************************************************************************************/
    PROCEDURE MAIN (ERRBUFF OUT VARCHAR2, RETCODE OUT VARCHAR2)
    AS
    BEGIN
        FND_FILE.PUT_LINE (FND_FILE.LOG, RPAD ('*', 25, '*'));
        FND_FILE.PUT_LINE (FND_FILE.LOG, '### Process Started ###');
        FND_FILE.PUT_LINE (FND_FILE.LOG, RPAD ('*', 25, '*'));
        LOAD_DATA;
        VALIDATE_REQUIRED;
        CREATE_CUSTOMERS_SITES; -- Uncomment to create the sites of the customer where sites does not belongs to Safalta
        --CREATE_CUSTOMER_AND_SITES; -- Uncomment to create customer and as well as sites where site does not belongs to Safalta
        --CREATE_SAFALTA_CUST_AND_SITES; --Uncomment to create customer and sites where sites belongs to Safalta either customer already exists or not
        UPDATE_CUST_DETAILS;
    EXCEPTION
        WHEN OTHERS
        THEN
            FND_FILE.PUT_LINE (FND_FILE.LOG, SQLCODE || ' - ' || SQLERRM);
    END MAIN;
END XXAU_CREATE_CUSTOMER_SITE_PKG;
/