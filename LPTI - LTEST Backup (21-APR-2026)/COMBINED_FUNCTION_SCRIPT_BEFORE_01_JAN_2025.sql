CREATE OR REPLACE FUNCTION "APPS"."CPGR_CHECK_PENDING_UPDATES" (
		cust_num VARCHAR2)
	RETURN NUMBER AUTHID CURRENT_USER AS
/* $Header: ARTAESDY.pls 115.3 2000/07/10 16:18:52 pkm ship      $ */
	BEGIN
		RETURN (0);
END cpgr_check_pending_updates;

/

CREATE OR REPLACE FUNCTION "APPS"."CPGR_CRED_SYNCH_FUNC" (
                		cust_num VARCHAR2,
                		orgid NUMBER,
                		sobi NUMBER)
        		RETURN NUMBER AUTHID CURRENT_USER AS
/* $Header: ARTAESDY.pls 115.3 2000/07/10 16:18:52 pkm ship      $ */
	BEGIN
             RETURN 0;
       	END cpgr_cred_synch_func;

/

CREATE OR REPLACE FUNCTION "APPS"."GET_COMPNO" (
               Set_of_books_id NUMBER,
               in_stallid VARCHAR2)
             RETURN NUMBER AUTHID CURRENT_USER IS
/* $Header: ARTAESDY.pls 115.3 2000/07/10 16:18:52 pkm ship      $ */
   BEGIN
      RETURN (0);
END get_compno;

/

CREATE OR REPLACE FUNCTION "APPS"."GET_CONTACT_POINT_COUNT" 
				   ( P_PHONE_NUMBER_S1 IN VARCHAR2
				   , P_PHONE_NUMBER_S2 IN VARCHAR2
				   , P_PHONE_NUMBER_S3 IN VARCHAR2
				   , P_PHONE_NUMBER_S4 IN VARCHAR2
				   , P_PHONE_NUMBER_S5 IN VARCHAR2
				   , P_PHONE_NUMBER_S6 IN VARCHAR2
				   )
				RETURN NUMBER
				IS
				   l_num_contact_points NUMBER(5);
				BEGIN

				   	l_num_contact_points := 0;

					IF P_PHONE_NUMBER_S1 IS NOT NULL THEN
						l_num_contact_points := l_num_contact_points + 1;
					END IF;

					IF P_PHONE_NUMBER_S2 IS NOT NULL THEN
						l_num_contact_points := l_num_contact_points + 1;
					END IF;

					IF P_PHONE_NUMBER_S3 IS NOT NULL THEN
						l_num_contact_points := l_num_contact_points + 1;
					END IF;

					IF P_PHONE_NUMBER_S4 IS NOT NULL THEN
						l_num_contact_points := l_num_contact_points + 1;
					END IF;

					IF P_PHONE_NUMBER_S5 IS NOT NULL THEN
						l_num_contact_points := l_num_contact_points + 1;
					END IF;

					IF P_PHONE_NUMBER_S6 IS NOT NULL THEN
						l_num_contact_points := l_num_contact_points + 1;
					END IF;

				RETURN l_num_contact_points;

				END Get_Contact_Point_Count;
/

CREATE OR REPLACE FUNCTION "APPS"."GET_INVALID_CP_COUNT" 
				   ( P_PHONE_NUMBER_S1 	IN VARCHAR2
				   , P_REASON_CODE_S1	IN VARCHAR2
				   , P_PHONE_NUMBER_S2 	IN VARCHAR2
				   , P_REASON_CODE_S2	IN VARCHAR2
				   , P_PHONE_NUMBER_S3 	IN VARCHAR2
				   , P_REASON_CODE_S3	IN VARCHAR2
				   , P_PHONE_NUMBER_S4 	IN VARCHAR2
				   , P_REASON_CODE_S4	IN VARCHAR2
				   , P_PHONE_NUMBER_S5 	IN VARCHAR2
				   , P_REASON_CODE_S5	IN VARCHAR2
				   , P_PHONE_NUMBER_S6 	IN VARCHAR2
				   , P_REASON_CODE_S6	IN VARCHAR2
				   )
				RETURN NUMBER
				IS
				   l_num_invalid_cps NUMBER(5);
				BEGIN

				   	l_num_invalid_cps := 0;

					IF  (P_PHONE_NUMBER_S1 IS NOT NULL AND P_REASON_CODE_S1 IS NULL) THEN
						l_num_invalid_cps := l_num_invalid_cps + 1;
					END IF;

					IF  (P_PHONE_NUMBER_S2 IS NOT NULL AND P_REASON_CODE_S2 IS NULL) THEN
						l_num_invalid_cps := l_num_invalid_cps + 1;
					END IF;

					IF  (P_PHONE_NUMBER_S3 IS NOT NULL AND P_REASON_CODE_S3 IS NULL) THEN
						l_num_invalid_cps := l_num_invalid_cps + 1;
					END IF;

					IF  (P_PHONE_NUMBER_S4 IS NOT NULL AND P_REASON_CODE_S4 IS NULL) THEN
						l_num_invalid_cps := l_num_invalid_cps + 1;
					END IF;

					IF  (P_PHONE_NUMBER_S5 IS NOT NULL AND P_REASON_CODE_S5 IS NULL) THEN
						l_num_invalid_cps := l_num_invalid_cps + 1;
					END IF;

					IF  (P_PHONE_NUMBER_S6 IS NOT NULL AND P_REASON_CODE_S6 IS NULL) THEN
						l_num_invalid_cps := l_num_invalid_cps + 1;
					END IF;

				RETURN l_num_invalid_cps;

				END Get_Invalid_CP_Count;
/

CREATE OR REPLACE FUNCTION "APPS"."GET_LEDGER_DESCRIPTION" (account_id IN NUMBER) return varchar2
is 


v_column_name      Varchar2(30);
v_column_value     Varchar2(30);
v_flex_id          Number;
v_description      Varchar2(100);
P_CHART_OF_ACCOUNTS_ID number;
 p_column_value      VARCHAR2(50);


Cursor get_app_column_name IS
Select distinct application_column_name
From fnd_segment_attribute_values
Where application_id = 101
AND id_flex_code = 'GL#'
AND id_flex_num = P_CHART_OF_ACCOUNTS_ID
AND segment_attribute_type = 'GL_ACCOUNT'
AND attribute_value = 'Y';

Cursor flex_val_set_id(v_column_name Varchar2) IS
Select a.flex_value_set_id
From fnd_id_flex_segments A
Where a.application_column_name = v_column_name 
AND a.application_id = 101
AND a.id_flex_code = 'GL#'
AND a.id_flex_num = P_CHART_OF_ACCOUNTS_ID;



Cursor get_description IS
Select substr(description,1,15) 
From fnd_flex_values_vl
Where flex_value_set_id = v_flex_id
AND flex_value = v_column_value;
begin


--return(to_char(:account_id));

begin
select CHART_OF_ACCOUNTS_ID 
into P_CHART_OF_ACCOUNTS_ID
from gl_sets_of_books
where set_of_books_id=fnd_profile.value('GL_SET_OF_BKS_ID');
EXCEPTION WHEN OTHERS THEN
P_CHART_OF_ACCOUNTS_ID:=0; 
end;


 OPEN get_app_column_name;
 FETCH get_app_column_name INTO v_column_name;
 CLOSE get_app_column_name;

IF v_column_name IS NULL THEN
v_column_name := 'SEGMENT2';
END IF;

 OPEN flex_val_set_id(v_column_name);
 FETCH flex_val_set_id INTO v_flex_id;
 CLOSE flex_val_set_id;

   begin
   select segment2 
   into p_column_value 
   from gl_code_combinations 
   where chart_of_accounts_id = P_CHART_OF_ACCOUNTS_ID AND code_combination_id = account_id;
   exception when others then 
   p_column_value:=null;
   end; 



 v_column_value := p_column_value;

 OPEN get_description;
 FETCH get_description INTO v_description;
 CLOSE get_description;

 RETURN(v_description);



end;

/

CREATE OR REPLACE FUNCTION "APPS"."GET_TRANSLATED_DNU_REASON" (P_DNU_REASON_CODE IN VARCHAR2)
				RETURN VARCHAR2
				IS
					l_dnu_reason VARCHAR2(500);
				BEGIN

				SELECT DESCRIPTION
				INTO l_dnu_reason
				FROM  FND_LOOKUPS
				WHERE LOOKUP_TYPE 	= 'IEC_DNU_REASON'
		  		AND  LOOKUP_CODE	= P_DNU_REASON_CODE;

				RETURN l_dnu_reason;

				END Get_Translated_DNU_Reason;
/

CREATE OR REPLACE FUNCTION "APPS"."IEC_CLEANDIVISOR" (p_divisor IN NUMBER)
                  RETURN NUMBER
               IS
                  l_clean_divisor     NUMBER;
               BEGIN
                  -- If divisor is 0, then return null
                  IF p_divisor <> 0 THEN
                     l_clean_divisor := p_divisor;
                  END IF;
                  RETURN l_clean_divisor;
               END;
/

