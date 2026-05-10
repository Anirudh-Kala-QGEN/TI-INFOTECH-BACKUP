CREATE OR REPLACE PACKAGE APPS.XXAU_AP_INV_WITH_GST_TDS_PKG
IS

    /***************************************************************************************************
     * Global Variables : Declaration and Initialization
     ***************************************************************************************************/
    /*************************************************************************************************
     *                 Copy Rights Reserved @ Ti Infotech- 2026
     *
     * $Header: @(#)
     * Program Name : XXAU_AP_INV_WITH_GST_TDS_PKG (Spec)
     * Language     : PL/SQL
     * Description  : Process to insert the custom AP Invoice, Lines and Tax details to the Oracle ERP system.
	 *				  This package can be used for Invoice with taxes as well as for invoices with taxes.
	 *				  To Create AP Invoices without tax : CREATE_ONLY_AP_INVOICES
	 *				  To Create AP Invoices with tax 	: MAIN
     * History      :
     *
     * WHO              Version #   WHEN            WHAT
     * ===============  =========   =============   ====================================================
     * AKALA            1.0         23-APR-2026      Initial Version
	 ***************************************************************************************************/

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
	
	/*Added by AKALA on 28-APR-2026, only for invoices which contains the line. No any tax.*/
	PROCEDURE CREATE_ONLY_AP_INVOICES (ERRBUFF OUT VARCHAR2,RETCODE OUT VARCHAR2, P_BATCH_ID IN NUMBER) ;
	
	PROCEDURE MAIN (ERRBUFF OUT VARCHAR2,RETCODE OUT VARCHAR2, P_BATCH_ID IN NUMBER) ;
	
END XXAU_AP_INV_WITH_GST_TDS_PKG;
/
