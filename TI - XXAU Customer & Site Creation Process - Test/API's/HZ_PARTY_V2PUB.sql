DECLARE
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
   fnd_global.apps_initialize(2482, 20678, 222);
   mo_global.init('AR');
   fnd_client_info.set_org_context(288);
   l_organization_rec.organization_name := 'XYZ Corporation Dummy';
   l_organization_rec.created_by_module := 'HZ_CPUI';
   DBMS_OUTPUT.PUT_LINE('Calling hz_party_v2pub.create_organization API');
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
      COMMIT;
      DBMS_OUTPUT.PUT_LINE('Organization Creation is Successful ');
      DBMS_OUTPUT.PUT_LINE('Party Id         ='|| l_party_id);
      DBMS_OUTPUT.PUT_LINE('Party Number     ='|| l_party_number);
      DBMS_OUTPUT.PUT_LINE('Profile Id       ='|| l_profile_id);  
   ELSE
      DBMS_OUTPUT.put_line ('Creation of Organization failed:'||l_msg_data);
      ROLLBACK;
      FOR i IN 1 .. l_msg_count
      LOOP
         l_msg_data := oe_msg_pub.get( p_msg_index => i, p_encoded => 'F');
         dbms_output.put_line( i|| ') '|| l_msg_data);
      END LOOP;
   END IF;
   DBMS_OUTPUT.PUT_LINE('Organization Creation Complete');
END;