CREATE OR REPLACE FUNCTION "APPS"."IEC_GETLOCATIONHEIRARCHY" (p_loc_id IN NUMBER)
                  RETURN VARCHAR2
               IS
                  l_loc_name          VARCHAR2(500);
                  l_loc_type          VARCHAR2(500);
                  l_loc_id            NUMBER(15);
                  l_parent_loc_id     NUMBER(15);

                  l_heirarchy_str     VARCHAR2(4000);
               BEGIN

                  -- Get name for location of leaf node
                  SELECT LOCATION_AREA_NAME, PARENT_LOCATION_AREA_ID
                  INTO l_loc_name, l_parent_loc_id
                  FROM JTF_LOC_AREAS_VL
                  WHERE LOCATION_AREA_ID = p_loc_id;

                  l_heirarchy_str := l_loc_name;
                  l_loc_id := l_parent_loc_id;

                  WHILE l_loc_id IS NOT NULL LOOP
                     SELECT LOCATION_AREA_NAME, LOCATION_TYPE_CODE, PARENT_LOCATION_AREA_ID
                     INTO l_loc_name, l_loc_type, l_parent_loc_id
                     FROM JTF_LOC_AREAS_VL
                     WHERE LOCATION_AREA_ID = l_loc_id;

                     l_heirarchy_str := l_loc_name || '/' || l_heirarchy_str;
                     l_loc_id := l_parent_loc_id;

                     EXIT WHEN L_loc_type = 'AREA1';

                  END LOOP;
                  RETURN l_heirarchy_str;
               END;
/

CREATE OR REPLACE FUNCTION "APPS"."IEC_GETPHONECOUNTRYCODEDISPLAY" (p_phone_country_code IN NUMBER)
                  RETURN VARCHAR2
               IS
                  l_display_str     VARCHAR2(4000);
                  l_country_col     SYSTEM.varchar_tbl_type;
               BEGIN

                  IF p_phone_country_code = 1 THEN

                     SELECT TERRITORY_SHORT_NAME
                     BULK COLLECT INTO l_country_col
                     FROM FND_TERRITORIES_VL
                     WHERE TERRITORY_CODE IN ('US', 'CA')
                     ORDER BY TERRITORY_SHORT_NAME;

                     l_display_str :=   '1 - (North American Numbering Plan - '
                                      || l_country_col(1)
                                      || ', ' || l_country_col(2) || ')';
                     RETURN l_display_str;
                  END IF;

                  SELECT TERRITORY_SHORT_NAME
                  BULK COLLECT INTO l_country_col
                  FROM FND_TERRITORIES_VL A, HZ_PHONE_COUNTRY_CODES B
                  WHERE A.TERRITORY_CODE = B.TERRITORY_CODE
                  AND B.PHONE_COUNTRY_CODE = p_phone_country_code
                  ORDER BY TERRITORY_SHORT_NAME;

                  l_display_str := p_phone_country_code;
                  IF l_country_col IS NOT NULL AND l_country_col.COUNT > 0 THEN
                     l_display_str := l_display_str || ' - (' || l_country_col(1);
                     FOR i IN 2..l_country_col.LAST LOOP
                        l_display_str := l_display_str || ', ' || l_country_col(i);
                     END LOOP;
                     l_display_str := l_display_str || ')';
                  END IF;

                  RETURN l_display_str;
               END;
/

CREATE OR REPLACE FUNCTION "APPS"."IEC_GETPREDICTEDEXHAUSTION" 
                                          ( p_rec_remain              IN NUMBER
                                          , p_rec_called_removed      IN NUMBER
                                          , p_start_time              IN DATE
                                          , p_sysdate                 IN DATE)
                  RETURN DATE
               IS
                  l_pred_exhaust DATE;
               BEGIN
                  BEGIN
                     IF p_start_time IS NOT NULL AND ((p_sysdate - p_start_time) > (8/24)) THEN

                        l_pred_exhaust := p_sysdate + (p_rec_remain * (1 / (p_rec_called_removed / Iec_CleanDivisor(p_sysdate - p_start_time))));

                     ELSE
                        -- not enough data to compute predicted exhaustion
                        l_pred_exhaust := NULL;
                     END IF;
                  EXCEPTION
                     WHEN OTHERS THEN
                        l_pred_exhaust := NULL;
                  END;
                  RETURN l_pred_exhaust;
               END;
/

CREATE OR REPLACE FUNCTION "APPS"."IEC_GET_TRANSLATED_FND_LOOKUP" 
				   ( P_LOOKUP_CODE IN VARCHAR2
				   , P_LOOKUP_TYPE IN VARCHAR2
				   , P_LANGUAGE IN VARCHAR2
				   )
				RETURN VARCHAR2
				IS
					l_translated_string VARCHAR2(500);
				BEGIN

				SELECT MEANING
				INTO l_translated_string
				FROM  FND_LOOKUP_VALUES
				WHERE LOOKUP_CODE	= P_LOOKUP_CODE
		  		AND  LOOKUP_TYPE 	= P_LOOKUP_TYPE
		  		AND  LANGUAGE		= P_LANGUAGE
				AND  ROWNUM 		= 1;

				RETURN l_translated_string;

				END iec_get_translated_fnd_lookup;
/

CREATE OR REPLACE FUNCTION "APPS"."INV_RCM_AMT" (p_invoice_id number) return number is
v_rcm_amount number;
begin
begin
select
SUM(nvl(b.amount,0)) into v_rcm_amount
from  
ap_invoices_all ap,
ap_invoice_distributions_all b,
po_vendors c,
gl_code_combinations gcc
where ap.invoice_id=b.invoice_id
and ap.vendor_id=c.vendor_id
and b.dist_code_combination_id=gcc.code_combination_id
and GCC.SEGMENT2 in ('11936','11935','11937')
and ap.invoice_id=p_invoice_id
and ap.CANCELLED_DATE is null;
exception when others then 
v_rcm_amount:=0;
end;
return (v_rcm_amount);
end;
/

CREATE OR REPLACE FUNCTION "APPS"."INV_RCM_CODE" (p_invoice_id number) return varchar2 is
v_rcm_code varchar2(10);
begin
begin
select
DISTINCT gcc.segment2 into v_rcm_code
from  
ap_invoices_all ap,
ap_invoice_distributions_all b,
po_vendors c,
gl_code_combinations gcc
where ap.invoice_id=b.invoice_id
and ap.vendor_id=c.vendor_id
and b.dist_code_combination_id=gcc.code_combination_id
and GCC.SEGMENT2 in ('11936','11935','11937')
and ap.invoice_id=p_invoice_id
and ap.CANCELLED_DATE is null;
exception when others then 
v_rcm_code:='N/A';
end;
return (v_rcm_code);
end;
/

CREATE OR REPLACE FUNCTION "APPS"."JA_CURR_CONV" (c_set_of_books_id In Number,
                              c_from_currency_code In varchar2,
                              c_conversion_date in date,
                              c_conversion_type in varchar2,
                              c_conversion_rate in number) return number is
  v_func_curr varchar2(15);
  ret_value number;

  Cursor currency_code_cur IS
  Select currency_code from gl_sets_of_books
  where set_of_books_id = c_set_of_books_id;

Begin
/* $Header: ja_in_curr_conv_f.sql 115.2.6107.1 2007/02/08 16:04:08 rallamse noship $ */

  Open  currency_code_cur;
  Fetch currency_code_cur Into v_func_curr;
  Close currency_code_cur;

  If NVL(v_func_curr,'NO') = c_from_currency_code Then

    ret_value := 1;

  Elsif upper(c_conversion_type) = 'USER' Then

    ret_value := c_conversion_rate;

  Else

    Declare

     v_frm_curr Varchar2(10) := c_from_currency_code ; -- added by Subbu, Sri on 02-NOV-2000

     v_dr_type Varchar2(20);                          -- added by Subbu, Sri on 02-NOV-2000

  -- Cursor for checking currency whether derived from Euro Derived / Euro Currency or not
  -- added by Subbu, Sri on 02-NOV-2000

     CURSOR Chk_Derived_Type_Cur IS SELECT Derive_type FROM Fnd_Currencies
                                    WHERE Currency_Code in (v_frm_curr);
    Begin

      OPEN Chk_Derived_Type_Cur;
        FETCH Chk_Derived_Type_Cur INTO v_dr_type;
      CLOSE Chk_Derived_Type_Cur;

     IF v_dr_type IS NULL THEN

 -- If currency is not derived from Euro derived / Euro Currency  by Subbu, Sri on 02-NOV-2000

      SELECT Conversion_Rate INTO ret_value FROM Gl_Daily_Rates
      WHERE To_Currency = v_func_curr and
            From_Currency = v_frm_curr and
            trunc(Conversion_Date) = trunc(nvl(c_conversion_date,sysdate)) and
            Conversion_Type = c_conversion_type;
     ELSE

       IF v_dr_type in('EMU','EURO') THEN

 -- If currency is derived from Euro derived / Euro Currency  by Subbu, Sri on 02-NOV-2000

        v_frm_curr := 'EUR';

      SELECT Conversion_Rate INTO ret_value FROM Gl_Daily_Rates
      WHERE To_Currency = v_func_curr and
            From_Currency = v_frm_curr and
            trunc(Conversion_Date) = trunc(nvl(c_conversion_date,sysdate)) and
            Conversion_Type = c_conversion_type;

       END IF;

     END IF;

    Exception When Others Then
--old code      ret_value := 1;
	RAISE_APPLICATION_ERROR(-20120,'Currency Conversion Rate Not Defined In The System');
    End;
  End If;
  Return(nvl(ret_value,1));
