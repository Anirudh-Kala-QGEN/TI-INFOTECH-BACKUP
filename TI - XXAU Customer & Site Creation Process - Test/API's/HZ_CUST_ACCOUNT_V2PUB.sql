DECLARE
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
   fnd_global.apps_initialize(2482, 20678, 222);
   mo_global.init('AR');
   fnd_client_info.set_org_context(288);
   --Populating organization record
   l_organization_rec.organization_name := 'XYZ Corporation Account'; -- Can be Null
   --For existing party use party_id
   l_organization_rec.party_rec.party_id:= 6177207;
   l_organization_rec.created_by_module := 'HZ_CPUI';
   l_cust_acct_rec.account_name         := 'XYZ Corp. Account'; -- Can be null
   l_cust_acct_rec.created_by_module    := 'BO_API';
   --Calling hz_cust_account_v2pub.create_cust_account
   DBMS_OUTPUT.PUT_LINE('Calling hz_cust_account_v2pub.create_cust_account api');
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
      COMMIT;
      DBMS_OUTPUT.PUT_LINE('Party and Customer Account Creation is Successful ');
      DBMS_OUTPUT.PUT_LINE('Party Id         ='|| l_party_id);
      DBMS_OUTPUT.PUT_LINE('Party Number     ='|| l_party_number);
      DBMS_OUTPUT.PUT_LINE('Profile Id       ='|| l_profile_id);  
      DBMS_OUTPUT.PUT_LINE('CUST_ACCOUNT_ID  ='|| l_cust_account_id);
      DBMS_OUTPUT.PUT_LINE('Account Number   ='|| l_account_number);  
   ELSE
      ROLLBACK;
      FOR i IN 1 .. l_msg_count
      LOOP
         l_msg_data := oe_msg_pub.get( p_msg_index => i, p_encoded => 'F');
         dbms_output.put_line( i|| ') '|| l_msg_data);
      END LOOP;
      DBMS_OUTPUT.put_line ('Party and Customer Account Creation failed:'||l_msg_data);
   END IF;
   DBMS_OUTPUT.PUT_LINE('Party and Customer Account Creation Complete');
END;