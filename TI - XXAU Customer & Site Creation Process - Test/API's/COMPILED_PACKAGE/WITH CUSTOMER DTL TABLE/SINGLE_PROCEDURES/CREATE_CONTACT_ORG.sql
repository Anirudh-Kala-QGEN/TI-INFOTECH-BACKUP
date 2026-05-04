PROCEDURE CREATE_CONTACT_ORG ( 	P_PARTY_ID IN NUMBER
							, P_CONTACT_PERSON IN VARCHAR2
							, P_MSG OUT VARCHAR2)
AS
    LV_ORG_CONTACT_REC          HZ_PARTY_CONTACT_V2PUB.ORG_CONTACT_REC_TYPE;
	LV_PERSON_REC               HZ_PARTY_V2PUB.PERSON_REC_TYPE;
	LV1_PARTY_ID				NUMBER;
	LV1_PARTY_NUMBER			VARCHAR2(1000);
	LV2_PARTY_NUMBER			VARCHAR2(1000);
	LV1_PROFILE_ID				NUMBER;
	X_RETURN_STATUS				VARCHAR2(100);
	X_MSG_COUNT					NUMBER;
	X_MSG_DATA					VARCHAR2(100);
	X_PARTY_ID					NUMBER;
	LV2_ORG_CONTACT_ID			NUMBER;
	LV_API_MESSAGE				VARCHAR2(4000);
BEGIN
	FND_FILE.PUT_LINE(FND_FILE.LOG, 'enter contact person creation');
	LV2_ORG_CONTACT_ID := 0;
	FND_FILE.PUT_LINE(FND_FILE.LOG, 'lv2_org_contact_id' || LV2_ORG_CONTACT_ID);

			LV_PERSON_REC.PERSON_FIRST_NAME := P_CONTACT_PERSON; --CREATE_CUSTOMER_REC.CONTACT_PERSON;
			LV_PERSON_REC.PERSON_LAST_NAME := '1';
			LV_PERSON_REC.PARTY_REC.STATUS := 'A';
			LV_PERSON_REC.CREATED_BY_MODULE := 'BO_API';
	  --
			HZ_PARTY_V2PUB.CREATE_PERSON(
				P_INIT_MSG_LIST => APPS.FND_API.G_FALSE,
				P_PERSON_REC    => LV_PERSON_REC,
				X_PARTY_ID      => LV1_PARTY_ID,
				X_PARTY_NUMBER  => LV1_PARTY_NUMBER,
				X_PROFILE_ID    => LV1_PROFILE_ID,
				X_RETURN_STATUS => X_RETURN_STATUS,
				X_MSG_COUNT     => X_MSG_COUNT,
				X_MSG_DATA      => X_MSG_DATA
			);

	  --
	  --Capturing error if not success
	  --
			IF X_RETURN_STATUS <> APPS.FND_API.G_RET_STS_SUCCESS THEN
				FOR I IN 1..FND_MSG_PUB.COUNT_MSG LOOP
					FND_MSG_PUB.GET(
						P_MSG_INDEX     => I,
						P_ENCODED       => APPS.FND_API.G_FALSE,
						P_DATA          => X_MSG_DATA,
						P_MSG_INDEX_OUT => LV_MSG_INDEX_OUT
					);

					LV_API_MESSAGE := LV_API_MESSAGE|| ' ~ '|| X_MSG_DATA;
					FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error: ' || LV_API_MESSAGE);
				END LOOP;
				P_MSG:= LV_API_MESSAGE;
			ELSIF ( x_return_status = apps.fnd_api.g_ret_sts_success ) THEN
				fnd_file.put_line(fnd_file.log, '***************************');
				fnd_file.put_line(fnd_file.log, 'Output information ....');
				fnd_file.put_line(fnd_file.log, 'Success');
				fnd_file.put_line(fnd_file.log, 'contact person id : ' || LV1_PARTY_ID);
				fnd_file.put_line(fnd_file.log, '***************************');
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
		LV_ORG_CONTACT_REC.CREATED_BY_MODULE := 'TCA_V1_API';
		HZ_PARTY_CONTACT_V2PUB.CREATE_ORG_CONTACT(
			P_INIT_MSG_LIST   => FND_API.G_TRUE,
			P_ORG_CONTACT_REC => LV_ORG_CONTACT_REC,
			X_ORG_CONTACT_ID  => LV2_ORG_CONTACT_ID,
			X_PARTY_REL_ID    => LV2_PARTY_REL_ID,
			X_PARTY_ID        => LV2_PARTY_ID,
			X_PARTY_NUMBER    => LV2_PARTY_NUMBER,
			X_RETURN_STATUS   => X_RETURN_STATUS,
			X_MSG_COUNT       => X_MSG_COUNT,
			X_MSG_DATA        => X_MSG_DATA
		);

		IF X_RETURN_STATUS <> FND_API.G_RET_STS_SUCCESS THEN
		LV_API_MESSAGE:= NULL;
			FOR I IN 1..FND_MSG_PUB.COUNT_MSG LOOP
				FND_MSG_PUB.GET(
					P_MSG_INDEX     => I,
					P_ENCODED       => FND_API.G_FALSE,
					P_DATA          => X_MSG_DATA,
					P_MSG_INDEX_OUT => LV_MSG_INDEX_OUT
				);

				LV_API_MESSAGE := LV_API_MESSAGE|| ' ~ '|| X_MSG_DATA;
			END LOOP;
			P_MSG:= P_MSG||';'||LV_API_MESSAGE;
			fnd_file.put_line(fnd_file.log, 'Error: ' || lv_api_message);
		ELSIF ( x_return_status = fnd_api.g_ret_sts_success ) THEN
			fnd_file.put_line(fnd_file.log, '***************************');
			fnd_file.put_line(fnd_file.log, 'Output information ....');
			fnd_file.put_line(fnd_file.log, 'Success');
			fnd_file.put_line(fnd_file.log, 'lv_org_contact_id: ' || lv2_org_contact_id);
			fnd_file.put_line(fnd_file.log, 'lv_party_id: ' || lv2_party_id);
			fnd_file.put_line(fnd_file.log, 'lv_party_rel_id: ' || lv2_party_rel_id);
			fnd_file.put_line(fnd_file.log, '***************************');
			COMMIT;
		END IF;
EXCEPTION
WHEN OTHERS THEN
	FND_FILE.PUT_LINE(FND_FILE.LOG,SQLCODE||'-'||SQLERRM);
END;