End;
/

CREATE OR REPLACE FUNCTION "APPS"."LPTI_AR_CUST_BAL_INBD" (p_as_on_date DATE) return number is
nAMOUNT number(22,5);
begin
IF  p_as_on_date IS NULL THEN
 nAMOUNT:=0;
ELSE
begin
SELECT
SUM(INR_AMOUNT) +
SUM(UNAPPLIED_INR) INTO NAMOUNT
FROM(
  SELECT
  SUM(DECODE(TYPE,'UR',0,'OA',0,(acctd_amount))) INR_AMOUNT,
  SUM(DECODE(TYPE,'UR',(ACCTD_AMOUNT),'OA',(ACCTD_AMOUNT),0)) UNAPPLIED_INR
   FROM LPTI_AR_TRX_BAL_V_NEW V
  WHERE GL_DATE <= p_as_on_date
  AND CUSTOMER_ID IN (SELECT ID FROM LPTI_VENDOR_VW@TAPROD_DBLINK WHERE TYPE = 'A' AND CATEGORY <> 'Outbound Agent')
  GROUP BY CUSTOMER_ID,TRX_DATE,TRX_NUMBER,currency_code
  HAVING SUM(ACCTD_AMOUNT) <>0 );
EXCEPTION
 WHEN NO_DATA_FOUND THEN
  nAMOUNT:=0;
 WHEN OTHERS THEN
  nAMOUNT:=0;
end;
END IF;
return(nAMOUNT);
end;
/

CREATE OR REPLACE FUNCTION "APPS"."LPTI_AR_CUST_BAL_OBT" (p_as_on_date DATE) return number is
nAMOUNT number(22,5);
begin
IF  p_as_on_date IS NULL THEN
 nAMOUNT:=0;
ELSE
begin
SELECT
SUM(INR_AMOUNT) +
SUM(UNAPPLIED_INR) INTO NAMOUNT
FROM(
  SELECT
  SUM(DECODE(TYPE,'UR',0,'OA',0,(acctd_amount))) INR_AMOUNT,
  SUM(DECODE(TYPE,'UR',(ACCTD_AMOUNT),'OA',(ACCTD_AMOUNT),0)) UNAPPLIED_INR
   FROM LPTI_AR_TRX_BAL_V_NEW V
  WHERE GL_DATE <= p_as_on_date
  AND CUSTOMER_ID IN (SELECT ID FROM LPTI_VENDOR_VW@TAPROD_DBLINK WHERE TYPE = 'A' AND CATEGORY = 'Outbound Agent')
  GROUP BY CUSTOMER_ID,TRX_DATE,TRX_NUMBER,currency_code
  HAVING SUM(ACCTD_AMOUNT) <>0 );
EXCEPTION
 WHEN NO_DATA_FOUND THEN
  nAMOUNT:=0;
 WHEN OTHERS THEN
  nAMOUNT:=0;
end;
END IF;
return(nAMOUNT);
end;
/

CREATE OR REPLACE FUNCTION "APPS"."LPTI_CREATE_CCID" (P_CONCAT_SEGS IN VARCHAR2)  RETURN VARCHAR2
IS

      /**********************************************************************************************
       * Name            :                                                                           *
       * Purpose         : This Functiona is used to create CCID                                     *
       * Program         : Based on Segments value from 11i , this programe create CCid in R12 if the*
       *                   CCID is not avliable in the syste,                                        *
       *                                                                                             *
       * ===============                                                                             *
       * Change History                                                                              *
       * ===============                                                                             *
       *       Date            Name               Ver    Description                                 *
       *  ----------------------------------------------------------------------------------------   *
       *     15-Mar-2020      NTalyan        1.0        Function Created for New CCID                *
       *                                                Conversion to 12.1.3 instance.               *
       *********************************************************************************************/


v_chart_of_account_id    VARCHAR2 (200):=50389;
v_code_combination_id     VARCHAR2 (200);

BEGIN
      v_code_combination_id :=fnd_flex_ext.get_ccid ('SQLGL',
                                'GL#',
                                v_chart_of_account_id,
                                SYSDATE,
                                P_CONCAT_SEGS
                               );
      IF v_code_combination_id <> 0
      THEN
         DBMS_OUTPUT.put_line ('Code Combination Id created' ||v_code_combination_id);
         RETURN v_code_combination_id;
      ELSE
         DBMS_OUTPUT.put_line ('failure');
        RETURN (0);
      END IF;
END LPTI_CREATE_CCID;
/

CREATE OR REPLACE FUNCTION "APPS"."LPTI_CUSTOMER_CLOSING_BAL" (  P_customer_id in number,
                                                       P_curr_code1 in varchar2,
                                                       p_end_date in date,
                                                       p_org_id in number,
                                                       P_SET_OF_BOOKS_ID NUMBER,   
                                                       func_closing_bal_dr out number,
                                                       func_closing_bal_cr out number,
                                                       tran_closing_bal_cr out number
                                                    ) return number
is 


Cursor  Get_debit_amount IS
Select
	    sum((b.amount)) sum_ext_amount,
	    sum((b.amount) * NVL(A.exchange_rate,1))
From
        ra_customer_trx_all              A,
        ar_payment_schedules_all         C,
        ra_cust_trx_line_gl_dist_all     B
Where
    	a.bill_to_customer_id        = P_customer_id
--AND 	trunc(a.trx_date)           <= trunc(p_end_date)
AND 	trunc(c.gl_date)            <= trunc(p_end_date)
AND 	a.invoice_currency_code      = P_curr_code1
AND 	a.complete_flag              = 'Y'
AND 	b.customer_trx_id            = a.customer_trx_id
AND 	b.account_class              = 'REC'
AND     b.LATEST_REC_FLAG            = 'Y'
AND    A.CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND     A.customer_trx_id            = C.customer_trx_id
AND     C.class                     In ('INV','DM','DEP')
AND     a.org_id                     = p_org_id
AND     A.SET_OF_BOOKS_ID 				   = P_SET_OF_BOOKS_ID
AND     c.Payment_schedule_id
IN     (SELECT  MIN(PAYMENT_SCHEDULE_ID) FROM    AR_PAYMENT_SCHEDULES_ALL WHERE   CUSTOMER_TRX_ID = C.CUSTOMER_TRX_ID);

-- Query for Adjustment
Cursor  get_adjustment_amount IS
SELECT
	    sum((b.amount)) sum_adj_amount,
	    sum((b.amount) * NVL(C.exchange_rate,1))
FROM
        aR_customers                     a,
        ar_adjustments_all               b,
        ra_customer_trx_all              c,
        ar_payment_schedules_all         d,
        gl_code_combinations             e
WHERE
	    a.customer_id                =  p_customer_id
AND 	b.customer_trx_id            = c.customer_trx_id
and     e.code_combination_id        = b.code_combination_id
AND 	c.bill_to_customer_id        = a.customer_id
--AND 	trunc(b.apply_date)         <= trunc(p_end_date)
AND 	trunc(b.gl_date)            <= trunc(p_end_date)
AND     c.invoice_currency_code      = P_curr_code1
AND 	b.status                     = 'A'
AND	    b.customer_trx_id            = d.customer_trx_id
AND    c.CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND     c.org_id                     =p_org_id
AND     B.SET_OF_BOOKS_ID 				   = P_SET_OF_BOOKS_ID
and     d.payment_schedule_id
IN      (SELECT MIN(PAYMENT_SCHEDULE_ID)
         FROM   AR_PAYMENT_SCHEDULES_ALL
	     WHERE  CUSTOMER_TRX_ID = d.CUSTOMER_TRX_ID
	    );


Cursor  Get_credit_amount IS
Select
	    sum(a.amount)                             sum_amount,
	    sum(a.amount * NVL(a.exchange_rate,1.00)) sum_amount_exchange
From
	    ar_cash_receipts_all             A
Where
     		a.pay_from_customer          = p_customer_id
AND 		a.currency_code              = P_curr_code1
AND     a.org_id                     =p_org_id
AND     A.SET_OF_BOOKS_ID 				   = P_SET_OF_BOOKS_ID
--Added the below by Sanjikum for Bug #3962497
AND 		EXISTS (	SELECT	1 
									FROM 		ar_cash_receipt_history_all
									WHERE		cash_receipt_id = a.cash_receipt_id
									AND  		org_id = p_org_id
									AND 		trunc(gl_date) <= trunc(p_end_date)
							 );

Cursor   get_reversal_amount IS
Select
	     sum(a.amount)                             sum_amount,
	     sum(a.amount * NVL(a.exchange_rate,1.00)) sum_amount_exchange -- a. added by ssumaith
From
	     ar_cash_receipts_all            A,
	     ar_cash_receipt_history_all     b -- added by sriram - 3328962
Where
         a.cash_receipt_id           = b.cash_receipt_id
AND    	 a.pay_from_customer         = p_customer_id
AND	     trunc(b.gl_date)           <= trunc(p_end_date)
AND      a.reversal_date               is not null
AND 	   a.currency_code             = P_curr_code1
--AND      b.current_record_flag        = 'Y' --Commented by Sanjikum for Bug #3962497
AND 	 	 b.status                      = 'REVERSED' --Added by Sanjikum for Bug #3962497
AND      a.org_id                    = p_org_id
AND     A.SET_OF_BOOKS_ID 				   = P_SET_OF_BOOKS_ID;

