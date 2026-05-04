CREATE OR REPLACE PROCEDURE APPS.LPTI_TA_UPLOAD_REM IS
p_invoice_id VARCHAR2(25);
P_VCH_TYPE VARCHAR2(25) :='ALL';
cPaygroup  VARCHAR2(100);
J NUMBER :=1;
CURSOR C1 IS SELECT DISTINCT INVOICE_DATE,GL_DATE,INVOICE_TYPE,VENDOR_NUM,SEGMENT2,INVOICE_CURRENCY_CODE,SUM(INVOICE_AMOUNT)INVOICE_AMOUNT FROM UPLOAD_REIMBURSEMENT@TAPROD_DBLINK
WHERE SEGMENT2 NOT IN ('30350','30950')
GROUP BY INVOICE_DATE,GL_DATE,INVOICE_TYPE,VENDOR_NUM,SEGMENT2,INVOICE_CURRENCY_CODE;
BEGIN
 FOR i in c1 loop
 -----FIND PAY GROUP OF VENDOR
/*	BEGIN
	SELECT PAY_GROUP_LOOKUP_CODE INTO cPaygroup FROM po_vendors WHERE
	     SEGMENT1 = 'V'||'-'||'R01071';
        EXCEPTION
	WHEN OTHERS THEN
	  cPaygroup := NULL;
	END;
	-----FIND PAY GROUP OF VENDOR*/
 select LPTI_AP_TA_INVOICES_S.nextval into p_invoice_id from dual;
 insert into ap_invoices_interface
    (invoice_id,
     INVOICE_DATE,
      GL_DATE,
     TERMS_NAME,
     invoice_type_lookup_code,
     vendor_NUM,
     vendor_site_CODE,
     ACCTS_PAY_CODE_COMBINATION_ID,
     invoice_amount,
     invoice_currency_code,
     source,
     group_id,
     ORG_ID,
     INVOICE_NUM)
VALUES
    ( p_invoice_id,
      TRUNC(I.INVOICE_DATE),
      TRUNC(I.GL_DATE),
     'IMMEDIATE',
      'STANDARD',
     'V-R01071',
     'HO',
     NULL,
     I.INVOICE_AMOUNT,
     'INR',
     'LPTI_TA_INV',
     'LPTI_TA_INV' ,
     '0',
     'REIM-FEB-'||J);
/* INSERT AP INVOICE LINES DISTRIBUTIONS */
DECLARE
 K NUMBER :=1;
CURSOR C2 IS SELECT * FROM UPLOAD_REIMBURSEMENT@TAPROD_DBLINK
WHERE SEGMENT2=I.SEGMENT2;
BEGIN
 FOR J IN C2 LOOP
  INSERT into ap_invoice_lines_interface
      ( invoice_id,
         invoice_line_id,
        line_number,
      line_type_lookup_code,
      amount,
       DIST_CODE_CONCATENATED,
      DESCRIPTION)
      VALUES
      (  p_invoice_id,
         LPTI_AP_OPEN_INVOICES_LINE_S.nextval,
         K,
        'ITEM',
         J.invoice_amount,
         J.SEGMENT1||'.'||J.SEGMENT2||'.'||J.SEGMENT3||'.'||'000000'||'.'||'00000'||'.'||'00000000'||'.'||'00000'||'.'||'000',
        J.ADDL_FIELD1);
--INSERT INTO LPTI_AP_TRF_INVOICES VALUES(I.BILL_NO,cVENDOR_TYPE||'-'||I.SUPP_CODE,I.BILL_VOUCHER_NO,I.VCH_TYP_CODE);
 		 commit;
 K:=K+1;
END LOOP;
END;
 COMMIT;
 J:=J+1;
end loop;
END;
/
