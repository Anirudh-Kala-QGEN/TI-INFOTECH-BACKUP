DECLARE
   L_LOCATION_REC     HZ_LOCATION_V2PUB.LOCATION_REC_TYPE;
   L_LOCATION_ID      NUMBER;
   L_RETURN_STATUS    VARCHAR2(100);
   L_MSG_COUNT        NUMBER;
   L_MSG_DATA         VARCHAR2(2000);
BEGIN
   DBMS_OUTPUT.ENABLE (BUFFER_SIZE => NULL);
   --INITIATE THE EBS ENVIRONMENT FOR API PROCESSING
   FND_GLOBAL.APPS_INITIALIZE(2482, 20678, 222);
   MO_GLOBAL.INIT('AR');
   FND_CLIENT_INFO.SET_ORG_CONTEXT(81);
   --POPULATING LOCATION RECORD
   L_LOCATION_REC.ADDRESS1          := '123 subway'; 				-- Required Parameter
   L_LOCATION_REC.ADDRESS2          := null; --'Enodeas Building';	--we Can pass null value
   L_LOCATION_REC.CITY              := null; --'New York';			--we Can pass null value
   L_LOCATION_REC.POSTAL_CODE       := null; --'10010';				--we Can pass null value
   L_LOCATION_REC.STATE             := null; --'NY';				--we Can pass null value
   L_LOCATION_REC.COUNTRY           := 'US'; 						-- Required Parameter
   L_LOCATION_REC.CREATED_BY_MODULE := 'BO_API';					-- Required Parameter
   --Calling hz_location_v2pub.create_location
   DBMS_OUTPUT.PUT_LINE('Calling hz_location_v2pub.create_location api');
   OE_MSG_PUB.INITIALIZE;
   HZ_LOCATION_V2PUB.CREATE_LOCATION
             (
			  P_INIT_MSG_LIST => FND_API.G_TRUE,
              P_LOCATION_REC  => L_LOCATION_REC,
              X_LOCATION_ID   => L_LOCATION_ID,
			  X_RETURN_STATUS => L_RETURN_STATUS,
              X_MSG_COUNT     => L_MSG_COUNT,
              X_MSG_DATA      => L_MSG_DATA
             );
   
   DBMS_OUTPUT.put_line ('Location Creation failed before everything:'||l_msg_data);
   IF l_return_status = 'S' 
   THEN
      COMMIT;
      DBMS_OUTPUT.PUT_LINE('Location Creation is Successful '); 
	  DBMS_OUTPUT.PUT_LINE('Location Id = '||l_location_id); 
   ELSE
      ROLLBACK;
      FOR i IN 1 .. l_msg_count
      LOOP
         l_msg_data := oe_msg_pub.get( p_msg_index => i, p_encoded => 'F');
         dbms_output.put_line( i|| ') '|| l_msg_data);
      END LOOP;
      DBMS_OUTPUT.put_line ('Location Creation failed after error loop:'||l_msg_data);
   END IF;
   DBMS_OUTPUT.PUT_LINE('Location Creation Complete');
END;