XXAU Outstanding Ledger Summary-R12-AR066 - XXAU_AR066_XXAARR007_SUMIT
------------------------------------------------------------------------------

Requirement : Need to find the NULL / Empty Columns reason and solution

------------------------------------------------------
Contains Package : XXAU_AR066_PKG.GET_DTL_PRC@EBSTOHR
Global Temporary Table : XXAU_AR066_CUST_DTL
------------------------------------------------------

Package Procedure called in BEFORE REPORT TRIGGER in RDF

OUTPUT Format : Page Layout

------------------------------------------------------------------------------
Responsibility : AUPL Corp OM User
------------------------------------------------------------------------------

CUSTOMER NUMBER / AGENCY NUMBER : 174401, 174410, 174522
-------------------------------------------------------------------------------------------------------------------------------------------------------------														 
Location1 	: LOCATION		: NULL FROM QUERY
											---------------location---------------------------------------------
										      CURSOR c_loc
											  IS
												 SELECT hza.cust_account_id, hcu.LOCATION
												   FROM hz_cust_accounts hza,
														hz_cust_acct_sites_all hcs,
														hz_cust_site_uses_all hcu
												  WHERE hza.cust_account_id = hcs.cust_account_id
													AND hcs.cust_acct_site_id = hcu.cust_acct_site_id
													AND hcu.site_use_code = 'BILL_TO'
													AND hcs.org_id = :p_org_id
													AND hcu.primary_flag = 'Y'
													AND EXISTS (SELECT 1
																  FROM XXAU_AR066_CUST_DTL@EBSTOHR xx
																 WHERE 1 = 1 AND xx.customer_id = hza.cust_account_id);

-------------------------------------------------------------------------------------------------------------------------------------------------------------														 
LAYOUT NAME | QUERY COLUMN NAME | RESULT
-----------------------------------------
Nature		: AGENCY_NATURE		: NULL FROM QUERY
										--------------- AGENCY NATURE ---------------------------------------------
										  CURSOR c_nature
										  IS
											 SELECT hza.cust_account_id, acm.au_cust_attribute2
											   FROM hz_cust_accounts hza,
													hz_cust_acct_sites_all hcs,
													hz_cust_site_uses_all hcu,
													au_customer_master_1@ebstohr acm
											  WHERE hza.cust_account_id = hcs.cust_account_id
												AND hcs.cust_acct_site_id = hcu.cust_acct_site_id
												AND hcu.site_use_code = 'BILL_TO'
												AND hcs.org_id = :p_org_id
												AND hcu.primary_flag = 'Y'
												AND hza.cust_account_id = acm.au_cust_id
												AND hcu.site_use_id = acm.au_cust_ship_to
												AND EXISTS (SELECT 1
															  FROM XXAU_AR066_CUST_DTL@EBSTOHR xx
															 WHERE 1 = 1 AND xx.customer_id = hza.cust_account_id);

-------------------------------------------------------------------------------------------------------------------------------------------------------------
LAYOUT NAME | QUERY COLUMN NAME | RESULT
-----------------------------------------
Pay term	: PAY_TERM			: NULL FROM QUERY

										-------------------PAYMENT_TERM---------------------------------------
										CURSOR c_pay_term
										  IS
											 SELECT xced.customer_id, UPPER (xced.payment_term)
											   FROM xxau_customer_executive_dtl@ebstohr xced
											  WHERE 1 = 1
												--AND customer_id =8992
												AND xced.payment_term IS NOT NULL
												AND EXISTS (SELECT 1
															  FROM XXAU_AR066_CUST_DTL@EBSTOHR xx
															 WHERE 1 = 1 AND xx.customer_id = xced.customer_id);

-------------------------------------------------------------------------------------------------------------------------------------------------------------
LAYOUT NAME | QUERY COLUMN NAME | RESULT
-----------------------------------------
District	: CF_DISTRICT		: FROM QUERY -- HZ_PARTIES
City		: CITY				: FROM QUERY -- HZ_PARTIES

------------------------------------ DISTRICT AND CITY-----------------------------
SELECT CUST_ACCT.ACCOUNT_NUMBER        AGENCY_NUM,
	   SUBSTRB (PARTY_NAME, 1, 50)     AGENCY_NAME,
	   HZ.PARTY_ID,
	   CUST_ACCT.CUST_ACCOUNT_ID,
	   HZ.CITY                         CITY,
	   CUST_ACCT.ATTRIBUTE9,
	   HZ.COUNTY                       DISTRICT
  FROM HZ_PARTIES HZ, HZ_CUST_ACCOUNTS CUST_ACCT
 WHERE     HZ.PARTY_ID = CUST_ACCT.PARTY_ID
	   AND (CUST_ACCT.CUST_ACCOUNT_ID = :P_CUST OR :P_CUST IS NULL)
	   AND (   CUST_ACCT.ATTRIBUTE_CATEGORY = :P_CUST_TYPE
			OR :P_CUST_TYPE IS NULL)
	   AND EXISTS
			   (SELECT 1
				  FROM RA_CUST_TRX_LINE_GL_DIST_ALL  GLD,
					   AR_PAYMENT_SCHEDULES_ALL      APS,
					   GL_CODE_COMBINATIONS          GCC
				 WHERE     1 = 1
					   AND APS.CUSTOMER_ID = CUST_ACCT.CUST_ACCOUNT_ID
					   AND APS.CUSTOMER_TRX_ID = GLD.CUSTOMER_TRX_ID
					   AND APS.ORG_ID = GLD.ORG_ID
					   AND GLD.CODE_COMBINATION_ID =
						   GCC.CODE_COMBINATION_ID
					   AND GLD.ACCOUNT_CLASS = 'REC'
					   AND GCC.SEGMENT1 BETWEEN NVL ( :P_UNIT_FROM,
													 GCC.SEGMENT1)
											AND NVL ( :P_UNIT_TO,
													 GCC.SEGMENT1)
					   AND APS.ORG_ID = :P_ORG_ID
					   AND APS.GL_DATE BETWEEN '01-MAR-2018' AND :P_DATE
				UNION ALL
				SELECT 1
				  FROM AR_CASH_RECEIPT_HISTORY_ALL  ACRH,
					   AR_PAYMENT_SCHEDULES_ALL     APS,
					   GL_CODE_COMBINATIONS         GCC
				 WHERE     1 = 1
					   AND APS.CUSTOMER_ID = CUST_ACCT.CUST_ACCOUNT_ID
					   AND APS.CASH_RECEIPT_ID = ACRH.CASH_RECEIPT_ID
					   --- COMMENTED BY ASHISH 27-FEB-2008
					   AND APS.ORG_ID = ACRH.ORG_ID
					   AND GCC.CODE_COMBINATION_ID =
						   ACRH.ACCOUNT_CODE_COMBINATION_ID
					   AND GCC.SEGMENT1 BETWEEN NVL ( :P_UNIT_FROM,
													 GCC.SEGMENT1)
											AND NVL ( :P_UNIT_TO,
													 GCC.SEGMENT1)
					   AND APS.ORG_ID = :P_ORG_ID
					   AND APS.GL_DATE BETWEEN '01-MAR-2018' AND :P_DATE);