CURSOR   Get_Discount_Cur is
Select
         nvl(sum(abs(NVL(d.EARNED_discount_taken,0))),0)                          sum_amount,
 	     nvl(sum(abs(NVL(d.ACCTD_EARNED_DISCOUNT_TAKEN,0))),0)  sum_amount_exchange
From
	     aR_customers                    a,
	     ra_customer_trx_ALL             B,
	     ar_receivable_applications_all  D
Where
		 a.customer_id               =  p_customer_id
AND	     b.bill_to_customer_id       =  a.customer_id
AND	     b.complete_flag             =  'Y'
AND      trunc(d.GL_DATE)           <= trunc(p_end_date)
AND      d.applied_customer_trx_id   = b.customer_trx_id
AND    b.CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND      b.invoice_currency_code     = P_curr_code1
AND      B.org_id                    =p_org_id
AND      D.SET_OF_BOOKS_ID 				   = P_SET_OF_BOOKS_ID
AND      d.earned_discount_taken is not null
and      d.earned_discount_taken <> 0 
and      d.application_type = 'CASH' 
and      d.display = 'Y' 
 ;

cursor  c_exch_gainloss_cr is
SELECT
        sum(e.amount_cr)             sum_amount     ,
        sum(e.acctd_amount_cr)       sum_exchange_amount
FROM
        aR_customers                     a ,
        ra_customer_trx_all              b ,
        ar_cash_receipts_all             c,
        ar_receivable_applications_all   d,
        ar_distributions_all             e
WHERE
        a.customer_id                = b.BILL_TO_CUSTOMER_ID
AND     b.customer_trx_id            = d.APPLIED_CUSTOMER_TRX_ID
AND     c.cash_receipt_id            = d.cash_receipt_id
AND     e.SOURCE_ID                  = d.receivable_application_id
AND    b.CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND     b.org_id                     = p_org_id
AND     D.SET_OF_BOOKS_ID 				   = P_SET_OF_BOOKS_ID
AND     e.source_Type IN ('EXCH_LOSS', 'EXCH_GAIN' )
AND     b.invoice_currency_code      = P_curr_code1
AND     a.customer_id                = p_customer_id
--AND     TRUNC(c.receipt_date)       <= trunc(p_end_date)
AND     TRUNC(d.gl_date)            <= trunc(p_end_date);


cursor  c_exch_gainloss_dr is
SELECT
        sum(e.amount_dr)             sum_amount     ,
        sum(e.acctd_amount_dr)       sum_exchange_amount
FROM
        aR_customers                     a ,
        ra_customer_trx_all              b ,
        ar_cash_receipts_all             c ,
        ar_receivable_applications_all   d ,
        ar_distributions_all             e
WHERE
        a.customer_id                = b.BILL_TO_CUSTOMER_ID
AND     b.customer_trx_id            = d.APPLIED_CUSTOMER_TRX_ID
AND     c.cash_receipt_id            = d.cash_receipt_id
AND     e.SOURCE_ID                  = d.receivable_application_id
AND     b.org_id                     = p_org_id
AND    b.CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND     B.SET_OF_BOOKS_ID 				   = P_SET_OF_BOOKS_ID
AND     b.invoice_currency_code      = P_curr_code1
AND     a.customer_id                =p_customer_id
--AND     TRUNC(c.receipt_date)       <= trunc(p_end_date)
AND     TRUNC(d.gl_date)            <= trunc(p_end_date)
AND     e.source_Type IN ('EXCH_GAIN','EXCH_LOSS' );


Cursor  c_receipt_w_off IS
Select
	    sum(c.amount_applied)                             sum_amount,
	    sum(c.amount_applied * NVL(a.exchange_rate,1.00)) sum_amount_exchange
From
	    ar_cash_receipts_all             A,
        ar_cash_receipt_history_all      B,
        ar_receivable_applications_all   c
Where
     	a.pay_from_customer          = p_customer_id
AND	    trunc(b.gl_date)              <= trunc(p_end_date)
AND     a.cash_receipt_id              = b.cash_receipt_id
and     a.cash_receipt_id              = c .cash_receipt_id
and     c.cash_receipt_history_id      = b.cash_receipt_history_id
and     c.applied_payment_schedule_id  = -3
and     c.status                       = 'ACTIVITY'
AND     a.currency_code                = P_curr_code1
AND    c.applied_CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
--- AND     B.REVERSAL_GL_DATE IS NULL ---commented by mohinder paul singh
AND     b.current_record_flag          = 'Y'
AND     a.org_id                       =p_org_id
AND     A.SET_OF_BOOKS_ID 				   = P_SET_OF_BOOKS_ID
and     not exists
 ( select 1
   from   ar_cash_receipt_history_all
   where  cash_receipt_id = b.cash_receipt_id
   and    status          = 'REVERSED'
 )
;


v_tr_disc_cr_amt            Number;
v_func_disc_cr_amt          Number;
v_tr_dr_amt 		        Number;
v_func_dr_amt		        Number;
v_tr_cr_amt		            Number;
v_func_cr_amt		        Number;
v_tr_rev_amt		        Number;
v_func_rev_amt		        Number;
v_tran_tot_amt		        Number;
v_func_tot_amt		        Number;
v_tran_cl_bal_dr	        Number;
v_cre_memo_amt              Number;
v_cre_memo_func_amt         Number;
v_tr_adj_amt		        Number;
v_func_adj_amt		        Number;
v_func_gain_amt             Number;
v_func_loss_amt             Number;
v_tran_loss_amt             Number;
v_tran_gain_amt             Number;
v_tran_rcp_w_off            Number;
v_func_rcp_w_off            Number;

begin
  Select
	   sum((b.amount))                           sum_ext_amount,
	   sum((b.amount) * NVL(A.exchange_rate,1))
  Into
       v_cre_memo_amt,
       v_cre_memo_func_amt
  From
       ra_customer_trx_all               A,
       ar_payment_schedules_all          C,
       ra_cust_trx_line_gl_dist_all      B
Where
  	   a.bill_to_customer_id         = p_customer_id
--AND    trunc(a.trx_date)            <= trunc(p_end_date)
AND    trunc(c.gl_date)             <= trunc(p_end_date)
AND    a.invoice_currency_code       = P_curr_code1
AND    a.complete_flag               = 'Y'
AND    b.customer_trx_id             = a.customer_trx_id
AND    b.account_class               = 'REC'
AND    b.LATEST_REC_FLAG             = 'Y'
AND    A.customer_trx_id             = C.customer_trx_id
AND    C.class In('CM')
AND    a.CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND    a.org_id                      =p_org_id
AND    A.SET_OF_BOOKS_ID 				     = P_SET_OF_BOOKS_ID
AND    c.payment_schedule_id
IN
 (SELECT MIN(PAYMENT_SCHEDULE_ID)
  FROM AR_PAYMENT_SCHEDULES_ALL
  WHERE CUSTOMER_TRX_ID = C.CUSTOMER_TRX_ID
 );


 OPEN get_debit_amount;
 FETCH get_debit_amount        INTO v_tr_dr_amt, v_func_dr_amt;
 CLOSE get_debit_amount;

 OPEN get_credit_amount;
 FETCH get_credit_amount       INTO v_tr_cr_amt, v_func_cr_amt;
 CLOSE get_credit_amount;

 OPEN get_reversal_amount;
 FETCH get_reversal_amount     INTO v_tr_rev_amt, v_func_rev_amt;
 CLOSE get_reversal_amount;

 OPEN get_adjustment_amount;
 FETCH get_adjustment_amount   INTO v_tr_adj_amt, v_func_adj_amt;
 CLOSE get_adjustment_amount;

 OPEN Get_Discount_Cur ;
 FETCH Get_Discount_Cur        into v_tr_disc_cr_amt,   v_func_disc_cr_amt ;
 CLOSE Get_Discount_Cur ;

 open  c_exch_gainloss_dr;
 fetch c_exch_gainloss_dr      into v_tran_gain_amt,v_func_gain_amt;
 close c_exch_gainloss_dr;

 Open   c_exch_gainloss_cr;
 fetch  c_exch_gainloss_cr     into v_tran_loss_amt,v_func_loss_amt;
 close  c_exch_gainloss_cr;


 open  c_receipt_w_off;
 fetch c_receipt_w_off         into v_tran_rcp_w_off,v_func_rcp_w_off;
 close c_receipt_w_off;

 v_func_tot_amt := (  (NVL(v_func_dr_amt,0)
                     + nvl(v_cre_memo_func_amt,0)
                     + NVL(v_func_rev_amt,0))
                     - NVL(v_func_cr_amt,0)
                     + nvl(v_func_rcp_w_off,0)
                     + (NVL(v_func_adj_amt,0))
                     - NVL(v_func_disc_cr_amt,0)
                     - NVL(v_func_gain_amt,0)
                     + NVL(v_func_loss_amt,0)  ) ;

 v_tran_tot_amt := ( (NVL(v_tr_dr_amt,0))
                    + nvl(v_cre_memo_amt,0)
                    +(NVL(v_tr_rev_amt,0))
                    - NVL(v_tr_cr_amt,0)
                    + nvl(v_tran_rcp_w_off,0)
                    - abs(NVL(v_tr_adj_amt,0))
                    - NVL(v_tr_disc_cr_amt,0) );

 IF P_curr_code1='INR' THEN
    IF   NVL(v_func_tot_amt,0) < 0 THEN
           func_closing_bal_cr := ABS(v_func_tot_amt)+NVL(TI_CUSTOMER_BAL_ADJUST(p_customer_id,p_END_date),0);
	       func_closing_bal_dr := 0;
    ELSE
	       func_closing_bal_cr := 0;
	       func_closing_bal_dr := ABS(v_func_tot_amt)-NVL(TI_CUSTOMER_BAL_ADJUST(p_customer_id,p_END_date),0);
    END IF;

    IF   NVL(v_tran_tot_amt,0) < 0 THEN
           tran_closing_bal_cr := ABS(NVL(v_tran_tot_amt,0))+NVL(TI_CUSTOMER_BAL_ADJUST(p_customer_id,p_END_date),0);
	       Return (0);
    ELSE
	       tran_closing_bal_cr := 0;
           Return(ABS(NVL(v_tran_tot_amt,0))-NVL(TI_CUSTOMER_BAL_ADJUST(p_customer_id,p_END_date),0));
    END IF;

   ELSE

   IF   NVL(v_func_tot_amt,0) < 0 THEN
           func_closing_bal_cr := ABS(v_func_tot_amt);
	       func_closing_bal_dr := 0;
    ELSE
	       func_closing_bal_cr := 0;
	       func_closing_bal_dr := ABS(v_func_tot_amt);
    END IF;
    IF   NVL(v_tran_tot_amt,0) < 0 THEN
           tran_closing_bal_cr := ABS(NVL(v_tran_tot_amt,0));
	       Return (0);
    ELSE
	       tran_closing_bal_cr := 0;
           Return(ABS(NVL(v_tran_tot_amt,0)));
    END IF;

  END IF;   



