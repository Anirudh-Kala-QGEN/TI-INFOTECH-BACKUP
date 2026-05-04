DECLARE
   L_CONTACT_POINT_REC    HZ_CONTACT_POINT_V2PUB.CONTACT_POINT_REC_TYPE;
   L_EDI_REC              HZ_CONTACT_POINT_V2PUB.EDI_REC_TYPE;
   L_EMAIL_REC            HZ_CONTACT_POINT_V2PUB.EMAIL_REC_TYPE;
   L_PHONE_REC            HZ_CONTACT_POINT_V2PUB.PHONE_REC_TYPE;
   L_TELEX_REC            HZ_CONTACT_POINT_V2PUB.TELEX_REC_TYPE;
   L_WEB_REC              HZ_CONTACT_POINT_V2PUB.WEB_REC_TYPE;
   L_CONTACT_POINT_ID     HZ_CONTACT_POINTS.CONTACT_POINT_ID%TYPE;
   L_RETURN_STATUS        VARCHAR2(100);
   L_MSG_COUNT            NUMBER;
   L_MSG_DATA             VARCHAR2(2000);
BEGIN
   DBMS_OUTPUT.ENABLE (BUFFER_SIZE => NULL);
   --INITIATE THE EBS ENVIRONMENT FOR API PROCESSING
   FND_GLOBAL.APPS_INITIALIZE(1516, 20678, 222);
   MO_GLOBAL.INIT('AR');
   FND_CLIENT_INFO.SET_ORG_CONTEXT(81);
   -- INITIALIZING THE MANDATORY API PARAMETERS
   --CONTACT RECORD
   L_CONTACT_POINT_REC.CONTACT_POINT_TYPE    := 'PHONE';
   L_CONTACT_POINT_REC.OWNER_TABLE_NAME      := 'HZ_PARTIES';
   L_CONTACT_POINT_REC.OWNER_TABLE_ID        := 18041584;
   L_CONTACT_POINT_REC.PRIMARY_FLAG          := 'Y';
   L_CONTACT_POINT_REC.CONTACT_POINT_PURPOSE := 'BUSINESS';
   L_CONTACT_POINT_REC.CREATED_BY_MODULE     := 'BO_API';
   --PHONE RECORD
   L_PHONE_REC.PHONE_COUNTRY_CODE            := '1';
   L_PHONE_REC.PHONE_NUMBER                  := '856-784-521';
   L_PHONE_REC.PHONE_LINE_TYPE               := 'MOBILE';
   --Calling hz_contact_point_v2pub.create_contact_point
   DBMS_OUTPUT.PUT_LINE('Calling hz_contact_point_v2pub.create_contact_point api');
   HZ_CONTACT_POINT_V2PUB.CREATE_CONTACT_POINT
             (
               P_INIT_MSG_LIST      => FND_API.G_TRUE,
               P_CONTACT_POINT_REC  => L_CONTACT_POINT_REC,
               P_EDI_REC            => L_EDI_REC,
               P_EMAIL_REC          => L_EMAIL_REC,
               P_PHONE_REC          => L_PHONE_REC,
               P_TELEX_REC          => L_TELEX_REC,
               P_WEB_REC            => L_WEB_REC,
               X_CONTACT_POINT_ID   => L_CONTACT_POINT_ID,
               X_RETURN_STATUS      => L_RETURN_STATUS,
               X_MSG_COUNT          => L_MSG_COUNT,
               X_MSG_DATA           => L_MSG_DATA
              );
IF L_RETURN_STATUS = 'S' 
   THEN
        DBMS_OUTPUT.PUT_LINE('Contact Point Creation is Successful '); 
	    DBMS_OUTPUT.PUT_LINE('contact_point_id = '||L_CONTACT_POINT_ID); 
        COMMIT;
   ELSE
	    DBMS_OUTPUT.PUT_LINE ('Contact Point Creation failed:'||L_MSG_DATA);
      FOR i IN 1 .. L_MSG_COUNT
      LOOP
         L_MSG_DATA := FND_MSG_PUB.GET( P_MSG_INDEX => I, P_ENCODED => 'F');
         DBMS_OUTPUT.PUT_LINE( I|| ') '|| L_MSG_DATA);
      END LOOP;
      DBMS_OUTPUT.put_line ('Contact Point Creation failed:'||L_MSG_DATA);
      ROLLBACK;
   END IF;
   DBMS_OUTPUT.PUT_LINE('Contact Point Creation Complete');
END;