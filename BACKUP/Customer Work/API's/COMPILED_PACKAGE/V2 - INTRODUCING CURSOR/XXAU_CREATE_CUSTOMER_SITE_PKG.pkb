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
     * ===============  =========   =============   ====================================================
     * AKALA            1.0         1-APR-2026      Initial Version
	 ***************************************************************************************************/

	
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
     * AKALA            1.0         12-APR-2026     Initial Version
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
				--DBMS_OUTPUT.put_line ('Cust Site Use Creation failed:'||l_msg_data);
				FOR i IN 1 .. l_msg_count
				LOOP
					 l_msg_data := FND_MSG_PUB.get( p_msg_index => i, p_encoded => 'F');
					 FND_FILE.PUT_LINE(FND_FILE.LOG, i|| ') '|| l_msg_data);
					 P_MSG := P_MSG||l_msg_data||'; ';
				END LOOP;
			  --FND_FILE.PUT_LINE(FND_FILE.LOG,'Cust Site Use Creation failed:'||l_msg_data);
			  ROLLBACK;
			  L_SITE_USE_ID:= -1;
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
     * AKALA            1.0         12-APR-2026     Initial Version
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
		   (
						   p_init_msg_list      => FND_API.G_TRUE,
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
     * AKALA            1.0         12-APR-2026     Initial Version
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
				 (
				  P_INIT_MSG_LIST       => FND_API.G_TRUE,
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
     * AKALA            1.0         12-APR-2026     Initial Version
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
     * AKALA            1.0         12-APR-2026     Initial Version
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
		   --Initiate the EBS Environment for API processing
		   FND_GLOBAL.APPS_INITIALIZE(GN_USER_ID, GN_RESP_ID, GN_RESP_APPL_ID);
		   MO_GLOBAL.INIT('AR');
		   FND_CLIENT_INFO.SET_ORG_CONTEXT(GN_ORG_ID);
		   L_ORGANIZATION_REC.ORGANIZATION_NAME := P_ORGANIZATION_NAME; --'XYZ Corporation Dummy';
		   L_ORGANIZATION_REC.CREATED_BY_MODULE := 'HZ_CPUI';
		   --DBMS_OUTPUT.PUT_LINE('Calling hz_party_v2pub.create_organization API');
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
			  DBMS_OUTPUT.put_line ('Creation of Organization failed:'||l_msg_data);
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
     * AKALA            1.0         12-APR-2026     Initial Version
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
			(
			P_INIT_MSG_LIST => FND_API.G_TRUE,
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
     * AKALA            1.0         02-APR-2026     Initial Version
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
	AND AGENCY_ID = 8026294
	;
	
	CURSOR SAFALTA_SITE(P_AGENCY_ID NUMBER) IS
	SELECT *
	FROM AU_CUSTOMER_SHIP_TO_TEST
	WHERE AGENCY_ID IN (SELECT AGENCY_ID 
						FROM XXAU_AGENCY_APPROVAL_DTL_TEST
						WHERE TRUNC(CREATION_DATE) >='01-OCT-2024'
						AND APPROVE_REJECT = 'A'
						AND AGREEMENT_FLAG = 'Y')					
	AND ERP_SITE_USE_ID IS NULL
	AND ERP_CUSTOMER_NUMBER IS NULL
	AND UPPER(PROUCT_NAME) LIKE '%SAFALTA%'
	AND AGENCY_ID = P_AGENCY_ID;
	
	LC_MSG 				VARCHAR2(4000);
	LC_ERR_MSG 			VARCHAR2(4000);
	LC_ACCOUNT_NUMBER 	VARCHAR2(200);
	LC_PARTY_NUMBER 	VARCHAR2(200);
	LC_PARTY_SITE_NUM 	VARCHAR2(200);
	LN_PROFILE_ID 		NUMBER;
	LN_PARTY_SITE_ID 	NUMBER;
	
	BEGIN
		FND_FILE.PUT_LINE(FND_FILE.LOG,RPAD('*',30,'*'));
		FND_FILE.PUT_LINE(FND_FILE.LOG,'In CREATE_CUSTOMER_AND_SITES');
		
		FOR I IN C1
		LOOP
			LN_LOCATION_ID:= NULL;
			LN_PARTY_ID := NULL;
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
					THEN LN_PARTY_ID:=NULL;
				END;
				FND_FILE.PUT_LINE(FND_FILE.LOG,'LN_CUST_ACCOUNT_ID: '||LN_CUST_ACCOUNT_ID||'; PARTY_ID: '||LN_PARTY_ID);
				
				IF LN_CUST_ACCOUNT_ID > 0
				THEN
					FOR J IN C2(I.AGENCY_ID)
					LOOP
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
									CREATE_CUST_ACCT_SITE (P_CUST_ACCOUNT_ID 	=> LN_CUST_ACCOUNT_ID
														 , P_PARTY_SITE_ID 		=> LN_PARTY_SITE_ID
														 , P_CUST_ACCT_SITE_ID	=> LN_CUST_ACCT_SITE_ID
														 , P_MSG				=> LC_MSG
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
											UPDATE AU_CUSTOMER_SHIP_TO_TEST
											SET ERP_CUSTOMER_NUMBER = LN_ACCOUNT_NUMBER
											, ERP_CREATION_DATE = SYSDATE
											, CUSTOMER_SHIP_ID = LN_CUST_ACCT_SITE_ID
											, ERP_SITE_USE_ID = LN_SITE_USE_ID
											, ERP_CUSTOMER_ID = LN_CUST_ACCOUNT_ID
											, ERP_PARTY_ID = LN_PARTY_ID
											, ERP_PROCESS_FLAG = 'S'
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
						LN_LOCATION_ID := -1;
						LN_PARTY_SITE_ID := -1;  
						LN_CUST_ACCT_SITE_ID := -1; 
						LN_SITE_USE_ID:= -1;
					END LOOP;
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
				WHERE AGENCY_ID = I.AGENCY_ID
				;
				COMMIT;
			END IF;
			
		END LOOP;

		/*BEGIN
			SELECT LOCATION_ID
			INTO LN_LOC_ID
			FROM HZ_LOCATIONS
			WHERE LOCATION_ID = LN_LOCATION_ID;
		EXCEPTION WHEN OTHERS THEN LN_LOC_ID:=10101010101;
		END;
		FND_FILE.PUT_LINE(FND_FILE.LOG,'LN_LOC_ID: '||LN_LOC_ID);
		FND_FILE.PUT_LINE(FND_FILE.LOG,RPAD('*',30,'*'));
		LN_PARTY_ID:= CREATE_PARTY (P_ORGANIZATION_NAME => NULL);
		FND_FILE.PUT_LINE(FND_FILE.LOG,'LN_PARTY_ID: '||LN_PARTY_ID);
		FND_FILE.PUT_LINE(FND_FILE.LOG,RPAD('*',30,'*'));
		LN_PARTY_SITE_ID := CREATE_PARTY_SITE (P_PARTY_ID => NULL, P_LOCATION_ID => NULL);
		FND_FILE.PUT_LINE(FND_FILE.LOG,'LN_PARTY_SITE_ID: '||LN_PARTY_SITE_ID);
		FND_FILE.PUT_LINE(FND_FILE.LOG,RPAD('*',30,'*'));
		--LN_CUST_ACCOUNT_ID := CREATE_CUST_ACCOUNT (P_ORGANIZATION_NAME => NULL,P_PARTY_ID => NULL, P_ACCOUNT_NAME => NULL) ;
		FND_FILE.PUT_LINE(FND_FILE.LOG,'LN_CUST_ACCOUNT_ID: '||LN_CUST_ACCOUNT_ID);
		FND_FILE.PUT_LINE(FND_FILE.LOG,RPAD('*',30,'*'));
		LN_CUST_ACCT_SITE_ID:= CREATE_CUST_ACCT_SITE (P_CUST_ACCOUNT_ID => NULL,P_PARTY_SITE_ID => NULL);
		FND_FILE.PUT_LINE(FND_FILE.LOG,'LN_CUST_ACCT_SITE_ID: '||LN_CUST_ACCT_SITE_ID);
		FND_FILE.PUT_LINE(FND_FILE.LOG,RPAD('*',30,'*'));
		LN_SITE_USE_ID := CREATE_CUST_SITE_USES (P_CUST_ACCT_SITE_ID => NULL,P_SITE_USE_CODE => 'SHIP_TO',P_LOCATION => NULL) ;
		FND_FILE.PUT_LINE(FND_FILE.LOG,'LN_SITE_USE_ID: '||LN_SITE_USE_ID);
		FND_FILE.PUT_LINE(FND_FILE.LOG,RPAD('*',30,'*'));*/
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
     * AKALA            1.0         01-APR-2026     Initial Version
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
	FROM AU_CUSTOMER_MASTER_NEW_TEST
	WHERE AGENCY_ID  IN (SELECT AGENCY_ID 
						FROM XXAU_AGENCY_APPROVAL_DTL_TEST
						WHERE TRUNC(CREATION_DATE) >='01-OCT-2024'
						AND APPROVE_REJECT = 'A'
						AND AGREEMENT_FLAG = 'Y')
	AND ERP_CUSTOMER_NUMBER IS NULL
	AND AGENCY_ID = 8026294
	;
	
	CURSOR C2(P_AGENCY_ID NUMBER) IS
	SELECT *
	FROM AU_CUSTOMER_SHIP_TO_TEST
	WHERE AGENCY_ID IN (SELECT AGENCY_ID 
						FROM XXAU_AGENCY_APPROVAL_DTL_TEST
						WHERE TRUNC(CREATION_DATE) >='01-OCT-2024'
						AND APPROVE_REJECT = 'A'
						AND AGREEMENT_FLAG = 'Y')					
	AND ERP_SITE_USE_ID IS NULL
	AND AGENCY_ID = P_AGENCY_ID;
	
	LC_MSG 				VARCHAR2(4000);
	LC_ERR_MSG 			VARCHAR2(4000);
	LC_ACCOUNT_NUMBER 	VARCHAR2(200);
	LC_PARTY_NUMBER 	VARCHAR2(200);
	LC_PARTY_SITE_NUM 	VARCHAR2(200);
	LN_PROFILE_ID 		NUMBER;
	LN_PARTY_SITE_ID 	NUMBER;
	
	BEGIN
		FND_FILE.PUT_LINE(FND_FILE.LOG,RPAD('*',30,'*'));
		FND_FILE.PUT_LINE(FND_FILE.LOG,'In CREATE_CUSTOMER_AND_SITES');
		
		FOR I IN C1
		LOOP
			LN_LOCATION_ID:= NULL;
			LN_PARTY_ID := NULL;
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
					THEN LN_PARTY_ID:=NULL;
				END;
				FND_FILE.PUT_LINE(FND_FILE.LOG,'LN_CUST_ACCOUNT_ID: '||LN_CUST_ACCOUNT_ID||'; PARTY_ID: '||LN_PARTY_ID);
				
				IF LN_CUST_ACCOUNT_ID > 0
				THEN
					FOR J IN C2(I.AGENCY_ID)
					LOOP
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
									CREATE_CUST_ACCT_SITE (P_CUST_ACCOUNT_ID 	=> LN_CUST_ACCOUNT_ID
														 , P_PARTY_SITE_ID 		=> LN_PARTY_SITE_ID
														 , P_CUST_ACCT_SITE_ID	=> LN_CUST_ACCT_SITE_ID
														 , P_MSG				=> LC_MSG
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
											UPDATE AU_CUSTOMER_SHIP_TO_TEST
											SET ERP_CUSTOMER_NUMBER = LN_ACCOUNT_NUMBER
											, ERP_CREATION_DATE = SYSDATE
											, CUSTOMER_SHIP_ID = LN_CUST_ACCT_SITE_ID
											, ERP_SITE_USE_ID = LN_SITE_USE_ID
											, ERP_CUSTOMER_ID = LN_CUST_ACCOUNT_ID
											, ERP_PARTY_ID = LN_PARTY_ID
											, ERP_PROCESS_FLAG = 'S'
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
						LN_LOCATION_ID := -1;
						LN_PARTY_SITE_ID := -1;  
						LN_CUST_ACCT_SITE_ID := -1; 
						LN_SITE_USE_ID:= -1;
					END LOOP;
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
				WHERE AGENCY_ID = I.AGENCY_ID
				;
				COMMIT;
			END IF;
			
		END LOOP;

		/*BEGIN
			SELECT LOCATION_ID
			INTO LN_LOC_ID
			FROM HZ_LOCATIONS
			WHERE LOCATION_ID = LN_LOCATION_ID;
		EXCEPTION WHEN OTHERS THEN LN_LOC_ID:=10101010101;
		END;
		FND_FILE.PUT_LINE(FND_FILE.LOG,'LN_LOC_ID: '||LN_LOC_ID);
		FND_FILE.PUT_LINE(FND_FILE.LOG,RPAD('*',30,'*'));
		LN_PARTY_ID:= CREATE_PARTY (P_ORGANIZATION_NAME => NULL);
		FND_FILE.PUT_LINE(FND_FILE.LOG,'LN_PARTY_ID: '||LN_PARTY_ID);
		FND_FILE.PUT_LINE(FND_FILE.LOG,RPAD('*',30,'*'));
		LN_PARTY_SITE_ID := CREATE_PARTY_SITE (P_PARTY_ID => NULL, P_LOCATION_ID => NULL);
		FND_FILE.PUT_LINE(FND_FILE.LOG,'LN_PARTY_SITE_ID: '||LN_PARTY_SITE_ID);
		FND_FILE.PUT_LINE(FND_FILE.LOG,RPAD('*',30,'*'));
		--LN_CUST_ACCOUNT_ID := CREATE_CUST_ACCOUNT (P_ORGANIZATION_NAME => NULL,P_PARTY_ID => NULL, P_ACCOUNT_NAME => NULL) ;
		FND_FILE.PUT_LINE(FND_FILE.LOG,'LN_CUST_ACCOUNT_ID: '||LN_CUST_ACCOUNT_ID);
		FND_FILE.PUT_LINE(FND_FILE.LOG,RPAD('*',30,'*'));
		LN_CUST_ACCT_SITE_ID:= CREATE_CUST_ACCT_SITE (P_CUST_ACCOUNT_ID => NULL,P_PARTY_SITE_ID => NULL);
		FND_FILE.PUT_LINE(FND_FILE.LOG,'LN_CUST_ACCT_SITE_ID: '||LN_CUST_ACCT_SITE_ID);
		FND_FILE.PUT_LINE(FND_FILE.LOG,RPAD('*',30,'*'));
		LN_SITE_USE_ID := CREATE_CUST_SITE_USES (P_CUST_ACCT_SITE_ID => NULL,P_SITE_USE_CODE => 'SHIP_TO',P_LOCATION => NULL) ;
		FND_FILE.PUT_LINE(FND_FILE.LOG,'LN_SITE_USE_ID: '||LN_SITE_USE_ID);
		FND_FILE.PUT_LINE(FND_FILE.LOG,RPAD('*',30,'*'));*/
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
		AND EXISTS (SELECT 1 
				FROM AU_CUSTOMER_SHIP_TO_TEST 
				WHERE AGENCY_ID = A.AGENCY_ID 
				AND UPPER(PROUCT_NAME) NOT LIKE '%SAFALTA%' 
				AND ERP_CUSTOMER_NUMBER IS NULL
				AND ERP_SITE_USE_ID IS NULL)
		AND AGENCY_ID = 8026294
		;
	
	CURSOR SITES_CUR(P_AGENCY_ID NUMBER) IS
		SELECT *
		FROM AU_CUSTOMER_SHIP_TO_TEST
		WHERE AGENCY_ID IN (SELECT AGENCY_ID 
							FROM XXAU_AGENCY_APPROVAL_DTL_TEST
							WHERE TRUNC(CREATION_DATE) >='01-OCT-2024'
							AND APPROVE_REJECT = 'A'
							AND AGREEMENT_FLAG = 'Y')						
		AND UPPER(PROUCT_NAME) NOT LIKE '%SAFALTA%' 
		AND ERP_CUSTOMER_NUMBER IS NULL
		AND ERP_SITE_USE_ID IS NULL
		AND AGENCY_ID = P_AGENCY_ID;
		
		LC_MSG VARCHAR2(4000);
		LC_ERR_MSG VARCHAR2(4000);
		LC_PARTY_SITE_NUM VARCHAR2(200);
	
	BEGIN
		FND_FILE.PUT_LINE(FND_FILE.LOG,RPAD('*',30,'*'));
		FND_FILE.PUT_LINE(FND_FILE.LOG,'In CREATE_CUSTOMERS_SITES');
		FOR I IN CUSTOMER_CUR
		LOOP
			LC_ERR_MSG := NULL;
			LN_LOCATION_ID:= NULL;
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
											UPDATE AU_CUSTOMER_SHIP_TO_TEST
											SET ERP_CUSTOMER_NUMBER = LN_ACCOUNT_NUMBER
											, ERP_CREATION_DATE = SYSDATE
											, CUSTOMER_SHIP_ID = LN_CUST_ACCT_SITE_ID
											, ERP_SITE_USE_ID = LN_SITE_USE_ID
											, ERP_CUSTOMER_ID = LN_CUST_ACCOUNT_ID
											, ERP_PARTY_ID = LN_PARTY_ID
											, ERP_PROCESS_FLAG = 'S'
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
						LN_LOCATION_ID := -1;
						LN_PARTY_SITE_ID := -1;  
						LN_CUST_ACCT_SITE_ID := -1; 
						LN_SITE_USE_ID:= -1;
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