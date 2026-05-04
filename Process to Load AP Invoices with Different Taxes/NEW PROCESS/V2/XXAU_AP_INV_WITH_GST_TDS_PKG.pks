CREATE OR REPLACE PACKAGE XXAU_AP_INV_WITH_GST_TDS_PKG
IS

    /***************************************************************************************************
     * Global Variables : Declaration and Initialization
     ***************************************************************************************************/
	 GN_USER_ID NUMBER := FND_PROFILE.VALUE('USER_ID');
	 GN_ORG_ID NUMBER := FND_PROFILE.VALUE('ORG_ID');
	 GN_RESP_ID NUMBER := FND_PROFILE.VALUE('RESP_ID');
	 GN_RESP_APPL_ID NUMBER := FND_PROFILE.VALUE('RESP_APPL_ID');
	 GN_CONC_REQUEST_ID NUMBER := FND_PROFILE.VALUE('CONC_REQUEST_ID');
	 GN_LOGIN_ID NUMBER := FND_PROFILE.VALUE('LOGIN_ID');
    /****************************************************************************************************/
	 
	
	PROCEDURE MIGRATE_TO_ERP (P_BATCH_ID NUMBER);
	
	PROCEDURE LOAD_DATA_TO_INTERFACE (P_BATCH_ID IN NUMBER);
	
	PROCEDURE VALIDATE_DATA (P_BATCH_ID IN NUMBER);
	
	PROCEDURE MAIN (ERRBUFF OUT VARCHAR2,RETCODE OUT VARCHAR2, P_BATCH_ID IN NUMBER) ;
	
END XXAU_AP_INV_WITH_GST_TDS_PKG;