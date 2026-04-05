DECLARE
   L_PARTY_SITE_REC    HZ_PARTY_SITE_V2PUB.PARTY_SITE_REC_TYPE;
   L_PARTY_SITE_ID     HZ_PARTY_SITES.PARTY_SITE_ID%TYPE;
   L_PARTY_SITE_NUMBER HZ_PARTY_SITES.PARTY_SITE_NUMBER%TYPE;
   L_RETURN_STATUS     VARCHAR2(100);
   L_MSG_COUNT         NUMBER;
   L_MSG_DATA          VARCHAR2(2000);
BEGIN
   DBMS_OUTPUT.ENABLE (buffer_size => NULL);
   --Initiate the EBS Environment for API processing
   fnd_global.apps_initialize(1516, 20678, 222);
   mo_global.init('AR');
   fnd_client_info.set_org_context(81);
   --Populating Party Site Record
   l_party_site_rec.party_id                 := 6177207;
   l_party_site_rec.location_id              := 368444;
   l_party_site_rec.identifying_address_flag := 'Y'; -- Can be null
   l_party_site_rec.created_by_module        := 'BO_API';
   --Calling hz_party_site_v2pub.create_party_site
   DBMS_OUTPUT.PUT_LINE('Calling hz_party_site_v2pub.create_party_site api');
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
      COMMIT;
      DBMS_OUTPUT.PUT_LINE('Party Site Creation is Successful '); 
	    DBMS_OUTPUT.PUT_LINE('Party Site Number = '||l_party_site_number); 
	    DBMS_OUTPUT.PUT_LINE('Party Site Id = '||l_party_site_id); 
   ELSE
      ROLLBACK;
      FOR i IN 1 .. l_msg_count
      LOOP
         l_msg_data := oe_msg_pub.get( p_msg_index => i, p_encoded => 'F');
         dbms_output.put_line( i|| ') '|| l_msg_data);
      END LOOP;
      DBMS_OUTPUT.put_line ('Party Site Creation failed:'||l_msg_data);
   END IF;
   DBMS_OUTPUT.PUT_LINE('Party Site Creation Complete');
END;