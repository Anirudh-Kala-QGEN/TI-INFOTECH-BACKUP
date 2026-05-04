DECLARE
   l_org_contact_rec      HZ_PARTY_CONTACT_V2PUB.ORG_CONTACT_REC_TYPE;
   l_org_contact_id       HZ_ORG_CONTACTS.ORG_CONTACT_ID%TYPE;
   l_party_rel_id         HZ_ORG_CONTACTS.PARTY_RELATIONSHIP_ID%TYPE;
   l_party_id             HZ_PARTIES.PARTY_ID%TYPE;
   l_party_number         HZ_PARTIES.PARTY_NUMBER%TYPE;
   l_return_status        VARCHAR2(100);
   l_msg_count            NUMBER;
   l_msg_data             VARCHAR2(2000);
BEGIN
   DBMS_OUTPUT.ENABLE (buffer_size => NULL);
   --Initiate the EBS Environment for API processing
   fnd_global.apps_initialize(1516, 20678, 222);
   mo_global.init('AR');
   fnd_client_info.set_org_context(81);
   -- Initializing the Mandatory API parameters
   l_org_contact_rec.job_title                        := 'Consultant';
   l_org_contact_rec.decision_maker_flag              := 'N';
   --l_org_contact_rec.job_title_code                   := 'CFO';
   l_org_contact_rec.created_by_module                := 'BO_API';
   l_org_contact_rec.party_rel_rec.subject_id         :=  18041600;
   l_org_contact_rec.party_rel_rec.subject_type       := 'PERSON';
   l_org_contact_rec.party_rel_rec.subject_table_name := 'HZ_PARTIES';
   l_org_contact_rec.party_rel_rec.object_id          :=  18041584;
   l_org_contact_rec.party_rel_rec.object_type        := 'ORGANIZATION';
   l_org_contact_rec.party_rel_rec.object_table_name  := 'HZ_PARTIES';
   l_org_contact_rec.party_rel_rec.relationship_code  := 'CONTACT_OF';
   l_org_contact_rec.party_rel_rec.relationship_type  := 'CONTACT';
   l_org_contact_rec.party_rel_rec.start_date         :=  SYSDATE;
   --Calling hz_cust_account_site_v2pub.create_cust_site_use
   DBMS_OUTPUT.PUT_LINE('Calling hz_party_contact_v2pub.create_org_contact api');
   HZ_PARTY_CONTACT_V2PUB.CREATE_ORG_CONTACT
             (
              p_init_msg_list    => FND_API.G_TRUE,
              p_org_contact_rec  => l_org_contact_rec,
              x_org_contact_id   => l_org_contact_id,
              x_party_rel_id     => l_party_rel_id,
              x_party_id         => l_party_id,
              x_party_number     => l_party_number,
              x_return_status    => l_return_status,
              x_msg_count        => l_msg_count,
              x_msg_data         => l_msg_data
                   );
IF l_return_status = 'S' 
   THEN
      COMMIT;
      DBMS_OUTPUT.PUT_LINE('Org Contact Creation is Successful '); 
	  DBMS_OUTPUT.PUT_LINE('org_contact_id = '||l_org_contact_id); 
	  DBMS_OUTPUT.PUT_LINE('party_rel_id = '||l_party_rel_id); 
	  DBMS_OUTPUT.PUT_LINE('party_id = '||l_party_id); 
   ELSE
      ROLLBACK;
	  DBMS_OUTPUT.put_line ('Org Contact Creation failed:'||l_msg_data);
      FOR i IN 1 .. l_msg_count
      LOOP
         l_msg_data := oe_msg_pub.get( p_msg_index => i, p_encoded => 'F');
         dbms_output.put_line( i|| ') '|| l_msg_data);
      END LOOP;
      DBMS_OUTPUT.put_line ('Org Contact Creation failed:'||l_msg_data);
   END IF;
   DBMS_OUTPUT.PUT_LINE('Org Contact Creation Complete');
END;