end;
/

CREATE OR REPLACE FUNCTION "APPS"."LPTI_CUSTOMER_OPENING_BAL" (  P_customer_id in number,
                                                       curr_code in varchar2,
                                                       p_start_date in date,
                                                       p_org_id in number,
                                                       P_SET_OF_BOOKS_ID NUMBER,   
                                                       func_open_bal_dr out number,
                                                       func_open_bal_cr out number,
                                                       tran_open_bal_cr out number
                                                    ) return number
is 


Cursor Get_debit_amount IS
Select
      sum((b.amount)) sum_ext_amount,
      sum((b.amount) * NVL(A.exchange_rate,1))
From
      ra_customer_trx_all                A,
      ar_payment_schedules_all           C,
      ra_cust_trx_line_gl_dist_all       B
Where
        a.bill_to_customer_id        = p_customer_id
-- AND     trunc(a.trx_date)            < trunc(:p_start_date)
AND     trunc(c.gl_date)            < trunc(p_start_date)
AND     a.invoice_currency_code      = curr_code
AND     a.complete_flag              = 'Y'
AND     b.customer_trx_id            = a.customer_trx_id
AND     b.account_class              = 'REC'
AND     b.LATEST_REC_FLAG            = 'Y'
AND     A.customer_trx_id            = C.customer_trx_id
AND     C.class In('INV','DM','DEP')
AND    A.CUSTOMER_TRX_ID NOT IN (325518,330653)     
AND     a.org_id                     =p_org_id
AND     A.SET_OF_BOOKS_ID     = P_SET_OF_BOOKS_ID
AND c.Payment_schedule_id
IN (SELECT MIN(PAYMENT_SCHEDULE_ID)
    FROM   AR_PAYMENT_SCHEDULES_ALL
      WHERE  CUSTOMER_TRX_ID = C.CUSTOMER_TRX_ID
   );

Cursor get_adjustment_amount IS
SELECT
          sum((b.amount)) sum_adj_amount,
       sum((b.amount) * NVL(C.exchange_rate,1)) 
FROM
       AR_customers                      a,
       ar_adjustments_all                b,
       ra_customer_trx_all               c,
       ar_payment_schedules_all          d,
       gl_code_combinations              e
WHERE
        a.customer_id                =  P_customer_id
AND     b.customer_trx_id            =  c.customer_trx_id
AND     c.bill_to_customer_id        =  a.customer_id
and     e.code_combination_id        = b.code_combination_id
--AND     trunc(b.apply_date)          < trunc(:p_start_date)
AND     trunc(b.gl_date)          < trunc(p_start_date)
AND     c.invoice_currency_code      = curr_code
AND     b.status                     = 'A'
AND    C.CUSTOMER_TRX_ID NOT IN (325518,330653)     
AND        b.customer_trx_id            = d.customer_trx_id
AND     c.org_id                     =p_org_id
AND     B.SET_OF_BOOKS_ID                    = P_SET_OF_BOOKS_ID
and     d.payment_schedule_id
IN      (SELECT MIN(PAYMENT_SCHEDULE_ID)
         FROM   AR_PAYMENT_SCHEDULES_ALL
         WHERE  CUSTOMER_TRX_ID = d.CUSTOMER_TRX_ID
        );

Cursor Get_credit_amount IS
Select
           sum(a.amount)                             sum_amount,
           sum(a.amount * NVL(a.exchange_rate,1.00)) sum_amount_exchange
From
           ar_cash_receipts_all              A
Where
        a.pay_from_customer           = P_customer_id
AND   a.currency_code               = curr_code
AND   a.org_id=p_org_id
AND   A.SET_OF_BOOKS_ID                    = P_SET_OF_BOOKS_ID
AND         EXISTS (    SELECT    1 
                                    FROM         ar_cash_receipt_history_all
                                    WHERE        cash_receipt_id = a.cash_receipt_id
                                    AND          org_id = p_org_id
                                    AND         trunc(gl_date) < trunc(p_start_date)
                             );

Cursor get_reversal_amount IS
Select
       sum(a.amount)                             sum_amount,
       sum(a.amount * NVL(a.exchange_rate,1.00)) sum_amount_exchange 
From
       ar_cash_receipts_all              A,
       ar_cash_receipt_history_all       b 
Where
       a.cash_receipt_id             = b.cash_receipt_id
AND    a.pay_from_customer           = P_customer_id
AND       trunc(b.gl_date)              < trunc(p_start_date)
AND    a.reversal_date                 is not null
AND    a.currency_code               = curr_code
AND      b.status                      = 'REVERSED' 
AND    a.org_id                      = p_org_id
AND     A.SET_OF_BOOKS_ID                    = P_SET_OF_BOOKS_ID;

CURSOR Get_Discount_Cur is
Select
          nvl(sum(abs(NVL(d.EARNED_DISCOUNT_TAKEN,0))),0)                          sum_amount,
       nvl(sum(abs(NVL(d.ACCTD_EARNED_DISCOUNT_TAKEN,0))),0)  sum_amount_exchange
From
       AR_customers                      a,
       ra_customer_trx_ALL               B,
       ar_receivable_applications_all    D
Where
       a.customer_id                 = p_customer_id
AND       b.bill_to_customer_id         = a.customer_id
AND       b.complete_flag               = 'Y'
AND    trunc(d.GL_DATE)              < trunc(p_start_date)
AND    d.applied_customer_trx_id             = b.customer_trx_id
AND    b.invoice_currency_code       = curr_code
AND    d.earned_DISCOUNT_TAKEN         is not  null 
and    d.earned_DISCOUNT_TAKEN       <> 0
AND    D.APPLIED_CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND    B.org_id                      = p_org_id
AND    B.SET_OF_BOOKS_ID                    = P_SET_OF_BOOKS_ID
and    d.application_type = 'CASH' 
and    d.display = 'Y';


cursor c_exch_gainloss_cr is
SELECT
       sum(e.AMOUNT_cr)              sum_amount     ,
       sum(e.ACCTD_AMOUNT_cr)        sum_exchange_amount
FROM
       AR_customers                      a ,
       ra_customer_trx_all               b ,
       ar_cash_receipts_all              c ,
       ar_receivable_applications_all    d ,
       ar_distributions_all              e
WHERE
       a.customer_id                 =  b.BILL_TO_CUSTOMER_ID
AND    b.customer_trx_id             =  d.APPLIED_CUSTOMER_TRX_ID
AND    c.cash_receipt_id             =  d.cash_receipt_id
AND    e.SOURCE_ID                   =  d.receivable_application_id
AND    b.org_id                      =  p_org_id
AND    B.SET_OF_BOOKS_ID                    = P_SET_OF_BOOKS_ID
AND    e.source_Type                 IN ('EXCH_LOSS','EXCH_GAIN' )
AND    B.CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND    b.invoice_currency_code       =  curr_code
AND    a.customer_id                 =  p_customer_id
--AND    TRUNC(c.receipt_date)         <  trunc(:p_start_date);
AND    TRUNC(d.gl_date)              <  trunc(p_start_date);

cursor c_exch_gainloss_dr is
SELECT
       sum(e.amount_dr)             sum_amount     ,
       sum(e.acctd_amount_dr)       sum_exchange_amount
FROM
       AR_customers                      a ,
       ra_customer_trx_all               b ,
       ar_cash_receipts_all              c,
       ar_receivable_applications_all    d,
       ar_distributions_all              e
WHERE
       a.customer_id                 =  b.BILL_TO_CUSTOMER_ID
