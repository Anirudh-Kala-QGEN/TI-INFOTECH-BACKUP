CREATE OR REPLACE PACKAGE BODY XXAU_CREATE_CUSTOMER_SITE_PKG
IS

	FUNCTION CREATE_CUST_SITE_USES (P_CUST_ACCT_SITE_ID NUMBER,P_SITE_USE_CODE VARCHAR2,P_LOCATION VARCHAR2) 
		RETURN NUMBER
	AS
		L_CUST_SITE_USE_REC    HZ_CUST_ACCOUNT_SITE_V2PUB.CUST_SITE_USE_REC_TYPE;
		L_CUSTOMER_PROFILE_REC HZ_CUSTOMER_PROFILE_V2PUB.CUSTOMER_PROFILE_REC_TYPE;
		L_SITE_USE_ID          HZ_CUST_SITE_USES.SITE_USE_ID%TYPE;
		L_RETURN_STATUS        VARCHAR2(100);
		L_MSG_COUNT            NUMBER;
		L_MSG_DATA             VARCHAR2(2000);
	BEGIN
			DBMS_OUTPUT.ENABLE (BUFFER_SIZE => NULL);
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
				END LOOP;
			  --FND_FILE.PUT_LINE(FND_FILE.LOG,'Cust Site Use Creation failed:'||l_msg_data);
			  ROLLBACK;
		   END IF;
		   --FND_FILE.PUT_LINE(FND_FILE.LOG,'Cust Site Use Creation Complete');
		RETURN L_SITE_USE_ID;
	EXCEPTION
	WHEN OTHERS 
	THEN 
		FND_FILE.PUT_LINE(FND_FILE.LOG,SQLCODE||' - '||SQLERRM);
		RETURN 0;
	END;
		
	FUNCTION CREATE_CUST_ACCT_SITE (P_CUST_ACCOUNT_ID NUMBER,P_PARTY_SITE_ID NUMBER) 
		RETURN NUMBER
	AS
		L_CUST_ACCT_SITE_REC HZ_CUST_ACCOUNT_SITE_V2PUB.CUST_ACCT_SITE_REC_TYPE;
		L_CUST_ACCT_SITE_ID  HZ_CUST_ACCT_SITES.CUST_ACCT_SITE_ID%TYPE;
		L_RETURN_STATUS      VARCHAR2(100);
		L_MSG_COUNT          NUMBER;
		L_MSG_DATA           VARCHAR2(2000);
	BEGIN
			DBMS_OUTPUT.ENABLE (buffer_size => NULL);
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
			  END LOOP;
			  ROLLBACK;
			  --FND_FILE.PUT_LINE(FND_FILE.LOG,'Cust Acct Site Creation failed:'||l_msg_data);
		   END IF;
		   --FND_FILE.PUT_LINE(FND_FILE.LOG,'Cust Acct Site Creation Complete');
		RETURN L_CUST_ACCT_SITE_ID;
	EXCEPTION
	WHEN OTHERS 
	THEN 
		FND_FILE.PUT_LINE(FND_FILE.LOG,SQLCODE||' - '||SQLERRM);
		RETURN 0;
	END;
		
	FUNCTION CREATE_CUST_ACCOUNT (P_ORGANIZATION_NAME VARCHAR2,P_PARTY_ID NUMBER, P_ACCOUNT_NAME VARCHAR2) 
		RETURN NUMBER
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
				  p_init_msg_list       => FND_API.G_TRUE,
				  p_cust_account_rec    =>l_cust_acct_rec,
				  p_organization_rec    =>l_organization_rec,
				  p_customer_profile_rec=>l_cust_profile_rec,
				  p_create_profile_amt  =>FND_API.G_FALSE,
				  x_cust_account_id     =>l_cust_account_id,
				  x_account_number      =>l_account_number,
				  x_party_id            =>l_party_id,
				  x_party_number        =>l_party_number,
				  x_profile_id          =>l_profile_id,
				  x_return_status       =>l_return_status,
				  x_msg_count           =>l_msg_count,
				  x_msg_data            =>l_msg_data
				 );
	   IF l_return_status = 'S' 
	   THEN
		  FND_FILE.PUT_LINE(FND_FILE.LOG,'Party and Customer Account Creation is Successful ');
		  FND_FILE.PUT_LINE(FND_FILE.LOG,'Party Id         ='|| l_party_id);
		  FND_FILE.PUT_LINE(FND_FILE.LOG,'Party Number     ='|| l_party_number);
		  FND_FILE.PUT_LINE(FND_FILE.LOG,'Profile Id       ='|| l_profile_id);  
		  FND_FILE.PUT_LINE(FND_FILE.LOG,'CUST_ACCOUNT_ID  ='|| l_cust_account_id);
		  FND_FILE.PUT_LINE(FND_FILE.LOG,'Account Number   ='|| l_account_number);  
		  COMMIT;
	   ELSE
		  FOR i IN 1 .. l_msg_count
		  LOOP
			 l_msg_data := FND_MSG_PUB.get( p_msg_index => i, p_encoded => 'F');
			 FND_FILE.PUT_LINE(FND_FILE.LOG, i|| ') '|| l_msg_data);
		  END LOOP;
		  ROLLBACK;
		  --FND_FILE.PUT_LINE(FND_FILE.LOG,'Party and Customer Account Creation failed:'||l_msg_data);
	   END IF;
	   --FND_FILE.PUT_LINE(FND_FILE.LOG,'Party and Customer Account Creation Complete');
		RETURN L_CUST_ACCOUNT_ID;
	EXCEPTION
	WHEN OTHERS 
	THEN 
		FND_FILE.PUT_LINE(FND_FILE.LOG,SQLCODE||' - '||SQLERRM);
		RETURN 0;
	END;
		
	FUNCTION CREATE_PARTY_SITE (P_PARTY_ID NUMBER, P_LOCATION_ID NUMBER) 
		RETURN NUMBER
	AS
		L_PARTY_SITE_REC    HZ_PARTY_SITE_V2PUB.PARTY_SITE_REC_TYPE;
		L_PARTY_SITE_ID     HZ_PARTY_SITES.PARTY_SITE_ID%TYPE;
		L_PARTY_SITE_NUMBER HZ_PARTY_SITES.PARTY_SITE_NUMBER%TYPE;
		L_RETURN_STATUS     VARCHAR2(100);
		L_MSG_COUNT         NUMBER;
		L_MSG_DATA          VARCHAR2(2000);
	BEGIN
			DBMS_OUTPUT.ENABLE (buffer_size => NULL);
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
			  END LOOP;
			  --FND_FILE.PUT_LINE(FND_FILE.LOG,'Party Site Creation failed:'||l_msg_data);
			  ROLLBACK;
		   END IF;
		   --FND_FILE.PUT_LINE(FND_FILE.LOG,'Party Site Creation Complete');
		RETURN L_PARTY_SITE_ID;
	EXCEPTION
	WHEN OTHERS 
	THEN 
		FND_FILE.PUT_LINE(FND_FILE.LOG,SQLCODE||' - '||SQLERRM);
		RETURN 0;
	END;
		
	FUNCTION CREATE_PARTY (P_ORGANIZATION_NAME VARCHAR2) 
		RETURN NUMBER
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
			  COMMIT;
		   ELSE
			  DBMS_OUTPUT.put_line ('Creation of Organization failed:'||l_msg_data);
			  FOR i IN 1 .. l_msg_count
			  LOOP
				 l_msg_data := FND_MSG_PUB.get( p_msg_index => i, p_encoded => 'F');
				 FND_FILE.PUT_LINE(FND_FILE.LOG, i|| ') '|| l_msg_data);
			  END LOOP;
			  ROLLBACK;
		   END IF;
		RETURN L_PARTY_ID;
	EXCEPTION
	WHEN OTHERS 
	THEN 
		FND_FILE.PUT_LINE(FND_FILE.LOG,SQLCODE||' - '||SQLERRM);
		RETURN 0;
	END;
		
	FUNCTION CREATE_LOCATION (P_ADDRESS1 VARCHAR2,P_ADDRESS2 VARCHAR2, P_CITY VARCHAR2, P_POSTAL_CODE NUMBER,P_STATE VARCHAR2,P_COUNTRY VARCHAR2) 
		RETURN NUMBER
	AS
		L_LOCATION_REC     HZ_LOCATION_V2PUB.LOCATION_REC_TYPE;
		L_LOCATION_ID      NUMBER;
		L_RETURN_STATUS    VARCHAR2(100);
		L_MSG_COUNT        NUMBER;
		L_MSG_DATA         VARCHAR2(2000);
	BEGIN
			DBMS_OUTPUT.ENABLE (BUFFER_SIZE => NULL);
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
					END LOOP;
				--FND_FILE.PUT_LINE(FND_FILE.LOG,'Location Creation failed after error loop:'||l_msg_data);
				ROLLBACK;
			END IF;
			FND_FILE.PUT_LINE(FND_FILE.LOG,'Location Creation PROCESS complete');
		RETURN L_LOCATION_ID;
	EXCEPTION
	WHEN OTHERS 
	THEN 
		FND_FILE.PUT_LINE(FND_FILE.LOG,SQLCODE||' - '||SQLERRM);
		RETURN 0;
	END;
		
	PROCEDURE CREATE_CUSTOMER_AND_SITES 
	AS
	LN_LOCATION_ID			HZ_LOCATIONS.LOCATION_ID%TYPE;
	LN_LOC_ID				HZ_LOCATIONS.LOCATION_ID%TYPE;
	LN_PARTY_ID				HZ_PARTIES.PARTY_ID%TYPE;
	LN_PARTY_SITE_ID		HZ_PARTY_SITES.PARTY_SITE_ID%TYPE;
	LN_CUST_ACCOUNT_ID		HZ_CUST_ACCOUNTS.CUST_ACCOUNT_ID%TYPE;
	LN_CUST_ACCT_SITE_ID	HZ_CUST_ACCT_SITES_ALL.CUST_ACCT_SITE_ID%TYPE;
	LN_SITE_USE_ID			HZ_CUST_SITE_USES_ALL.SITE_USE_ID%TYPE;
	BEGIN
		FND_FILE.PUT_LINE(FND_FILE.LOG,RPAD('*',30,'*'));
		LN_LOCATION_ID:= CREATE_LOCATION (P_ADDRESS1 => '123 subway Dummy'
										, P_ADDRESS2 => 'Enodeas Building'
										, P_CITY => 'New York'
										, P_POSTAL_CODE => '10010'
										, P_STATE => 'NY'
										, P_COUNTRY => 'US');
		BEGIN
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
		LN_CUST_ACCOUNT_ID := CREATE_CUST_ACCOUNT (P_ORGANIZATION_NAME => NULL,P_PARTY_ID => NULL, P_ACCOUNT_NAME => NULL) ;
		FND_FILE.PUT_LINE(FND_FILE.LOG,'LN_CUST_ACCOUNT_ID: '||LN_CUST_ACCOUNT_ID);
		FND_FILE.PUT_LINE(FND_FILE.LOG,RPAD('*',30,'*'));
		LN_CUST_ACCT_SITE_ID:= CREATE_CUST_ACCT_SITE (P_CUST_ACCOUNT_ID => NULL,P_PARTY_SITE_ID => NULL);
		FND_FILE.PUT_LINE(FND_FILE.LOG,'LN_CUST_ACCT_SITE_ID: '||LN_CUST_ACCT_SITE_ID);
		FND_FILE.PUT_LINE(FND_FILE.LOG,RPAD('*',30,'*'));
		LN_SITE_USE_ID := CREATE_CUST_SITE_USES (P_CUST_ACCT_SITE_ID => NULL,P_SITE_USE_CODE => 'SHIP_TO',P_LOCATION => NULL) ;
		FND_FILE.PUT_LINE(FND_FILE.LOG,'LN_SITE_USE_ID: '||LN_SITE_USE_ID);
		FND_FILE.PUT_LINE(FND_FILE.LOG,RPAD('*',30,'*'));
	EXCEPTION
	WHEN OTHERS 
	THEN 
		FND_FILE.PUT_LINE(FND_FILE.LOG,SQLCODE||' - '||SQLERRM);
	END;
	
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
	END;
	
	PROCEDURE MAIN (ERRBUFF OUT VARCHAR2, RETCODE OUT VARCHAR2) 
	AS
	BEGIN
		FND_FILE.PUT_LINE(FND_FILE.LOG,RPAD('*',30,'*'));
		FND_FILE.PUT_LINE(FND_FILE.LOG,'In MAIN');
		FND_FILE.PUT_LINE(FND_FILE.LOG,RPAD('*',30,'*'));
		FND_FILE.PUT_LINE(FND_FILE.LOG,'GN_USER_ID: '||GN_USER_ID);
		FND_FILE.PUT_LINE(FND_FILE.LOG,'GN_ORG_ID: '||GN_ORG_ID);
		FND_FILE.PUT_LINE(FND_FILE.LOG,'GN_RESP_ID: '||GN_RESP_ID);
		FND_FILE.PUT_LINE(FND_FILE.LOG,'GN_RESP_APPL_ID: '||GN_RESP_APPL_ID);
		VALIDATE_REQUIRED;
		CREATE_CUSTOMER_AND_SITES; 
	EXCEPTION
	WHEN OTHERS 
	THEN 
		FND_FILE.PUT_LINE(FND_FILE.LOG,SQLCODE||' - '||SQLERRM);
	END;
	
END XXAU_CREATE_CUSTOMER_SITE_PKG;