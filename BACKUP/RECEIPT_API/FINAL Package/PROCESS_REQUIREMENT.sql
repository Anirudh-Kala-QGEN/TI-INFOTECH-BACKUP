PROJECT REQUIRED OBJECTS
------------------------------------------ 
Receipt Process Program for NOT NULL CONS_RCPT_NO
-------------------------
Program Name 			: XXAU Composite Receipt Process - Test
Short Name	 			: XXAU_CONS_RCPT_PRC
Responsibility	 		: Receivable Manager
Executable Short Name 	: XXAU_CONS_RCPT_PRC_EXE
Executable File 		: XXAU_COMP_RCPT_CREATION_PKG.MAIN

XXAU Composite Receipt Process - Test
------------------------------------------ 
XXAU_AR_TRNSP_RCPT_ERR
CREATE TABLE APPS.XXAU_AR_TRNSP_RCPT_ERR
(
  CONC_RCPT_ID          NUMBER,
  COMPOSITE_RECEIPT_ID  NUMBER,
  STATUS                VARCHAR2(1 BYTE),
  ERROR_MESSAGE         VARCHAR2(4000 BYTE)
)

------------------------------------------
REQUIRED PACKAGE
------------------------------------------
XXAU_COMP_RCPT_CREATION_PKG.pkb / sql
XXAU_COMP_RCPT_CREATION_PKG.pks / sql
------------------------------------------

LOOKUP REQUIRED FOR VALID ACTIVITY NAME
------------------------------------------
XXAU_UNIT_CASH_CLEARING
------------------------------------------

REQUIRED VALIDATIONS
--------------------
FOR ACTIVITY NAME
------------------------------------------
BEGIN
	SELECT AR_REC_TRX_A.RECEIVABLES_TRX_ID
	FROM FND_LOOKUP_VALUES FLV
	, AR_RECEIVABLES_TRX_ALL AR_REC_TRX_A
	WHERE 1=1
	AND AR_REC_TRX_A.NAME = FLV.MEANING
	AND LOOKUP_CODE = SUBSTR(J.ATTRIBUTE11,1,3)
	AND LOOKUP_TYPE = 'XXAU_UNIT_CASH_CLEARING';
EXCEPTION 
	WHEN OTHERS 
	THEN LN_ACTIVITY:=NULL;
END;
------------------------------------------
ATTRIBUTE VALIDATIONS
------------------------------------------
Check Type 												- ATTRIBUTE2 				- XXAU_CHECK_LOCAL
Cheque Date 											- ATTRIBUTE10
Customer Bank 											- ATTRIBUTE11
Bank Branch 											- ATTRIBUTE12
Display In Deposite Slip								- ATTRIBUTE3 				- AR_SRS_YES_NO
Covering Letter 										- ATTRIBUTE4 				- AR_SRS_YES_NO
Stamped 												- ATTRIBUTE5 				- AR_SRS_YES_NO
Signed 													- ATTRIBUTE6 				- AR_SRS_YES_NO
Account Nature 				- Branch IFSC Code 			- ATTRIBUTE13 				- 20 Characters
Provisional Receipt 									- ATTRIBUTE14 				- XXA_Prov_Receipt
Provisional Receipt Date 								- ATTRIBUTE15 				- 20 Characters
Composit Receipt # Reference 							- ATTRIBUTE9 				- 20 Characters
Bank Name 												- Attribute7 				- XXA_BANK_NAME
Bank Account No 										- ATTRIBUTE8 				- XXA_BANK_ACCOUNT_NUMBER
DCR Receipt No 											- ATTRIBUTE1 				- 5 Characters

------------------------------------------
SEGMENTS
------------------------------------------
-- SEGMENT1 -> AUPL_Company -> INDEPENDENT VALUE SET
-- SEGMENT2 -> 
-- SEGMENT3 -> AUPL_Location -> INDEPENDENT VALUE SET
-- SEGMENT4 -> AUPL_Department -> INDEPENDENT VALUE SET
-- SEGMENT5 -> AUPL_Natural_Account -> INDEPENDENT VALUE SET, 207510,  509309
-- SEGMENT6 -> 
-- SEGMENT7 -> 
-- SEGMENT8 -> AUPL_Division Location -> INDEPENDENT VALUE SET
------------------------------------------