AND    b.customer_trx_id             =  d.APPLIED_CUSTOMER_TRX_ID
AND    c.cash_receipt_id             =  d.cash_receipt_id
AND    e.SOURCE_ID                   =  d.receivable_application_id
AND    b.org_id                      =  p_org_id
AND    B.SET_OF_BOOKS_ID                    = P_SET_OF_BOOKS_ID
AND    B.CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND    e.source_Type                IN  ('EXCH_GAIN','EXCH_LOSS' )
AND    b.invoice_currency_code       = curr_code
AND    a.customer_id                 =p_customer_id
--AND    TRUNC(c.receipt_date)         < trunc(:p_start_date) ;
AND    TRUNC(d.gl_date)              < trunc(p_start_date) ;


Cursor c_receipt_w_off IS
Select
       sum(c.amount_applied)                             sum_amount,
       sum(c.amount_applied * NVL(a.exchange_rate,1.00)) sum_amount_exchange
From
       ar_cash_receipts_all              A,
       ar_cash_receipt_history_all       B,
       ar_receivable_applications_all    c
Where
       a.pay_from_customer           = P_customer_id
AND       trunc(b.gl_date)              < trunc(p_start_date)
AND    a.cash_receipt_id             = b.cash_receipt_id
and    a.cash_receipt_id             = c .cash_receipt_id
and    c.cash_receipt_history_id     = b.cash_receipt_history_id
and    c.applied_payment_schedule_id = -3
and    c.status                      = 'ACTIVITY'
AND    a.currency_code               = curr_code
AND    b.current_record_flag         = 'Y'
AND    a.org_id                      = p_org_id
AND    A.SET_OF_BOOKS_ID                    = P_SET_OF_BOOKS_ID
and    not exists
 ( select 1
   from   ar_cash_receipt_history_all
   where  cash_receipt_id = b.cash_receipt_id
   and    status = 'REVERSED'
 )
;




v_tr_dr_amt                   Number;
v_func_dr_amt                  Number;
v_tr_cr_amt                      Number;
v_func_cr_amt                  Number;
v_tr_rev_amt                  Number;
v_func_rev_amt                  Number;
v_tran_tot_amt                  Number;
v_func_tot_amt                  Number;
v_tran_cl_bal_dr              Number;
v_cre_memo_amt                Number;
v_cre_memo_func_amt           Number;
v_tr_adj_amt                  Number;
v_func_adj_amt                  Number;
v_func_gain_amt               Number;
v_func_loss_amt               Number;
v_tran_loss_amt               Number;
v_tran_gain_amt               Number;
v_tran_rcp_w_off              Number;
v_func_rcp_w_off              Number;
v_tr_disc_cr_amt              Number;
v_func_disc_cr_amt            Number;
--func_open_bal_cr              Number;
--func_open_bal_dr              Number;  
--tran_open_bal_cr              Number;


begin
  Select
           sum((b.amount)) sum_ext_amount,
           sum((b.amount) * NVL(A.exchange_rate,1))
   Into    v_cre_memo_amt,
           v_cre_memo_func_amt
   From
           ra_customer_trx_all           A,
           ar_payment_schedules_all      C,
           ra_cust_trx_line_gl_dist_all  B
Where
           a.bill_to_customer_id        = p_customer_id
--AND        trunc(a.trx_date)            < trunc(:p_start_date)
AND        trunc(c.gl_date)             < trunc(p_start_date)
AND        a.invoice_currency_code      = curr_code
AND        a.complete_flag              = 'Y'
AND        b.customer_trx_id            = a.customer_trx_id
AND        b.account_class              = 'REC'
AND        b.LATEST_REC_FLAG            = 'Y'
AND        A.customer_trx_id            = C.customer_trx_id
AND        C.class In('CM')
AND    A.CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND        a.org_id                     =p_org_id
AND        A.SET_OF_BOOKS_ID                    = P_SET_OF_BOOKS_ID
AND        c.payment_schedule_id
IN         (SELECT MIN(PAYMENT_SCHEDULE_ID)
            FROM   AR_PAYMENT_SCHEDULES_ALL
            WHERE  CUSTOMER_TRX_ID = C.CUSTOMER_TRX_ID
           );

    OPEN  get_debit_amount;
    FETCH get_debit_amount       INTO v_tr_dr_amt, v_func_dr_amt;
    CLOSE get_debit_amount;

    OPEN  get_credit_amount;
    FETCH get_credit_amount      INTO v_tr_cr_amt, v_func_cr_amt;
    CLOSE get_credit_amount;


    OPEN  get_reversal_amount;
    FETCH get_reversal_amount    INTO v_tr_rev_amt, v_func_rev_amt;
    CLOSE get_reversal_amount;

    OPEN  get_adjustment_amount;
    FETCH get_adjustment_amount  INTO v_tr_adj_amt, v_func_adj_amt;
    CLOSE get_adjustment_amount;

    OPEN  Get_Discount_Cur ;
    FETCH Get_Discount_Cur       into v_tr_disc_cr_amt,   v_func_disc_cr_amt ;
    CLOSE Get_Discount_Cur ;


    open  c_exch_gainloss_dr;
    fetch c_exch_gainloss_dr     into v_tran_gain_amt,v_func_gain_amt;
    close c_exch_gainloss_dr;

    Open   c_exch_gainloss_cr;
    fetch  c_exch_gainloss_cr    into v_tran_loss_amt,v_func_loss_amt;
    close  c_exch_gainloss_cr;

    open  c_receipt_w_off;
    fetch c_receipt_w_off        into v_tran_rcp_w_off,v_func_rcp_w_off;
    close c_receipt_w_off;

    v_func_tot_amt := ( NVL(v_func_dr_amt,0      )
                      + nvl(v_cre_memo_func_amt,0)
                      + NVL(v_func_rev_amt,0     )
                      - NVL(v_func_cr_amt,0      )
                      + NVL(v_func_rcp_w_off,0   )
                      + (NVL(v_func_adj_amt,0   ))
                      - NVL(v_func_disc_cr_amt,0 )
                      - NVL(v_func_gain_amt,0    )
                      + NVL(v_func_loss_amt,0    )
                      ) ;

    v_tran_tot_amt := ( (NVL(v_tr_dr_amt,0)     )
                       + nvl(v_cre_memo_amt,0   )
                       +(NVL(v_tr_rev_amt,0    ))
                       - NVL(v_tr_cr_amt,0      )
                       + NVL(v_tran_rcp_w_off,0 )
                       - abs(NVL(v_tr_adj_amt,0))
                       - NVL(v_tr_disc_cr_amt,0)) ;

 if curr_code='INR' THEN 
    IF NVL(v_func_tot_amt,0) < 0 THEN
       func_open_bal_cr := ABS(v_func_tot_amt)+TI_CUSTOMER_BAL_ADJUST1(p_customer_id,p_start_date);
       func_open_bal_dr := 0;
    ELSE
	   func_open_bal_cr := 0;
	   func_open_bal_dr := ABS(v_func_tot_amt)-TI_CUSTOMER_BAL_ADJUST1(p_customer_id,p_start_date);
    END IF;

    IF NVL(v_tran_tot_amt,0) < 0 THEN
       tran_open_bal_cr := ABS(NVL(v_tran_tot_amt,0))+TI_CUSTOMER_BAL_ADJUST1(p_customer_id,p_start_date);
	    Return (0);
    ELSE
	   tran_open_bal_cr := 0;
       Return(ABS(NVL(v_tran_tot_amt,0))-TI_CUSTOMER_BAL_ADJUST1(p_customer_id,p_start_date));
    END IF;
ELSE
IF NVL(v_func_tot_amt,0) < 0 THEN
       func_open_bal_cr := ABS(v_func_tot_amt);
       func_open_bal_dr := 0;
    ELSE
	   func_open_bal_cr := 0;
	   func_open_bal_dr := ABS(v_func_tot_amt);
    END IF;

    IF NVL(v_tran_tot_amt,0) < 0 THEN
       tran_open_bal_cr := ABS(NVL(v_tran_tot_amt,0));
	    Return (0);
    ELSE
	   tran_open_bal_cr := 0;
       Return(ABS(NVL(v_tran_tot_amt,0)));
    END IF;    
END IF;
end;
/

CREATE OR REPLACE FUNCTION "APPS"."LPTI_DR_CR_AMT" (
                                          p_type in varchar2,
                                          p_amount IN NUMBER,
                                          P_remarks IN VARCHAR2,
                                          p_amount_other_currency IN NUMBER,
                                          func_dr_amt OUT NUMBER,
                                          func_cr_amt OUT NUMBER,
                                          tran_cr_amt OUT NUMBER
                                          ) return number is
begin

