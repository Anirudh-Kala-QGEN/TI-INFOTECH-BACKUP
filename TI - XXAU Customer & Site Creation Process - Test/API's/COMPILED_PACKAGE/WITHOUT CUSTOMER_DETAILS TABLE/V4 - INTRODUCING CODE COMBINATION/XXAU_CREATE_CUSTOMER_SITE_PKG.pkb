CREATE OR REPLACE PACKAGE BODY XXAU_CREATE_CUSTOMER_SITE_PKG
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
     * AKALA            1.4         08-APR-2026      Updated Version -> Create Procedure 1. CREATED CREATE_CODE_COMBINATION
																					     2. (Update conditions in CREATE_CUSTOMER_SITES
																						 , CREATE_CUSTOMER_AND_SITES 
																						 and CREATE_SAFALTA_CUST_AND_SITES FOR CODE COMBINATION)
     * AKALA            1.5         09-APR-2026      Updated Version -> Create Procedure (Updated Validate Required - For validations)
	 ************************************************************************************************************************************/

	 /*************************************************************************************************
     * Program Name : CREATE_CODE_COMBINATION
     * Language     : PL/SQL
     * Description  : Creates the CODE COMBINATION ID; GET if code combination already exists.
     * History      -----------------------------------------------------------------------------------
	 * Parameters   : P_ORG_ID 			=> IN PARAMETER , NUMBER
					  P_INV_ORG 		=> IN PARAMETER , NUMBER
					  P_AGENCY_ID		=> IN PARAMETER , NUMBER
					  P_CENTRE_NUMBER 	=> IN PARAMETER , VARCHAR2
					  P_AGENCY_NAME 	=> IN PARAMETER , VARCHAR2
					  P_CCID 			=> OUT PARAMETER , NUMBER 
					  P_MSG 			=> OUT PARAMETER , VARCHAR2 (FOR ERROR MESSAGE)
     *
     * WHO              Version #   WHEN            WHAT
     * ===============  =========   =============   ====================================================
     * AKALA            1.0         08-APR-2026     Initial Version
     ***************************************************************************************************/

	PROCEDURE CREATE_CODE_COMBINATION (P_ORG_ID 		IN NUMBER
									, P_INV_ORG 		IN NUMBER
									, P_AGENCY_ID 		IN NUMBER
									, P_CENTRE_NUMBER 	IN VARCHAR2
									, P_AGENCY_NAME 	IN VARCHAR2
									, P_CCID			OUT NUMBER
									, P_MSG 			OUT VARCHAR2)
	AS
	LN_CCID GL_CODE_COMBINATIONS.CODE_COMBINATION_ID%TYPE;
	LC_CONCATE_SEGMENTS GL_CODE_COMBINATIONS_KFV.CONCATENATED_SEGMENTS%TYPE;
	LN_CHART_OF_ACCT_ID NUMBER;
	BEGIN
	
	FND_FILE.PUT_LINE(FND_FILE.LOG,RPAD('=',25,'='));
	FND_FILE.PUT_LINE(FND_FILE.LOG,'CREATE_CODE_COMBINATION');
	FND_FILE.PUT_LINE(FND_FILE.LOG,RPAD('=',25,'='));
		BEGIN
			    SELECT CHART_OF_ACCOUNTS_ID
				INTO LN_CHART_OF_ACCT_ID
				FROM ORG_ORGANIZATION_DEFINITIONS
				WHERE OPERATING_UNIT =  P_ORG_ID
				AND ORGANIZATION_ID = P_INV_ORG;
		EXCEPTION
			WHEN OTHERS
			THEN
				BEGIN
					SELECT CHART_OF_ACCOUNTS_ID
					INTO LN_CHART_OF_ACCT_ID
					FROM GL_SETS_OF_BOOKS
					WHERE SET_OF_BOOKS_ID = FND_PROFILE.VALUE('GL_SET_OF_BKS_ID');
				EXCEPTION
				WHEN OTHERS
				THEN 
					LN_CHART_OF_ACCT_ID := -1;
					P_CCID := -1;
					P_MSG := 'Cannot find Chart Accounts ID.' ;
					FND_FILE.PUT_LINE(FND_FILE.LOG,SQLCODE||'-'||SQLERRM);
					FND_FILE.PUT_LINE(FND_FILE.LOG,P_MSG);
				END;
		END;
		
		
		IF LN_CHART_OF_ACCT_ID > 0
		THEN
			BEGIN
				SELECT  A.REC_ACCOUNT
					INTO LC_CONCATE_SEGMENTS
				FROM XXAU_CUSTOMER_DETAILS_TEST A
				, AU_CUSTOMER_MASTER_NEW_TEST B
				, AU_CUSTOMER_SHIP_TO_TEST C
				WHERE 1=1
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
				
				P_CCID := FND_FLEX_EXT.get_ccid('SQLGL'
												, 'GL#'
												, LN_CHART_OF_ACCT_ID
												, TO_CHAR(SYSDATE,'DD-MON-YYYY')
												, LC_CONCATE_SEGMENTS
												);
				
				IF P_CCID  <= 0 
					THEN 
						P_MSG := P_MSG||'- Not able to create Code Combination.';
						P_CCID:= -1; 
				END IF;
				FND_FILE.PUT_LINE(FND_FILE.LOG,'CODE_COMBINATION_ID : '||P_CCID);
			EXCEPTION
			WHEN OTHERS 
				THEN 
					P_CCID := -1;
					LN_CHART_OF_ACCT_ID:= -1;
					P_MSG := P_MSG||' - '||'Customer REC_ACCOUNT is not available in XXAU_CUSTOMER_DETAILS.';
			END;
		END IF;
	EXCEPTION
	WHEN OTHERS 
		THEN 
			LN_CHART_OF_ACCT_ID:= -1;
			P_CCID := -1;
	END CREATE_CODE_COMBINATION;

	 /*************************************************************************************************
     * Program Name : CREATE_CONTACT_POINT_SITE_LVL
     * Language     : PL/SQL
     * Description  : Creates the final Customer contact point details according to site level for Email and Phone
     * History      -----------------------------------------------------------------------------------
	 * Parameters   : P_PARTY_SITE_ID 			=> IN PARAMETER, NUMBER
					  P_PHONE 					=> IN PARAMETER , NUMBER
					  P_EMAIL					=> IN PARAMETER , VARCHAR2
					  P_TABLE 					=> IN PARAMETER ,VARCHAR (HZ_PARTIES , HZ_PARTY_SITES)
					  P_PHONE_CONTACT_POINT_ID 	=> OUT PARAMETER , NUMBER
					  P_EMAIL_CONTACT_POINT_ID 	=> OUT PARAMETER , NUMBER 
					  P_MSG 					=> OUT PARAMETER , VARCHAR2 (FOR ERROR MESSAGE)
     *
     * WHO              Version #   WHEN            WHAT
     * ===============  =========   =============   ====================================================
     * AKALA            1.0         07-APR-2026     Initial Version
     ***************************************************************************************************/
	PROCEDURE CREATE_CONTACT_POINT_SITE_LVL ( P_PARTY_SITE_ID IN NUMBER
											, P_PHONE IN NUMBER 
											, P_EMAIL IN VARCHAR2
											, P_TABLE IN VARCHAR2
											, P_PHONE_CONTACT_POINT_ID OUT NUMBER
											, P_EMAIL_CONTACT_POINT_ID OUT NUMBER
											, P_MSG OUT VARCHAR2)
	AS
	   L_CONTACT_POINT_REC    HZ_CONTACT_POINT_V2PUB.CONTACT_POINT_REC_TYPE;
	   L_EDI_REC              HZ_CONTACT_POINT_V2PUB.EDI_REC_TYPE;
	   L_EMAIL_REC            HZ_CONTACT_POINT_V2PUB.EMAIL_REC_TYPE;
	   L_PHONE_REC            HZ_CONTACT_POINT_V2PUB.PHONE_REC_TYPE;
	   L_TELEX_REC            HZ_CONTACT_POINT_V2PUB.TELEX_REC_TYPE;
	   L_WEB_REC              HZ_CONTACT_POINT_V2PUB.WEB_REC_TYPE;
	   LN_PHONE_CONTACT_POINT_ID     HZ_CONTACT_POINTS.CONTACT_POINT_ID%TYPE;
	   LN_EMAIL_CONTACT_POINT_ID     HZ_CONTACT_POINTS.CONTACT_POINT_ID%TYPE;
	   L_RETURN_STATUS        VARCHAR2(100);
	   L_MSG_COUNT            NUMBER;
	   L_MSG_DATA             VARCHAR2(2000);
	BEGIN
	   DBMS_OUTPUT.ENABLE (BUFFER_SIZE => NULL);
	   --INITIATE THE EBS ENVIRONMENT FOR API PROCESSING
	   FND_GLOBAL.APPS_INITIALIZE(GN_USER_ID, GN_RESP_ID, GN_RESP_APPL_ID);
	   MO_GLOBAL.INIT('AR');
	   FND_CLIENT_INFO.SET_ORG_CONTEXT(GN_ORG_ID);
	   -- INITIALIZING THE MANDATORY API PARAMETERS
	   
	   P_MSG:= NULL;
	   
	   -- TO CREATE PHONE CONTACT POINT ACCORDING TO SITE
	   IF TRIM(P_PHONE) IS NOT NULL
	   THEN
	   --CONTACT RECORD
	   L_CONTACT_POINT_REC.CONTACT_POINT_TYPE    := 'PHONE';
	   L_CONTACT_POINT_REC.OWNER_TABLE_NAME      := P_TABLE;
	   L_CONTACT_POINT_REC.OWNER_TABLE_ID        := P_PARTY_SITE_ID;
	   L_CONTACT_POINT_REC.PRIMARY_FLAG          := 'Y';
	   L_CONTACT_POINT_REC.CONTACT_POINT_PURPOSE := 'BUSINESS';
	   L_CONTACT_POINT_REC.CREATED_BY_MODULE     := 'BO_API';
	   --PHONE RECORD
	   L_PHONE_REC.PHONE_COUNTRY_CODE            := '91';
	   L_PHONE_REC.PHONE_NUMBER                  := P_PHONE;
	   L_PHONE_REC.PHONE_LINE_TYPE               := 'MOBILE';
	   --Calling hz_contact_point_v2pub.create_contact_point
	   FND_FILE.PUT_LINE(FND_FILE.LOG,'Calling hz_contact_point_v2pub.create_contact_point api');
	   HZ_CONTACT_POINT_V2PUB.CREATE_CONTACT_POINT
				 (
				   P_INIT_MSG_LIST      => FND_API.G_TRUE,
				   P_CONTACT_POINT_REC  => L_CONTACT_POINT_REC,
				   P_EDI_REC            => L_EDI_REC,
				   --P_EMAIL_REC          => L_EMAIL_REC,
				   P_PHONE_REC          => L_PHONE_REC,
				   P_TELEX_REC          => L_TELEX_REC,
				   P_WEB_REC            => L_WEB_REC,
				   X_CONTACT_POINT_ID   => LN_PHONE_CONTACT_POINT_ID,
				   X_RETURN_STATUS      => L_RETURN_STATUS,
				   X_MSG_COUNT          => L_MSG_COUNT,
				   X_MSG_DATA           => L_MSG_DATA
				  );
			IF L_RETURN_STATUS = 'S' 
			THEN
				FND_FILE.PUT_LINE(FND_FILE.LOG,'Contact Point Creation is Successful '); 
				FND_FILE.PUT_LINE(FND_FILE.LOG,'contact_point_id = '||LN_PHONE_CONTACT_POINT_ID); 
				P_PHONE_CONTACT_POINT_ID := LN_PHONE_CONTACT_POINT_ID;
				COMMIT;
			ELSE
				FND_FILE.PUT_LINE(FND_FILE.LOG,'Contact Point Creation failed:'||L_MSG_DATA);
				FOR i IN 1 .. L_MSG_COUNT
					LOOP
					L_MSG_DATA := FND_MSG_PUB.GET( P_MSG_INDEX => I, P_ENCODED => 'F');
					FND_FILE.PUT_LINE(FND_FILE.LOG, I|| ') '|| L_MSG_DATA);
					P_MSG := P_MSG||'; '||L_MSG_DATA;
				END LOOP;
				FND_FILE.PUT_LINE(FND_FILE.LOG,'Contact Point Creation failed:'||L_MSG_DATA);
				P_EMAIL_CONTACT_POINT_ID := -1;
				ROLLBACK;
			END IF;
	   ELSE
	   P_PHONE_CONTACT_POINT_ID := -1;
	   END IF;
	   FND_FILE.PUT_LINE(FND_FILE.LOG,RPAD('-',25,'-'));
	   
	   -- TO CREATE EMAIL CONTACT POINT ACCORDING TO SITE LEVEL
	   IF TRIM(P_EMAIL) IS NOT NULL
	   THEN
		   L_CONTACT_POINT_REC.CONTACT_POINT_TYPE    := 'EMAIL';
		   L_CONTACT_POINT_REC.OWNER_TABLE_NAME      := P_TABLE;
		   L_CONTACT_POINT_REC.OWNER_TABLE_ID        := P_PARTY_SITE_ID;
		   L_CONTACT_POINT_REC.PRIMARY_FLAG          := 'Y';
		   L_CONTACT_POINT_REC.CONTACT_POINT_PURPOSE := 'BUSINESS';
		   L_CONTACT_POINT_REC.CREATED_BY_MODULE     := 'BO_API';
		   --EMAIL RECORD
		   L_EMAIL_REC.EMAIL_FORMAT                  := 'MAILHTML';
		   L_EMAIL_REC.EMAIL_ADDRESS                 := P_EMAIL;
		   --Calling hz_contact_point_v2pub.create_contact_point
		   FND_FILE.PUT_LINE(FND_FILE.LOG,'Calling hz_contact_point_v2pub.create_contact_point api');
		   HZ_CONTACT_POINT_V2PUB.CREATE_CONTACT_POINT
				 (
				   P_INIT_MSG_LIST      => FND_API.G_TRUE,
				   P_CONTACT_POINT_REC  => L_CONTACT_POINT_REC,
				   P_EDI_REC            => L_EDI_REC,
				   P_EMAIL_REC          => L_EMAIL_REC,
				   --P_PHONE_REC          => L_PHONE_REC,
				   P_TELEX_REC          => L_TELEX_REC,
				   P_WEB_REC            => L_WEB_REC,
				   X_CONTACT_POINT_ID   => LN_EMAIL_CONTACT_POINT_ID,
				   X_RETURN_STATUS      => L_RETURN_STATUS,
				   X_MSG_COUNT          => L_MSG_COUNT,
				   X_MSG_DATA           => L_MSG_DATA
				  );
				IF L_RETURN_STATUS = 'S' 
				THEN
					FND_FILE.PUT_LINE(FND_FILE.LOG,'EMAIL : Contact Point Creation is Successful '); 
					FND_FILE.PUT_LINE(FND_FILE.LOG,'Contact_point_id = '||LN_EMAIL_CONTACT_POINT_ID); 
					P_EMAIL_CONTACT_POINT_ID := LN_EMAIL_CONTACT_POINT_ID;
					COMMIT;
				ELSE
					FND_FILE.PUT_LINE(FND_FILE.LOG,'EMAIL : Contact Point Creation failed:'||L_MSG_DATA);
				  FOR i IN 1 .. L_MSG_COUNT
				  LOOP
					 L_MSG_DATA := FND_MSG_PUB.GET( P_MSG_INDEX => I, P_ENCODED => 'F');
					 FND_FILE.PUT_LINE(FND_FILE.LOG, I|| ') '|| L_MSG_DATA);
					 P_MSG := P_MSG||'; '||L_MSG_DATA;
				  END LOOP;
				  FND_FILE.PUT_LINE(FND_FILE.LOG,'EMAIL : Contact Point Creation failed:'||L_MSG_DATA);
				  P_EMAIL_CONTACT_POINT_ID := -1;
				  ROLLBACK;
				END IF;
	   ELSE
			P_EMAIL_CONTACT_POINT_ID := -1;
	   END IF;
	   FND_FILE.PUT_LINE(FND_FILE.LOG,'Contact Point Creation Complete');
	   FND_FILE.PUT_LINE(FND_FILE.LOG,RPAD('-',25,'-'));
	END CREATE_CONTACT_POINT_SITE_LVL;
	 
	
	 /*************************************************************************************************
     * Program Name : CREATE_CUST_SITE_USES
     * Language     : PL/SQL
     * Description  : Creates the final Customer Site Use as SHIP_TO
     * History      -----------------------------------------------------------------------------------
	 * Parameters   : P_CUST_ACCT_SITE_ID 		=> IN PARAMETER, NUMBER
					  P_SITE_USE_CODE 			=> IN PARAMETER (EITHER SHIP_TO OR BILL_TO) , VARCHAR2
					  P_LOCATION				=> IN PARAMETER LOCATION NAME , VARCHAR2
					  P_SITE_USE_ID 			=> OUT PARAMETER , NUMBER (FOR ERP SITE_USE_ID)
					  P_MSG 					=> OUT PARAMETER , VARCHAR2 (FOR ERROR MESSAGE)
     *
     * WHO              Version #   WHEN            WHAT
     * ===============  =========   =============   ====================================================
     * AKALA            1.0         6-APR-2026     Initial Version
     * AKALA            1.0         7-APR-2026     Update code for already existing Site Uses 
												   for Specific Location of specific customer
     ***************************************************************************************************/
	PROCEDURE CREATE_CUST_SITE_USES (P_CUST_ACCT_SITE_ID NUMBER
									,P_SITE_USE_CODE VARCHAR2
									,P_LOCATION VARCHAR2
									,P_SITE_USE_ID OUT NUMBER
									,P_MSG OUT VARCHAR2
									) 
	AS
		L_CUST_SITE_USE_REC    HZ_CUST_ACCOUNT_SITE_V2PUB.CUST_SITE_USE_REC_TYPE;
		L_CUSTOMER_PROFILE_REC HZ_CUSTOMER_PROFILE_V2PUB.CUSTOMER_PROFILE_REC_TYPE;
		L_SITE_USE_ID          HZ_CUST_SITE_USES.SITE_USE_ID%TYPE;
		L_RETURN_STATUS        VARCHAR2(100);
		L_MSG_COUNT            NUMBER;
		L_MSG_DATA             VARCHAR2(2000);
	BEGIN
			DBMS_OUTPUT.ENABLE (BUFFER_SIZE => NULL);
			P_MSG := NULL;
			FND_FILE.PUT_LINE(FND_FILE.LOG,RPAD('-',25,'-'));
		   --INITIATE THE EBS ENVIRONMENT FOR API PROCESSING
		   FND_GLOBAL.APPS_INITIALIZE(2482, 20678, 222);
		   MO_GLOBAL.INIT('AR');
		   FND_CLIENT_INFO.SET_ORG_CONTEXT(81);
		   --POPULATING CUST ACCT SITE RECORD  
		   L_CUST_SITE_USE_REC.CUST_ACCT_SITE_ID    := P_CUST_ACCT_SITE_ID;
		   L_CUST_SITE_USE_REC.SITE_USE_CODE        := NVL(P_SITE_USE_CODE,'SHIP_TO');
		   L_CUST_SITE_USE_REC.LOCATION             := P_LOCATION; --'NEW YORK';
		   L_CUST_SITE_USE_REC.CREATED_BY_MODULE    := 'BO_API';
		   --Calling hz_cust_account_site_v2pub.create_cust_site_use
		   FND_FILE.PUT_LINE(FND_FILE.LOG,'Calling hz_cust_account_site_v2pub.create_cust_site_use api');
		   HZ_CUST_ACCOUNT_SITE_V2PUB.CREATE_CUST_SITE_USE
						   (
							 p_init_msg_list         => FND_API.G_TRUE,
							 p_cust_site_use_rec     => l_cust_site_use_rec,
							 p_customer_profile_rec  => l_customer_profile_rec,
							 p_create_profile        => FND_API.G_TRUE,
							 p_create_profile_amt    => FND_API.G_TRUE,
							 x_site_use_id           => l_site_use_id,
							 x_return_status         => l_return_status,
							 x_msg_count             => l_msg_count,
							 x_msg_data              => l_msg_data
							);
		   IF l_return_status = 'S' 
		   THEN
				FND_FILE.PUT_LINE(FND_FILE.LOG,'Cust Site Use Creation is Successful '); 
				FND_FILE.PUT_LINE(FND_FILE.LOG,'site_use_id = '||l_site_use_id); 
				COMMIT;
		   ELSE
				--FND_FILE.PUT_LINE(FND_FILE.LOG,'Cust Site Use Creation failed:'||l_msg_data);
				FOR i IN 1 .. l_msg_count
				LOOP
					 l_msg_data := FND_MSG_PUB.get( p_msg_index => i, p_encoded => 'F');
					 FND_FILE.PUT_LINE(FND_FILE.LOG, i|| ') '|| l_msg_data);
					 P_MSG := P_MSG||l_msg_data||'; ';
				END LOOP;
				
				-- STATE - Added on 07-APR-2026, to assign the already exists site use id
				BEGIN
					SELECT SITE_USE_ID
					INTO L_SITE_USE_ID
					FROM HZ_CUST_SITE_USES_ALL
					WHERE 1=1
					AND UPPER(P_MSG) LIKE '%LOCATION ALREADY EXISTS FOR THIS BUSINESS PURPOSE AND CUSTOMER%'
					AND LOCATION = P_LOCATION
					AND SITE_USE_CODE = 'SHIP_TO'
					AND EXISTS (SELECT 1
								FROM HZ_CUST_ACCOUNTS HCA
								, HZ_CUST_ACCT_SITES_ALL HCASA
								WHERE 1=1
								AND HCA.CUST_ACCOUNT_ID = HCASA.CUST_ACCOUNT_ID
								AND HCASA.CUST_ACCT_SITE_ID = P_CUST_ACCT_SITE_ID);
					COMMIT;
				EXCEPTION
				WHEN OTHERS THEN
					ROLLBACK;
					L_SITE_USE_ID:= -1;
				END;
				-- Added on 07-APR-2026 END

			  --FND_FILE.PUT_LINE(FND_FILE.LOG,'Cust Site Use Creation failed:'||l_msg_data);
		   END IF;
		   --FND_FILE.PUT_LINE(FND_FILE.LOG,'Cust Site Use Creation Complete');
		P_SITE_USE_ID := L_SITE_USE_ID;
	EXCEPTION
	WHEN OTHERS 
	THEN 
		FND_FILE.PUT_LINE(FND_FILE.LOG,SQLCODE||' - '||SQLERRM);
		P_SITE_USE_ID := -1;
	END CREATE_CUST_SITE_USES;
		
		
	/*************************************************************************************************
     * Program Name : CREATE_CUST_ACCT_SITE
     * Language     : PL/SQL
     * Description  : Creates the Customer Site.
     * History      -----------------------------------------------------------------------------------
	 * Parameters   : P_CUST_ACCOUNT_ID 		=> IN PARAMETER , NUMBER
					  P_PARTY_SITE_ID 			=> IN PARAMETER , NUMBER
					  P_CUST_ACCT_SITE_ID 		=> OUT PARAMETER , NUMBER (FOR ERP CUST_ACCT_SITE_ID)
					  P_MSG 					=> OUT PARAMETER , VARCHAR2 (FOR ERROR MESSAGE)
     *
     * WHO              Version #   WHEN            WHAT
     * ===============  =========   =============   ====================================================
     * AKALA            1.0         7-APR-2026     Initial Version
     ***************************************************************************************************/
	PROCEDURE CREATE_CUST_ACCT_SITE (P_CUST_ACCOUNT_ID IN NUMBER
									,P_PARTY_SITE_ID IN NUMBER
									,P_CUST_ACCT_SITE_ID OUT NUMBER
									,P_MSG OUT VARCHAR2
									)
	AS
		L_CUST_ACCT_SITE_REC HZ_CUST_ACCOUNT_SITE_V2PUB.CUST_ACCT_SITE_REC_TYPE;
		L_CUST_ACCT_SITE_ID  HZ_CUST_ACCT_SITES.CUST_ACCT_SITE_ID%TYPE;
		L_RETURN_STATUS      VARCHAR2(100);
		L_MSG_COUNT          NUMBER;
		L_MSG_DATA           VARCHAR2(2000);
	BEGIN
			DBMS_OUTPUT.ENABLE (buffer_size => NULL);
			P_MSG:= NULL;
			FND_FILE.PUT_LINE(FND_FILE.LOG,RPAD('-',25,'-'));
		   --Initiate the EBS Environment for API processing
		   FND_GLOBAL.APPS_INITIALIZE(GN_USER_ID, GN_RESP_ID, GN_RESP_APPL_ID);
		   MO_GLOBAL.INIT('AR');
		   FND_CLIENT_INFO.SET_ORG_CONTEXT(GN_ORG_ID);
		   --POPULATING CUST ACCT SITE RECORD
		   L_CUST_ACCT_SITE_REC.CUST_ACCOUNT_ID      := P_CUST_ACCOUNT_ID;
		   L_CUST_ACCT_SITE_REC.PARTY_SITE_ID        := P_PARTY_SITE_ID;
		   L_CUST_ACCT_SITE_REC.CREATED_BY_MODULE    := 'BO_API';
		   --CALLING HZ_CUST_ACCOUNT_SITE_V2PUB.CREATE_CUST_ACCT_SITE
		   --FND_FILE.PUT_LINE(FND_FILE.LOG,'Calling hz_cust_account_site_v2pub.create_cust_acct_site api');
		   HZ_CUST_ACCOUNT_SITE_V2PUB.CREATE_CUST_ACCT_SITE
													   (	p_init_msg_list      => FND_API.G_TRUE,
															p_cust_acct_site_rec => l_cust_acct_site_rec,
															x_cust_acct_site_id  => l_cust_acct_site_id,
															x_return_status      => l_return_status,
															x_msg_count          => l_msg_count,
															x_msg_data           => l_msg_data
														);
		   IF l_return_status = 'S' 
		   THEN
			  FND_FILE.PUT_LINE(FND_FILE.LOG,'Cust Acct Site Creation is Successful '); 
			  FND_FILE.PUT_LINE(FND_FILE.LOG,'Cust Acct Site Id = '||l_cust_acct_site_id); 
			  COMMIT;
		   ELSE
			  FOR i IN 1 .. l_msg_count
			  LOOP
				 l_msg_data := FND_MSG_PUB.get( p_msg_index => i, p_encoded => 'F');
				 FND_FILE.PUT_LINE(FND_FILE.LOG, i|| ') '|| l_msg_data);
				 P_MSG := P_MSG||l_msg_data||'; ';
			  END LOOP;
			  ROLLBACK;
			  L_CUST_ACCT_SITE_ID:=-1;
			  --FND_FILE.PUT_LINE(FND_FILE.LOG,'Cust Acct Site Creation failed:'||l_msg_data);
		   END IF;
		   --FND_FILE.PUT_LINE(FND_FILE.LOG,'Cust Acct Site Creation Complete');
		P_CUST_ACCT_SITE_ID:= L_CUST_ACCT_SITE_ID;
	EXCEPTION
	WHEN OTHERS 
	THEN 
		FND_FILE.PUT_LINE(FND_FILE.LOG,SQLCODE||' - '||SQLERRM);
		P_CUST_ACCT_SITE_ID := -1;
	END CREATE_CUST_ACCT_SITE;
	
			
	/*************************************************************************************************
     * Program Name : CREATE_CUST_ACCOUNT
     * Language     : PL/SQL
     * Description  : Creates the Customer and it's profile in HZ_ORGANIZATION_PROFILES Base table; 
					  (if Party Id is not available then It will creates the Party as well).
     * History      -----------------------------------------------------------------------------------
	 * Parameters   : P_ORGANIZATION_NAME 		=> IN PARAMETER , VARCHAR2
					  P_PARTY_ID 				=> IN OUT PARAMETER , NUMBER
					  P_ACCOUNT_NAME 			=> IN PARAMETER , VARCHAR2
					  P_CUST_ACCOUNT_ID 		=> OUT PARAMETER , NUMBER (FOR ERP CUST_ACCOUNT_ID)
					  P_PARTY_NUMBER 			=> OUT PARAMETER , VARCHAR2 (FOR ERP PARTY_NUMBER)
					  P_PROFILE_ID 				=> OUT PARAMETER , NUMBER (FOR ERP PROFILE_ID)
					  P_ACCOUNT_NUMBER 			=> OUT PARAMETER , VARCHAR2 (FOR ERP ACCOUNT_NUMBER)
					  P_MSG 					=> OUT PARAMETER , VARCHAR2 (FOR ERROR MESSAGE)
     *
     * WHO              Version #   WHEN            WHAT
     * ===============  =========   =============   ====================================================
     * AKALA            1.0         2-APR-2026     Initial Version
     ***************************************************************************************************/	
	PROCEDURE CREATE_CUST_ACCOUNT (P_ORGANIZATION_NAME IN VARCHAR2
								,  P_PARTY_ID IN OUT NUMBER
								,  P_ACCOUNT_NAME IN VARCHAR2
								,  P_CUST_ACCOUNT_ID OUT NUMBER
								,  P_PARTY_NUMBER OUT VARCHAR2
								,  P_PROFILE_ID OUT NUMBER
								,  P_ACCOUNT_NUMBER OUT VARCHAR2
								,  P_MSG OUT VARCHAR2
								)
	AS
		L_ORGANIZATION_REC HZ_PARTY_V2PUB.ORGANIZATION_REC_TYPE;
		L_CUST_ACCT_REC    HZ_CUST_ACCOUNT_V2PUB.CUST_ACCOUNT_REC_TYPE;
		L_CUST_PROFILE_REC HZ_CUSTOMER_PROFILE_V2PUB.CUSTOMER_PROFILE_REC_TYPE;
		L_CUST_ACCOUNT_ID  HZ_CUST_ACCOUNTS.CUST_ACCOUNT_ID%TYPE;
		L_ACCOUNT_NUMBER   HZ_CUST_ACCOUNTS.ACCOUNT_NUMBER%TYPE;
		L_PARTY_ID         HZ_PARTIES.PARTY_ID%TYPE;
		L_PARTY_NUMBER     HZ_PARTIES.PARTY_NUMBER%TYPE;
		L_PROFILE_ID       HZ_ORGANIZATION_PROFILES.ORGANIZATION_PROFILE_ID%TYPE;
		L_RETURN_STATUS    VARCHAR2(100);
		L_MSG_COUNT        NUMBER;
		L_MSG_DATA         VARCHAR2(2000);
	BEGIN
	   DBMS_OUTPUT.ENABLE (buffer_size => NULL);
	   P_MSG := NULL;
	   FND_FILE.PUT_LINE(FND_FILE.LOG,RPAD('-',25,'-'));
	   --Initiate the EBS Environment for API processing
	   fnd_global.apps_initialize(GN_USER_ID, GN_RESP_ID, GN_RESP_APPL_ID);
	   mo_global.init('AR');
	   fnd_client_info.set_org_context(GN_ORG_ID);
	   FND_MSG_PUB.INITIALIZE;
	   --Populating organization record
	   l_organization_rec.organization_name := P_ORGANIZATION_NAME; --'XYZ Corporation Account'; -- Can be Null
	   --For existing party use party_id
	   l_organization_rec.party_rec.party_id:= P_PARTY_ID;
	   l_organization_rec.created_by_module := 'HZ_CPUI';
	   l_cust_acct_rec.account_name         := P_ACCOUNT_NAME; --'XYZ Corp. Account'; -- Can be null
	   l_cust_acct_rec.created_by_module    := 'BO_API';
	   --Calling hz_cust_account_v2pub.create_cust_account
	   --FND_FILE.PUT_LINE(FND_FILE.LOG,'Calling hz_cust_account_v2pub.create_cust_account api');
	   HZ_CUST_ACCOUNT_V2PUB.CREATE_CUST_ACCOUNT
											 (	P_INIT_MSG_LIST       => FND_API.G_TRUE,
												P_CUST_ACCOUNT_REC    =>L_CUST_ACCT_REC,
												P_ORGANIZATION_REC    =>L_ORGANIZATION_REC,
												P_CUSTOMER_PROFILE_REC=>L_CUST_PROFILE_REC,
												P_CREATE_PROFILE_AMT  =>FND_API.G_FALSE,
												X_CUST_ACCOUNT_ID     =>L_CUST_ACCOUNT_ID,
												X_ACCOUNT_NUMBER      =>L_ACCOUNT_NUMBER,
												X_PARTY_ID            =>L_PARTY_ID,
												X_PARTY_NUMBER        =>L_PARTY_NUMBER,
												X_PROFILE_ID          =>L_PROFILE_ID,
												X_RETURN_STATUS       =>L_RETURN_STATUS,
												X_MSG_COUNT           =>L_MSG_COUNT,
												X_MSG_DATA            =>L_MSG_DATA
											 );
	   IF l_return_status = 'S' 
	   THEN
		  FND_FILE.PUT_LINE(FND_FILE.LOG,'Party and Customer Account Creation is Successful ');
		  FND_FILE.PUT_LINE(FND_FILE.LOG,'Party Id         ='|| L_PARTY_ID);
		  FND_FILE.PUT_LINE(FND_FILE.LOG,'Party Number     ='|| L_PARTY_NUMBER);
		  FND_FILE.PUT_LINE(FND_FILE.LOG,'Profile Id       ='|| L_PROFILE_ID);  
		  FND_FILE.PUT_LINE(FND_FILE.LOG,'CUST_ACCOUNT_ID  ='|| L_CUST_ACCOUNT_ID);
		  FND_FILE.PUT_LINE(FND_FILE.LOG,'Account Number   ='|| L_ACCOUNT_NUMBER);  
		  
		  P_ACCOUNT_NUMBER 	:= L_ACCOUNT_NUMBER;
		  P_PROFILE_ID		:= L_PROFILE_ID;
		  P_PARTY_NUMBER 	:= L_PARTY_NUMBER;
		  P_PARTY_ID 		:= NVL(L_PARTY_ID,P_PARTY_ID);
		  COMMIT;
	   ELSE
		  FOR i IN 1 .. l_msg_count
		  LOOP
			 l_msg_data := FND_MSG_PUB.get( p_msg_index => i, p_encoded => 'F');
			 FND_FILE.PUT_LINE(FND_FILE.LOG, i|| ') '|| l_msg_data);
			 P_MSG := P_MSG||l_msg_data||'; ';
		  END LOOP;
		  ROLLBACK;
		  L_CUST_ACCOUNT_ID:= -1;
		  --FND_FILE.PUT_LINE(FND_FILE.LOG,'Party and Customer Account Creation failed:'||l_msg_data);
	   END IF;
	   --FND_FILE.PUT_LINE(FND_FILE.LOG,'Party and Customer Account Creation Complete');
		P_CUST_ACCOUNT_ID := L_CUST_ACCOUNT_ID;
	EXCEPTION
	WHEN OTHERS 
	THEN 
		FND_FILE.PUT_LINE(FND_FILE.LOG,SQLCODE||' - '||SQLERRM);
		P_CUST_ACCOUNT_ID := -1;
	END CREATE_CUST_ACCOUNT;
	
	
	/*************************************************************************************************
     * Program Name : CREATE_PARTY_SITE
     * Language     : PL/SQL
     * Description  : Creates Party Sites.
     * History      -----------------------------------------------------------------------------------
	 * Parameters   : P_PARTY_ID 				=> IN PARAMETER , NUMBER
					  P_LOCATION_ID 			=> IN PARAMETER , NUMBER
					  P_PARTY_SITE_ID 			=> OUT PARAMETER , NUMBER (FOR ERP PARTY_SITE_ID)
					  P_PARTY_SITE_NUM 			=> OUT PARAMETER , VARCHAR2 (FOR ERP PARTY_SITE_NUMBER)
					  P_MSG 					=> OUT PARAMETER , VARCHAR2 (FOR ERROR MESSAGE)
     *
     * WHO              Version #   WHEN            WHAT
     * ===============  =========   =============   ====================================================
     * AKALA            1.0         6-APR-2026     Initial Version
     ***************************************************************************************************/	
	PROCEDURE CREATE_PARTY_SITE ( P_PARTY_ID IN NUMBER
								, P_LOCATION_ID IN NUMBER
								, P_PARTY_SITE_ID OUT NUMBER
								, P_PARTY_SITE_NUM OUT VARCHAR2
								, P_MSG OUT VARCHAR2) 
	AS
		L_PARTY_SITE_REC    HZ_PARTY_SITE_V2PUB.PARTY_SITE_REC_TYPE;
		L_PARTY_SITE_ID     HZ_PARTY_SITES.PARTY_SITE_ID%TYPE;
		L_PARTY_SITE_NUMBER HZ_PARTY_SITES.PARTY_SITE_NUMBER%TYPE;
		L_RETURN_STATUS     VARCHAR2(100);
		L_MSG_COUNT         NUMBER;
		L_MSG_DATA          VARCHAR2(2000);
	BEGIN
		   DBMS_OUTPUT.ENABLE (buffer_size => NULL);
		   P_MSG := NULL;
		   FND_FILE.PUT_LINE(FND_FILE.LOG,RPAD('-',25,'-'));
		   --Initiate the EBS Environment for API processing
		   FND_GLOBAL.APPS_INITIALIZE(GN_USER_ID, GN_RESP_ID, GN_RESP_APPL_ID);
		   MO_GLOBAL.INIT('AR');
		   FND_CLIENT_INFO.SET_ORG_CONTEXT(GN_ORG_ID);
		   --POPULATING PARTY SITE RECORD
		   L_PARTY_SITE_REC.PARTY_ID                 := P_PARTY_ID;
		   L_PARTY_SITE_REC.LOCATION_ID              := P_LOCATION_ID;
		   L_PARTY_SITE_REC.IDENTIFYING_ADDRESS_FLAg := 'Y'; -- Can be null
		   L_PARTY_SITE_REC.CREATED_BY_MODULE        := 'BO_API';
		   --Calling hz_party_site_v2pub.create_party_site
		   FND_FILE.PUT_LINE(FND_FILE.LOG,'Calling hz_party_site_v2pub.create_party_site api');
		   HZ_PARTY_SITE_V2PUB.CREATE_PARTY_SITE
					(
					 p_init_msg_list     => FND_API.G_TRUE,
					 p_party_site_rec    => l_party_site_rec,
					 x_party_site_id     => l_party_site_id,
					 x_party_site_number => l_party_site_number,
					 x_return_status     => l_return_status,
					 x_msg_count         => l_msg_count,
					 x_msg_data          => l_msg_data
					);
		   IF l_return_status = 'S' 
		   THEN
			    FND_FILE.PUT_LINE(FND_FILE.LOG,'Party Site Creation is Successful '); 
				FND_FILE.PUT_LINE(FND_FILE.LOG,'Party Site Number = '||l_party_site_number); 
				FND_FILE.PUT_LINE(FND_FILE.LOG,'Party Site Id = '||l_party_site_id); 
				COMMIT;
		   ELSE
			  FOR i IN 1 .. l_msg_count
			  LOOP
				 l_msg_data := FND_MSG_PUB.get( p_msg_index => i, p_encoded => 'F');
				 FND_FILE.PUT_LINE(FND_FILE.LOG, i|| ') '|| l_msg_data);
				 P_MSG := P_MSG||l_msg_data||'; ';
			  END LOOP;
			  --FND_FILE.PUT_LINE(FND_FILE.LOG,'Party Site Creation failed:'||l_msg_data);
			  ROLLBACK;
			  L_PARTY_SITE_ID:=-1;
		   END IF;
		   --FND_FILE.PUT_LINE(FND_FILE.LOG,'Party Site Creation Complete');
		P_PARTY_SITE_ID := L_PARTY_SITE_ID;
		P_PARTY_SITE_NUM := l_party_site_number;
	EXCEPTION
	WHEN OTHERS 
	THEN 
		FND_FILE.PUT_LINE(FND_FILE.LOG,SQLCODE||' - '||SQLERRM);
		P_PARTY_SITE_ID := -1;
	END CREATE_PARTY_SITE;
	
	
	/*************************************************************************************************
     * Program Name : CREATE_PARTY
     * Language     : PL/SQL
     * Description  : Creates Party.
     * History      -----------------------------------------------------------------------------------
	 * Parameters   : P_ORGANIZATION_NAME 	=> IN PARAMETER , VARCHAR2
					  P_PARTY_ID 			=> OUT PARAMETER , NUMBER (FOR ERP PARTY_ID)
					  P_PARTY_NUMBER 		=> OUT PARAMETER , NUMBER (FOR ERP PARTY_NUMBER)
					  P_PROFILE_ID 			=> OUT PARAMETER , NUMBER (FOR ERP PROFILE_ID)
					  P_MSG 				=> OUT PARAMETER , VARCHAR2 (FOR ERROR MESSAGE)
     *
     * WHO              Version #   WHEN            WHAT
     * ===============  =========   =============   ====================================================
     * AKALA            1.0         2-APR-2026     Initial Version
     ***************************************************************************************************/	
	PROCEDURE CREATE_PARTY (P_ORGANIZATION_NAME IN VARCHAR2
						,  P_PARTY_ID OUT NUMBER
						,  P_PARTY_NUMBER OUT VARCHAR2
						,  P_PROFILE_ID OUT NUMBER
						,  P_MSG OUT VARCHAR2) 
	AS
		L_ORGANIZATION_REC HZ_PARTY_V2PUB.ORGANIZATION_REC_TYPE;
		L_PARTY_ID         HZ_PARTIES.PARTY_ID%TYPE;
		L_PARTY_NUMBER     HZ_PARTIES.PARTY_NUMBER%TYPE;
		L_PROFILE_ID       HZ_ORGANIZATION_PROFILES.ORGANIZATION_PROFILE_ID%TYPE;
		L_RETURN_STATUS    VARCHAR2(100);
		L_MSG_COUNT        NUMBER;
		L_MSG_DATA         VARCHAR2(2000);
	BEGIN
		   DBMS_OUTPUT.ENABLE (buffer_size => NULL);
		   P_MSG := NULL;
		   FND_FILE.PUT_LINE(FND_FILE.LOG,RPAD('-',25,'-'));
		   --Initiate the EBS Environment for API processing
		   FND_GLOBAL.APPS_INITIALIZE(GN_USER_ID, GN_RESP_ID, GN_RESP_APPL_ID);
		   MO_GLOBAL.INIT('AR');
		   FND_CLIENT_INFO.SET_ORG_CONTEXT(GN_ORG_ID);
		   L_ORGANIZATION_REC.ORGANIZATION_NAME := P_ORGANIZATION_NAME; --'XYZ Corporation Dummy';
		   L_ORGANIZATION_REC.CREATED_BY_MODULE := 'HZ_CPUI';
		   --FND_FILE.PUT_LINE(FND_FILE.LOG,'Calling hz_party_v2pub.create_organization API');
		   --Call hz_party_v2pub.create_organization
		   hz_party_v2pub.create_organization
					 (
					  p_init_msg_list    => FND_API.G_TRUE,
					  p_organization_rec => l_organization_rec,
					  x_return_status    => l_return_status,
					  x_msg_count        => l_msg_count,
					  x_msg_data         => l_msg_data,
					  x_party_id         => l_party_id,
					  x_party_number     => l_party_number,
					  x_profile_id       => l_profile_id
					 );
		   IF l_return_status = 'S' 
		   THEN
			  FND_FILE.PUT_LINE(FND_FILE.LOG,'Organization Creation is Successful ');
			  FND_FILE.PUT_LINE(FND_FILE.LOG,'Party Id         ='|| l_party_id);
			  FND_FILE.PUT_LINE(FND_FILE.LOG,'Party Number     ='|| l_party_number);
			  FND_FILE.PUT_LINE(FND_FILE.LOG,'Profile Id       ='|| l_profile_id); 
			  P_PARTY_NUMBER := l_party_number;
			  P_PROFILE_ID := l_profile_id;
			  COMMIT;
		   ELSE
			  FND_FILE.PUT_LINE(FND_FILE.LOG,'Creation of Organization failed:'||l_msg_data);
			  FOR i IN 1 .. l_msg_count
			  LOOP
				 l_msg_data := FND_MSG_PUB.get( p_msg_index => i, p_encoded => 'F');
				 FND_FILE.PUT_LINE(FND_FILE.LOG, i|| ') '|| l_msg_data);
				 P_MSG := P_MSG||L_MSG_DATA||'; ';
			  END LOOP;
			  ROLLBACK;
			  L_PARTY_ID:=-1;
		   END IF;
		P_PARTY_ID := L_PARTY_ID;
	EXCEPTION
	WHEN OTHERS 
	THEN 
		FND_FILE.PUT_LINE(FND_FILE.LOG,SQLCODE||' - '||SQLERRM);
		P_PARTY_ID := -1;
	END CREATE_PARTY;
	
		
	/*************************************************************************************************
     * Program Name : CREATE_LOCATION
     * Language     : PL/SQL
     * Description  : Creates Location.
     * History      -----------------------------------------------------------------------------------
	 * Parameters   : P_ADDRESS1 		=> IN PARAMETER , VARCHAR2
	 *                P_ADDRESS2 		=> IN PARAMETER , VARCHAR2
	 *                P_CITY 			=> IN PARAMETER , VARCHAR2
	 *                P_POSTAL_CODE 	=> IN PARAMETER , NUMBER
	 *                P_STATE 			=> IN PARAMETER , VARCHAR2
	 *                P_COUNTY 			=> IN PARAMETER , VARCHAR2
	 *                P_COUNTRY 		=> IN PARAMETER , VARCHAR2
					  P_LOCATION_ID 	=> OUT PARAMETER , NUMBER (FOR ERP LOCATION_ID)
					  P_MSG 			=> OUT PARAMETER , VARCHAR2 (FOR ERROR MESSAGE)
     *
     * WHO              Version #   WHEN            WHAT
     * ===============  =========   =============   ====================================================
     * AKALA            1.0         6-APR-2026     Initial Version
     ***************************************************************************************************/	
	PROCEDURE CREATE_LOCATION (P_ADDRESS1 IN VARCHAR2
							,  P_ADDRESS2 IN VARCHAR2
							,  P_CITY  IN VARCHAR2
							,  P_POSTAL_CODE IN NUMBER
							,  P_STATE IN VARCHAR2
							,  P_COUNTY IN VARCHAR2
							,  P_COUNTRY IN VARCHAR2
							,  P_LOCATION_ID OUT NUMBER
							,  P_MSG OUT VARCHAR2)
	AS
		L_LOCATION_REC     HZ_LOCATION_V2PUB.LOCATION_REC_TYPE;
		L_LOCATION_ID      NUMBER;
		L_RETURN_STATUS    VARCHAR2(100);
		L_MSG_COUNT        NUMBER;
		L_MSG_DATA         VARCHAR2(2000);
	BEGIN
			DBMS_OUTPUT.ENABLE (BUFFER_SIZE => NULL);
			P_MSG := NULL;
		   FND_FILE.PUT_LINE(FND_FILE.LOG,RPAD('-',25,'-'));
			   --INITIATE THE EBS ENVIRONMENT FOR API PROCESSING
			FND_GLOBAL.APPS_INITIALIZE(GN_USER_ID, GN_RESP_ID, GN_RESP_APPL_ID);
			MO_GLOBAL.INIT('AR');
			FND_CLIENT_INFO.SET_ORG_CONTEXT(GN_ORG_ID);
			--POPULATING LOCATION RECORD
			L_LOCATION_REC.ADDRESS1          := P_ADDRESS1; --'123 subway Dummy'; 				-- Required Parameter
			L_LOCATION_REC.ADDRESS2          := P_ADDRESS2; --'Enodeas Building';	--we Can pass null value
			L_LOCATION_REC.CITY              := P_CITY; --'New York';			--we Can pass null value
			L_LOCATION_REC.POSTAL_CODE       := P_POSTAL_CODE; --'10010';				--we Can pass null value
			L_LOCATION_REC.STATE             := P_STATE; --'NY';				--we Can pass null value
			L_LOCATION_REC.COUNTY            := P_COUNTY; --DISTRICT; 						-- Required Parameter
			L_LOCATION_REC.COUNTRY           := P_COUNTRY; --'US'; 						-- Required Parameter
			L_LOCATION_REC.CREATED_BY_MODULE := 'BO_API';					-- Required Parameter
			--Calling hz_location_v2pub.create_location
			--FND_FILE.PUT_LINE(FND_FILE.LOG,'Calling hz_location_v2pub.create_location api');
			FND_MSG_PUB.INITIALIZE;
			HZ_LOCATION_V2PUB.CREATE_LOCATION
											(	P_INIT_MSG_LIST => FND_API.G_TRUE,
												P_LOCATION_REC  => L_LOCATION_REC,
												X_LOCATION_ID   => L_LOCATION_ID,
												X_RETURN_STATUS => L_RETURN_STATUS,
												X_MSG_COUNT     => L_MSG_COUNT,
												X_MSG_DATA      => L_MSG_DATA
											);
			--FND_FILE.PUT_LINE(FND_FILE.LOG,'Location Creation failed after error loop:'||l_msg_data);
			IF l_return_status = 'S' 
				THEN
					FND_FILE.PUT_LINE(FND_FILE.LOG,'Location Creation is Successful '); 
					FND_FILE.PUT_LINE(FND_FILE.LOG,'Location Id = '||L_LOCATION_ID); 
					COMMIT;
			ELSE
				FOR i IN 1 .. l_msg_count
					LOOP
						l_msg_data := fnd_msg_pub.get( p_msg_index => i, p_encoded => 'F');
						FND_FILE.PUT_LINE(FND_FILE.LOG, i|| ') '|| l_msg_data);
						P_MSG := P_MSG || l_msg_data||'; ';
					END LOOP;
				--FND_FILE.PUT_LINE(FND_FILE.LOG,'Location Creation failed after error loop:'||l_msg_data);
				ROLLBACK;
				L_LOCATION_ID:=-1;
			END IF;
			FND_FILE.PUT_LINE(FND_FILE.LOG,'Location Creation PROCESS complete');
		P_LOCATION_ID:= L_LOCATION_ID;
	EXCEPTION
	WHEN OTHERS 
	THEN 
		P_LOCATION_ID := -1;
		FND_FILE.PUT_LINE(FND_FILE.LOG,SQLCODE||' - '||SQLERRM);
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
     * AKALA            1.0         7-APR-2026     Initial Version
     * AKALA            1.0         8-APR-2026     1. Updated for Creation customer account according to the Name of Center
												   2. Added logic for CREATE_CODE_COMBINATION
     ***************************************************************************************************/	
	PROCEDURE CREATE_SAFALTA_CUST_AND_SITES 
	AS
	LN_LOCATION_ID			HZ_LOCATIONS.LOCATION_ID%TYPE;
	LN_LOC_ID				HZ_LOCATIONS.LOCATION_ID%TYPE;
	LN_PARTY_ID				HZ_PARTIES.PARTY_ID%TYPE;
	LN_PARTY_SITE_ID		HZ_PARTY_SITES.PARTY_SITE_ID%TYPE;
	LN_CUST_ACCOUNT_ID		HZ_CUST_ACCOUNTS.CUST_ACCOUNT_ID%TYPE;
	LN_ACCOUNT_NUMBER		HZ_CUST_ACCOUNTS.ACCOUNT_NUMBER%TYPE;
	LN_CUST_ACCT_SITE_ID	HZ_CUST_ACCT_SITES_ALL.CUST_ACCT_SITE_ID%TYPE;
	LN_SITE_USE_ID			HZ_CUST_SITE_USES_ALL.SITE_USE_ID%TYPE;
	
	CURSOR SAFALTA_CUST IS
	SELECT *
	FROM AU_CUSTOMER_MASTER_NEW_TEST A
	WHERE AGENCY_ID  IN (SELECT AGENCY_ID 
						FROM XXAU_AGENCY_APPROVAL_DTL_TEST
						WHERE TRUNC(CREATION_DATE) >='01-OCT-2024'
						AND APPROVE_REJECT = 'A'
						AND AGREEMENT_FLAG = 'Y')
	--AND ERP_CUSTOMER_NUMBER IS NULL
	AND EXISTS (SELECT 1 
				FROM AU_CUSTOMER_SHIP_TO_TEST 
				WHERE AGENCY_ID = A.AGENCY_ID 
				AND UPPER(PROUCT_NAME) LIKE '%SAFALTA%' 
				AND ERP_CUSTOMER_NUMBER IS NULL
				AND ERP_SITE_USE_ID IS NULL)
	;
	
	CURSOR SAFALTA_SITE(P_AGENCY_ID NUMBER) IS
		SELECT *
		FROM AU_CUSTOMER_SHIP_TO_TEST A
		WHERE AGENCY_ID IN (SELECT AGENCY_ID 
							FROM XXAU_AGENCY_APPROVAL_DTL_TEST
							WHERE TRUNC(CREATION_DATE) >='01-OCT-2024'
							AND APPROVE_REJECT = 'A'
							AND AGREEMENT_FLAG = 'Y')						
		AND UPPER(PROUCT_NAME) LIKE '%SAFALTA%' 
		AND CUSTOMER_SHIP_ID IS NULL
		AND ERP_PARTY_ID IS NULL
		AND ERP_SITE_USE_ID IS NULL
		AND ERP_CUSTOMER_NUMBER IS NULL
		AND ERP_CUSTOMER_ID IS NULL
		AND AGENCY_ID = P_AGENCY_ID
	;
	
	LC_MSG 							VARCHAR2(4000);
	LC_ACCOUNT_NUMBER 				VARCHAR2(200);
	LC_PARTY_NUMBER 				VARCHAR2(200);
	LC_PARTY_SITE_NUM 				VARCHAR2(200);
	LN_PROFILE_ID 					NUMBER;
	LN_CCID 						NUMBER; -- Added by AKALA on 08-APR-2026 for CODE_COMBINATION_ID
	LN_PHONE_CONTACT_POINT_ID 		NUMBER;
	LN_EMAIL_CONTACT_POINT_ID 		NUMBER;
	
	BEGIN
		FND_FILE.PUT_LINE(FND_FILE.LOG,RPAD('*',30,'*'));
		FND_FILE.PUT_LINE(FND_FILE.LOG,'In CREATE_SAFALTA_CUST_AND_SITES');
		
		FOR I IN SAFALTA_CUST
		LOOP
			LN_LOCATION_ID:= NULL;
			LN_PARTY_ID := NULL;
			LN_CUST_ACCOUNT_ID:=NULL;
			BEGIN
				-- IF LN_CUST_ACCOUNT_ID > 0
				-- THEN
					FOR J IN SAFALTA_SITE(I.AGENCY_ID)
					LOOP
						J.ERP_ERR_MSG:= NULL;
						CREATE_CUST_ACCOUNT (P_ORGANIZATION_NAME 	=> I.AGENCY_NAME||' - (New Safalta Unit)' -- Added by AKALA on 08-APR-2026, Due to Account already exists for the Given Agency Name
											, P_ACCOUNT_NAME 		=> I.AGENCY_NAME||' - (New Safalta Unit)'  -- J.NAME_OF_CENTRE
											, P_CUST_ACCOUNT_ID		=> LN_CUST_ACCOUNT_ID
											, P_PARTY_ID			=> LN_PARTY_ID
											, P_PARTY_NUMBER		=> LC_PARTY_NUMBER
											, P_ACCOUNT_NUMBER		=> LC_ACCOUNT_NUMBER
											, P_PROFILE_ID			=> LN_PROFILE_ID
											, P_MSG					=> LC_MSG
											) ;
		
						--LC_ERR_MSG := LC_MSG;
						BEGIN
							SELECT PARTY_ID, ACCOUNT_NUMBER
							INTO LN_PARTY_ID, LN_ACCOUNT_NUMBER
							FROM HZ_CUST_ACCOUNTS
							WHERE CUST_ACCOUNT_ID = LN_CUST_ACCOUNT_ID;
						EXCEPTION 
						WHEN OTHERS 
							THEN 
								LN_PARTY_ID:= -1;
								LN_CUST_ACCOUNT_ID:= -1;
								J.ERP_ERR_MSG := TRIM(LC_MSG) ;
						END;
						FND_FILE.PUT_LINE(FND_FILE.LOG,'LN_CUST_ACCOUNT_ID: '||LN_CUST_ACCOUNT_ID||'; PARTY_ID: '||LN_PARTY_ID);
					-- Resetting the Variables for Updating and Correct values
						LN_LOCATION_ID := -1;
						LN_PARTY_SITE_ID := -1;  
						LN_CUST_ACCT_SITE_ID := -1; 
						LN_SITE_USE_ID:= -1;
						
						IF LN_CUST_ACCOUNT_ID > 0
						THEN
							BEGIN						
							CREATE_LOCATION (P_ADDRESS1 	=> J.ADDRESS
											, P_ADDRESS2 	=> NULL
											, P_CITY 		=> J.CITY
											, P_POSTAL_CODE => J.POSTAL_CODE
											, P_COUNTY 		=> J.DISTRICT
											, P_STATE 		=> J.STATE
											, P_COUNTRY 	=> 'IN'
											, P_LOCATION_ID => LN_LOCATION_ID
											, P_MSG			=> LC_MSG);
											
							J.ERP_ERR_MSG := TRIM(LC_MSG);
							IF LN_LOCATION_ID > 0
							THEN																	 
								CREATE_PARTY_SITE (P_PARTY_ID 		=> LN_PARTY_ID
												 , P_LOCATION_ID 	=> LN_LOCATION_ID
												 , P_PARTY_SITE_NUM => LC_PARTY_SITE_NUM
												 , P_PARTY_SITE_ID	=> LN_PARTY_SITE_ID
												 , P_MSG		 	=> LC_MSG
												 );
												 
								J.ERP_ERR_MSG := J.ERP_ERR_MSG ||'; '|| LC_MSG;
								IF LN_PARTY_SITE_ID > 0
								THEN 
								
								-- Creating Contact Point -- Added on 07-APR-2026
									CREATE_CONTACT_POINT_SITE_LVL ( P_PARTY_SITE_ID => LN_PARTY_SITE_ID
																  , P_PHONE => J.MOBILE_NO 
																  , P_EMAIL => J.EMAIL
																  , P_TABLE => 'HZ_PARTY_SITES'
																  , P_PHONE_CONTACT_POINT_ID => LN_PHONE_CONTACT_POINT_ID
																  , P_EMAIL_CONTACT_POINT_ID => LN_EMAIL_CONTACT_POINT_ID
																  , P_MSG => LC_MSG);
									IF LN_PHONE_CONTACT_POINT_ID < 0
									THEN
										FND_FILE.PUT_LINE(FND_FILE.LOG,'Cannot create Phone Contact Point : '||J.MOBILE_NO);
									END IF;
									
									IF LN_EMAIL_CONTACT_POINT_ID < 0
									THEN
										FND_FILE.PUT_LINE(FND_FILE.LOG,'Cannot create Email Cotact Point : '||J.EMAIL);
									END IF;
								-- End: Added Email and phone contact points on 07-APR-2026
									
									CREATE_CUST_ACCT_SITE (P_CUST_ACCOUNT_ID 	=> LN_CUST_ACCOUNT_ID
														 , P_PARTY_SITE_ID 		=> LN_PARTY_SITE_ID
														 , P_CUST_ACCT_SITE_ID	=> LN_CUST_ACCT_SITE_ID
														 , P_MSG				=> LC_MSG
														 );
									
									J.ERP_ERR_MSG := J.ERP_ERR_MSG ||'; '|| LC_MSG;
								    IF LN_CUST_ACCT_SITE_ID > 0
									THEN
										
										CREATE_CUST_SITE_USES (P_CUST_ACCT_SITE_ID 	=> LN_CUST_ACCT_SITE_ID
															, P_SITE_USE_CODE 		=> 'SHIP_TO'
															, P_LOCATION 			=> J.DAK_NAME
															, P_SITE_USE_ID			=> LN_SITE_USE_ID
															, P_MSG					=> LC_MSG
															) ;
										
										J.ERP_ERR_MSG := J.ERP_ERR_MSG ||'; '|| LC_MSG;
										IF LN_SITE_USE_ID > 0
										THEN
										LN_CCID:=-1;
										
										CREATE_CODE_COMBINATION ( P_ORG_ID 		    => J.ORG_ID
																, P_INV_ORG 		=> J.INV_ORG
																, P_AGENCY_ID 		=> J.AGENCY_ID
																, P_CENTRE_NUMBER 	=> J.CENTRE_NUMBER
																, P_AGENCY_NAME 	=> I.AGENCY_NAME
																, P_CCID			=> LN_CCID
																, P_MSG 			=> LC_MSG);
										J.ERP_ERR_MSG := J.ERP_ERR_MSG ||'; '|| LC_MSG;
										FND_FILE.PUT_LINE(FND_FILE.LOG,'Retrived Code Combination ID : '||LN_CCID);
										
										UPDATE AU_CUSTOMER_SHIP_TO_TEST
										SET ERP_CUSTOMER_NUMBER = LN_ACCOUNT_NUMBER
										, ERP_CREATION_DATE = SYSDATE
										, CUSTOMER_SHIP_ID = LN_CUST_ACCT_SITE_ID
										, ERP_SITE_USE_ID = LN_SITE_USE_ID
										, ERP_CUSTOMER_ID = LN_CUST_ACCOUNT_ID
										, ERP_PARTY_ID = LN_PARTY_ID
										, ERP_PROCESS_FLAG = 'S'
										, CCID = LN_CCID
										, ERP_ERR_MSG = DECODE(ERP_ERR_MSG, NULL,'',ERP_ERR_MSG||'; ')||J.ERP_ERR_MSG
										WHERE 1=1
										AND AGENCY_ID = J.AGENCY_ID
										AND CENTRE_NUMBER = J.CENTRE_NUMBER
										AND MAIN_CENTRE_NUMBER = J.MAIN_CENTRE_NUMBER;
											
											COMMIT;
										END IF;
									END IF;
								END IF;
							END IF;
							
							FND_FILE.PUT_LINE(FND_FILE.LOG,'LN_CUST_ACCOUNT_ID: '
											||LN_CUST_ACCOUNT_ID
											||'; PARTY_ID: '||LN_PARTY_ID
											||'; LN_LOCATION_ID: '||LN_LOCATION_ID
											||'; LN_PARTY_SITE_ID: '||LN_PARTY_SITE_ID
											||'; LN_CUST_ACCT_SITE_ID: '||LN_CUST_ACCT_SITE_ID
											||'; LN_SITE_USE_ID: '||LN_SITE_USE_ID
											);
							
							EXCEPTION 
							WHEN OTHERS 
								THEN FND_FILE.PUT_LINE(FND_FILE.LOG,SQLCODE||' - '||SQLERRM); 
							END;
						END IF;
						
					END LOOP;
				--END IF;
			EXCEPTION 
				WHEN OTHERS THEN 
					FND_FILE.PUT_LINE(FND_FILE.LOG, SQLCODE||' - '||SQLERRM);
			END;
			
			/*IF LN_CUST_ACCOUNT_ID > 0 AND LN_LOCATION_ID > 0  AND  LN_PARTY_SITE_ID > 0  
			AND  LN_CUST_ACCT_SITE_ID > 0  AND  LN_SITE_USE_ID > 0
			THEN
				UPDATE AU_CUSTOMER_MASTER_NEW_TEST
				SET ERP_CUSTOMER_ID = LN_CUST_ACCOUNT_ID
				, ERP_CUSTOMER_NUMBER = LN_ACCOUNT_NUMBER
				, ERP_PARTY_ID = LN_PARTY_ID
				WHERE AGENCY_ID = I.AGENCY_ID
				;
				COMMIT;
			END IF;*/
			
		END LOOP;
	EXCEPTION
	WHEN OTHERS 
	THEN 
		FND_FILE.PUT_LINE(FND_FILE.LOG,SQLCODE||' - '||SQLERRM);
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
     * AKALA            1.2         08-APR-2026     1. Upgraded code for EMAIL and PHONE creation in ERP
													2. Added logic for CREATE_CODE_COMBINATION
     ***************************************************************************************************/		
	PROCEDURE CREATE_CUSTOMER_AND_SITES 
	AS
	LN_LOCATION_ID			HZ_LOCATIONS.LOCATION_ID%TYPE;
	LN_LOC_ID				HZ_LOCATIONS.LOCATION_ID%TYPE;
	LN_PARTY_ID				HZ_PARTIES.PARTY_ID%TYPE;
	LN_PARTY_SITE_ID		HZ_PARTY_SITES.PARTY_SITE_ID%TYPE;
	LN_CUST_ACCOUNT_ID		HZ_CUST_ACCOUNTS.CUST_ACCOUNT_ID%TYPE;
	LN_ACCOUNT_NUMBER		HZ_CUST_ACCOUNTS.ACCOUNT_NUMBER%TYPE;
	LN_CUST_ACCT_SITE_ID	HZ_CUST_ACCT_SITES_ALL.CUST_ACCT_SITE_ID%TYPE;
	LN_SITE_USE_ID			HZ_CUST_SITE_USES_ALL.SITE_USE_ID%TYPE;
	
	CURSOR C1 IS
	SELECT *
	FROM AU_CUSTOMER_MASTER_NEW_TEST A
	WHERE AGENCY_ID  IN (SELECT AGENCY_ID 
						FROM XXAU_AGENCY_APPROVAL_DTL_TEST
						WHERE TRUNC(CREATION_DATE) >='01-OCT-2024'
						AND APPROVE_REJECT = 'A'
						AND AGREEMENT_FLAG = 'Y')
	AND ERP_PARTY_ID IS NULL
	AND ERP_CUSTOMER_NUMBER IS NULL
	AND ERP_CUSTOMER_ID IS NULL
	AND EXISTS (SELECT 1 
				FROM AU_CUSTOMER_SHIP_TO_TEST 
				WHERE AGENCY_ID = A.AGENCY_ID 
				AND UPPER(PROUCT_NAME) NOT LIKE '%SAFALTA%' 
				AND ERP_CUSTOMER_NUMBER IS NULL
				AND ERP_SITE_USE_ID IS NULL)
	;
	
	CURSOR C2(P_AGENCY_ID NUMBER) IS
		SELECT *
		FROM AU_CUSTOMER_SHIP_TO_TEST A
		WHERE AGENCY_ID IN (SELECT AGENCY_ID 
							FROM XXAU_AGENCY_APPROVAL_DTL_TEST
							WHERE TRUNC(CREATION_DATE) >='01-OCT-2024'
							AND APPROVE_REJECT = 'A'
							AND AGREEMENT_FLAG = 'Y')						
		AND UPPER(PROUCT_NAME) NOT LIKE '%SAFALTA%' 
		AND CUSTOMER_SHIP_ID IS NULL
		AND ERP_PARTY_ID IS NULL
		AND ERP_SITE_USE_ID IS NULL
		AND ERP_CUSTOMER_NUMBER IS NULL
		AND ERP_CUSTOMER_ID IS NULL
		AND AGENCY_ID = P_AGENCY_ID
	;
	
	LC_MSG 							VARCHAR2(4000);
	LC_ERR_MSG 						VARCHAR2(4000);
	LC_ACCOUNT_NUMBER 				VARCHAR2(200);
	LC_PARTY_NUMBER 				VARCHAR2(200);
	LC_PARTY_SITE_NUM 				VARCHAR2(200);
	LN_PROFILE_ID 					NUMBER;
	LN_CCID		 					NUMBER; -- Added by AKALA on 08-APR-2026 for CODE_COMBINATION_ID
	LN_PHONE_CONTACT_POINT_ID 		NUMBER;
	LN_EMAIL_CONTACT_POINT_ID 		NUMBER;
	
	BEGIN
		FND_FILE.PUT_LINE(FND_FILE.LOG,RPAD('*',30,'*'));
		FND_FILE.PUT_LINE(FND_FILE.LOG,'In CREATE_CUSTOMER_AND_SITES');
		
		FOR I IN C1
		LOOP
			LN_LOCATION_ID:= NULL;
			LN_PARTY_ID := NULL;
			I.ERP_ERR_MSG := NULL;
			FND_FILE.PUT_LINE(FND_FILE.LOG,RPAD('+',25,'+'));
			BEGIN
				CREATE_CUST_ACCOUNT (P_ORGANIZATION_NAME 	=> I.AGENCY_NAME
									, P_ACCOUNT_NAME 		=> I.DROP_POINT
									, P_CUST_ACCOUNT_ID		=> LN_CUST_ACCOUNT_ID
									, P_PARTY_ID			=> LN_PARTY_ID
									, P_PARTY_NUMBER		=> LC_PARTY_NUMBER
									, P_ACCOUNT_NUMBER		=> LC_ACCOUNT_NUMBER
									, P_PROFILE_ID			=> LN_PROFILE_ID
									, P_MSG					=> LC_MSG
									) ;
				
				LC_ERR_MSG := LC_MSG;
				BEGIN
					SELECT PARTY_ID, ACCOUNT_NUMBER
					INTO LN_PARTY_ID, LN_ACCOUNT_NUMBER
					FROM HZ_CUST_ACCOUNTS
					WHERE CUST_ACCOUNT_ID = LN_CUST_ACCOUNT_ID;
				EXCEPTION 
				WHEN OTHERS 
					THEN 
						LN_PARTY_ID:= -1;
						LN_CUST_ACCOUNT_ID:= -1;
						I.ERP_ERR_MSG := LC_MSG;
				END;
				FND_FILE.PUT_LINE(FND_FILE.LOG,'LN_CUST_ACCOUNT_ID: '||LN_CUST_ACCOUNT_ID||'; PARTY_ID: '||LN_PARTY_ID);
				
				IF LN_CUST_ACCOUNT_ID > 0 AND LN_PARTY_ID > 0
				THEN
					FOR J IN C2(I.AGENCY_ID)
					LOOP
					-- Resetting the Variables For Correct Values And Updation
						LN_LOCATION_ID := -1;
						LN_PARTY_SITE_ID := -1;  
						LN_CUST_ACCT_SITE_ID := -1; 
						LN_SITE_USE_ID:= -1;
						FND_FILE.PUT_LINE(FND_FILE.LOG,RPAD('_',25,'_'));
						BEGIN
							LC_ERR_MSG := NULL;
						
							CREATE_LOCATION (P_ADDRESS1 	=> J.ADDRESS
											, P_ADDRESS2 	=> NULL
											, P_CITY 		=> J.CITY
											, P_POSTAL_CODE => J.POSTAL_CODE
											, P_COUNTY 		=> J.DISTRICT
											, P_STATE 		=> J.STATE
											, P_COUNTRY 	=> 'IN'
											, P_LOCATION_ID => LN_LOCATION_ID
											, P_MSG			=> LC_MSG);
											
							LC_ERR_MSG := LC_MSG;
							IF LN_LOCATION_ID > 0
							THEN																	 
								CREATE_PARTY_SITE (P_PARTY_ID 		=> LN_PARTY_ID
												 , P_LOCATION_ID 	=> LN_LOCATION_ID
												 , P_PARTY_SITE_NUM => LC_PARTY_SITE_NUM
												 , P_PARTY_SITE_ID	=> LN_PARTY_SITE_ID
												 , P_MSG		 	=> LC_MSG
												 );
												 
								LC_ERR_MSG := LC_MSG;
								IF LN_PARTY_SITE_ID > 0
								THEN 
								-- start: Creating Contact Point -- Added on 07-APR-2026
									CREATE_CONTACT_POINT_SITE_LVL ( P_PARTY_SITE_ID => LN_PARTY_SITE_ID
																  , P_PHONE => J.MOBILE_NO 
																  , P_EMAIL => J.EMAIL
																  , P_TABLE => 'HZ_PARTY_SITES'
																  , P_PHONE_CONTACT_POINT_ID => LN_PHONE_CONTACT_POINT_ID
																  , P_EMAIL_CONTACT_POINT_ID => LN_EMAIL_CONTACT_POINT_ID
																  , P_MSG => LC_MSG);
									IF LN_PHONE_CONTACT_POINT_ID < 0
									THEN
										FND_FILE.PUT_LINE(FND_FILE.LOG,'Cannot create Phone Cotact Point : '||J.MOBILE_NO);
									END IF;
									
									IF LN_EMAIL_CONTACT_POINT_ID < 0
									THEN
										FND_FILE.PUT_LINE(FND_FILE.LOG,'Cannot create Email Cotact Point : '||J.EMAIL);
									END IF;
								-- end : Added Email and Phone contact points on 07-APR-2026
									
								-- Creating Customer Account Site
									CREATE_CUST_ACCT_SITE (P_CUST_ACCOUNT_ID 	=> LN_CUST_ACCOUNT_ID
														 , P_PARTY_SITE_ID 		=> LN_PARTY_SITE_ID
														 , P_CUST_ACCT_SITE_ID	=> LN_CUST_ACCT_SITE_ID
														 , P_MSG				=> LC_MSG
														 );
									
									LC_ERR_MSG := LC_MSG;
								    IF LN_CUST_ACCT_SITE_ID > 0
									THEN
									-- Creating Customer Site Uses
										CREATE_CUST_SITE_USES (P_CUST_ACCT_SITE_ID 	=> LN_CUST_ACCT_SITE_ID
															, P_SITE_USE_CODE 		=> 'SHIP_TO'
															, P_LOCATION 			=> J.DAK_NAME
															, P_SITE_USE_ID			=> LN_SITE_USE_ID
															, P_MSG					=> LC_MSG
															) ;
															
										LC_ERR_MSG := LC_MSG;
										IF LN_SITE_USE_ID > 0
										THEN
										--Start:  Added by AKALA on 08-APR-2026, to create or get CCID									
										LN_CCID:=-1;
										
										CREATE_CODE_COMBINATION ( P_ORG_ID 		    => J.ORG_ID
																, P_INV_ORG 		=> J.INV_ORG
																, P_AGENCY_ID 		=> J.AGENCY_ID
																, P_CENTRE_NUMBER 	=> J.CENTRE_NUMBER
																, P_AGENCY_NAME 	=> I.AGENCY_NAME
																, P_CCID			=> LN_CCID
																, P_MSG 			=> LC_MSG);
										
										FND_FILE.PUT_LINE(FND_FILE.LOG,'Retrived Code Combination ID : '||LN_CCID);
										-- END :  Added by AKALA on 08-APR-2026, to create or get CCID	
										LC_ERR_MSG := LC_MSG;
										-- Updating AU_CUSTOMER_SHIP_TO_TEST on Successful Creation of every Site and Uses
											UPDATE AU_CUSTOMER_SHIP_TO_TEST
											SET ERP_CUSTOMER_NUMBER = LN_ACCOUNT_NUMBER
											, ERP_CREATION_DATE = SYSDATE
											, CUSTOMER_SHIP_ID = LN_CUST_ACCT_SITE_ID
											, ERP_SITE_USE_ID = LN_SITE_USE_ID
											, ERP_CUSTOMER_ID = LN_CUST_ACCOUNT_ID
											, ERP_PARTY_ID = LN_PARTY_ID
											, ERP_PROCESS_FLAG = 'S'
											, CCID = LN_CCID
											, ERP_ERR_MSG = DECODE(ERP_ERR_MSG, NULL,'',ERP_ERR_MSG||'; ')||J.ERP_ERR_MSG
											WHERE 1=1
											AND AGENCY_ID = J.AGENCY_ID
											AND CENTRE_NUMBER = J.CENTRE_NUMBER
											AND MAIN_CENTRE_NUMBER = J.MAIN_CENTRE_NUMBER;
											COMMIT;
										ELSE
											FND_FILE.PUT_LINE(FND_FILE.LOG,'LN_SITE_USE_ID: '||LN_SITE_USE_ID||'; ERROR : '||LC_ERR_MSG);
											ROLLBACK;
										END IF;
									ELSE
										FND_FILE.PUT_LINE(FND_FILE.LOG,'LN_CUST_ACCT_SITE_ID: '||LN_CUST_ACCT_SITE_ID||'; ERROR : '||LC_MSG);
									END IF;
								ELSE
									FND_FILE.PUT_LINE(FND_FILE.LOG,'LN_PARTY_SITE_ID: '||LN_PARTY_SITE_ID||'; ERROR : '||LC_MSG);
								END IF;
							ELSE 
							FND_FILE.PUT_LINE(FND_FILE.LOG,'LN_LOCATION_ID: '||LN_LOCATION_ID||'; ERROR : '||LC_MSG);
							END IF;
							
							FND_FILE.PUT_LINE(FND_FILE.LOG,'LN_CUST_ACCOUNT_ID: '
											||LN_CUST_ACCOUNT_ID
											||'; PARTY_ID: '||LN_PARTY_ID
											||'; LN_LOCATION_ID: '||LN_LOCATION_ID
											||'; LN_PARTY_SITE_ID: '||LN_PARTY_SITE_ID
											||'; LN_CUST_ACCT_SITE_ID: '||LN_CUST_ACCT_SITE_ID
											||'; LN_SITE_USE_ID: '||LN_SITE_USE_ID
											);
							
						EXCEPTION 
						WHEN OTHERS 
							THEN FND_FILE.PUT_LINE(FND_FILE.LOG,SQLCODE||' - '||SQLERRM); 
						END;
						FND_FILE.PUT_LINE(FND_FILE.LOG,RPAD('*',25,'*'));
					END LOOP;
				ELSE 
				FND_FILE.PUT_LINE(FND_FILE.LOG,'LN_CUST_ACCOUNT_ID: '||LN_CUST_ACCOUNT_ID||'; PARTY_ID: '||LN_PARTY_ID||'; ERROR : '||LC_MSG);
				END IF;
			EXCEPTION 
				WHEN OTHERS THEN 
					FND_FILE.PUT_LINE(FND_FILE.LOG, SQLCODE||' - '||SQLERRM);
			END;
			
			IF LN_CUST_ACCOUNT_ID > 0 AND LN_LOCATION_ID > 0  AND  LN_PARTY_SITE_ID > 0  
			AND  LN_CUST_ACCT_SITE_ID > 0  AND  LN_SITE_USE_ID > 0
			THEN
				UPDATE AU_CUSTOMER_MASTER_NEW_TEST
				SET ERP_CUSTOMER_ID = LN_CUST_ACCOUNT_ID
				, ERP_CUSTOMER_NUMBER = LN_ACCOUNT_NUMBER
				, ERP_PARTY_ID = LN_PARTY_ID
				, ERP_PROCESS_FLAG = 'Y'
				, ERP_ERR_MSG = DECODE(ERP_ERR_MSG,NULL,'',ERP_ERR_MSG||'; ')||I.ERP_ERR_MSG
				WHERE AGENCY_ID = I.AGENCY_ID
				;
				COMMIT;
			ELSE
				FND_FILE.PUT_LINE(FND_FILE.LOG,'LN_CUST_ACCOUNT_ID: '||LN_CUST_ACCOUNT_ID||'; PARTY_ID: '||LN_PARTY_ID||'; ERROR : '||LC_MSG);
				FND_FILE.PUT_LINE(FND_FILE.LOG,'LN_LOCATION_ID: '||LN_LOCATION_ID||'; ERROR : '||LC_MSG);
				FND_FILE.PUT_LINE(FND_FILE.LOG,'LN_PARTY_SITE_ID: '||LN_PARTY_SITE_ID||'; ERROR : '||LC_MSG);
				FND_FILE.PUT_LINE(FND_FILE.LOG,'LN_CUST_ACCT_SITE_ID: '||LN_CUST_ACCT_SITE_ID||'; ERROR : '||LC_MSG);
				FND_FILE.PUT_LINE(FND_FILE.LOG,'LN_SITE_USE_ID: '||LN_SITE_USE_ID||'; ERROR : '||LC_MSG);
			END IF;
			FND_FILE.PUT_LINE(FND_FILE.LOG,RPAD('*',25,'*'));
			FND_FILE.PUT_LINE(FND_FILE.LOG,'Loop for Agency ID: '||I.AGENCY_ID||' is completed.');
			FND_FILE.PUT_LINE(FND_FILE.LOG,RPAD('*',25,'*'));
		END LOOP;
	EXCEPTION
	WHEN OTHERS 
	THEN 
		FND_FILE.PUT_LINE(FND_FILE.LOG,SQLCODE||' - '||SQLERRM);
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
     ***************************************************************************************************/
	PROCEDURE CREATE_CUSTOMERS_SITES 
	AS
	LN_LOCATION_ID			HZ_LOCATIONS.LOCATION_ID%TYPE;
	LN_LOC_ID				HZ_LOCATIONS.LOCATION_ID%TYPE;
	LN_PARTY_ID				HZ_PARTIES.PARTY_ID%TYPE;
	LN_PARTY_SITE_ID		HZ_PARTY_SITES.PARTY_SITE_ID%TYPE;
	LN_CUST_ACCOUNT_ID		HZ_CUST_ACCOUNTS.CUST_ACCOUNT_ID%TYPE;
	LN_ACCOUNT_NUMBER		HZ_CUST_ACCOUNTS.ACCOUNT_NUMBER%TYPE;
	LN_CUST_ACCT_SITE_ID	HZ_CUST_ACCT_SITES_ALL.CUST_ACCT_SITE_ID%TYPE;
	LN_SITE_USE_ID			HZ_CUST_SITE_USES_ALL.SITE_USE_ID%TYPE;
	
	CURSOR CUSTOMER_CUR IS
		SELECT *
		FROM AU_CUSTOMER_MASTER_NEW_TEST A
		WHERE AGENCY_ID  IN (SELECT AGENCY_ID 
							FROM XXAU_AGENCY_APPROVAL_DTL_TEST
							WHERE TRUNC(CREATION_DATE) >='01-OCT-2024'
							AND APPROVE_REJECT = 'A'
							AND AGREEMENT_FLAG = 'Y')
		AND ERP_CUSTOMER_NUMBER IS NOT NULL
		AND ERP_CUSTOMER_ID IS NOT NULL
		AND ERP_PARTY_ID IS NOT NULL
		AND EXISTS (SELECT 1 
				FROM AU_CUSTOMER_SHIP_TO_TEST 
				WHERE AGENCY_ID = A.AGENCY_ID 
				AND UPPER(PROUCT_NAME) NOT LIKE '%SAFALTA%' 
				AND ERP_CUSTOMER_NUMBER IS NULL
				AND ERP_SITE_USE_ID IS NULL)
	;
	
	CURSOR SITES_CUR(P_AGENCY_ID NUMBER) IS
		SELECT *
		FROM AU_CUSTOMER_SHIP_TO_TEST A
		WHERE AGENCY_ID IN (SELECT AGENCY_ID 
							FROM XXAU_AGENCY_APPROVAL_DTL_TEST
							WHERE TRUNC(CREATION_DATE) >='01-OCT-2024'
							AND APPROVE_REJECT = 'A'
							AND AGREEMENT_FLAG = 'Y')						
		AND UPPER(PROUCT_NAME) NOT LIKE '%SAFALTA%' 
		AND CUSTOMER_SHIP_ID IS NULL
		AND ERP_PARTY_ID IS NULL
		AND ERP_SITE_USE_ID IS NULL
		AND ERP_CUSTOMER_NUMBER IS NULL
		AND ERP_CUSTOMER_ID IS NULL
		AND AGENCY_ID = P_AGENCY_ID
	;
		
		LC_MSG VARCHAR2(4000);
		LC_ERR_MSG VARCHAR2(4000);
		LC_PARTY_SITE_NUM VARCHAR2(200);
		LN_PHONE_CONTACT_POINT_ID NUMBER;
		LN_EMAIL_CONTACT_POINT_ID NUMBER;
		LN_CCID					  NUMBER; -- Added by AKALA on 08-APR-2026 for CODE_COMBINATION_ID
	
	BEGIN
		FND_FILE.PUT_LINE(FND_FILE.LOG,RPAD('*',30,'*'));
		FND_FILE.PUT_LINE(FND_FILE.LOG,'In CREATE_CUSTOMERS_SITES');
		FOR I IN CUSTOMER_CUR
		LOOP
			LC_ERR_MSG := NULL;
			LN_LOCATION_ID:= NULL;
			FND_FILE.PUT_LINE(FND_FILE.LOG,RPAD('+',25,'+'));
			BEGIN
				BEGIN
					SELECT PARTY_ID, CUST_ACCOUNT_ID, ACCOUNT_NUMBER
					INTO LN_PARTY_ID, LN_CUST_ACCOUNT_ID, LN_ACCOUNT_NUMBER
					FROM HZ_CUST_ACCOUNTS
					WHERE CUST_ACCOUNT_ID = I.ERP_CUSTOMER_ID;
				EXCEPTION 
				WHEN OTHERS 
					THEN LN_PARTY_ID:=NULL;
				END;
			
				FOR J IN SITES_CUR(I.AGENCY_ID)
				LOOP
				FND_FILE.PUT_LINE(FND_FILE.LOG,RPAD('_',25,'_'));
					BEGIN
						LC_ERR_MSG := NULL;
						LN_LOCATION_ID := -1;
						LN_PARTY_SITE_ID := -1;  
						LN_CUST_ACCT_SITE_ID := -1; 
						LN_SITE_USE_ID:= -1;
						CREATE_LOCATION (P_ADDRESS1 	=> J.ADDRESS
										, P_ADDRESS2 	=> NULL
										, P_CITY 		=> J.CITY
										, P_POSTAL_CODE => J.POSTAL_CODE
										, P_COUNTY 		=> J.DISTRICT
										, P_STATE 		=> J.STATE
										, P_COUNTRY 	=> 'IN'
										, P_LOCATION_ID => LN_LOCATION_ID
										, P_MSG			=> LC_MSG);
										
						LC_ERR_MSG := LC_MSG;
						IF LN_LOCATION_ID > 0
							THEN
								CREATE_PARTY_SITE (P_PARTY_ID 		=> LN_PARTY_ID
												 , P_LOCATION_ID 	=> LN_LOCATION_ID
												 , P_PARTY_SITE_NUM => LC_PARTY_SITE_NUM
												 , P_PARTY_SITE_ID	=> LN_PARTY_SITE_ID
												 , P_MSG		 	=> LC_MSG
												 );
												 
								LC_ERR_MSG := LC_MSG;
								IF LN_PARTY_SITE_ID > 0
								THEN 
								-- Creating Contact Point -- Added by AKALA on 07-APR-2026
									CREATE_CONTACT_POINT_SITE_LVL ( P_PARTY_SITE_ID => LN_PARTY_SITE_ID
																  , P_PHONE => J.MOBILE_NO 
																  , P_EMAIL => J.EMAIL
																  , P_TABLE => 'HZ_PARTY_SITES'
																  , P_PHONE_CONTACT_POINT_ID => LN_PHONE_CONTACT_POINT_ID
																  , P_EMAIL_CONTACT_POINT_ID => LN_EMAIL_CONTACT_POINT_ID
																  , P_MSG => LC_MSG);
									IF LN_PHONE_CONTACT_POINT_ID < 0
									THEN
										FND_FILE.PUT_LINE(FND_FILE.LOG,'Cannot create Phone Cotact Point : '||J.MOBILE_NO);
									END IF;
									
									IF LN_EMAIL_CONTACT_POINT_ID < 0
									THEN
										FND_FILE.PUT_LINE(FND_FILE.LOG,'Cannot create Email Cotact Point : '||J.EMAIL);
									END IF;
								-- end : Added Email and Phone Contact Points on 07-APR-2026
								
									CREATE_CUST_ACCT_SITE (P_CUST_ACCOUNT_ID 	=> LN_CUST_ACCOUNT_ID
														 , P_PARTY_SITE_ID 		=> LN_PARTY_SITE_ID
														 , P_CUST_ACCT_SITE_ID	=> LN_CUST_ACCT_SITE_ID
														 , P_MSG				=>	LC_MSG
														 );
									
									LC_ERR_MSG := LC_MSG;
									IF LN_CUST_ACCT_SITE_ID > 0
									THEN
										CREATE_CUST_SITE_USES (P_CUST_ACCT_SITE_ID 	=> LN_CUST_ACCT_SITE_ID
															, P_SITE_USE_CODE 		=> 'SHIP_TO'
															, P_LOCATION 			=> J.DAK_NAME
															, P_SITE_USE_ID			=> LN_SITE_USE_ID
															, P_MSG					=> LC_MSG
															) ;
															
										LC_ERR_MSG := LC_MSG;					
										IF LN_SITE_USE_ID > 0
										THEN
										--Start:  Added by AKALA on 08-APR-2026, to create or get CCID									
										LN_CCID:=-1;
										
										CREATE_CODE_COMBINATION ( P_ORG_ID 		    => J.ORG_ID
																, P_INV_ORG 		=> J.INV_ORG
																, P_AGENCY_ID 		=> J.AGENCY_ID
																, P_CENTRE_NUMBER 	=> J.CENTRE_NUMBER
																, P_AGENCY_NAME 	=> I.AGENCY_NAME
																, P_CCID			=> LN_CCID
																, P_MSG 			=> LC_MSG);
										
										FND_FILE.PUT_LINE(FND_FILE.LOG,'Retrived Code Combination ID : '||LN_CCID);
										-- END :  Added by AKALA on 08-APR-2026, to create or get CCID	
										LC_ERR_MSG := LC_MSG;
										UPDATE AU_CUSTOMER_SHIP_TO_TEST
											SET ERP_CUSTOMER_NUMBER = LN_ACCOUNT_NUMBER
											, ERP_CREATION_DATE = SYSDATE
											, CUSTOMER_SHIP_ID = LN_CUST_ACCT_SITE_ID
											, ERP_SITE_USE_ID = LN_SITE_USE_ID
											, ERP_CUSTOMER_ID = LN_CUST_ACCOUNT_ID
											, ERP_PARTY_ID = LN_PARTY_ID
											, ERP_PROCESS_FLAG = 'S'
											, CCID = LN_CCID
											, ERP_ERR_MSG = DECODE(ERP_ERR_MSG, NULL,'',ERP_ERR_MSG||'; ')||LC_ERR_MSG
											WHERE 1=1
											AND AGENCY_ID = J.AGENCY_ID
											AND CENTRE_NUMBER = J.CENTRE_NUMBER
											AND MAIN_CENTRE_NUMBER = J.MAIN_CENTRE_NUMBER;
											
											COMMIT;
										END IF;
									END IF;
								END IF;
							END IF;
						
						FND_FILE.PUT_LINE(FND_FILE.LOG,'LN_CUST_ACCOUNT_ID: '
										||LN_CUST_ACCOUNT_ID
										||'; PARTY_ID: '||LN_PARTY_ID
										||'; LN_LOCATION_ID: '||LN_LOCATION_ID
										||'; LN_PARTY_SITE_ID: '||LN_PARTY_SITE_ID
										||'; LN_CUST_ACCT_SITE_ID: '||LN_CUST_ACCT_SITE_ID
										||'; LN_SITE_USE_ID: '||LN_SITE_USE_ID
										);
						FND_FILE.PUT_LINE(FND_FILE.LOG,RPAD('-',25,'-'));
						
					EXCEPTION 
					WHEN OTHERS 
						THEN FND_FILE.PUT_LINE(FND_FILE.LOG,SQLCODE||' - '||SQLERRM); 
					END;
				END LOOP;
			EXCEPTION 
				WHEN OTHERS THEN 
					FND_FILE.PUT_LINE(FND_FILE.LOG, SQLCODE||' - '||SQLERRM);
			END;
		END LOOP;
	EXCEPTION
	WHEN OTHERS 
	THEN 
		FND_FILE.PUT_LINE(FND_FILE.LOG,SQLCODE||' - '||SQLERRM);
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
     ***************************************************************************************************/
	PROCEDURE VALIDATE_REQUIRED 
	AS
	BEGIN
		FND_FILE.PUT_LINE(FND_FILE.LOG,RPAD('*',30,'*'));
		FND_FILE.PUT_LINE(FND_FILE.LOG,'In VALIDATE_REQUIRED');
		FND_FILE.PUT_LINE(FND_FILE.LOG,'GN_USER_ID: '||GN_USER_ID);
		FND_FILE.PUT_LINE(FND_FILE.LOG,'GN_ORG_ID: '||GN_ORG_ID);
		FND_FILE.PUT_LINE(FND_FILE.LOG,'GN_RESP_ID: '||GN_RESP_ID);
		FND_FILE.PUT_LINE(FND_FILE.LOG,'GN_RESP_APPL_ID: '||GN_RESP_APPL_ID);
	EXCEPTION
	WHEN OTHERS 
	THEN 
		FND_FILE.PUT_LINE(FND_FILE.LOG,SQLCODE||' - '||SQLERRM);
	END VALIDATE_REQUIRED;
	
	
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
     ***************************************************************************************************/
	PROCEDURE MAIN (ERRBUFF OUT VARCHAR2, RETCODE OUT VARCHAR2) 
	AS
	BEGIN
		FND_FILE.PUT_LINE(FND_FILE.LOG,RPAD('*',25,'*'));
		FND_FILE.PUT_LINE(FND_FILE.LOG,'### Process Started ###');
		FND_FILE.PUT_LINE(FND_FILE.LOG,RPAD('*',25,'*'));
		VALIDATE_REQUIRED;
		CREATE_CUSTOMERS_SITES;
		CREATE_CUSTOMER_AND_SITES; 
		CREATE_SAFALTA_CUST_AND_SITES;
	EXCEPTION
	WHEN OTHERS 
	THEN 
		FND_FILE.PUT_LINE(FND_FILE.LOG,SQLCODE||' - '||SQLERRM);
	END MAIN;
	
END XXAU_CREATE_CUSTOMER_SITE_PKG;