IF NVL(p_type,'##') IN ('INV','DM','REV','DEP') and p_amount > 0 THEN 
     func_dr_amt := NVL(abs(p_amount_other_currency),0);
     tran_cr_amt := 0;
     func_cr_amt := 0;
       Return(NVL(abs(p_amount),0));    

  elsIF NVL(p_type,'##') IN ('INV','DM','REV','DEP') and p_amount <= 0 THEN 
     func_cr_amt := NVL(abs(p_amount_other_currency),0);
     tran_cr_amt := NVL(abs(p_amount),0);
     func_dr_amt := 0;

  ELsif NVL(p_type,'##') IN ('CM','REC') THEN  
     tran_cr_amt := NVL(abs(p_amount),0);
     func_cr_amt := NVL(abs(p_amount_other_currency),0);
     func_dr_amt := 0;

     Return(0);         

  ELsif NVL(p_type,'##') IN ('ADJ') and p_amount <= 0  THEN   
     tran_cr_amt := NVL(abs(p_amount),0);
     func_cr_amt := NVL(abs(p_amount_other_currency),0);
     func_dr_amt := 0;

     Return(0);         
  ELsif NVL(p_type,'##') IN ('ADJ') and p_amount > 0  THEN   
     func_dr_amt := NVL(abs(p_amount_other_currency),0);
     func_cr_amt := 0;
     tran_cr_amt :=0;

     Return(NVL(abs(p_amount),0));    


  ELsif NVL(p_type,'##') IN ('W/O') and p_amount <= 0  THEN  
     tran_cr_amt := NVL(abs(p_amount),0);
     func_cr_amt := NVL(abs(p_amount_other_currency),0);
     func_dr_amt := 0;

     Return(0);         
  ELsif NVL(p_type,'##') IN ('W/O') and p_amount > 0  THEN   
     func_dr_amt := NVL(abs(p_amount_other_currency),0);
     func_cr_amt := 0;
     tran_cr_amt :=0;

     Return(NVL(abs(p_amount),0));    

  Elsif NVL(p_type,'##') IN ('DSC') THEN

       tran_cr_amt := NVL(abs(p_amount),0);
     func_cr_amt := NVL(abs(p_amount_other_currency),0);
     func_dr_amt := 0;

     Return(0);    
  Elsif NVL(p_type,'##') in ('EXCH_GAIN','EXCH_LOSS') then  
       tran_cr_amt := 0;

       if  P_remarks = 'CR' then
            func_cr_amt := 0;
            func_dr_amt := nvl(p_amount_other_currency,0);
       elsif  P_remarks = 'DR' then
            func_dr_amt := 0;
            func_cr_amt := nvl(p_amount_other_currency,0);
       end if;


  	Return(0);

  END If;
    Return(0);

end; 
/

CREATE OR REPLACE FUNCTION "APPS"."LPTI_REV_EXCH_RATE_NEW_0007" (P_SOB_ID IN VARCHAR2,P_CURR_CODE IN VARCHAR2,P_DATE IN DATE)
RETURN NUMBER
IS
nEXCH_RATE NUMBER(25,5);
vCURR_CODE VARCHAR2(15);
BEGIN
    BEGIN
       SELECT CURRENCY_CODE
       INTO vCURR_CODE
       FROM GL_SETS_OF_BOOKS
       WHERE SET_OF_BOOKS_ID = P_SOB_ID;
    EXCEPTION
       WHEN OTHERS THEN
         vCURR_CODE := 'INR';
    END;

    BEGIN
        SELECT CONVERSION_RATE
        INTO nEXCH_RATE
        FROM LPTI_GL_DAILY_RATES
        WHERE PERIOD_NAME = TO_CHAR(P_DATE,'MON-RR')
        AND TO_CURRENCY = vCURR_CODE
        AND FROM_CURRENCY = P_CURR_CODE;
        RETURN (nEXCH_RATE);
     EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            BEGIN
                SELECT REV_RATE
                INTO nEXCH_RATE
                FROM GL_TRANSLATION_RATES_V
                WHERE PERIOD_END_DATE = (
                                        SELECT MAX(PERIOD_END_DATE)D1
                                        FROM GL_TRANSLATION_RATES_V
                                        WHERE PERIOD_END_DATE < LAST_DAY(TO_DATE(P_DATE,'DD-MON-RRRR'))
                                        AND FUNCTIONAL_CURRENCY = vCURR_CODE
                                        AND TO_CURRENCY_CODE = 'EUR'
                                         )
                AND FUNCTIONAL_CURRENCY = vCURR_CODE
                AND TO_CURRENCY_CODE = P_CURR_CODE;
                RETURN (nEXCH_RATE);
            EXCEPTION
                WHEN OTHERS THEN
                 nEXCH_RATE :=1;
            END;
        WHEN OTHERS    THEN
          nEXCH_RATE :=1;
    END;
     RETURN (nEXCH_RATE);
END;
/

CREATE OR REPLACE FUNCTION "APPS"."OA_GET_GL_NAME" (P_SEGMENT2 IN VARCHAR2)--,P_LEDGER_ID IN NUMBER)
   RETURN VARCHAR2
IS
   V_DESCRIPTION   VARCHAR2 (1000);
BEGIN
   SELECT B.DESCRIPTION
     INTO V_DESCRIPTION
     FROM FND_FLEX_VALUES A, FND_FLEX_VALUES_TL B
    WHERE     A.FLEX_VALUE_ID = B.FLEX_VALUE_ID
          AND A.FLEX_VALUE_SET_ID in(SELECT SG.FLEX_VALUE_SET_ID      
                                    FROM FND_ID_FLEX_STRUCTURES ST,
                                         FND_ID_FLEX_SEGMENTS SG,   
                                         FND_FLEX_VALUE_SETS VS,
                                         GL_LEDGERS GL --,     FND_FLEX_VALUES A 
                                    WHERE ST.APPLICATION_ID = 101
                                    and ST.APPLICATION_ID = SG.APPLICATION_ID
                                    AND ST.ID_FLEX_CODE = SG.ID_FLEX_CODE 
                                    AND ST.ID_FLEX_NUM = SG.ID_FLEX_NUM
                                    and SG.FLEX_VALUE_SET_ID = VS.FLEX_VALUE_SET_ID
                                    AND ST.ID_FLEX_CODE = 'GL#'
                                    AND ST.ENABLED_FLAG = 'Y'
                                    AND SG.ID_FLEX_NUM = GL.CHART_OF_ACCOUNTS_ID
                                    AND GL.LEDGER_ID = 2121
                                    AND SG.APPLICATION_COLUMN_NAME ='SEGMENT2')
                                    AND A.FLEX_VALUE IN P_SEGMENT2;

   RETURN (V_DESCRIPTION);
EXCEPTION
   WHEN OTHERS
   THEN
      RETURN NULL;
END OA_GET_GL_NAME;
/

CREATE OR REPLACE FUNCTION "APPS"."OA_GET_SL_NAME" (P_SEGMENT2 IN VARCHAR2,P_SEGMENT3 IN VARCHAR2)
RETURN VARCHAR2 IS 
V_DESCRIPTION VARCHAR2(1000);
BEGIN
  SELECT SUBSTR(DESCRIPTION,1,50) INTO V_DESCRIPTION 
  FROM FND_FLEX_VALUES A , FND_FLEX_VALUES_TL B
WHERE A.FLEX_VALUE_ID = B.FLEX_VALUE_ID
      AND A.PARENT_FLEX_VALUE_LOW =P_SEGMENT2
      AND A.FLEX_VALUE =P_SEGMENT3
      AND A.FLEX_VALUE_SET_ID =1016629;
RETURN(V_DESCRIPTION);
EXCEPTION 
WHEN OTHERS THEN
RETURN NULL;
END OA_GET_SL_NAME;

/

CREATE OR REPLACE FUNCTION "APPS"."OA_GET_SL_NAME1" (P_SEGMENT2 IN VARCHAR2,P_SEGMENT3 IN VARCHAR2)
RETURN VARCHAR2 IS 
V_DESCRIPTION VARCHAR2(1000);
BEGIN
  SELECT SUBSTR(DESCRIPTION,1,50) 
  INTO V_DESCRIPTION 
  FROM FND_FLEX_VALUES A , FND_FLEX_VALUES_TL B
WHERE A.FLEX_VALUE_ID = B.FLEX_VALUE_ID
      AND A.PARENT_FLEX_VALUE_LOW =P_SEGMENT2
      AND A.FLEX_VALUE =P_SEGMENT3
      AND A.FLEX_VALUE_SET_ID =1016629;
RETURN(V_DESCRIPTION);
EXCEPTION 
WHEN OTHERS THEN
RETURN NULL;
END OA_GET_SL_NAME1;

/

CREATE OR REPLACE FUNCTION "APPS"."OA_RECEIPT_FILE_CODE" (p_receipt_number varchar2) return varchar2 is
v_count number:=0;
v_receipt_file_dtl varchar2(2000);
v_file_code varchar2(2000);
v_remarks   varchar2(2500);

begin

    begin
        select count(1)
        into  v_count
        from oa_ar_receipt_mas@taprod_dblink a,
        oa_ar_receipt_line_dtl@taprod_dblink b
        where a.receipt_id=b.receipt_id(+)
        and a.sbu_code=b.sbu_code(+)
        and a.receipt_number=p_receipt_number;
    end;
    
    begin
        select remarks
        into  v_remarks
        from oa_ar_receipt_mas@taprod_dblink a
        where a.sbu_code='0002'
        and a.receipt_number=p_receipt_number;
    end;
    

    if v_count = 0 then
    return null;
    else 
        for i in 1..v_count loop 

            begin
                select c.file_code||'-'||b.amount--c.file_code||'-CCode:'||c.costing_code||'-CN:'||c.COSTING_NAME||'-ARRD:'||to_char(c.TOUR_ARR_DATE,'dd-Mon-rrrr')
                into v_receipt_file_dtl
                from oa_ar_receipt_mas@taprod_dblink a,
                oa_ar_receipt_line_dtl@taprod_dblink b,
                tour_costing_mas@taprod_dblink c
                where a.receipt_id=b.receipt_id(+)
                and nvl(b.file_code,a.project_code)=c.file_code
                and a.sbu_code=b.sbu_code(+)
                and a.sbu_code=c.sbu_code
                and a.receipt_number=p_receipt_number
                and b.s_no(+)=i;
            exception when others then
                v_receipt_file_dtl:='N/A';
            end;

        v_file_code:=v_file_code||' / '||v_receipt_file_dtl;

        end loop;

    return v_remarks||'->file code detail:'||v_file_code;
    end if;
return null;

end;
/

CREATE OR REPLACE FUNCTION "APPS"."TA_CUSTOMER_CATEGORY" (customer_id varchar2) return varchar2
is
vcat varchar2(50);
begin

Begin
 SELECT category into vcat FROM lpti_vendor_vw@taprod_dblink
  WHERE TYPE='A'
    and id=customer_id;
Exception when others then
    vcat:='Not Defined'; 
end;    

return (vcat);

end; 
/

CREATE OR REPLACE FUNCTION "APPS"."TI_AR_CUSTOMER_BAL" (P_CUSTOMER_NUMBER IN VARCHAR2 ) 
RETURN NUMBER IS
nCUST_BALANCE NUMBER;
BEGIN
SELECT SUM(AMOUNT_DUE_REMAINING) INTO nCUST_BALANCE 
FROM AR_PAYMENT_SCHEDULES_ALL
WHERE CUSTOMER_ID = ( SELECT CUSTOMER_ID FROM AR_CUSTOMERS WHERE CUSTOMER_NUMBER = P_CUSTOMER_NUMBER );
RETURN(nCUST_BALANCE);
END;
/

CREATE OR REPLACE FUNCTION "APPS"."TI_CUSTOMER_BAL_ADJUST" (p_customer_id2 VARCHAR2,p_end_date DATE) RETURN NUMBER
IS
NVAL NUMBER;
BEGIN

SELECT SUM(NVL(acctd_amount_applied_from,0)) INTO NVAL FROM (

select BILL_TO_CUSTOMER_ID customer_id,(SELECT CUSTOMER_NAME FROM ar_CUSTOMERS WHERE CUSTOMER_ID=PAY_FROM_CUSTOMER) RECEIPT_CUSTOMER
,RECEIPT_NUMBER,t.trx_number,(select sum(revenue_amount) from ra_customer_trx_lines_all
where interface_line_attribute2=t.trx_number) INVOICE_amount,
invoice_currency_code INV_CURR,t.exchange_rate INV_RATE,
amount_applied APPLY_AMT,gl_date,gl_posted_date,acctd_amount_applied_from,acctd_amount_applied_to
,acctd_amount_applied_from-acctd_amount_applied_to "Gain/Loss" from
AR_RECEIVABLE_APPLICATIONS_all a,
ar_cash_receipts_all c,
ra_customer_trx_all t
WHERE a.cash_receipt_id=c.cash_receipt_id
and t.CUSTOMER_TRX_ID=APPLIED_CUSTOMER_TRX_ID
 anD APPLIED_CUSTOMER_TRX_ID IN (
select CUSTOMER_TRX_ID from ra_customer_trx_all
where  BILL_TO_CUSTOMER_ID=p_customer_id2
)
and gl_date<=p_end_date
AND DISPLAY='Y'
AND PAY_FROM_CUSTOMER<>p_customer_id2
union all
select BILL_TO_CUSTOMER_ID customer_id,(SELECT CUSTOMER_NAME FROM AR_CUSTOMERS WHERE CUSTOMER_ID=BILL_TO_CUSTOMER_ID) RECEIPT_CUSTOMER
,RECEIPT_NUMBER,t.trx_number,(select sum(revenue_amount) from ra_customer_trx_lines_all
where interface_line_attribute2=t.trx_number) INVOICE_amount,
invoice_currency_code INV_CURR,t.exchange_rate INV_RATE,
amount_applied APPLY_AMT,gl_date,gl_posted_date,acctd_amount_applied_from*-1,acctd_amount_applied_to
,acctd_amount_applied_from-acctd_amount_applied_to "Gain/Loss" from
AR_RECEIVABLE_APPLICATIONS_all a,
ar_cash_receipts_all c,
ra_customer_trx_all t
WHERE a.cash_receipt_id=c.cash_receipt_id
and t.CUSTOMER_TRX_ID=APPLIED_CUSTOMER_TRX_ID
 anD APPLIED_CUSTOMER_TRX_ID not IN (
select CUSTOMER_TRX_ID from ra_customer_trx_all
where  BILL_TO_CUSTOMER_ID=p_customer_id2
)
and gl_date<=p_end_date
AND DISPLAY='Y'
AND PAY_FROM_CUSTOMER=p_customer_id2

UNION ALL

SELECT 
PAY_FROM_CUSTOMER,
NULL,
RECEIPT_NUMBER,
RECEIPT_NUMBER,
NVL(H.FACTOR_DISCOUNT_AMOUNT,0),
C.CURRENCY_CODE,
C.EXCHANGE_RATE,NULL,NULL,NULL,
NVL(H.FACTOR_DISCOUNT_AMOUNT,0)*NVL(C.EXCHANGE_RATE,1)*-1 acctd_amount_applied_from,NULL,NULL
FROM ar_cash_receipt_history_all H,ar_cash_receipts_all C
WHERE C.cash_receipt_id IN (
select cash_receipt_id from ar_cash_receipts_all
where RECEIPT_date<=p_end_date
)
and gl_date>p_end_date
AND C.cash_receipt_id=H.cash_receipt_id
AND  PAY_FROM_CUSTOMER=p_customer_id2
AND  PAY_FROM_CUSTOMER<>'7730'
AND CURRENT_RECORD_FLAG='Y'
);

RETURN(NVL(NVAL,0));
END TI_CUSTOMER_BAL_ADJUST;
/

CREATE OR REPLACE FUNCTION "APPS"."TI_CUSTOMER_BAL_ADJUST1" (p_customer_id2 VARCHAR2,p_start_date DATE) RETURN NUMBER
IS
NVAL NUMBER;
BEGIN

SELECT NVL(SUM(NVL(acctd_amount_applied_from,0)),0) INTO NVAL FROM (
select BILL_TO_CUSTOMER_ID customer_id,(SELECT CUSTOMER_NAME FROM ar_CUSTOMERS WHERE CUSTOMER_ID=PAY_FROM_CUSTOMER) RECEIPT_CUSTOMER
,RECEIPT_NUMBER,t.trx_number,(select sum(revenue_amount) from ra_customer_trx_lines_all
where interface_line_attribute2=t.trx_number) INVOICE_amount,
invoice_currency_code INV_CURR,t.exchange_rate INV_RATE,
amount_applied APPLY_AMT,gl_date,gl_posted_date,acctd_amount_applied_from,acctd_amount_applied_to
,acctd_amount_applied_from-acctd_amount_applied_to "Gain/Loss" from
AR_RECEIVABLE_APPLICATIONS_all a,
ar_cash_receipts_all c,
ra_customer_trx_all t
WHERE a.cash_receipt_id=c.cash_receipt_id
and t.CUSTOMER_TRX_ID=APPLIED_CUSTOMER_TRX_ID
--AND T.TRX_NUMBER = 'I09252600170'
 anD APPLIED_CUSTOMER_TRX_ID IN (
                                                        select CUSTOMER_TRX_ID from ra_customer_trx_all
                                                        where  BILL_TO_CUSTOMER_ID=p_customer_id2
                                                        )
and gl_date<p_start_date
AND DISPLAY='Y'
AND PAY_FROM_CUSTOMER<>p_customer_id2
union all
select BILL_TO_CUSTOMER_ID customer_id,(SELECT CUSTOMER_NAME FROM ar_CUSTOMERS WHERE CUSTOMER_ID=BILL_TO_CUSTOMER_ID) RECEIPT_CUSTOMER
,RECEIPT_NUMBER,t.trx_number,(select sum(revenue_amount) from ra_customer_trx_lines_all
where interface_line_attribute2=t.trx_number) INVOICE_amount,
invoice_currency_code INV_CURR,t.exchange_rate INV_RATE,
amount_applied APPLY_AMT,gl_date,gl_posted_date,acctd_amount_applied_from*-1,acctd_amount_applied_to
,acctd_amount_applied_from-acctd_amount_applied_to "Gain/Loss" from
AR_RECEIVABLE_APPLICATIONS_all a,
ar_cash_receipts_all c,
ra_customer_trx_all t
WHERE a.cash_receipt_id=c.cash_receipt_id
and t.CUSTOMER_TRX_ID=APPLIED_CUSTOMER_TRX_ID
--AND T.TRX_NUMBER = 'I09252600170'
 anD APPLIED_CUSTOMER_TRX_ID not IN (
                                                                select CUSTOMER_TRX_ID from ra_customer_trx_all
                                                                where  BILL_TO_CUSTOMER_ID=p_customer_id2
                                                                )
and gl_date<p_start_date
AND DISPLAY='Y'
AND PAY_FROM_CUSTOMER=p_customer_id2
);

RETURN(NVL(NVAL,0));
END TI_CUSTOMER_BAL_ADJUST1;
/
"
