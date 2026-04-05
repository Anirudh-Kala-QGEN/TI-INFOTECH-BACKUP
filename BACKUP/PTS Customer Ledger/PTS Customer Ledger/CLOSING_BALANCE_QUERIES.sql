-- CLOSING RELATED QUERY

SELECT 
 ( Select
	   sum((b.amount))
  From
       ra_customer_trx_all               A,
       ar_payment_schedules_all          C,
       ra_cust_trx_line_gl_dist_all      B
Where
  	   a.bill_to_customer_id         = :customer_id2
--AND    trunc(a.trx_date)            <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND    trunc(c.gl_date)             <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND    (a.invoice_currency_code       = :curr_code1 OR :curr_code1 IS NULL)
AND    a.complete_flag               = 'Y'
AND    b.customer_trx_id             = a.customer_trx_id
AND    b.account_class               = 'REC'
AND    b.LATEST_REC_FLAG             = 'Y'
AND    A.customer_trx_id             = C.customer_trx_id
AND    C.class In('CM')
AND    a.CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND    a.org_id                      =:p_org_id
AND    A.SET_OF_BOOKS_ID 				     = NVL(:P_SOB_ID,A.SET_OF_BOOKS_ID)
AND    c.payment_schedule_id
IN
 (SELECT MIN(PAYMENT_SCHEDULE_ID)
  FROM AR_PAYMENT_SCHEDULES_ALL
  WHERE CUSTOMER_TRX_ID = C.CUSTOMER_TRX_ID
 ))       v_cre_memo_amt
, ( Select
	   sum((b.amount) * NVL(A.exchange_rate,1))
  From
       ra_customer_trx_all               A,
       ar_payment_schedules_all          C,
       ra_cust_trx_line_gl_dist_all      B
Where
  	   a.bill_to_customer_id         = :customer_id2
--AND    trunc(a.trx_date)            <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND    trunc(c.gl_date)             <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND    (a.invoice_currency_code       = :curr_code1 OR :curr_code1 IS NULL)
AND    a.complete_flag               = 'Y'
AND    b.customer_trx_id             = a.customer_trx_id
AND    b.account_class               = 'REC'
AND    b.LATEST_REC_FLAG             = 'Y'
AND    A.customer_trx_id             = C.customer_trx_id
AND    C.class In('CM')
AND    a.CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND    a.org_id                      =:p_org_id
AND    A.SET_OF_BOOKS_ID 				     = NVL(:P_SOB_ID,A.SET_OF_BOOKS_ID)
AND    c.payment_schedule_id
IN
 (SELECT MIN(PAYMENT_SCHEDULE_ID)
  FROM AR_PAYMENT_SCHEDULES_ALL
  WHERE CUSTOMER_TRX_ID = C.CUSTOMER_TRX_ID
 ))   v_cre_memo_func_amt
 , (
Select
	    sum((b.amount)) 
From
        ra_customer_trx_all              A,
        ar_payment_schedules_all         C,
        ra_cust_trx_line_gl_dist_all     B
Where
    	a.bill_to_customer_id        = :customer_id2
--AND 	trunc(a.trx_date)           <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND 	trunc(c.gl_date)            <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND 	(a.invoice_currency_code      = :curr_code1 OR :curr_code1 IS NULL)
AND 	a.complete_flag              = 'Y'
AND 	b.customer_trx_id            = a.customer_trx_id
AND 	b.account_class              = 'REC'
AND     b.LATEST_REC_FLAG            = 'Y'
AND    A.CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND     A.customer_trx_id            = C.customer_trx_id
AND     C.class                     In ('INV','DM','DEP')
AND     a.org_id                     = :p_org_id
AND     A.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,A.SET_OF_BOOKS_ID)
AND     c.Payment_schedule_id
IN     (SELECT  MIN(PAYMENT_SCHEDULE_ID)
        FROM    AR_PAYMENT_SCHEDULES_ALL
	    WHERE   CUSTOMER_TRX_ID = C.CUSTOMER_TRX_ID
	   ) ) v_tr_dr_amt
,(
Select
	    sum((b.amount) * NVL(A.exchange_rate,1))
From
        ra_customer_trx_all              A,
        ar_payment_schedules_all         C,
        ra_cust_trx_line_gl_dist_all     B
Where
    	a.bill_to_customer_id        = :customer_id2
--AND 	trunc(a.trx_date)           <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND 	trunc(c.gl_date)            <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND 	(a.invoice_currency_code      = :curr_code1 OR :curr_code1 IS NULL)
AND 	a.complete_flag              = 'Y'
AND 	b.customer_trx_id            = a.customer_trx_id
AND 	b.account_class              = 'REC'
AND     b.LATEST_REC_FLAG            = 'Y'
AND    A.CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND     A.customer_trx_id            = C.customer_trx_id
AND     C.class                     In ('INV','DM','DEP')
AND     a.org_id                     = :p_org_id
AND     A.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,A.SET_OF_BOOKS_ID)
AND     c.Payment_schedule_id
IN     (SELECT  MIN(PAYMENT_SCHEDULE_ID)
        FROM    AR_PAYMENT_SCHEDULES_ALL
	    WHERE   CUSTOMER_TRX_ID = C.CUSTOMER_TRX_ID
	   ) ) v_func_dr_amt
, (SELECT
	    sum((b.amount))
FROM
        ar_customers                     a,
        ar_adjustments_all               b,
        ra_customer_trx_all              c,
        ar_payment_schedules_all         d,
        gl_code_combinations             e
WHERE
	    a.customer_id                =  :customer_id2
AND 	b.customer_trx_id            = c.customer_trx_id
and     e.code_combination_id        = b.code_combination_id
AND 	c.bill_to_customer_id        = a.customer_id
--AND 	trunc(b.apply_date)         <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND 	trunc(b.gl_date)            <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND     (c.invoice_currency_code      = :curr_code1 OR :curr_code1 IS NULL)
AND 	b.status                     = 'A'
AND	    b.customer_trx_id            = d.customer_trx_id
AND    c.CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND     c.org_id                     =:p_org_id
AND     B.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,B.SET_OF_BOOKS_ID)
and     d.payment_schedule_id
IN      (SELECT MIN(PAYMENT_SCHEDULE_ID)
         FROM   AR_PAYMENT_SCHEDULES_ALL
	     WHERE  CUSTOMER_TRX_ID = d.CUSTOMER_TRX_ID
	    )) v_tr_adj_amt
, (SELECT
	    sum((b.amount) * NVL(C.exchange_rate,1))
FROM
        ar_customers                     a,
        ar_adjustments_all               b,
        ra_customer_trx_all              c,
        ar_payment_schedules_all         d,
        gl_code_combinations             e
WHERE
	    a.customer_id                =  :customer_id2
AND 	b.customer_trx_id            = c.customer_trx_id
and     e.code_combination_id        = b.code_combination_id
AND 	c.bill_to_customer_id        = a.customer_id
--AND 	trunc(b.apply_date)         <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND 	trunc(b.gl_date)            <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND     (c.invoice_currency_code      = :curr_code1 OR :curr_code1 IS NULL)
AND 	b.status                     = 'A'
AND	    b.customer_trx_id            = d.customer_trx_id
AND    c.CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND     c.org_id                     =:p_org_id
AND     B.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,B.SET_OF_BOOKS_ID)
and     d.payment_schedule_id
IN      (SELECT MIN(PAYMENT_SCHEDULE_ID)
         FROM   AR_PAYMENT_SCHEDULES_ALL
	     WHERE  CUSTOMER_TRX_ID = d.CUSTOMER_TRX_ID
	    )) v_func_adj_amt
, (Select
	    sum(a.amount)        
From
	    ar_cash_receipts_all             A
Where
     		a.pay_from_customer          = :customer_id2
AND 		(a.currency_code             = :curr_code1 OR :curr_code1 IS NULL)
AND     a.org_id                     =:p_org_id
AND     A.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,A.SET_OF_BOOKS_ID)
--Added the below by Sanjikum for Bug #3962497
AND 		EXISTS (	SELECT	1 
									FROM 		ar_cash_receipt_history_all
									WHERE		cash_receipt_id = a.cash_receipt_id
									AND  		org_id = :p_org_id
									AND 		trunc(gl_date) <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
							 )) v_tr_cr_amt
,
 (Select
	   sum(a.amount * NVL(a.exchange_rate,1.00)) sum_amount_exchange
From
	    ar_cash_receipts_all             A
Where
     		a.pay_from_customer          = :customer_id2
AND 		(a.currency_code             = :curr_code1 OR :curr_code1 IS NULL)
AND     a.org_id                     =:p_org_id
AND     A.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,A.SET_OF_BOOKS_ID)
--Added the below by Sanjikum for Bug #3962497
AND 		EXISTS (	SELECT	1 
									FROM 		ar_cash_receipt_history_all
									WHERE		cash_receipt_id = a.cash_receipt_id
									AND  		org_id = :p_org_id
									AND 		trunc(gl_date) <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
							 ))  v_func_cr_amt
, (Select
	     sum(a.amount * NVL(a.exchange_rate,1.00)) sum_amount_exchange -- a. added by ssumaith
From
	     ar_cash_receipts_all            A,
	     ar_cash_receipt_history_all     b -- added by sriram - 3328962
Where
         a.cash_receipt_id           = b.cash_receipt_id
AND    	 a.pay_from_customer         = :customer_id2
AND	     trunc(b.gl_date)           <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND      a.reversal_date               is not null
AND 	  ( a.currency_code             = :curr_code1 OR :curr_code1 IS NULL)
--AND      b.current_record_flag        = 'Y' --Commented by Sanjikum for Bug #3962497
AND 	 	 b.status                      = 'REVERSED' --Added by Sanjikum for Bug #3962497
AND      a.org_id                    = :p_org_id
AND     A.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,A.SET_OF_BOOKS_ID))v_tr_rev_amt
, (Select
	     sum(a.amount * NVL(a.exchange_rate,1.00)) sum_amount_exchange -- a. added by ssumaith
From
	     ar_cash_receipts_all            A,
	     ar_cash_receipt_history_all     b -- added by sriram - 3328962
Where
         a.cash_receipt_id           = b.cash_receipt_id
AND    	 a.pay_from_customer         = :customer_id2
AND	     trunc(b.gl_date)           <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND      a.reversal_date               is not null
AND 	  ( a.currency_code = :curr_code1 OR :curr_code1 IS NULL)
--AND      b.current_record_flag        = 'Y' --Commented by Sanjikum for Bug #3962497
AND 	 	 b.status                      = 'REVERSED' --Added by Sanjikum for Bug #3962497
AND      a.org_id                    = :p_org_id
AND     A.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,A.SET_OF_BOOKS_ID)) v_func_rev_amt
, (Select
         nvl(sum(abs(NVL(d.EARNED_discount_taken,0))),0)                  
From
	     ar_customers                    a,
	     ra_customer_trx_ALL             B,
	     ar_receivable_applications_all  D
Where
		 a.customer_id               =  :customer_id2
AND	     b.bill_to_customer_id       =  a.customer_id
AND	     b.complete_flag             =  'Y'
AND      trunc(d.GL_DATE)           <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND      d.applied_customer_trx_id   = b.customer_trx_id
AND    b.CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND      (b.invoice_currency_code     = :curr_code1 OR :curr_code1 IS NULL)
AND      B.org_id                    =:p_org_id
AND      D.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,D.SET_OF_BOOKS_ID)
AND      d.earned_discount_taken is not null
and      d.earned_discount_taken <> 0 
and      d.application_type = 'CASH' 
and      d.display = 'Y') v_tr_disc_cr_amt
, (Select
 	     nvl(sum(abs(NVL(d.ACCTD_EARNED_DISCOUNT_TAKEN,0))),0)  sum_amount_exchange
From
	     ar_customers                    a,
	     ra_customer_trx_ALL             B,
	     ar_receivable_applications_all  D
Where
		 a.customer_id               =  :customer_id2
AND	     b.bill_to_customer_id       =  a.customer_id
AND	     b.complete_flag             =  'Y'
AND      trunc(d.GL_DATE)           <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND      d.applied_customer_trx_id   = b.customer_trx_id
AND    b.CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND      (b.invoice_currency_code  = :curr_code1 OR :curr_code1 IS NULL)
AND      B.org_id                    =:p_org_id
AND      D.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,D.SET_OF_BOOKS_ID)
AND      d.earned_discount_taken is not null
and      d.earned_discount_taken <> 0 
and      d.application_type = 'CASH' 
and      d.display = 'Y')  v_func_disc_cr_amt
, (SELECT
        sum(e.amount_cr)        
FROM
        ar_customers                     a ,
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
AND     b.org_id                     = :p_org_id
AND     D.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,D.SET_OF_BOOKS_ID)
AND     e.source_Type IN ('EXCH_LOSS', 'EXCH_GAIN' )
AND     (b.invoice_currency_code      = :curr_code1 OR :curr_code1 IS NULL)
AND     a.customer_id                = :customer_id2
--AND     TRUNC(c.receipt_date)       <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND     TRUNC(d.gl_date)            <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) ) v_tran_loss_amt
, (SELECT sum(e.acctd_amount_cr)       sum_exchange_amount
FROM
        ar_customers                     a ,
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
AND     b.org_id                     = :p_org_id
AND     D.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,D.SET_OF_BOOKS_ID)
AND     e.source_Type IN ('EXCH_LOSS', 'EXCH_GAIN' )
AND     (b.invoice_currency_code      = :curr_code1 OR :curr_code1 IS NULL)
AND     a.customer_id                = :customer_id2
--AND     TRUNC(c.receipt_date)       <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND     TRUNC(d.gl_date)            <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) ) v_func_loss_amt
, (SELECT
        sum(e.amount_dr)             sum_amount 
FROM
        ar_customers                     a ,
        ra_customer_trx_all              b ,
        ar_cash_receipts_all             c ,
        ar_receivable_applications_all   d ,
        ar_distributions_all             e
WHERE
        a.customer_id                = b.BILL_TO_CUSTOMER_ID
AND     b.customer_trx_id            = d.APPLIED_CUSTOMER_TRX_ID
AND     c.cash_receipt_id            = d.cash_receipt_id
AND     e.SOURCE_ID                  = d.receivable_application_id
AND     b.org_id                     = :p_org_id
AND    b.CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND     B.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,B.SET_OF_BOOKS_ID)
AND    ( b.invoice_currency_code      = :curr_code1 OR :curr_code1 IS NULL)
AND     a.customer_id                =:customer_id2
--AND     TRUNC(c.receipt_date)       <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND     TRUNC(d.gl_date)            <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND     e.source_Type IN ('EXCH_GAIN','EXCH_LOSS' ))  v_tran_gain_amt
, (SELECT
        sum(e.acctd_amount_dr)       sum_exchange_amount
FROM
        ar_customers                     a ,
        ra_customer_trx_all              b ,
        ar_cash_receipts_all             c ,
        ar_receivable_applications_all   d ,
        ar_distributions_all             e
WHERE
        a.customer_id                = b.BILL_TO_CUSTOMER_ID
AND     b.customer_trx_id            = d.APPLIED_CUSTOMER_TRX_ID
AND     c.cash_receipt_id            = d.cash_receipt_id
AND     e.SOURCE_ID                  = d.receivable_application_id
AND     b.org_id                     = :p_org_id
AND    b.CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND     B.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,B.SET_OF_BOOKS_ID)
AND     (b.invoice_currency_code      = :curr_code1 OR :curr_code1 IS NULL)
AND     a.customer_id                =:customer_id2
--AND     TRUNC(c.receipt_date)       <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND     TRUNC(d.gl_date)            <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND     e.source_Type IN ('EXCH_GAIN','EXCH_LOSS' )) v_func_gain_amt
, (Select
	    sum(c.amount_applied)
From
	    ar_cash_receipts_all             A,
        ar_cash_receipt_history_all      B,
        ar_receivable_applications_all   c
Where
     	a.pay_from_customer          = :customer_id2
AND	    trunc(b.gl_date)              <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND     a.cash_receipt_id              = b.cash_receipt_id
and     a.cash_receipt_id              = c .cash_receipt_id
and     c.cash_receipt_history_id      = b.cash_receipt_history_id
and     c.applied_payment_schedule_id  = -3
and     c.status                       = 'ACTIVITY'
AND     (a.currency_code                = :curr_code1 OR :curr_code1 IS NULL)
AND    c.applied_CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
--- AND     B.REVERSAL_GL_DATE IS NULL ---commented by mohinder paul singh
AND     b.current_record_flag          = 'Y'
AND     a.org_id                       =:p_org_id
AND     A.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,A.SET_OF_BOOKS_ID)
and     not exists
 ( select 1
   from   ar_cash_receipt_history_all
   where  cash_receipt_id = b.cash_receipt_id
   and    status          = 'REVERSED'
 )) v_tran_rcp_w_off
, ((Select
	    sum(c.amount_applied * NVL(a.exchange_rate,1.00)) sum_amount_exchange
From
	    ar_cash_receipts_all             A,
        ar_cash_receipt_history_all      B,
        ar_receivable_applications_all   c
Where
     	a.pay_from_customer          = :customer_id2
AND	    trunc(b.gl_date)              <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND     a.cash_receipt_id              = b.cash_receipt_id
and     a.cash_receipt_id              = c .cash_receipt_id
and     c.cash_receipt_history_id      = b.cash_receipt_history_id
and     c.applied_payment_schedule_id  = -3
and     c.status                       = 'ACTIVITY'
AND     (a.currency_code               = :curr_code1 OR :curr_code1 IS NULL)
AND    c.applied_CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
--- AND     B.REVERSAL_GL_DATE IS NULL ---commented by mohinder paul singh
AND     b.current_record_flag          = 'Y'
AND     a.org_id                       =:p_org_id
AND     A.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,A.SET_OF_BOOKS_ID)
and     not exists
 ( select 1
   from   ar_cash_receipt_history_all
   where  cash_receipt_id = b.cash_receipt_id
   and    status          = 'REVERSED'
 ))) v_func_rcp_w_off
FROM DUAL

-- STEP 2
SELECT
(  (NVL(v_func_dr_amt,0)
                     + nvl(v_cre_memo_func_amt,0)
                     + NVL(v_func_rev_amt,0))
                     - NVL(v_func_cr_amt,0)
                     + nvl(v_func_rcp_w_off,0)
                     + (NVL(v_func_adj_amt,0))
                     - NVL(v_func_disc_cr_amt,0)
                     - NVL(v_func_gain_amt,0)
                     + NVL(v_func_loss_amt,0)  ) v_func_tot_amt
,  ( (NVL(v_tr_dr_amt,0))
                    + nvl(v_cre_memo_amt,0)
                    +(NVL(v_tr_rev_amt,0))
                    - NVL(v_tr_cr_amt,0)
                    + nvl(v_tran_rcp_w_off,0)
                    - abs(NVL(v_tr_adj_amt,0))
                    - NVL(v_tr_disc_cr_amt,0) ) v_tran_tot_amt
, TBL_BASE.*
FROM 
(
SELECT 
 ( Select
	   sum((b.amount))
  From
       ra_customer_trx_all               A,
       ar_payment_schedules_all          C,
       ra_cust_trx_line_gl_dist_all      B
Where
  	   a.bill_to_customer_id         = :customer_id2
--AND    trunc(a.trx_date)            <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND    trunc(c.gl_date)             <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND    (a.invoice_currency_code       = :curr_code1 OR :curr_code1 IS NULL)
AND    a.complete_flag               = 'Y'
AND    b.customer_trx_id             = a.customer_trx_id
AND    b.account_class               = 'REC'
AND    b.LATEST_REC_FLAG             = 'Y'
AND    A.customer_trx_id             = C.customer_trx_id
AND    C.class In('CM')
AND    a.CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND    a.org_id                      =:p_org_id
AND    A.SET_OF_BOOKS_ID 				     = NVL(:P_SOB_ID,A.SET_OF_BOOKS_ID)
AND    c.payment_schedule_id
IN
 (SELECT MIN(PAYMENT_SCHEDULE_ID)
  FROM AR_PAYMENT_SCHEDULES_ALL
  WHERE CUSTOMER_TRX_ID = C.CUSTOMER_TRX_ID
 ))       v_cre_memo_amt
, ( Select
	   sum((b.amount) * NVL(A.exchange_rate,1))
  From
       ra_customer_trx_all               A,
       ar_payment_schedules_all          C,
       ra_cust_trx_line_gl_dist_all      B
Where
  	   a.bill_to_customer_id         = :customer_id2
--AND    trunc(a.trx_date)            <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND    trunc(c.gl_date)             <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND    (a.invoice_currency_code       = :curr_code1 OR :curr_code1 IS NULL)
AND    a.complete_flag               = 'Y'
AND    b.customer_trx_id             = a.customer_trx_id
AND    b.account_class               = 'REC'
AND    b.LATEST_REC_FLAG             = 'Y'
AND    A.customer_trx_id             = C.customer_trx_id
AND    C.class In('CM')
AND    a.CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND    a.org_id                      =:p_org_id
AND    A.SET_OF_BOOKS_ID 				     = NVL(:P_SOB_ID,A.SET_OF_BOOKS_ID)
AND    c.payment_schedule_id
IN
 (SELECT MIN(PAYMENT_SCHEDULE_ID)
  FROM AR_PAYMENT_SCHEDULES_ALL
  WHERE CUSTOMER_TRX_ID = C.CUSTOMER_TRX_ID
 ))   v_cre_memo_func_amt
 , (
Select
	    sum((b.amount)) 
From
        ra_customer_trx_all              A,
        ar_payment_schedules_all         C,
        ra_cust_trx_line_gl_dist_all     B
Where
    	a.bill_to_customer_id        = :customer_id2
--AND 	trunc(a.trx_date)           <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND 	trunc(c.gl_date)            <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND 	(a.invoice_currency_code      = :curr_code1 OR :curr_code1 IS NULL)
AND 	a.complete_flag              = 'Y'
AND 	b.customer_trx_id            = a.customer_trx_id
AND 	b.account_class              = 'REC'
AND     b.LATEST_REC_FLAG            = 'Y'
AND    A.CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND     A.customer_trx_id            = C.customer_trx_id
AND     C.class                     In ('INV','DM','DEP')
AND     a.org_id                     = :p_org_id
AND     A.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,A.SET_OF_BOOKS_ID)
AND     c.Payment_schedule_id
IN     (SELECT  MIN(PAYMENT_SCHEDULE_ID)
        FROM    AR_PAYMENT_SCHEDULES_ALL
	    WHERE   CUSTOMER_TRX_ID = C.CUSTOMER_TRX_ID
	   ) ) v_tr_dr_amt
,(
Select
	    sum((b.amount) * NVL(A.exchange_rate,1))
From
        ra_customer_trx_all              A,
        ar_payment_schedules_all         C,
        ra_cust_trx_line_gl_dist_all     B
Where
    	a.bill_to_customer_id        = :customer_id2
--AND 	trunc(a.trx_date)           <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND 	trunc(c.gl_date)            <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND 	(a.invoice_currency_code      = :curr_code1 OR :curr_code1 IS NULL)
AND 	a.complete_flag              = 'Y'
AND 	b.customer_trx_id            = a.customer_trx_id
AND 	b.account_class              = 'REC'
AND     b.LATEST_REC_FLAG            = 'Y'
AND    A.CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND     A.customer_trx_id            = C.customer_trx_id
AND     C.class                     In ('INV','DM','DEP')
AND     a.org_id                     = :p_org_id
AND     A.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,A.SET_OF_BOOKS_ID)
AND     c.Payment_schedule_id
IN     (SELECT  MIN(PAYMENT_SCHEDULE_ID)
        FROM    AR_PAYMENT_SCHEDULES_ALL
	    WHERE   CUSTOMER_TRX_ID = C.CUSTOMER_TRX_ID
	   ) ) v_func_dr_amt
, (SELECT
	    sum((b.amount))
FROM
        ar_customers                     a,
        ar_adjustments_all               b,
        ra_customer_trx_all              c,
        ar_payment_schedules_all         d,
        gl_code_combinations             e
WHERE
	    a.customer_id                =  :customer_id2
AND 	b.customer_trx_id            = c.customer_trx_id
and     e.code_combination_id        = b.code_combination_id
AND 	c.bill_to_customer_id        = a.customer_id
--AND 	trunc(b.apply_date)         <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND 	trunc(b.gl_date)            <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND     (c.invoice_currency_code      = :curr_code1 OR :curr_code1 IS NULL)
AND 	b.status                     = 'A'
AND	    b.customer_trx_id            = d.customer_trx_id
AND    c.CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND     c.org_id                     =:p_org_id
AND     B.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,B.SET_OF_BOOKS_ID)
and     d.payment_schedule_id
IN      (SELECT MIN(PAYMENT_SCHEDULE_ID)
         FROM   AR_PAYMENT_SCHEDULES_ALL
	     WHERE  CUSTOMER_TRX_ID = d.CUSTOMER_TRX_ID
	    )) v_tr_adj_amt
, (SELECT
	    sum((b.amount) * NVL(C.exchange_rate,1))
FROM
        ar_customers                     a,
        ar_adjustments_all               b,
        ra_customer_trx_all              c,
        ar_payment_schedules_all         d,
        gl_code_combinations             e
WHERE
	    a.customer_id                =  :customer_id2
AND 	b.customer_trx_id            = c.customer_trx_id
and     e.code_combination_id        = b.code_combination_id
AND 	c.bill_to_customer_id        = a.customer_id
--AND 	trunc(b.apply_date)         <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND 	trunc(b.gl_date)            <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND     (c.invoice_currency_code      = :curr_code1 OR :curr_code1 IS NULL)
AND 	b.status                     = 'A'
AND	    b.customer_trx_id            = d.customer_trx_id
AND    c.CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND     c.org_id                     =:p_org_id
AND     B.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,B.SET_OF_BOOKS_ID)
and     d.payment_schedule_id
IN      (SELECT MIN(PAYMENT_SCHEDULE_ID)
         FROM   AR_PAYMENT_SCHEDULES_ALL
	     WHERE  CUSTOMER_TRX_ID = d.CUSTOMER_TRX_ID
	    )) v_func_adj_amt
, (Select
	    sum(a.amount)        
From
	    ar_cash_receipts_all             A
Where
     		a.pay_from_customer          = :customer_id2
AND 		(a.currency_code             = :curr_code1 OR :curr_code1 IS NULL)
AND     a.org_id                     =:p_org_id
AND     A.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,A.SET_OF_BOOKS_ID)
--Added the below by Sanjikum for Bug #3962497
AND 		EXISTS (	SELECT	1 
									FROM 		ar_cash_receipt_history_all
									WHERE		cash_receipt_id = a.cash_receipt_id
									AND  		org_id = :p_org_id
									AND 		trunc(gl_date) <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
							 )) v_tr_cr_amt
,
 (Select
	   sum(a.amount * NVL(a.exchange_rate,1.00)) sum_amount_exchange
From
	    ar_cash_receipts_all             A
Where
     		a.pay_from_customer          = :customer_id2
AND 		(a.currency_code             = :curr_code1 OR :curr_code1 IS NULL)
AND     a.org_id                     =:p_org_id
AND     A.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,A.SET_OF_BOOKS_ID)
--Added the below by Sanjikum for Bug #3962497
AND 		EXISTS (	SELECT	1 
									FROM 		ar_cash_receipt_history_all
									WHERE		cash_receipt_id = a.cash_receipt_id
									AND  		org_id = :p_org_id
									AND 		trunc(gl_date) <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
							 ))  v_func_cr_amt
, (Select
	     sum(a.amount * NVL(a.exchange_rate,1.00)) sum_amount_exchange -- a. added by ssumaith
From
	     ar_cash_receipts_all            A,
	     ar_cash_receipt_history_all     b -- added by sriram - 3328962
Where
         a.cash_receipt_id           = b.cash_receipt_id
AND    	 a.pay_from_customer         = :customer_id2
AND	     trunc(b.gl_date)           <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND      a.reversal_date               is not null
AND 	  ( a.currency_code             = :curr_code1 OR :curr_code1 IS NULL)
--AND      b.current_record_flag        = 'Y' --Commented by Sanjikum for Bug #3962497
AND 	 	 b.status                      = 'REVERSED' --Added by Sanjikum for Bug #3962497
AND      a.org_id                    = :p_org_id
AND     A.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,A.SET_OF_BOOKS_ID))v_tr_rev_amt
, (Select
	     sum(a.amount * NVL(a.exchange_rate,1.00)) sum_amount_exchange -- a. added by ssumaith
From
	     ar_cash_receipts_all            A,
	     ar_cash_receipt_history_all     b -- added by sriram - 3328962
Where
         a.cash_receipt_id           = b.cash_receipt_id
AND    	 a.pay_from_customer         = :customer_id2
AND	     trunc(b.gl_date)           <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND      a.reversal_date               is not null
AND 	  ( a.currency_code = :curr_code1 OR :curr_code1 IS NULL)
--AND      b.current_record_flag        = 'Y' --Commented by Sanjikum for Bug #3962497
AND 	 	 b.status                      = 'REVERSED' --Added by Sanjikum for Bug #3962497
AND      a.org_id                    = :p_org_id
AND     A.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,A.SET_OF_BOOKS_ID)) v_func_rev_amt
, (Select
         nvl(sum(abs(NVL(d.EARNED_discount_taken,0))),0)                  
From
	     ar_customers                    a,
	     ra_customer_trx_ALL             B,
	     ar_receivable_applications_all  D
Where
		 a.customer_id               =  :customer_id2
AND	     b.bill_to_customer_id       =  a.customer_id
AND	     b.complete_flag             =  'Y'
AND      trunc(d.GL_DATE)           <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND      d.applied_customer_trx_id   = b.customer_trx_id
AND    b.CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND      (b.invoice_currency_code     = :curr_code1 OR :curr_code1 IS NULL)
AND      B.org_id                    =:p_org_id
AND      D.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,D.SET_OF_BOOKS_ID)
AND      d.earned_discount_taken is not null
and      d.earned_discount_taken <> 0 
and      d.application_type = 'CASH' 
and      d.display = 'Y') v_tr_disc_cr_amt
, (Select
 	     nvl(sum(abs(NVL(d.ACCTD_EARNED_DISCOUNT_TAKEN,0))),0)  sum_amount_exchange
From
	     ar_customers                    a,
	     ra_customer_trx_ALL             B,
	     ar_receivable_applications_all  D
Where
		 a.customer_id               =  :customer_id2
AND	     b.bill_to_customer_id       =  a.customer_id
AND	     b.complete_flag             =  'Y'
AND      trunc(d.GL_DATE)           <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND      d.applied_customer_trx_id   = b.customer_trx_id
AND    b.CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND      (b.invoice_currency_code  = :curr_code1 OR :curr_code1 IS NULL)
AND      B.org_id                    =:p_org_id
AND      D.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,D.SET_OF_BOOKS_ID)
AND      d.earned_discount_taken is not null
and      d.earned_discount_taken <> 0 
and      d.application_type = 'CASH' 
and      d.display = 'Y')  v_func_disc_cr_amt
, (SELECT
        sum(e.amount_cr)        
FROM
        ar_customers                     a ,
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
AND     b.org_id                     = :p_org_id
AND     D.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,D.SET_OF_BOOKS_ID)
AND     e.source_Type IN ('EXCH_LOSS', 'EXCH_GAIN' )
AND     (b.invoice_currency_code      = :curr_code1 OR :curr_code1 IS NULL)
AND     a.customer_id                = :customer_id2
--AND     TRUNC(c.receipt_date)       <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND     TRUNC(d.gl_date)            <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) ) v_tran_loss_amt
, (SELECT sum(e.acctd_amount_cr)       sum_exchange_amount
FROM
        ar_customers                     a ,
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
AND     b.org_id                     = :p_org_id
AND     D.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,D.SET_OF_BOOKS_ID)
AND     e.source_Type IN ('EXCH_LOSS', 'EXCH_GAIN' )
AND     (b.invoice_currency_code      = :curr_code1 OR :curr_code1 IS NULL)
AND     a.customer_id                = :customer_id2
--AND     TRUNC(c.receipt_date)       <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND     TRUNC(d.gl_date)            <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) ) v_func_loss_amt
, (SELECT
        sum(e.amount_dr)             sum_amount 
FROM
        ar_customers                     a ,
        ra_customer_trx_all              b ,
        ar_cash_receipts_all             c ,
        ar_receivable_applications_all   d ,
        ar_distributions_all             e
WHERE
        a.customer_id                = b.BILL_TO_CUSTOMER_ID
AND     b.customer_trx_id            = d.APPLIED_CUSTOMER_TRX_ID
AND     c.cash_receipt_id            = d.cash_receipt_id
AND     e.SOURCE_ID                  = d.receivable_application_id
AND     b.org_id                     = :p_org_id
AND    b.CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND     B.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,B.SET_OF_BOOKS_ID)
AND    ( b.invoice_currency_code      = :curr_code1 OR :curr_code1 IS NULL)
AND     a.customer_id                =:customer_id2
--AND     TRUNC(c.receipt_date)       <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND     TRUNC(d.gl_date)            <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND     e.source_Type IN ('EXCH_GAIN','EXCH_LOSS' ))  v_tran_gain_amt
, (SELECT
        sum(e.acctd_amount_dr)       sum_exchange_amount
FROM
        ar_customers                     a ,
        ra_customer_trx_all              b ,
        ar_cash_receipts_all             c ,
        ar_receivable_applications_all   d ,
        ar_distributions_all             e
WHERE
        a.customer_id                = b.BILL_TO_CUSTOMER_ID
AND     b.customer_trx_id            = d.APPLIED_CUSTOMER_TRX_ID
AND     c.cash_receipt_id            = d.cash_receipt_id
AND     e.SOURCE_ID                  = d.receivable_application_id
AND     b.org_id                     = :p_org_id
AND    b.CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND     B.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,B.SET_OF_BOOKS_ID)
AND     (b.invoice_currency_code      = :curr_code1 OR :curr_code1 IS NULL)
AND     a.customer_id                =:customer_id2
--AND     TRUNC(c.receipt_date)       <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND     TRUNC(d.gl_date)            <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND     e.source_Type IN ('EXCH_GAIN','EXCH_LOSS' )) v_func_gain_amt
, (Select
	    sum(c.amount_applied)
From
	    ar_cash_receipts_all             A,
        ar_cash_receipt_history_all      B,
        ar_receivable_applications_all   c
Where
     	a.pay_from_customer          = :customer_id2
AND	    trunc(b.gl_date)              <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND     a.cash_receipt_id              = b.cash_receipt_id
and     a.cash_receipt_id              = c .cash_receipt_id
and     c.cash_receipt_history_id      = b.cash_receipt_history_id
and     c.applied_payment_schedule_id  = -3
and     c.status                       = 'ACTIVITY'
AND     (a.currency_code                = :curr_code1 OR :curr_code1 IS NULL)
AND    c.applied_CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
--- AND     B.REVERSAL_GL_DATE IS NULL ---commented by mohinder paul singh
AND     b.current_record_flag          = 'Y'
AND     a.org_id                       =:p_org_id
AND     A.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,A.SET_OF_BOOKS_ID)
and     not exists
 ( select 1
   from   ar_cash_receipt_history_all
   where  cash_receipt_id = b.cash_receipt_id
   and    status          = 'REVERSED'
 )) v_tran_rcp_w_off
, ((Select
	    sum(c.amount_applied * NVL(a.exchange_rate,1.00)) sum_amount_exchange
From
	    ar_cash_receipts_all             A,
        ar_cash_receipt_history_all      B,
        ar_receivable_applications_all   c
Where
     	a.pay_from_customer          = :customer_id2
AND	    trunc(b.gl_date)              <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND     a.cash_receipt_id              = b.cash_receipt_id
and     a.cash_receipt_id              = c .cash_receipt_id
and     c.cash_receipt_history_id      = b.cash_receipt_history_id
and     c.applied_payment_schedule_id  = -3
and     c.status                       = 'ACTIVITY'
AND     (a.currency_code               = :curr_code1 OR :curr_code1 IS NULL)
AND    c.applied_CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
--- AND     B.REVERSAL_GL_DATE IS NULL ---commented by mohinder paul singh
AND     b.current_record_flag          = 'Y'
AND     a.org_id                       =:p_org_id
AND     A.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,A.SET_OF_BOOKS_ID)
and     not exists
 ( select 1
   from   ar_cash_receipt_history_all
   where  cash_receipt_id = b.cash_receipt_id
   and    status          = 'REVERSED'
 ))) v_func_rcp_w_off
FROM DUAL
) TBL_BASE

-- STEP 3
SELECT CASE WHEN NVL(v_func_tot_amt,0) < 0 THEN ABS(v_func_tot_amt) ELSE 0 END func_closing_bal_cr
, CASE WHEN NVL(v_func_tot_amt,0) < 0 THEN 0 ELSE ABS(v_func_tot_amt) END func_closing_bal_dr
, CASE WHEN NVL(v_tran_tot_amt,0) < 0 THEN ABS(NVL(v_tran_tot_amt,0)) ELSE 0 END tran_closing_bal_cr
, CASE WHEN NVL(v_tran_tot_amt,0) < 0 THEN 0 ELSE (ABS(NVL(v_tran_tot_amt,0))) END TRAN_CLOSING_BAL_DR
, TBL_2.*
FROM 
(SELECT
(  (NVL(v_func_dr_amt,0)
                     + nvl(v_cre_memo_func_amt,0)
                     + NVL(v_func_rev_amt,0))
                     - NVL(v_func_cr_amt,0)
                     + nvl(v_func_rcp_w_off,0)
                     + (NVL(v_func_adj_amt,0))
                     - NVL(v_func_disc_cr_amt,0)
                     - NVL(v_func_gain_amt,0)
                     + NVL(v_func_loss_amt,0)  ) v_func_tot_amt
,  ( (NVL(v_tr_dr_amt,0))
                    + nvl(v_cre_memo_amt,0)
                    +(NVL(v_tr_rev_amt,0))
                    - NVL(v_tr_cr_amt,0)
                    + nvl(v_tran_rcp_w_off,0)
                    - abs(NVL(v_tr_adj_amt,0))
                    - NVL(v_tr_disc_cr_amt,0) ) v_tran_tot_amt
, TBL_BASE.*
FROM 
(
SELECT 
 ( Select
	   sum((b.amount))
  From
       ra_customer_trx_all               A,
       ar_payment_schedules_all          C,
       ra_cust_trx_line_gl_dist_all      B
Where
  	   a.bill_to_customer_id         = :customer_id2
--AND    trunc(a.trx_date)            <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND    trunc(c.gl_date)             <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND    (a.invoice_currency_code       = :curr_code1 OR :curr_code1 IS NULL)
AND    a.complete_flag               = 'Y'
AND    b.customer_trx_id             = a.customer_trx_id
AND    b.account_class               = 'REC'
AND    b.LATEST_REC_FLAG             = 'Y'
AND    A.customer_trx_id             = C.customer_trx_id
AND    C.class In('CM')
AND    a.CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND    a.org_id                      =:p_org_id
AND    A.SET_OF_BOOKS_ID 				     = NVL(:P_SOB_ID,A.SET_OF_BOOKS_ID)
AND    c.payment_schedule_id
IN
 (SELECT MIN(PAYMENT_SCHEDULE_ID)
  FROM AR_PAYMENT_SCHEDULES_ALL
  WHERE CUSTOMER_TRX_ID = C.CUSTOMER_TRX_ID
 ))       v_cre_memo_amt
, ( Select
	   sum((b.amount) * NVL(A.exchange_rate,1))
  From
       ra_customer_trx_all               A,
       ar_payment_schedules_all          C,
       ra_cust_trx_line_gl_dist_all      B
Where
  	   a.bill_to_customer_id         = :customer_id2
--AND    trunc(a.trx_date)            <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND    trunc(c.gl_date)             <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND    (a.invoice_currency_code       = :curr_code1 OR :curr_code1 IS NULL)
AND    a.complete_flag               = 'Y'
AND    b.customer_trx_id             = a.customer_trx_id
AND    b.account_class               = 'REC'
AND    b.LATEST_REC_FLAG             = 'Y'
AND    A.customer_trx_id             = C.customer_trx_id
AND    C.class In('CM')
AND    a.CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND    a.org_id                      =:p_org_id
AND    A.SET_OF_BOOKS_ID 				     = NVL(:P_SOB_ID,A.SET_OF_BOOKS_ID)
AND    c.payment_schedule_id
IN
 (SELECT MIN(PAYMENT_SCHEDULE_ID)
  FROM AR_PAYMENT_SCHEDULES_ALL
  WHERE CUSTOMER_TRX_ID = C.CUSTOMER_TRX_ID
 ))   v_cre_memo_func_amt
 , (
Select
	    sum((b.amount)) 
From
        ra_customer_trx_all              A,
        ar_payment_schedules_all         C,
        ra_cust_trx_line_gl_dist_all     B
Where
    	a.bill_to_customer_id        = :customer_id2
--AND 	trunc(a.trx_date)           <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND 	trunc(c.gl_date)            <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND 	(a.invoice_currency_code      = :curr_code1 OR :curr_code1 IS NULL)
AND 	a.complete_flag              = 'Y'
AND 	b.customer_trx_id            = a.customer_trx_id
AND 	b.account_class              = 'REC'
AND     b.LATEST_REC_FLAG            = 'Y'
AND    A.CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND     A.customer_trx_id            = C.customer_trx_id
AND     C.class                     In ('INV','DM','DEP')
AND     a.org_id                     = :p_org_id
AND     A.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,A.SET_OF_BOOKS_ID)
AND     c.Payment_schedule_id
IN     (SELECT  MIN(PAYMENT_SCHEDULE_ID)
        FROM    AR_PAYMENT_SCHEDULES_ALL
	    WHERE   CUSTOMER_TRX_ID = C.CUSTOMER_TRX_ID
	   ) ) v_tr_dr_amt
,(
Select
	    sum((b.amount) * NVL(A.exchange_rate,1))
From
        ra_customer_trx_all              A,
        ar_payment_schedules_all         C,
        ra_cust_trx_line_gl_dist_all     B
Where
    	a.bill_to_customer_id        = :customer_id2
--AND 	trunc(a.trx_date)           <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND 	trunc(c.gl_date)            <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND 	(a.invoice_currency_code      = :curr_code1 OR :curr_code1 IS NULL)
AND 	a.complete_flag              = 'Y'
AND 	b.customer_trx_id            = a.customer_trx_id
AND 	b.account_class              = 'REC'
AND     b.LATEST_REC_FLAG            = 'Y'
AND    A.CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND     A.customer_trx_id            = C.customer_trx_id
AND     C.class                     In ('INV','DM','DEP')
AND     a.org_id                     = :p_org_id
AND     A.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,A.SET_OF_BOOKS_ID)
AND     c.Payment_schedule_id
IN     (SELECT  MIN(PAYMENT_SCHEDULE_ID)
        FROM    AR_PAYMENT_SCHEDULES_ALL
	    WHERE   CUSTOMER_TRX_ID = C.CUSTOMER_TRX_ID
	   ) ) v_func_dr_amt
, (SELECT
	    sum((b.amount))
FROM
        ar_customers                     a,
        ar_adjustments_all               b,
        ra_customer_trx_all              c,
        ar_payment_schedules_all         d,
        gl_code_combinations             e
WHERE
	    a.customer_id                =  :customer_id2
AND 	b.customer_trx_id            = c.customer_trx_id
and     e.code_combination_id        = b.code_combination_id
AND 	c.bill_to_customer_id        = a.customer_id
--AND 	trunc(b.apply_date)         <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND 	trunc(b.gl_date)            <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND     (c.invoice_currency_code      = :curr_code1 OR :curr_code1 IS NULL)
AND 	b.status                     = 'A'
AND	    b.customer_trx_id            = d.customer_trx_id
AND    c.CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND     c.org_id                     =:p_org_id
AND     B.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,B.SET_OF_BOOKS_ID)
and     d.payment_schedule_id
IN      (SELECT MIN(PAYMENT_SCHEDULE_ID)
         FROM   AR_PAYMENT_SCHEDULES_ALL
	     WHERE  CUSTOMER_TRX_ID = d.CUSTOMER_TRX_ID
	    )) v_tr_adj_amt
, (SELECT
	    sum((b.amount) * NVL(C.exchange_rate,1))
FROM
        ar_customers                     a,
        ar_adjustments_all               b,
        ra_customer_trx_all              c,
        ar_payment_schedules_all         d,
        gl_code_combinations             e
WHERE
	    a.customer_id                =  :customer_id2
AND 	b.customer_trx_id            = c.customer_trx_id
and     e.code_combination_id        = b.code_combination_id
AND 	c.bill_to_customer_id        = a.customer_id
--AND 	trunc(b.apply_date)         <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND 	trunc(b.gl_date)            <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND     (c.invoice_currency_code      = :curr_code1 OR :curr_code1 IS NULL)
AND 	b.status                     = 'A'
AND	    b.customer_trx_id            = d.customer_trx_id
AND    c.CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND     c.org_id                     =:p_org_id
AND     B.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,B.SET_OF_BOOKS_ID)
and     d.payment_schedule_id
IN      (SELECT MIN(PAYMENT_SCHEDULE_ID)
         FROM   AR_PAYMENT_SCHEDULES_ALL
	     WHERE  CUSTOMER_TRX_ID = d.CUSTOMER_TRX_ID
	    )) v_func_adj_amt
, (Select
	    sum(a.amount)        
From
	    ar_cash_receipts_all             A
Where
     		a.pay_from_customer          = :customer_id2
AND 		(a.currency_code             = :curr_code1 OR :curr_code1 IS NULL)
AND     a.org_id                     =:p_org_id
AND     A.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,A.SET_OF_BOOKS_ID)
--Added the below by Sanjikum for Bug #3962497
AND 		EXISTS (	SELECT	1 
									FROM 		ar_cash_receipt_history_all
									WHERE		cash_receipt_id = a.cash_receipt_id
									AND  		org_id = :p_org_id
									AND 		trunc(gl_date) <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
							 )) v_tr_cr_amt
,
 (Select
	   sum(a.amount * NVL(a.exchange_rate,1.00)) sum_amount_exchange
From
	    ar_cash_receipts_all             A
Where
     		a.pay_from_customer          = :customer_id2
AND 		(a.currency_code             = :curr_code1 OR :curr_code1 IS NULL)
AND     a.org_id                     =:p_org_id
AND     A.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,A.SET_OF_BOOKS_ID)
--Added the below by Sanjikum for Bug #3962497
AND 		EXISTS (	SELECT	1 
									FROM 		ar_cash_receipt_history_all
									WHERE		cash_receipt_id = a.cash_receipt_id
									AND  		org_id = :p_org_id
									AND 		trunc(gl_date) <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
							 ))  v_func_cr_amt
, (Select
	     sum(a.amount * NVL(a.exchange_rate,1.00)) sum_amount_exchange -- a. added by ssumaith
From
	     ar_cash_receipts_all            A,
	     ar_cash_receipt_history_all     b -- added by sriram - 3328962
Where
         a.cash_receipt_id           = b.cash_receipt_id
AND    	 a.pay_from_customer         = :customer_id2
AND	     trunc(b.gl_date)           <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND      a.reversal_date               is not null
AND 	  ( a.currency_code             = :curr_code1 OR :curr_code1 IS NULL)
--AND      b.current_record_flag        = 'Y' --Commented by Sanjikum for Bug #3962497
AND 	 	 b.status                      = 'REVERSED' --Added by Sanjikum for Bug #3962497
AND      a.org_id                    = :p_org_id
AND     A.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,A.SET_OF_BOOKS_ID))v_tr_rev_amt
, (Select
	     sum(a.amount * NVL(a.exchange_rate,1.00)) sum_amount_exchange -- a. added by ssumaith
From
	     ar_cash_receipts_all            A,
	     ar_cash_receipt_history_all     b -- added by sriram - 3328962
Where
         a.cash_receipt_id           = b.cash_receipt_id
AND    	 a.pay_from_customer         = :customer_id2
AND	     trunc(b.gl_date)           <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND      a.reversal_date               is not null
AND 	  ( a.currency_code = :curr_code1 OR :curr_code1 IS NULL)
--AND      b.current_record_flag        = 'Y' --Commented by Sanjikum for Bug #3962497
AND 	 	 b.status                      = 'REVERSED' --Added by Sanjikum for Bug #3962497
AND      a.org_id                    = :p_org_id
AND     A.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,A.SET_OF_BOOKS_ID)) v_func_rev_amt
, (Select
         nvl(sum(abs(NVL(d.EARNED_discount_taken,0))),0)                  
From
	     ar_customers                    a,
	     ra_customer_trx_ALL             B,
	     ar_receivable_applications_all  D
Where
		 a.customer_id               =  :customer_id2
AND	     b.bill_to_customer_id       =  a.customer_id
AND	     b.complete_flag             =  'Y'
AND      trunc(d.GL_DATE)           <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND      d.applied_customer_trx_id   = b.customer_trx_id
AND    b.CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND      (b.invoice_currency_code     = :curr_code1 OR :curr_code1 IS NULL)
AND      B.org_id                    =:p_org_id
AND      D.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,D.SET_OF_BOOKS_ID)
AND      d.earned_discount_taken is not null
and      d.earned_discount_taken <> 0 
and      d.application_type = 'CASH' 
and      d.display = 'Y') v_tr_disc_cr_amt
, (Select
 	     nvl(sum(abs(NVL(d.ACCTD_EARNED_DISCOUNT_TAKEN,0))),0)  sum_amount_exchange
From
	     ar_customers                    a,
	     ra_customer_trx_ALL             B,
	     ar_receivable_applications_all  D
Where
		 a.customer_id               =  :customer_id2
AND	     b.bill_to_customer_id       =  a.customer_id
AND	     b.complete_flag             =  'Y'
AND      trunc(d.GL_DATE)           <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND      d.applied_customer_trx_id   = b.customer_trx_id
AND    b.CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND      (b.invoice_currency_code  = :curr_code1 OR :curr_code1 IS NULL)
AND      B.org_id                    =:p_org_id
AND      D.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,D.SET_OF_BOOKS_ID)
AND      d.earned_discount_taken is not null
and      d.earned_discount_taken <> 0 
and      d.application_type = 'CASH' 
and      d.display = 'Y')  v_func_disc_cr_amt
, (SELECT
        sum(e.amount_cr)        
FROM
        ar_customers                     a ,
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
AND     b.org_id                     = :p_org_id
AND     D.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,D.SET_OF_BOOKS_ID)
AND     e.source_Type IN ('EXCH_LOSS', 'EXCH_GAIN' )
AND     (b.invoice_currency_code      = :curr_code1 OR :curr_code1 IS NULL)
AND     a.customer_id                = :customer_id2
--AND     TRUNC(c.receipt_date)       <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND     TRUNC(d.gl_date)            <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) ) v_tran_loss_amt
, (SELECT sum(e.acctd_amount_cr)       sum_exchange_amount
FROM
        ar_customers                     a ,
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
AND     b.org_id                     = :p_org_id
AND     D.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,D.SET_OF_BOOKS_ID)
AND     e.source_Type IN ('EXCH_LOSS', 'EXCH_GAIN' )
AND     (b.invoice_currency_code      = :curr_code1 OR :curr_code1 IS NULL)
AND     a.customer_id                = :customer_id2
--AND     TRUNC(c.receipt_date)       <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND     TRUNC(d.gl_date)            <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) ) v_func_loss_amt
, (SELECT
        sum(e.amount_dr)             sum_amount 
FROM
        ar_customers                     a ,
        ra_customer_trx_all              b ,
        ar_cash_receipts_all             c ,
        ar_receivable_applications_all   d ,
        ar_distributions_all             e
WHERE
        a.customer_id                = b.BILL_TO_CUSTOMER_ID
AND     b.customer_trx_id            = d.APPLIED_CUSTOMER_TRX_ID
AND     c.cash_receipt_id            = d.cash_receipt_id
AND     e.SOURCE_ID                  = d.receivable_application_id
AND     b.org_id                     = :p_org_id
AND    b.CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND     B.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,B.SET_OF_BOOKS_ID)
AND    ( b.invoice_currency_code      = :curr_code1 OR :curr_code1 IS NULL)
AND     a.customer_id                =:customer_id2
--AND     TRUNC(c.receipt_date)       <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND     TRUNC(d.gl_date)            <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND     e.source_Type IN ('EXCH_GAIN','EXCH_LOSS' ))  v_tran_gain_amt
, (SELECT
        sum(e.acctd_amount_dr)       sum_exchange_amount
FROM
        ar_customers                     a ,
        ra_customer_trx_all              b ,
        ar_cash_receipts_all             c ,
        ar_receivable_applications_all   d ,
        ar_distributions_all             e
WHERE
        a.customer_id                = b.BILL_TO_CUSTOMER_ID
AND     b.customer_trx_id            = d.APPLIED_CUSTOMER_TRX_ID
AND     c.cash_receipt_id            = d.cash_receipt_id
AND     e.SOURCE_ID                  = d.receivable_application_id
AND     b.org_id                     = :p_org_id
AND    b.CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND     B.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,B.SET_OF_BOOKS_ID)
AND     (b.invoice_currency_code      = :curr_code1 OR :curr_code1 IS NULL)
AND     a.customer_id                =:customer_id2
--AND     TRUNC(c.receipt_date)       <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND     TRUNC(d.gl_date)            <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND     e.source_Type IN ('EXCH_GAIN','EXCH_LOSS' )) v_func_gain_amt
, (Select
	    sum(c.amount_applied)
From
	    ar_cash_receipts_all             A,
        ar_cash_receipt_history_all      B,
        ar_receivable_applications_all   c
Where
     	a.pay_from_customer          = :customer_id2
AND	    trunc(b.gl_date)              <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND     a.cash_receipt_id              = b.cash_receipt_id
and     a.cash_receipt_id              = c .cash_receipt_id
and     c.cash_receipt_history_id      = b.cash_receipt_history_id
and     c.applied_payment_schedule_id  = -3
and     c.status                       = 'ACTIVITY'
AND     (a.currency_code                = :curr_code1 OR :curr_code1 IS NULL)
AND    c.applied_CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
--- AND     B.REVERSAL_GL_DATE IS NULL ---commented by mohinder paul singh
AND     b.current_record_flag          = 'Y'
AND     a.org_id                       =:p_org_id
AND     A.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,A.SET_OF_BOOKS_ID)
and     not exists
 ( select 1
   from   ar_cash_receipt_history_all
   where  cash_receipt_id = b.cash_receipt_id
   and    status          = 'REVERSED'
 )) v_tran_rcp_w_off
, ((Select
	    sum(c.amount_applied * NVL(a.exchange_rate,1.00)) sum_amount_exchange
From
	    ar_cash_receipts_all             A,
        ar_cash_receipt_history_all      B,
        ar_receivable_applications_all   c
Where
     	a.pay_from_customer          = :customer_id2
AND	    trunc(b.gl_date)              <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND     a.cash_receipt_id              = b.cash_receipt_id
and     a.cash_receipt_id              = c .cash_receipt_id
and     c.cash_receipt_history_id      = b.cash_receipt_history_id
and     c.applied_payment_schedule_id  = -3
and     c.status                       = 'ACTIVITY'
AND     (a.currency_code               = :curr_code1 OR :curr_code1 IS NULL)
AND    c.applied_CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
--- AND     B.REVERSAL_GL_DATE IS NULL ---commented by mohinder paul singh
AND     b.current_record_flag          = 'Y'
AND     a.org_id                       =:p_org_id
AND     A.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,A.SET_OF_BOOKS_ID)
and     not exists
 ( select 1
   from   ar_cash_receipt_history_all
   where  cash_receipt_id = b.cash_receipt_id
   and    status          = 'REVERSED'
 ))) v_func_rcp_w_off
FROM DUAL
) TBL_BASE) TBL_2


-- STEP 4
SELECT 
 (SELECT NVL (SUM (NVL (acctd_amount_applied_from, 0)), 0)
   FROM (SELECT BILL_TO_CUSTOMER_ID
                    customer_id,
                (SELECT CUSTOMER_NAME
                   FROM RA_CUSTOMERS
                  WHERE CUSTOMER_ID = PAY_FROM_CUSTOMER)
                    RECEIPT_CUSTOMER,
                RECEIPT_NUMBER,
                t.trx_number,
                (SELECT SUM (revenue_amount)
                   FROM ra_customer_trx_lines_all
                  WHERE interface_line_attribute2 = t.trx_number)
                    INVOICE_amount,
                invoice_currency_code
                    INV_CURR,
                t.exchange_rate
                    INV_RATE,
                amount_applied
                    APPLY_AMT,
                gl_date,
                gl_posted_date,
                NVL (acctd_amount_applied_from, 0)
                    acctd_amount_applied_from,
                acctd_amount_applied_to,
                acctd_amount_applied_from - acctd_amount_applied_to
                    "Gain/Loss"
           FROM AR_RECEIVABLE_APPLICATIONS_all  a,
                ar_cash_receipts_all            c,
                ra_customer_trx_all             t
          WHERE     a.cash_receipt_id = c.cash_receipt_id
                AND INVOICE_CURRENCY_CODE = :curr_code
                AND t.CUSTOMER_TRX_ID = APPLIED_CUSTOMER_TRX_ID
                AND APPLIED_CUSTOMER_TRX_ID IN
                        (SELECT CUSTOMER_TRX_ID
                           FROM ra_customer_trx_all
                          WHERE BILL_TO_CUSTOMER_ID = :p_customer_id2)
                AND gl_date <= :p_end_date_R
                AND DISPLAY = 'Y'
                AND PAY_FROM_CUSTOMER <> :p_customer_id2
         UNION ALL
         SELECT BILL_TO_CUSTOMER_ID
                    customer_id,
                (SELECT CUSTOMER_NAME
                   FROM AR_CUSTOMERS
                  WHERE CUSTOMER_ID = BILL_TO_CUSTOMER_ID)
                    RECEIPT_CUSTOMER,
                RECEIPT_NUMBER,
                t.trx_number,
                (SELECT SUM (revenue_amount)
                   FROM ra_customer_trx_lines_all
                  WHERE interface_line_attribute2 = t.trx_number)
                    INVOICE_amount,
                invoice_currency_code
                    INV_CURR,
                t.exchange_rate
                    INV_RATE,
                amount_applied
                    APPLY_AMT,
                gl_date,
                gl_posted_date,
                NVL (acctd_amount_applied_from * -1, 0),
                acctd_amount_applied_to,
                acctd_amount_applied_from - acctd_amount_applied_to
                    "Gain/Loss"
           FROM AR_RECEIVABLE_APPLICATIONS_all  a,
                ar_cash_receipts_all            c,
                ra_customer_trx_all             t
          WHERE     a.cash_receipt_id = c.cash_receipt_id
                AND INVOICE_CURRENCY_CODE = :curr_code
                AND t.CUSTOMER_TRX_ID = APPLIED_CUSTOMER_TRX_ID
                AND APPLIED_CUSTOMER_TRX_ID NOT IN
                        (SELECT CUSTOMER_TRX_ID
                           FROM ra_customer_trx_all
                          WHERE BILL_TO_CUSTOMER_ID = :p_customer_id2)
                AND gl_date <= :p_end_date_R
                AND DISPLAY = 'Y'
                AND PAY_FROM_CUSTOMER = :p_customer_id2
         UNION ALL
         SELECT PAY_FROM_CUSTOMER,
                NULL,
                RECEIPT_NUMBER,
                RECEIPT_NUMBER,
                NVL (H.FACTOR_DISCOUNT_AMOUNT, 0),
                C.CURRENCY_CODE,
                C.EXCHANGE_RATE,
                NULL,
                NULL,
                NULL,
                NVL (
                      NVL (H.FACTOR_DISCOUNT_AMOUNT, 0)
                    * NVL (C.EXCHANGE_RATE, 1)
                    * -1,
                    0)    acctd_amount_applied_from,
                NULL,
                NULL
           FROM ar_cash_receipt_history_all H, ar_cash_receipts_all C
          WHERE     C.cash_receipt_id IN
                        (SELECT cash_receipt_id
                           FROM ar_cash_receipts_all
                          WHERE RECEIPT_date <= :p_end_date_R)
                AND C.CURRENCY_CODE = :curr_code
                AND gl_date > :p_end_date_R
                AND C.cash_receipt_id = H.cash_receipt_id
                AND PAY_FROM_CUSTOMER = :p_customer_id2
                AND PAY_FROM_CUSTOMER <> '7730'
                AND CURRENT_RECORD_FLAG = 'Y')) 
				CF_APPLIEF_FROM_func
, (SELECT SUM (acctd_amount_applied_from)
   FROM (SELECT BILL_TO_CUSTOMER_ID
                    customer_id,
                (SELECT CUSTOMER_NAME
                   FROM AR_CUSTOMERS
                  WHERE CUSTOMER_ID = PAY_FROM_CUSTOMER)
                    RECEIPT_CUSTOMER,
                RECEIPT_NUMBER,
                t.trx_number,
                (SELECT SUM (revenue_amount)
                   FROM ra_customer_trx_lines_all
                  WHERE interface_line_attribute2 = t.trx_number)
                    INVOICE_amount,
                invoice_currency_code
                    INV_CURR,
                t.exchange_rate
                    INV_RATE,
                amount_applied
                    APPLY_AMT,
                gl_date,
                gl_posted_date,
                acctd_amount_applied_from,
                acctd_amount_applied_to,
                acctd_amount_applied_from - acctd_amount_applied_to
                    "Gain/Loss",
                'A'
                    source
           FROM AR_RECEIVABLE_APPLICATIONS_all  a,
                ar_cash_receipts_all            c,
                ra_customer_trx_all             t
          WHERE     a.cash_receipt_id = c.cash_receipt_id
                AND invoice_currency_code = :CURR_CODE
                AND t.CUSTOMER_TRX_ID = APPLIED_CUSTOMER_TRX_ID
                AND A.SET_OF_BOOKS_ID = NVL ( :P_SOB_ID, A.SET_OF_BOOKS_ID)
                AND APPLIED_CUSTOMER_TRX_ID IN
                        (SELECT CUSTOMER_TRX_ID
                           FROM ra_customer_trx_all
                          WHERE     BILL_TO_CUSTOMER_ID = :p_customer_id2
                                AND SET_OF_BOOKS_ID =
                                    NVL ( :P_SOB_ID, SET_OF_BOOKS_ID))
                AND gl_date <= :p_end_date_R
                AND DISPLAY = 'Y'
                AND PAY_FROM_CUSTOMER <> :p_customer_id2
         UNION ALL
         SELECT BILL_TO_CUSTOMER_ID
                    customer_id,
                (SELECT CUSTOMER_NAME
                   FROM AR_CUSTOMERS
                  WHERE CUSTOMER_ID = BILL_TO_CUSTOMER_ID)
                    RECEIPT_CUSTOMER,
                RECEIPT_NUMBER,
                t.trx_number,
                (SELECT SUM (revenue_amount)
                   FROM ra_customer_trx_lines_all
                  WHERE interface_line_attribute2 = t.trx_number)
                    INVOICE_amount,
                invoice_currency_code
                    INV_CURR,
                t.exchange_rate
                    INV_RATE,
                amount_applied
                    APPLY_AMT,
                gl_date,
                gl_posted_date,
                acctd_amount_applied_from * -1,
                acctd_amount_applied_to,
                acctd_amount_applied_from - acctd_amount_applied_to
                    "Gain/Loss",
                'B'
                    source
           FROM AR_RECEIVABLE_APPLICATIONS_all  a,
                ar_cash_receipts_all            c,
                ra_customer_trx_all             t
          WHERE     a.cash_receipt_id = c.cash_receipt_id
                AND invoice_currency_code = :CURR_CODE
                AND t.CUSTOMER_TRX_ID = APPLIED_CUSTOMER_TRX_ID
                AND A.SET_OF_BOOKS_ID = NVL ( :P_SOB_ID, A.SET_OF_BOOKS_ID)
                AND APPLIED_CUSTOMER_TRX_ID NOT IN
                        (SELECT CUSTOMER_TRX_ID
                           FROM ra_customer_trx_all
                          WHERE     BILL_TO_CUSTOMER_ID = :p_customer_id2
                                AND SET_OF_BOOKS_ID =
                                    NVL ( :P_SOB_ID, SET_OF_BOOKS_ID))))
				CS_SUM_APPLIED_OTHERS
, TBL_4.*
FROM
(SELECT 
SUM(FUNC_CLOSING_BAL_DR) FUNC_CL_BAL_DR
, SUM(FUNC_CLOSING_BAL_CR) FUNC_CL_BAL_CR
FROM 
(SELECT CASE WHEN NVL(v_func_tot_amt,0) < 0 THEN ABS(v_func_tot_amt) ELSE 0 END func_closing_bal_cr
, CASE WHEN NVL(v_func_tot_amt,0) < 0 THEN 0 ELSE ABS(v_func_tot_amt) END func_closing_bal_dr
, CASE WHEN NVL(v_tran_tot_amt,0) < 0 THEN ABS(NVL(v_tran_tot_amt,0)) ELSE 0 END tran_closing_bal_cr
, CASE WHEN NVL(v_tran_tot_amt,0) < 0 THEN 0 ELSE (ABS(NVL(v_tran_tot_amt,0))) END TRAN_CLOSING_BAL_DR
, TBL_2.*
FROM 
(SELECT
(  (NVL(v_func_dr_amt,0)
                     + nvl(v_cre_memo_func_amt,0)
                     + NVL(v_func_rev_amt,0))
                     - NVL(v_func_cr_amt,0)
                     + nvl(v_func_rcp_w_off,0)
                     + (NVL(v_func_adj_amt,0))
                     - NVL(v_func_disc_cr_amt,0)
                     - NVL(v_func_gain_amt,0)
                     + NVL(v_func_loss_amt,0)  ) v_func_tot_amt
,  ( (NVL(v_tr_dr_amt,0))
                    + nvl(v_cre_memo_amt,0)
                    +(NVL(v_tr_rev_amt,0))
                    - NVL(v_tr_cr_amt,0)
                    + nvl(v_tran_rcp_w_off,0)
                    - abs(NVL(v_tr_adj_amt,0))
                    - NVL(v_tr_disc_cr_amt,0) ) v_tran_tot_amt
, TBL_BASE.*
FROM 
(
SELECT 
 ( Select
	   sum((b.amount))
  From
       ra_customer_trx_all               A,
       ar_payment_schedules_all          C,
       ra_cust_trx_line_gl_dist_all      B
Where
  	   a.bill_to_customer_id         = :customer_id2
--AND    trunc(a.trx_date)            <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND    trunc(c.gl_date)             <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND    (a.invoice_currency_code       = :curr_code1 OR :curr_code1 IS NULL)
AND    a.complete_flag               = 'Y'
AND    b.customer_trx_id             = a.customer_trx_id
AND    b.account_class               = 'REC'
AND    b.LATEST_REC_FLAG             = 'Y'
AND    A.customer_trx_id             = C.customer_trx_id
AND    C.class In('CM')
AND    a.CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND    a.org_id                      =:p_org_id
AND    A.SET_OF_BOOKS_ID 				     = NVL(:P_SOB_ID,A.SET_OF_BOOKS_ID)
AND    c.payment_schedule_id
IN
 (SELECT MIN(PAYMENT_SCHEDULE_ID)
  FROM AR_PAYMENT_SCHEDULES_ALL
  WHERE CUSTOMER_TRX_ID = C.CUSTOMER_TRX_ID
 ))       v_cre_memo_amt
, ( Select
	   sum((b.amount) * NVL(A.exchange_rate,1))
  From
       ra_customer_trx_all               A,
       ar_payment_schedules_all          C,
       ra_cust_trx_line_gl_dist_all      B
Where
  	   a.bill_to_customer_id         = :customer_id2
--AND    trunc(a.trx_date)            <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND    trunc(c.gl_date)             <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND    (a.invoice_currency_code       = :curr_code1 OR :curr_code1 IS NULL)
AND    a.complete_flag               = 'Y'
AND    b.customer_trx_id             = a.customer_trx_id
AND    b.account_class               = 'REC'
AND    b.LATEST_REC_FLAG             = 'Y'
AND    A.customer_trx_id             = C.customer_trx_id
AND    C.class In('CM')
AND    a.CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND    a.org_id                      =:p_org_id
AND    A.SET_OF_BOOKS_ID 				     = NVL(:P_SOB_ID,A.SET_OF_BOOKS_ID)
AND    c.payment_schedule_id
IN
 (SELECT MIN(PAYMENT_SCHEDULE_ID)
  FROM AR_PAYMENT_SCHEDULES_ALL
  WHERE CUSTOMER_TRX_ID = C.CUSTOMER_TRX_ID
 ))   v_cre_memo_func_amt
 , (
Select
	    sum((b.amount)) 
From
        ra_customer_trx_all              A,
        ar_payment_schedules_all         C,
        ra_cust_trx_line_gl_dist_all     B
Where
    	a.bill_to_customer_id        = :customer_id2
--AND 	trunc(a.trx_date)           <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND 	trunc(c.gl_date)            <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND 	(a.invoice_currency_code      = :curr_code1 OR :curr_code1 IS NULL)
AND 	a.complete_flag              = 'Y'
AND 	b.customer_trx_id            = a.customer_trx_id
AND 	b.account_class              = 'REC'
AND     b.LATEST_REC_FLAG            = 'Y'
AND    A.CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND     A.customer_trx_id            = C.customer_trx_id
AND     C.class                     In ('INV','DM','DEP')
AND     a.org_id                     = :p_org_id
AND     A.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,A.SET_OF_BOOKS_ID)
AND     c.Payment_schedule_id
IN     (SELECT  MIN(PAYMENT_SCHEDULE_ID)
        FROM    AR_PAYMENT_SCHEDULES_ALL
	    WHERE   CUSTOMER_TRX_ID = C.CUSTOMER_TRX_ID
	   ) ) v_tr_dr_amt
,(
Select
	    sum((b.amount) * NVL(A.exchange_rate,1))
From
        ra_customer_trx_all              A,
        ar_payment_schedules_all         C,
        ra_cust_trx_line_gl_dist_all     B
Where
    	a.bill_to_customer_id        = :customer_id2
--AND 	trunc(a.trx_date)           <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND 	trunc(c.gl_date)            <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND 	(a.invoice_currency_code      = :curr_code1 OR :curr_code1 IS NULL)
AND 	a.complete_flag              = 'Y'
AND 	b.customer_trx_id            = a.customer_trx_id
AND 	b.account_class              = 'REC'
AND     b.LATEST_REC_FLAG            = 'Y'
AND    A.CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND     A.customer_trx_id            = C.customer_trx_id
AND     C.class                     In ('INV','DM','DEP')
AND     a.org_id                     = :p_org_id
AND     A.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,A.SET_OF_BOOKS_ID)
AND     c.Payment_schedule_id
IN     (SELECT  MIN(PAYMENT_SCHEDULE_ID)
        FROM    AR_PAYMENT_SCHEDULES_ALL
	    WHERE   CUSTOMER_TRX_ID = C.CUSTOMER_TRX_ID
	   ) ) v_func_dr_amt
, (SELECT
	    sum((b.amount))
FROM
        ar_customers                     a,
        ar_adjustments_all               b,
        ra_customer_trx_all              c,
        ar_payment_schedules_all         d,
        gl_code_combinations             e
WHERE
	    a.customer_id                =  :customer_id2
AND 	b.customer_trx_id            = c.customer_trx_id
and     e.code_combination_id        = b.code_combination_id
AND 	c.bill_to_customer_id        = a.customer_id
--AND 	trunc(b.apply_date)         <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND 	trunc(b.gl_date)            <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND     (c.invoice_currency_code      = :curr_code1 OR :curr_code1 IS NULL)
AND 	b.status                     = 'A'
AND	    b.customer_trx_id            = d.customer_trx_id
AND    c.CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND     c.org_id                     =:p_org_id
AND     B.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,B.SET_OF_BOOKS_ID)
and     d.payment_schedule_id
IN      (SELECT MIN(PAYMENT_SCHEDULE_ID)
         FROM   AR_PAYMENT_SCHEDULES_ALL
	     WHERE  CUSTOMER_TRX_ID = d.CUSTOMER_TRX_ID
	    )) v_tr_adj_amt
, (SELECT
	    sum((b.amount) * NVL(C.exchange_rate,1))
FROM
        ar_customers                     a,
        ar_adjustments_all               b,
        ra_customer_trx_all              c,
        ar_payment_schedules_all         d,
        gl_code_combinations             e
WHERE
	    a.customer_id                =  :customer_id2
AND 	b.customer_trx_id            = c.customer_trx_id
and     e.code_combination_id        = b.code_combination_id
AND 	c.bill_to_customer_id        = a.customer_id
--AND 	trunc(b.apply_date)         <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND 	trunc(b.gl_date)            <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND     (c.invoice_currency_code      = :curr_code1 OR :curr_code1 IS NULL)
AND 	b.status                     = 'A'
AND	    b.customer_trx_id            = d.customer_trx_id
AND    c.CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND     c.org_id                     =:p_org_id
AND     B.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,B.SET_OF_BOOKS_ID)
and     d.payment_schedule_id
IN      (SELECT MIN(PAYMENT_SCHEDULE_ID)
         FROM   AR_PAYMENT_SCHEDULES_ALL
	     WHERE  CUSTOMER_TRX_ID = d.CUSTOMER_TRX_ID
	    )) v_func_adj_amt
, (Select
	    sum(a.amount)        
From
	    ar_cash_receipts_all             A
Where
     		a.pay_from_customer          = :customer_id2
AND 		(a.currency_code             = :curr_code1 OR :curr_code1 IS NULL)
AND     a.org_id                     =:p_org_id
AND     A.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,A.SET_OF_BOOKS_ID)
--Added the below by Sanjikum for Bug #3962497
AND 		EXISTS (	SELECT	1 
									FROM 		ar_cash_receipt_history_all
									WHERE		cash_receipt_id = a.cash_receipt_id
									AND  		org_id = :p_org_id
									AND 		trunc(gl_date) <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
							 )) v_tr_cr_amt
,
 (Select
	   sum(a.amount * NVL(a.exchange_rate,1.00)) sum_amount_exchange
From
	    ar_cash_receipts_all             A
Where
     		a.pay_from_customer          = :customer_id2
AND 		(a.currency_code             = :curr_code1 OR :curr_code1 IS NULL)
AND     a.org_id                     =:p_org_id
AND     A.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,A.SET_OF_BOOKS_ID)
--Added the below by Sanjikum for Bug #3962497
AND 		EXISTS (	SELECT	1 
									FROM 		ar_cash_receipt_history_all
									WHERE		cash_receipt_id = a.cash_receipt_id
									AND  		org_id = :p_org_id
									AND 		trunc(gl_date) <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
							 ))  v_func_cr_amt
, (Select
	     sum(a.amount * NVL(a.exchange_rate,1.00)) sum_amount_exchange -- a. added by ssumaith
From
	     ar_cash_receipts_all            A,
	     ar_cash_receipt_history_all     b -- added by sriram - 3328962
Where
         a.cash_receipt_id           = b.cash_receipt_id
AND    	 a.pay_from_customer         = :customer_id2
AND	     trunc(b.gl_date)           <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND      a.reversal_date               is not null
AND 	  ( a.currency_code             = :curr_code1 OR :curr_code1 IS NULL)
--AND      b.current_record_flag        = 'Y' --Commented by Sanjikum for Bug #3962497
AND 	 	 b.status                      = 'REVERSED' --Added by Sanjikum for Bug #3962497
AND      a.org_id                    = :p_org_id
AND     A.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,A.SET_OF_BOOKS_ID))v_tr_rev_amt
, (Select
	     sum(a.amount * NVL(a.exchange_rate,1.00)) sum_amount_exchange -- a. added by ssumaith
From
	     ar_cash_receipts_all            A,
	     ar_cash_receipt_history_all     b -- added by sriram - 3328962
Where
         a.cash_receipt_id           = b.cash_receipt_id
AND    	 a.pay_from_customer         = :customer_id2
AND	     trunc(b.gl_date)           <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND      a.reversal_date               is not null
AND 	  ( a.currency_code = :curr_code1 OR :curr_code1 IS NULL)
--AND      b.current_record_flag        = 'Y' --Commented by Sanjikum for Bug #3962497
AND 	 	 b.status                      = 'REVERSED' --Added by Sanjikum for Bug #3962497
AND      a.org_id                    = :p_org_id
AND     A.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,A.SET_OF_BOOKS_ID)) v_func_rev_amt
, (Select
         nvl(sum(abs(NVL(d.EARNED_discount_taken,0))),0)                  
From
	     ar_customers                    a,
	     ra_customer_trx_ALL             B,
	     ar_receivable_applications_all  D
Where
		 a.customer_id               =  :customer_id2
AND	     b.bill_to_customer_id       =  a.customer_id
AND	     b.complete_flag             =  'Y'
AND      trunc(d.GL_DATE)           <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND      d.applied_customer_trx_id   = b.customer_trx_id
AND    b.CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND      (b.invoice_currency_code     = :curr_code1 OR :curr_code1 IS NULL)
AND      B.org_id                    =:p_org_id
AND      D.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,D.SET_OF_BOOKS_ID)
AND      d.earned_discount_taken is not null
and      d.earned_discount_taken <> 0 
and      d.application_type = 'CASH' 
and      d.display = 'Y') v_tr_disc_cr_amt
, (Select
 	     nvl(sum(abs(NVL(d.ACCTD_EARNED_DISCOUNT_TAKEN,0))),0)  sum_amount_exchange
From
	     ar_customers                    a,
	     ra_customer_trx_ALL             B,
	     ar_receivable_applications_all  D
Where
		 a.customer_id               =  :customer_id2
AND	     b.bill_to_customer_id       =  a.customer_id
AND	     b.complete_flag             =  'Y'
AND      trunc(d.GL_DATE)           <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND      d.applied_customer_trx_id   = b.customer_trx_id
AND    b.CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND      (b.invoice_currency_code  = :curr_code1 OR :curr_code1 IS NULL)
AND      B.org_id                    =:p_org_id
AND      D.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,D.SET_OF_BOOKS_ID)
AND      d.earned_discount_taken is not null
and      d.earned_discount_taken <> 0 
and      d.application_type = 'CASH' 
and      d.display = 'Y')  v_func_disc_cr_amt
, (SELECT
        sum(e.amount_cr)        
FROM
        ar_customers                     a ,
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
AND     b.org_id                     = :p_org_id
AND     D.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,D.SET_OF_BOOKS_ID)
AND     e.source_Type IN ('EXCH_LOSS', 'EXCH_GAIN' )
AND     (b.invoice_currency_code      = :curr_code1 OR :curr_code1 IS NULL)
AND     a.customer_id                = :customer_id2
--AND     TRUNC(c.receipt_date)       <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND     TRUNC(d.gl_date)            <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) ) v_tran_loss_amt
, (SELECT sum(e.acctd_amount_cr)       sum_exchange_amount
FROM
        ar_customers                     a ,
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
AND     b.org_id                     = :p_org_id
AND     D.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,D.SET_OF_BOOKS_ID)
AND     e.source_Type IN ('EXCH_LOSS', 'EXCH_GAIN' )
AND     (b.invoice_currency_code      = :curr_code1 OR :curr_code1 IS NULL)
AND     a.customer_id                = :customer_id2
--AND     TRUNC(c.receipt_date)       <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND     TRUNC(d.gl_date)            <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) ) v_func_loss_amt
, (SELECT
        sum(e.amount_dr)             sum_amount 
FROM
        ar_customers                     a ,
        ra_customer_trx_all              b ,
        ar_cash_receipts_all             c ,
        ar_receivable_applications_all   d ,
        ar_distributions_all             e
WHERE
        a.customer_id                = b.BILL_TO_CUSTOMER_ID
AND     b.customer_trx_id            = d.APPLIED_CUSTOMER_TRX_ID
AND     c.cash_receipt_id            = d.cash_receipt_id
AND     e.SOURCE_ID                  = d.receivable_application_id
AND     b.org_id                     = :p_org_id
AND    b.CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND     B.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,B.SET_OF_BOOKS_ID)
AND    ( b.invoice_currency_code      = :curr_code1 OR :curr_code1 IS NULL)
AND     a.customer_id                =:customer_id2
--AND     TRUNC(c.receipt_date)       <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND     TRUNC(d.gl_date)            <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND     e.source_Type IN ('EXCH_GAIN','EXCH_LOSS' ))  v_tran_gain_amt
, (SELECT
        sum(e.acctd_amount_dr)       sum_exchange_amount
FROM
        ar_customers                     a ,
        ra_customer_trx_all              b ,
        ar_cash_receipts_all             c ,
        ar_receivable_applications_all   d ,
        ar_distributions_all             e
WHERE
        a.customer_id                = b.BILL_TO_CUSTOMER_ID
AND     b.customer_trx_id            = d.APPLIED_CUSTOMER_TRX_ID
AND     c.cash_receipt_id            = d.cash_receipt_id
AND     e.SOURCE_ID                  = d.receivable_application_id
AND     b.org_id                     = :p_org_id
AND    b.CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND     B.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,B.SET_OF_BOOKS_ID)
AND     (b.invoice_currency_code      = :curr_code1 OR :curr_code1 IS NULL)
AND     a.customer_id                =:customer_id2
--AND     TRUNC(c.receipt_date)       <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND     TRUNC(d.gl_date)            <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND     e.source_Type IN ('EXCH_GAIN','EXCH_LOSS' )) v_func_gain_amt
, (Select
	    sum(c.amount_applied)
From
	    ar_cash_receipts_all             A,
        ar_cash_receipt_history_all      B,
        ar_receivable_applications_all   c
Where
     	a.pay_from_customer          = :customer_id2
AND	    trunc(b.gl_date)              <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND     a.cash_receipt_id              = b.cash_receipt_id
and     a.cash_receipt_id              = c .cash_receipt_id
and     c.cash_receipt_history_id      = b.cash_receipt_history_id
and     c.applied_payment_schedule_id  = -3
and     c.status                       = 'ACTIVITY'
AND     (a.currency_code                = :curr_code1 OR :curr_code1 IS NULL)
AND    c.applied_CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
--- AND     B.REVERSAL_GL_DATE IS NULL ---commented by mohinder paul singh
AND     b.current_record_flag          = 'Y'
AND     a.org_id                       =:p_org_id
AND     A.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,A.SET_OF_BOOKS_ID)
and     not exists
 ( select 1
   from   ar_cash_receipt_history_all
   where  cash_receipt_id = b.cash_receipt_id
   and    status          = 'REVERSED'
 )) v_tran_rcp_w_off
, ((Select
	    sum(c.amount_applied * NVL(a.exchange_rate,1.00)) sum_amount_exchange
From
	    ar_cash_receipts_all             A,
        ar_cash_receipt_history_all      B,
        ar_receivable_applications_all   c
Where
     	a.pay_from_customer          = :customer_id2
AND	    trunc(b.gl_date)              <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND     a.cash_receipt_id              = b.cash_receipt_id
and     a.cash_receipt_id              = c .cash_receipt_id
and     c.cash_receipt_history_id      = b.cash_receipt_history_id
and     c.applied_payment_schedule_id  = -3
and     c.status                       = 'ACTIVITY'
AND     (a.currency_code               = :curr_code1 OR :curr_code1 IS NULL)
AND    c.applied_CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
--- AND     B.REVERSAL_GL_DATE IS NULL ---commented by mohinder paul singh
AND     b.current_record_flag          = 'Y'
AND     a.org_id                       =:p_org_id
AND     A.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,A.SET_OF_BOOKS_ID)
and     not exists
 ( select 1
   from   ar_cash_receipt_history_all
   where  cash_receipt_id = b.cash_receipt_id
   and    status          = 'REVERSED'
 ))) v_func_rcp_w_off
FROM DUAL
) TBL_BASE) TBL_2
) TBL_3
) TBL_4


-- STEP 5
SELECT 
CASE WHEN NVL(FUNC_CL_BAL_DR,0) - NVL(FUNC_CL_BAL_CR,0) < 0 THEN 
	CASE WHEN :P_CUSTOMER_ID2 IS NOT NULL 
		THEN ABS(NVL(FUNC_CL_BAL_DR,0) - NVL(FUNC_CL_BAL_CR,0))+CS_SUM_APPLIED_OTHERS 
	ELSE ABS(NVL(FUNC_CL_BAL_DR,0) - NVL(FUNC_CL_BAL_CR,0))+CF_APPLIEF_FROM_FUNC 
	END
ELSE 
	CASE WHEN :P_CUSTOMER_ID2 IS NOT NULL 
		THEN 0 
	ELSE 0 
	END 
END CL_TOT_CR
, CASE WHEN NVL(FUNC_CL_BAL_DR,0) - NVL(FUNC_CL_BAL_CR,0) < 0 
	THEN 	
		CASE WHEN :P_CUSTOMER_ID2 IS NOT NULL THEN 0 
		ELSE 0 END
ELSE 
	CASE WHEN :P_CUSTOMER_ID2 IS NOT NULL THEN (ABS(NVL(NVL(FUNC_CL_BAL_DR,0) - NVL(FUNC_CL_BAL_CR,0),0))-CS_SUM_APPLIED_OTHERS) 
	ELSE (ABS(NVL(NVL(FUNC_CL_BAL_DR,0) - NVL(FUNC_CL_BAL_CR,0),0))-CF_APPLIEF_FROM_FUNC) 
	END 
END CL_TOT_DR
, TBL_5.* 
FROM 
(SELECT 
 (SELECT NVL (SUM (NVL (acctd_amount_applied_from, 0)), 0)
   FROM (SELECT BILL_TO_CUSTOMER_ID
                    customer_id,
                (SELECT CUSTOMER_NAME
                   FROM RA_CUSTOMERS
                  WHERE CUSTOMER_ID = PAY_FROM_CUSTOMER)
                    RECEIPT_CUSTOMER,
                RECEIPT_NUMBER,
                t.trx_number,
                (SELECT SUM (revenue_amount)
                   FROM ra_customer_trx_lines_all
                  WHERE interface_line_attribute2 = t.trx_number)
                    INVOICE_amount,
                invoice_currency_code
                    INV_CURR,
                t.exchange_rate
                    INV_RATE,
                amount_applied
                    APPLY_AMT,
                gl_date,
                gl_posted_date,
                NVL (acctd_amount_applied_from, 0)
                    acctd_amount_applied_from,
                acctd_amount_applied_to,
                acctd_amount_applied_from - acctd_amount_applied_to
                    "Gain/Loss"
           FROM AR_RECEIVABLE_APPLICATIONS_all  a,
                ar_cash_receipts_all            c,
                ra_customer_trx_all             t
          WHERE     a.cash_receipt_id = c.cash_receipt_id
                AND INVOICE_CURRENCY_CODE = :curr_code
                AND t.CUSTOMER_TRX_ID = APPLIED_CUSTOMER_TRX_ID
                AND APPLIED_CUSTOMER_TRX_ID IN
                        (SELECT CUSTOMER_TRX_ID
                           FROM ra_customer_trx_all
                          WHERE BILL_TO_CUSTOMER_ID = :p_customer_id2)
                AND gl_date <= :p_end_date_R
                AND DISPLAY = 'Y'
                AND PAY_FROM_CUSTOMER <> :p_customer_id2
         UNION ALL
         SELECT BILL_TO_CUSTOMER_ID
                    customer_id,
                (SELECT CUSTOMER_NAME
                   FROM AR_CUSTOMERS
                  WHERE CUSTOMER_ID = BILL_TO_CUSTOMER_ID)
                    RECEIPT_CUSTOMER,
                RECEIPT_NUMBER,
                t.trx_number,
                (SELECT SUM (revenue_amount)
                   FROM ra_customer_trx_lines_all
                  WHERE interface_line_attribute2 = t.trx_number)
                    INVOICE_amount,
                invoice_currency_code
                    INV_CURR,
                t.exchange_rate
                    INV_RATE,
                amount_applied
                    APPLY_AMT,
                gl_date,
                gl_posted_date,
                NVL (acctd_amount_applied_from * -1, 0),
                acctd_amount_applied_to,
                acctd_amount_applied_from - acctd_amount_applied_to
                    "Gain/Loss"
           FROM AR_RECEIVABLE_APPLICATIONS_all  a,
                ar_cash_receipts_all            c,
                ra_customer_trx_all             t
          WHERE     a.cash_receipt_id = c.cash_receipt_id
                AND INVOICE_CURRENCY_CODE = :curr_code
                AND t.CUSTOMER_TRX_ID = APPLIED_CUSTOMER_TRX_ID
                AND APPLIED_CUSTOMER_TRX_ID NOT IN
                        (SELECT CUSTOMER_TRX_ID
                           FROM ra_customer_trx_all
                          WHERE BILL_TO_CUSTOMER_ID = :p_customer_id2)
                AND gl_date <= :p_end_date_R
                AND DISPLAY = 'Y'
                AND PAY_FROM_CUSTOMER = :p_customer_id2
         UNION ALL
         SELECT PAY_FROM_CUSTOMER,
                NULL,
                RECEIPT_NUMBER,
                RECEIPT_NUMBER,
                NVL (H.FACTOR_DISCOUNT_AMOUNT, 0),
                C.CURRENCY_CODE,
                C.EXCHANGE_RATE,
                NULL,
                NULL,
                NULL,
                NVL (
                      NVL (H.FACTOR_DISCOUNT_AMOUNT, 0)
                    * NVL (C.EXCHANGE_RATE, 1)
                    * -1,
                    0)    acctd_amount_applied_from,
                NULL,
                NULL
           FROM ar_cash_receipt_history_all H, ar_cash_receipts_all C
          WHERE     C.cash_receipt_id IN
                        (SELECT cash_receipt_id
                           FROM ar_cash_receipts_all
                          WHERE RECEIPT_date <= :p_end_date_R)
                AND C.CURRENCY_CODE = :curr_code
                AND gl_date > :p_end_date_R
                AND C.cash_receipt_id = H.cash_receipt_id
                AND PAY_FROM_CUSTOMER = :p_customer_id2
                AND PAY_FROM_CUSTOMER <> '7730'
                AND CURRENT_RECORD_FLAG = 'Y')) 
				CF_APPLIEF_FROM_func
, (SELECT SUM (acctd_amount_applied_from)
   FROM (SELECT BILL_TO_CUSTOMER_ID
                    customer_id,
                (SELECT CUSTOMER_NAME
                   FROM AR_CUSTOMERS
                  WHERE CUSTOMER_ID = PAY_FROM_CUSTOMER)
                    RECEIPT_CUSTOMER,
                RECEIPT_NUMBER,
                t.trx_number,
                (SELECT SUM (revenue_amount)
                   FROM ra_customer_trx_lines_all
                  WHERE interface_line_attribute2 = t.trx_number)
                    INVOICE_amount,
                invoice_currency_code
                    INV_CURR,
                t.exchange_rate
                    INV_RATE,
                amount_applied
                    APPLY_AMT,
                gl_date,
                gl_posted_date,
                acctd_amount_applied_from,
                acctd_amount_applied_to,
                acctd_amount_applied_from - acctd_amount_applied_to
                    "Gain/Loss",
                'A'
                    source
           FROM AR_RECEIVABLE_APPLICATIONS_all  a,
                ar_cash_receipts_all            c,
                ra_customer_trx_all             t
          WHERE     a.cash_receipt_id = c.cash_receipt_id
                AND invoice_currency_code = :CURR_CODE
                AND t.CUSTOMER_TRX_ID = APPLIED_CUSTOMER_TRX_ID
                AND A.SET_OF_BOOKS_ID = NVL ( :P_SOB_ID, A.SET_OF_BOOKS_ID)
                AND APPLIED_CUSTOMER_TRX_ID IN
                        (SELECT CUSTOMER_TRX_ID
                           FROM ra_customer_trx_all
                          WHERE     BILL_TO_CUSTOMER_ID = :p_customer_id2
                                AND SET_OF_BOOKS_ID =
                                    NVL ( :P_SOB_ID, SET_OF_BOOKS_ID))
                AND gl_date <= :p_end_date_R
                AND DISPLAY = 'Y'
                AND PAY_FROM_CUSTOMER <> :p_customer_id2
         UNION ALL
         SELECT BILL_TO_CUSTOMER_ID
                    customer_id,
                (SELECT CUSTOMER_NAME
                   FROM AR_CUSTOMERS
                  WHERE CUSTOMER_ID = BILL_TO_CUSTOMER_ID)
                    RECEIPT_CUSTOMER,
                RECEIPT_NUMBER,
                t.trx_number,
                (SELECT SUM (revenue_amount)
                   FROM ra_customer_trx_lines_all
                  WHERE interface_line_attribute2 = t.trx_number)
                    INVOICE_amount,
                invoice_currency_code
                    INV_CURR,
                t.exchange_rate
                    INV_RATE,
                amount_applied
                    APPLY_AMT,
                gl_date,
                gl_posted_date,
                acctd_amount_applied_from * -1,
                acctd_amount_applied_to,
                acctd_amount_applied_from - acctd_amount_applied_to
                    "Gain/Loss",
                'B'
                    source
           FROM AR_RECEIVABLE_APPLICATIONS_all  a,
                ar_cash_receipts_all            c,
                ra_customer_trx_all             t
          WHERE     a.cash_receipt_id = c.cash_receipt_id
                AND invoice_currency_code = :CURR_CODE
                AND t.CUSTOMER_TRX_ID = APPLIED_CUSTOMER_TRX_ID
                AND A.SET_OF_BOOKS_ID = NVL ( :P_SOB_ID, A.SET_OF_BOOKS_ID)
                AND APPLIED_CUSTOMER_TRX_ID NOT IN
                        (SELECT CUSTOMER_TRX_ID
                           FROM ra_customer_trx_all
                          WHERE     BILL_TO_CUSTOMER_ID = :p_customer_id2
                                AND SET_OF_BOOKS_ID =
                                    NVL ( :P_SOB_ID, SET_OF_BOOKS_ID))))
				CS_SUM_APPLIED_OTHERS
, TBL_4.*
FROM
(SELECT 
SUM(FUNC_CLOSING_BAL_DR) FUNC_CL_BAL_DR
, SUM(FUNC_CLOSING_BAL_CR) FUNC_CL_BAL_CR
FROM 
(SELECT CASE WHEN NVL(v_func_tot_amt,0) < 0 THEN ABS(v_func_tot_amt) ELSE 0 END func_closing_bal_cr
, CASE WHEN NVL(v_func_tot_amt,0) < 0 THEN 0 ELSE ABS(v_func_tot_amt) END func_closing_bal_dr
, CASE WHEN NVL(v_tran_tot_amt,0) < 0 THEN ABS(NVL(v_tran_tot_amt,0)) ELSE 0 END tran_closing_bal_cr
, CASE WHEN NVL(v_tran_tot_amt,0) < 0 THEN 0 ELSE (ABS(NVL(v_tran_tot_amt,0))) END TRAN_CLOSING_BAL_DR
, TBL_2.*
FROM 
(SELECT
(  (NVL(v_func_dr_amt,0)
                     + nvl(v_cre_memo_func_amt,0)
                     + NVL(v_func_rev_amt,0))
                     - NVL(v_func_cr_amt,0)
                     + nvl(v_func_rcp_w_off,0)
                     + (NVL(v_func_adj_amt,0))
                     - NVL(v_func_disc_cr_amt,0)
                     - NVL(v_func_gain_amt,0)
                     + NVL(v_func_loss_amt,0)  ) v_func_tot_amt
,  ( (NVL(v_tr_dr_amt,0))
                    + nvl(v_cre_memo_amt,0)
                    +(NVL(v_tr_rev_amt,0))
                    - NVL(v_tr_cr_amt,0)
                    + nvl(v_tran_rcp_w_off,0)
                    - abs(NVL(v_tr_adj_amt,0))
                    - NVL(v_tr_disc_cr_amt,0) ) v_tran_tot_amt
, TBL_BASE.*
FROM 
(
SELECT 
 nvl(( Select
	   sum((b.amount))
  From
       ra_customer_trx_all               A,
       ar_payment_schedules_all          C,
       ra_cust_trx_line_gl_dist_all      B
Where
  	   a.bill_to_customer_id         = :customer_id2
--AND    trunc(a.trx_date)            <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND    trunc(c.gl_date)             <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND    (a.invoice_currency_code       = :curr_code1 OR :curr_code1 IS NULL)
AND    a.complete_flag               = 'Y'
AND    b.customer_trx_id             = a.customer_trx_id
AND    b.account_class               = 'REC'
AND    b.LATEST_REC_FLAG             = 'Y'
AND    A.customer_trx_id             = C.customer_trx_id
AND    C.class In('CM')
AND    a.CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND    a.org_id                      =:p_org_id
AND    A.SET_OF_BOOKS_ID 				     = NVL(:P_SOB_ID,A.SET_OF_BOOKS_ID)
AND    c.payment_schedule_id
IN
 (SELECT MIN(PAYMENT_SCHEDULE_ID)
  FROM AR_PAYMENT_SCHEDULES_ALL
  WHERE CUSTOMER_TRX_ID = C.CUSTOMER_TRX_ID
 )),0)       v_cre_memo_amt
, nvl(( Select
	   sum((b.amount) * NVL(A.exchange_rate,1))
  From
       ra_customer_trx_all               A,
       ar_payment_schedules_all          C,
       ra_cust_trx_line_gl_dist_all      B
Where
  	   a.bill_to_customer_id         = :customer_id2
--AND    trunc(a.trx_date)            <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND    trunc(c.gl_date)             <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND    (a.invoice_currency_code       = :curr_code1 OR :curr_code1 IS NULL)
AND    a.complete_flag               = 'Y'
AND    b.customer_trx_id             = a.customer_trx_id
AND    b.account_class               = 'REC'
AND    b.LATEST_REC_FLAG             = 'Y'
AND    A.customer_trx_id             = C.customer_trx_id
AND    C.class In('CM')
AND    a.CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND    a.org_id                      =:p_org_id
AND    A.SET_OF_BOOKS_ID 				     = NVL(:P_SOB_ID,A.SET_OF_BOOKS_ID)
AND    c.payment_schedule_id
IN
 (SELECT MIN(PAYMENT_SCHEDULE_ID)
  FROM AR_PAYMENT_SCHEDULES_ALL
  WHERE CUSTOMER_TRX_ID = C.CUSTOMER_TRX_ID
 )),0)   v_cre_memo_func_amt
 , nvl((
Select
	    sum((b.amount)) 
From
        ra_customer_trx_all              A,
        ar_payment_schedules_all         C,
        ra_cust_trx_line_gl_dist_all     B
Where
    	a.bill_to_customer_id        = :customer_id2
--AND 	trunc(a.trx_date)           <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND 	trunc(c.gl_date)            <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND 	(a.invoice_currency_code      = :curr_code1 OR :curr_code1 IS NULL)
AND 	a.complete_flag              = 'Y'
AND 	b.customer_trx_id            = a.customer_trx_id
AND 	b.account_class              = 'REC'
AND     b.LATEST_REC_FLAG            = 'Y'
AND    A.CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND     A.customer_trx_id            = C.customer_trx_id
AND     C.class                     In ('INV','DM','DEP')
AND     a.org_id                     = :p_org_id
AND     A.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,A.SET_OF_BOOKS_ID)
AND     c.Payment_schedule_id
IN     (SELECT  MIN(PAYMENT_SCHEDULE_ID)
        FROM    AR_PAYMENT_SCHEDULES_ALL
	    WHERE   CUSTOMER_TRX_ID = C.CUSTOMER_TRX_ID
	   ) ),0) v_tr_dr_amt
,nvl((
Select
	    sum((b.amount) * NVL(A.exchange_rate,1))
From
        ra_customer_trx_all              A,
        ar_payment_schedules_all         C,
        ra_cust_trx_line_gl_dist_all     B
Where
    	a.bill_to_customer_id        = :customer_id2
--AND 	trunc(a.trx_date)           <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND 	trunc(c.gl_date)            <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND 	(a.invoice_currency_code      = :curr_code1 OR :curr_code1 IS NULL)
AND 	a.complete_flag              = 'Y'
AND 	b.customer_trx_id            = a.customer_trx_id
AND 	b.account_class              = 'REC'
AND     b.LATEST_REC_FLAG            = 'Y'
AND    A.CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND     A.customer_trx_id            = C.customer_trx_id
AND     C.class                     In ('INV','DM','DEP')
AND     a.org_id                     = :p_org_id
AND     A.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,A.SET_OF_BOOKS_ID)
AND     c.Payment_schedule_id
IN     (SELECT  MIN(PAYMENT_SCHEDULE_ID)
        FROM    AR_PAYMENT_SCHEDULES_ALL
	    WHERE   CUSTOMER_TRX_ID = C.CUSTOMER_TRX_ID
	   ) ),0) v_func_dr_amt
, nvl((SELECT
	    sum((b.amount))
FROM
        ar_customers                     a,
        ar_adjustments_all               b,
        ra_customer_trx_all              c,
        ar_payment_schedules_all         d,
        gl_code_combinations             e
WHERE
	    a.customer_id                =  :customer_id2
AND 	b.customer_trx_id            = c.customer_trx_id
and     e.code_combination_id        = b.code_combination_id
AND 	c.bill_to_customer_id        = a.customer_id
--AND 	trunc(b.apply_date)         <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND 	trunc(b.gl_date)            <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND     (c.invoice_currency_code      = :curr_code1 OR :curr_code1 IS NULL)
AND 	b.status                     = 'A'
AND	    b.customer_trx_id            = d.customer_trx_id
AND    c.CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND     c.org_id                     =:p_org_id
AND     B.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,B.SET_OF_BOOKS_ID)
and     d.payment_schedule_id
IN      (SELECT MIN(PAYMENT_SCHEDULE_ID)
         FROM   AR_PAYMENT_SCHEDULES_ALL
	     WHERE  CUSTOMER_TRX_ID = d.CUSTOMER_TRX_ID
	    )),0) v_tr_adj_amt
, nvl((SELECT
	    sum((b.amount) * NVL(C.exchange_rate,1))
FROM
        ar_customers                     a,
        ar_adjustments_all               b,
        ra_customer_trx_all              c,
        ar_payment_schedules_all         d,
        gl_code_combinations             e
WHERE
	    a.customer_id                =  :customer_id2
AND 	b.customer_trx_id            = c.customer_trx_id
and     e.code_combination_id        = b.code_combination_id
AND 	c.bill_to_customer_id        = a.customer_id
--AND 	trunc(b.apply_date)         <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND 	trunc(b.gl_date)            <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND     (c.invoice_currency_code      = :curr_code1 OR :curr_code1 IS NULL)
AND 	b.status                     = 'A'
AND	    b.customer_trx_id            = d.customer_trx_id
AND    c.CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND     c.org_id                     =:p_org_id
AND     B.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,B.SET_OF_BOOKS_ID)
and     d.payment_schedule_id
IN      (SELECT MIN(PAYMENT_SCHEDULE_ID)
         FROM   AR_PAYMENT_SCHEDULES_ALL
	     WHERE  CUSTOMER_TRX_ID = d.CUSTOMER_TRX_ID
	    )),0) v_func_adj_amt
, nvl((Select
	    sum(a.amount)        
From
	    ar_cash_receipts_all             A
Where
     		a.pay_from_customer          = :customer_id2
AND 		(a.currency_code             = :curr_code1 OR :curr_code1 IS NULL)
AND     a.org_id                     =:p_org_id
AND     A.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,A.SET_OF_BOOKS_ID)
--Added the below by Sanjikum for Bug #3962497
AND 		EXISTS (	SELECT	1 
									FROM 		ar_cash_receipt_history_all
									WHERE		cash_receipt_id = a.cash_receipt_id
									AND  		org_id = :p_org_id
									AND 		trunc(gl_date) <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
							 )),0) v_tr_cr_amt
,
 (Select
	   sum(a.amount * NVL(a.exchange_rate,1.00)) sum_amount_exchange
From
	    ar_cash_receipts_all             A
Where
     		a.pay_from_customer          = :customer_id2
AND 		(a.currency_code             = :curr_code1 OR :curr_code1 IS NULL)
AND     a.org_id                     =:p_org_id
AND     A.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,A.SET_OF_BOOKS_ID)
--Added the below by Sanjikum for Bug #3962497
AND 		EXISTS (	SELECT	1 
									FROM 		ar_cash_receipt_history_all
									WHERE		cash_receipt_id = a.cash_receipt_id
									AND  		org_id = :p_org_id
									AND 		trunc(gl_date) <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
							 ))  v_func_cr_amt
, nvl((Select
	     sum(a.amount * NVL(a.exchange_rate,1.00)) sum_amount_exchange -- a. added by ssumaith
From
	     ar_cash_receipts_all            A,
	     ar_cash_receipt_history_all     b -- added by sriram - 3328962
Where
         a.cash_receipt_id           = b.cash_receipt_id
AND    	 a.pay_from_customer         = :customer_id2
AND	     trunc(b.gl_date)           <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND      a.reversal_date               is not null
AND 	  ( a.currency_code             = :curr_code1 OR :curr_code1 IS NULL)
--AND      b.current_record_flag        = 'Y' --Commented by Sanjikum for Bug #3962497
AND 	 	 b.status                      = 'REVERSED' --Added by Sanjikum for Bug #3962497
AND      a.org_id                    = :p_org_id
AND     A.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,A.SET_OF_BOOKS_ID)),0) v_tr_rev_amt
, nvl((Select
	     sum(a.amount * NVL(a.exchange_rate,1.00)) sum_amount_exchange -- a. added by ssumaith
From
	     ar_cash_receipts_all            A,
	     ar_cash_receipt_history_all     b -- added by sriram - 3328962
Where
         a.cash_receipt_id           = b.cash_receipt_id
AND    	 a.pay_from_customer         = :customer_id2
AND	     trunc(b.gl_date)           <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND      a.reversal_date               is not null
AND 	  ( a.currency_code = :curr_code1 OR :curr_code1 IS NULL)
--AND      b.current_record_flag        = 'Y' --Commented by Sanjikum for Bug #3962497
AND 	 	 b.status                      = 'REVERSED' --Added by Sanjikum for Bug #3962497
AND      a.org_id                    = :p_org_id
AND     A.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,A.SET_OF_BOOKS_ID)),0) v_func_rev_amt
, nvl((Select
         nvl(sum(abs(NVL(d.EARNED_discount_taken,0))),0)                  
From
	     ar_customers                    a,
	     ra_customer_trx_ALL             B,
	     ar_receivable_applications_all  D
Where
		 a.customer_id               =  :customer_id2
AND	     b.bill_to_customer_id       =  a.customer_id
AND	     b.complete_flag             =  'Y'
AND      trunc(d.GL_DATE)           <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND      d.applied_customer_trx_id   = b.customer_trx_id
AND    b.CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND      (b.invoice_currency_code     = :curr_code1 OR :curr_code1 IS NULL)
AND      B.org_id                    =:p_org_id
AND      D.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,D.SET_OF_BOOKS_ID)
AND      d.earned_discount_taken is not null
and      d.earned_discount_taken <> 0 
and      d.application_type = 'CASH' 
and      d.display = 'Y'),0) v_tr_disc_cr_amt
, nvl((Select
 	     nvl(sum(abs(NVL(d.ACCTD_EARNED_DISCOUNT_TAKEN,0))),0)  sum_amount_exchange
From
	     ar_customers                    a,
	     ra_customer_trx_ALL             B,
	     ar_receivable_applications_all  D
Where
		 a.customer_id               =  :customer_id2
AND	     b.bill_to_customer_id       =  a.customer_id
AND	     b.complete_flag             =  'Y'
AND      trunc(d.GL_DATE)           <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND      d.applied_customer_trx_id   = b.customer_trx_id
AND    b.CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND      (b.invoice_currency_code  = :curr_code1 OR :curr_code1 IS NULL)
AND      B.org_id                    =:p_org_id
AND      D.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,D.SET_OF_BOOKS_ID)
AND      d.earned_discount_taken is not null
and      d.earned_discount_taken <> 0 
and      d.application_type = 'CASH' 
and      d.display = 'Y'),0)  v_func_disc_cr_amt
, nvl((SELECT
        sum(e.amount_cr)        
FROM
        ar_customers                     a ,
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
AND     b.org_id                     = :p_org_id
AND     D.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,D.SET_OF_BOOKS_ID)
AND     e.source_Type IN ('EXCH_LOSS', 'EXCH_GAIN' )
AND     (b.invoice_currency_code      = :curr_code1 OR :curr_code1 IS NULL)
AND     a.customer_id                = :customer_id2
--AND     TRUNC(c.receipt_date)       <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND     TRUNC(d.gl_date)            <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) ),0) v_tran_loss_amt
, nvl((SELECT sum(e.acctd_amount_cr)       sum_exchange_amount
FROM
        ar_customers                     a ,
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
AND     b.org_id                     = :p_org_id
AND     D.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,D.SET_OF_BOOKS_ID)
AND     e.source_Type IN ('EXCH_LOSS', 'EXCH_GAIN' )
AND     (b.invoice_currency_code      = :curr_code1 OR :curr_code1 IS NULL)
AND     a.customer_id                = :customer_id2
--AND     TRUNC(c.receipt_date)       <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND     TRUNC(d.gl_date)            <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) ),0) v_func_loss_amt
, nvl((SELECT
        sum(e.amount_dr)             sum_amount 
FROM
        ar_customers                     a ,
        ra_customer_trx_all              b ,
        ar_cash_receipts_all             c ,
        ar_receivable_applications_all   d ,
        ar_distributions_all             e
WHERE
        a.customer_id                = b.BILL_TO_CUSTOMER_ID
AND     b.customer_trx_id            = d.APPLIED_CUSTOMER_TRX_ID
AND     c.cash_receipt_id            = d.cash_receipt_id
AND     e.SOURCE_ID                  = d.receivable_application_id
AND     b.org_id                     = :p_org_id
AND    b.CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND     B.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,B.SET_OF_BOOKS_ID)
AND    ( b.invoice_currency_code      = :curr_code1 OR :curr_code1 IS NULL)
AND     a.customer_id                =:customer_id2
--AND     TRUNC(c.receipt_date)       <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND     TRUNC(d.gl_date)            <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND     e.source_Type IN ('EXCH_GAIN','EXCH_LOSS' )),0)  v_tran_gain_amt
, nvl((SELECT
        sum(e.acctd_amount_dr)       sum_exchange_amount
FROM
        ar_customers                     a ,
        ra_customer_trx_all              b ,
        ar_cash_receipts_all             c ,
        ar_receivable_applications_all   d ,
        ar_distributions_all             e
WHERE
        a.customer_id                = b.BILL_TO_CUSTOMER_ID
AND     b.customer_trx_id            = d.APPLIED_CUSTOMER_TRX_ID
AND     c.cash_receipt_id            = d.cash_receipt_id
AND     e.SOURCE_ID                  = d.receivable_application_id
AND     b.org_id                     = :p_org_id
AND    b.CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND     B.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,B.SET_OF_BOOKS_ID)
AND     (b.invoice_currency_code      = :curr_code1 OR :curr_code1 IS NULL)
AND     a.customer_id                =:customer_id2
--AND     TRUNC(c.receipt_date)       <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND     TRUNC(d.gl_date)            <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND     e.source_Type IN ('EXCH_GAIN','EXCH_LOSS' )),0) v_func_gain_amt
, nvl((Select
	    sum(c.amount_applied)
From
	    ar_cash_receipts_all             A,
        ar_cash_receipt_history_all      B,
        ar_receivable_applications_all   c
Where
     	a.pay_from_customer          = :customer_id2
AND	    trunc(b.gl_date)              <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND     a.cash_receipt_id              = b.cash_receipt_id
and     a.cash_receipt_id              = c .cash_receipt_id
and     c.cash_receipt_history_id      = b.cash_receipt_history_id
and     c.applied_payment_schedule_id  = -3
and     c.status                       = 'ACTIVITY'
AND     (a.currency_code                = :curr_code1 OR :curr_code1 IS NULL)
AND    c.applied_CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
--- AND     B.REVERSAL_GL_DATE IS NULL ---commented by mohinder paul singh
AND     b.current_record_flag          = 'Y'
AND     a.org_id                       =:p_org_id
AND     A.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,A.SET_OF_BOOKS_ID)
and     not exists
 ( select 1
   from   ar_cash_receipt_history_all
   where  cash_receipt_id = b.cash_receipt_id
   and    status          = 'REVERSED'
 )),0) v_tran_rcp_w_off
, nvl(((Select
	    sum(c.amount_applied * NVL(a.exchange_rate,1.00)) sum_amount_exchange
From
	    ar_cash_receipts_all             A,
        ar_cash_receipt_history_all      B,
        ar_receivable_applications_all   c
Where
     	a.pay_from_customer          = :customer_id2
AND	    trunc(b.gl_date)              <= TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND     a.cash_receipt_id              = b.cash_receipt_id
and     a.cash_receipt_id              = c .cash_receipt_id
and     c.cash_receipt_history_id      = b.cash_receipt_history_id
and     c.applied_payment_schedule_id  = -3
and     c.status                       = 'ACTIVITY'
AND     (a.currency_code               = :curr_code1 OR :curr_code1 IS NULL)
AND    c.applied_CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
--- AND     B.REVERSAL_GL_DATE IS NULL ---commented by mohinder paul singh
AND     b.current_record_flag          = 'Y'
AND     a.org_id                       =:p_org_id
AND     A.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,A.SET_OF_BOOKS_ID)
and     not exists
 ( select 1
   from   ar_cash_receipt_history_all
   where  cash_receipt_id = b.cash_receipt_id
   and    status          = 'REVERSED'
 ))),0) v_func_rcp_w_off
FROM DUAL
) TBL_BASE) TBL_2
) TBL_3
) TBL_4) TBL_5









------------------------------------------------------
------------------------------------------------------
------------------------------------------------------
SELECT
CASE WHEN  NVL(func_CL_bal_tot_dr,0) - NVL(func_CL_bal_tot_cr,0) < 0 THEN
   ABS( NVL(func_CL_bal_tot_dr,0) - NVL(func_CL_bal_tot_cr,0))
ELSE
   0
END CL_TOT_CR 
, CASE WHEN  NVL(FUNC_CL_BAL_TOT_DR,0) - NVL(FUNC_CL_BAL_TOT_CR,0) < 0 THEN
   0
ELSE
   nvl(abs( NVL(func_CL_bal_tot_dr,0) - NVL(func_CL_bal_tot_cr,0)),0)
END CL_TOT_DR 
, CLOSE_BAL_TR
, (SELECT NVL(SUM(NVL(acctd_amount_applied_from,0)),0) FROM (
select BILL_TO_CUSTOMER_ID customer_id,(SELECT CUSTOMER_NAME FROM RA_CUSTOMERS WHERE CUSTOMER_ID=PAY_FROM_CUSTOMER) RECEIPT_CUSTOMER
,RECEIPT_NUMBER,t.trx_number,(select sum(revenue_amount) from ra_customer_trx_lines_all
where interface_line_attribute2=t.trx_number) INVOICE_amount,
invoice_currency_code INV_CURR,t.exchange_rate INV_RATE,
amount_applied APPLY_AMT,gl_date,gl_posted_date,NVL(acctd_amount_applied_from,0) acctd_amount_applied_from,acctd_amount_applied_to
,acctd_amount_applied_from-acctd_amount_applied_to "Gain/Loss" from
AR_RECEIVABLE_APPLICATIONS_all a,
ar_cash_receipts_all c,
ra_customer_trx_all t
WHERE a.cash_receipt_id=c.cash_receipt_id
AND INVOICE_CURRENCY_CODE = :curr_code
and t.CUSTOMER_TRX_ID=APPLIED_CUSTOMER_TRX_ID
 anD APPLIED_CUSTOMER_TRX_ID IN (
select CUSTOMER_TRX_ID from ra_customer_trx_all
where  BILL_TO_CUSTOMER_ID=:p_customer_id2
)
and gl_date<=:p_end_date_R
AND DISPLAY='Y'
AND PAY_FROM_CUSTOMER<>:p_customer_id2
union all
select BILL_TO_CUSTOMER_ID customer_id,(SELECT CUSTOMER_NAME FROM AR_CUSTOMERS WHERE CUSTOMER_ID=BILL_TO_CUSTOMER_ID) RECEIPT_CUSTOMER
,RECEIPT_NUMBER,t.trx_number,(select sum(revenue_amount) from ra_customer_trx_lines_all
where interface_line_attribute2=t.trx_number) INVOICE_amount,
invoice_currency_code INV_CURR,t.exchange_rate INV_RATE,
amount_applied APPLY_AMT,gl_date,gl_posted_date,NVL(acctd_amount_applied_from*-1,0),acctd_amount_applied_to
,acctd_amount_applied_from-acctd_amount_applied_to "Gain/Loss" from
AR_RECEIVABLE_APPLICATIONS_all a,
ar_cash_receipts_all c,
ra_customer_trx_all t
WHERE a.cash_receipt_id=c.cash_receipt_id
AND INVOICE_CURRENCY_CODE = :curr_code
and t.CUSTOMER_TRX_ID=APPLIED_CUSTOMER_TRX_ID
 anD APPLIED_CUSTOMER_TRX_ID not IN (
select CUSTOMER_TRX_ID from ra_customer_trx_all
where  BILL_TO_CUSTOMER_ID=:p_customer_id2
)
and gl_date<=:p_end_date_R
AND DISPLAY='Y'
AND PAY_FROM_CUSTOMER=:p_customer_id2
UNION ALL
SELECT 
PAY_FROM_CUSTOMER,
NULL,
RECEIPT_NUMBER,
RECEIPT_NUMBER,
NVL(H.FACTOR_DISCOUNT_AMOUNT,0),
C.CURRENCY_CODE,
C.EXCHANGE_RATE,NULL,NULL,NULL,
NVL(NVL(H.FACTOR_DISCOUNT_AMOUNT,0)*NVL(C.EXCHANGE_RATE,1)*-1,0) acctd_amount_applied_from,NULL,NULL
FROM ar_cash_receipt_history_all H,ar_cash_receipts_all C
WHERE C.cash_receipt_id IN (
select cash_receipt_id from ar_cash_receipts_all
where RECEIPT_date<=:p_end_date_R
)
AND C.CURRENCY_CODE = :curr_code
and gl_date>:p_end_date_R
AND C.cash_receipt_id=H.cash_receipt_id
AND  PAY_FROM_CUSTOMER=:p_customer_id2
AND  PAY_FROM_CUSTOMER<>'7730'
AND CURRENT_RECORD_FLAG='Y'
)) CF_APPLIEF_FROM_function
, (SELECT SUM (acctd_amount_applied_from)
FROM (SELECT 
BILL_TO_CUSTOMER_ID customer_id,(SELECT CUSTOMER_NAME FROM AR_CUSTOMERS WHERE CUSTOMER_ID=PAY_FROM_CUSTOMER) RECEIPT_CUSTOMER,
RECEIPT_NUMBER,
t.trx_number,(SELECT SUM(revenue_amount) FROM ra_customer_trx_lines_all
WHERE interface_line_attribute2=t.trx_number) INVOICE_amount,
invoice_currency_code INV_CURR,t.exchange_rate INV_RATE,
amount_applied APPLY_AMT,gl_date,gl_posted_date,acctd_amount_applied_from,acctd_amount_applied_to
,acctd_amount_applied_from-acctd_amount_applied_to "Gain/Loss" ,'A' source
FROM 
AR_RECEIVABLE_APPLICATIONS_all a,
ar_cash_receipts_all c,
ra_customer_trx_all t
WHERE a.cash_receipt_id=c.cash_receipt_id
AND invoice_currency_code = :CURR_CODE
AND t.CUSTOMER_TRX_ID=APPLIED_CUSTOMER_TRX_ID 
AND A.SET_OF_BOOKS_ID = NVL(:P_SOB_ID,A.SET_OF_BOOKS_ID)
AND APPLIED_CUSTOMER_TRX_ID IN (
SELECT CUSTOMER_TRX_ID FROM ra_customer_trx_all
WHERE  BILL_TO_CUSTOMER_ID=:p_customer_id2
AND    SET_OF_BOOKS_ID = NVL(:P_SOB_ID,SET_OF_BOOKS_ID)
)
AND gl_date<=:p_end_date_R
AND DISPLAY='Y'
AND PAY_FROM_CUSTOMER<>:p_customer_id2
UNION ALL
SELECT BILL_TO_CUSTOMER_ID customer_id,(SELECT CUSTOMER_NAME FROM AR_CUSTOMERS WHERE CUSTOMER_ID=BILL_TO_CUSTOMER_ID) RECEIPT_CUSTOMER,
RECEIPT_NUMBER,t.trx_number,(SELECT SUM(revenue_amount) FROM ra_customer_trx_lines_all
WHERE interface_line_attribute2=t.trx_number) INVOICE_amount,
invoice_currency_code INV_CURR,t.exchange_rate INV_RATE,
amount_applied APPLY_AMT,gl_date,gl_posted_date,acctd_amount_applied_from*-1,acctd_amount_applied_to
,acctd_amount_applied_from-acctd_amount_applied_to "Gain/Loss",'B' source
FROM 
AR_RECEIVABLE_APPLICATIONS_all a,
ar_cash_receipts_all c,
ra_customer_trx_all t
WHERE a.cash_receipt_id=c.cash_receipt_id
AND invoice_currency_code = :CURR_CODE
AND t.CUSTOMER_TRX_ID=APPLIED_CUSTOMER_TRX_ID 
AND A.SET_OF_BOOKS_ID = NVL(:P_SOB_ID,A.SET_OF_BOOKS_ID)
AND APPLIED_CUSTOMER_TRX_ID NOT IN (
SELECT CUSTOMER_TRX_ID FROM ra_customer_trx_all
WHERE  BILL_TO_CUSTOMER_ID=:p_customer_id2
AND    SET_OF_BOOKS_ID = NVL(:P_SOB_ID,SET_OF_BOOKS_ID)
))) CS_SUM_APPLIED_OTHERS
FROM ( 
SELECT SUM(FUNC_CLOSE_BAL_CR) FUNC_CL_BAL_TOT_CR
, SUM(FUNC_CLOSE_BAL_DR) FUNC_CL_BAL_TOT_DR
, SUM(TRAN_CLOSE_BAL_CR)
, SUM(CLOSE_BAL_TR) CLOSE_BAL_TR
FROM 
(SELECT  CASE WHEN NVL(v_func_tot_amt,0) < 0  THEN ABS(v_func_tot_amt) ELSE 0 END FUNC_CLOSE_BAL_CR
, CASE WHEN NVL(v_func_tot_amt,0) < 0  THEN 0 ELSE ABS(v_func_tot_amt) END FUNC_CLOSE_BAL_DR
, CASE WHEN NVL(v_tran_tot_amt,0) < 0  THEN ABS(NVL(v_tran_tot_amt,0)) ELSE 0 END TRAN_CLOSE_BAL_CR
--, CASE WHEN NVL(v_tran_tot_amt,0) < 0  THEN ABS(NVL(v_tran_tot_amt,0)) ELSE 0 END tran_CLOSE_bal_cr
, CASE WHEN NVL(v_tran_tot_amt,0) < 0  THEN 0 ELSE (ABS(NVL(v_tran_tot_amt,0))) END CLOSE_BAL_TR
FROM (
SELECT ( NVL(v_func_dr_amt,0      )
                      + nvl(v_cre_memo_func_amt,0)
                      + NVL(v_func_rev_amt,0     )
                      - NVL(v_func_cr_amt,0      )
                      + NVL(v_func_rcp_w_off,0   )
                      + (NVL(v_func_adj_amt,0   ))
                      - NVL(v_func_disc_cr_amt,0 )
                      - NVL(v_func_gain_amt,0    )
                      + NVL(v_func_loss_amt,0    )
                      ) v_func_tot_amt
, ( (NVL(v_tr_dr_amt,0)     )
                       + nvl(v_cre_memo_amt,0   )
                       +(NVL(v_tr_rev_amt,0    ))
                       - NVL(v_tr_cr_amt,0      )
                       + NVL(v_tran_rcp_w_off,0 )
                       - abs(NVL(v_tr_adj_amt,0))
                       - NVL(v_tr_disc_cr_amt,0)) v_tran_tot_amt
FROM (
SELECT 
(Select
	  sum((b.amount)) sum_ext_amount
From
      ra_customer_trx_all                A,
      ar_payment_schedules_all           C,
      ra_cust_trx_line_gl_dist_all       B
Where
	    a.bill_to_customer_id        = :customer_id
-- AND 	trunc(a.trx_date)            < trunc(:P_END_DATE)
AND 	trunc(c.gl_date)            < TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND 	a.invoice_currency_code      = :curr_code
AND 	a.complete_flag              = 'Y'
AND 	b.customer_trx_id            = a.customer_trx_id
AND 	b.account_class              = 'REC'
AND     b.LATEST_REC_FLAG            = 'Y'
AND     A.customer_trx_id            = C.customer_trx_id
AND     C.class In('INV','DM','DEP')
AND    A.CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND     a.org_id                     =:p_org_id
AND     A.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,A.SET_OF_BOOKS_ID)
AND c.Payment_schedule_id
IN (SELECT MIN(PAYMENT_SCHEDULE_ID)
    FROM   AR_PAYMENT_SCHEDULES_ALL
  	WHERE  CUSTOMER_TRX_ID = C.CUSTOMER_TRX_ID
   )) v_tr_dr_amt
, (Select
	  sum((b.amount) * NVL(A.exchange_rate,1))
From
      ra_customer_trx_all                A,
      ar_payment_schedules_all           C,
      ra_cust_trx_line_gl_dist_all       B
Where
	    a.bill_to_customer_id        = :customer_id
-- AND 	trunc(a.trx_date)            < trunc(:p_start_date)
AND 	trunc(c.gl_date)            < TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND 	a.invoice_currency_code      = :curr_code
AND 	a.complete_flag              = 'Y'
AND 	b.customer_trx_id            = a.customer_trx_id
AND 	b.account_class              = 'REC'
AND     b.LATEST_REC_FLAG            = 'Y'
AND     A.customer_trx_id            = C.customer_trx_id
AND     C.class In('INV','DM','DEP')
AND    A.CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND     a.org_id                     =:p_org_id
AND     A.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,A.SET_OF_BOOKS_ID)
AND c.Payment_schedule_id
IN (SELECT MIN(PAYMENT_SCHEDULE_ID)
    FROM   AR_PAYMENT_SCHEDULES_ALL
  	WHERE  CUSTOMER_TRX_ID = C.CUSTOMER_TRX_ID
   ))   
v_func_dr_amt 
, (
SELECT 
   	   sum((b.amount)) sum_adj_amount
FROM
       ra_customers                      a
   , ar_adjustments_all                b
   , ra_customer_trx_all               c
   , ar_payment_schedules_all          d
   , gl_code_combinations              e
WHERE
    	a.customer_id                =  :customer_id
AND 	b.customer_trx_id            =  c.customer_trx_id
AND 	c.bill_to_customer_id        =  a.customer_id
and     e.code_combination_id        = b.code_combination_id
AND 	trunc(b.apply_date)          < TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR'))
AND 	trunc(b.gl_date)          < TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
 AND     c.invoice_currency_code      = :curr_code
AND 	b.status                     = 'A'
AND    C.CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND	    b.customer_trx_id            = d.customer_trx_id
AND     c.org_id                     =:p_org_id
AND     B.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,B.SET_OF_BOOKS_ID)
and     d.payment_schedule_id
IN      (SELECT MIN(PAYMENT_SCHEDULE_ID)
         FROM   AR_PAYMENT_SCHEDULES_ALL
	     WHERE  CUSTOMER_TRX_ID = d.CUSTOMER_TRX_ID
	    )
) v_tr_adj_amt
, 
(
SELECT 
	   sum((b.amount) * NVL(C.exchange_rate,1)) --sum_extended_amount_exchange
FROM
       ra_customers                      a
   , ar_adjustments_all                b
   , ra_customer_trx_all               c
   , ar_payment_schedules_all          d
   , gl_code_combinations              e
WHERE
    	a.customer_id                =  :customer_id
AND 	b.customer_trx_id            =  c.customer_trx_id
AND 	c.bill_to_customer_id        =  a.customer_id
and     e.code_combination_id        = b.code_combination_id
AND 	trunc(b.apply_date)          < TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR'))
AND 	trunc(b.gl_date)          < TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
 AND     c.invoice_currency_code      = :curr_code
AND 	b.status                     = 'A'
AND    C.CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND	    b.customer_trx_id            = d.customer_trx_id
AND     c.org_id                     =:p_org_id
AND     B.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,B.SET_OF_BOOKS_ID)
and     d.payment_schedule_id
IN      (SELECT MIN(PAYMENT_SCHEDULE_ID)
         FROM   AR_PAYMENT_SCHEDULES_ALL
	     WHERE  CUSTOMER_TRX_ID = d.CUSTOMER_TRX_ID
	    )
) v_func_adj_amt
, (
Select  --DISTINCT a.currency_code 
	   	sum(a.amount)                             
From
	   	ar_cash_receipts_all              A
Where 1=1
AND   a.pay_from_customer           = :customer_id
 AND   a.currency_code               = :curr_code
AND   a.org_id=:p_org_id
AND   A.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,A.SET_OF_BOOKS_ID)
--Added the below by Sanjikum for Bug #3962497
AND 		EXISTS (	SELECT	1 
									FROM 		ar_cash_receipt_history_all
									WHERE		cash_receipt_id = a.cash_receipt_id
									AND  		org_id = :p_org_id
									AND 		trunc(gl_date) < TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
							 )) v_tr_cr_amt
, (
Select  
	   	sum(a.amount * NVL(a.exchange_rate,1.00)) sum_amount_exchange
From
	   	ar_cash_receipts_all              A
Where 1=1
AND   a.pay_from_customer           = :customer_id
 AND   a.currency_code               = :curr_code
AND   a.org_id=:p_org_id
AND   A.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,A.SET_OF_BOOKS_ID)
--Added the below by Sanjikum for Bug #3962497
AND 		EXISTS (	SELECT	1 
									FROM 		ar_cash_receipt_history_all
									WHERE		cash_receipt_id = a.cash_receipt_id
									AND  		org_id = :p_org_id
									AND 		trunc(gl_date) < TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
							 )) v_func_cr_amt
, (
Select 
	   sum(a.amount)                             sum_amount
From
	   ar_cash_receipts_all              A
	   , ar_cash_receipt_history_all       b -- added by sriram - 3328962
Where 1=1
AND    a.cash_receipt_id             = b.cash_receipt_id
AND    a.pay_from_customer           = :customer_id
AND	   trunc(b.gl_date)              < TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR'))
AND    a.reversal_date                 is not null
AND    a.currency_code               = :curr_code
--AND    b.current_record_flag         = 'Y' --Commented by Sanjikum for Bug #3962497
AND 	 b.status                      = 'REVERSED' --Added by Sanjikum for Bug #3962497
AND    a.org_id                      = :p_org_id
AND     A.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,A.SET_OF_BOOKS_ID) 
) v_tr_rev_amt
, (
Select 
	   sum(a.amount * NVL(a.exchange_rate,1.00)) sum_amount_exchange -- a. added by sriram 
From
	   ar_cash_receipts_all              A
	   , ar_cash_receipt_history_all       b -- added by sriram - 3328962
Where 1=1
AND    a.cash_receipt_id             = b.cash_receipt_id
AND    a.pay_from_customer           = :customer_id
AND	   trunc(b.gl_date)              < TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR'))
AND    a.reversal_date                 is not null
AND    a.currency_code               = :curr_code
--AND    b.current_record_flag         = 'Y' --Commented by Sanjikum for Bug #3962497
AND 	 b.status                      = 'REVERSED' --Added by Sanjikum for Bug #3962497
AND    a.org_id                      = :p_org_id
AND     A.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,A.SET_OF_BOOKS_ID) 
)  v_func_rev_amt
, (
Select
   	   nvl(sum(abs(NVL(d.EARNED_DISCOUNT_TAKEN,0))),0)   
From
	   ra_customers                      a,
	   ra_customer_trx_ALL               B,
	   ar_receivable_applications_all    D
Where
	   a.customer_id                 = :customer_id
AND	   b.bill_to_customer_id         = a.customer_id
AND	   b.complete_flag               = 'Y'
AND    trunc(d.GL_DATE)              < TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR'))
AND    d.applied_customer_trx_id             = b.customer_trx_id
AND    b.invoice_currency_code       = :curr_code
AND    d.earned_DISCOUNT_TAKEN         is not  null 
and    d.earned_DISCOUNT_TAKEN       <> 0
AND    D.APPLIED_CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND    B.org_id                      = :p_org_id
AND    B.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,B.SET_OF_BOOKS_ID)
and    d.application_type = 'CASH' 
and    d.display = 'Y'
) v_tr_disc_cr_amt
, (
Select
	   nvl(sum(abs(NVL(d.ACCTD_EARNED_DISCOUNT_TAKEN,0))),0)  sum_amount_exchange
From
	   ra_customers                      a,
	   ra_customer_trx_ALL               B,
	   ar_receivable_applications_all    D
Where
	   a.customer_id                 = :customer_id
AND	   b.bill_to_customer_id         = a.customer_id
AND	   b.complete_flag               = 'Y'
AND    trunc(d.GL_DATE)              < TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR'))
AND    d.applied_customer_trx_id             = b.customer_trx_id
AND    b.invoice_currency_code       = :curr_code
AND    d.earned_DISCOUNT_TAKEN         is not  null 
and    d.earned_DISCOUNT_TAKEN       <> 0
AND    D.APPLIED_CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND    B.org_id                      = :p_org_id
AND    B.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,B.SET_OF_BOOKS_ID)
and    d.application_type = 'CASH' 
and    d.display = 'Y'
)  v_func_disc_cr_amt 
, (
SELECT 
       sum(e.AMOUNT_cr)              sum_amount 
FROM
       RA_customers                      a ,
       ra_customer_trx_all               b ,
       ar_cash_receipts_all              c ,
       ar_receivable_applications_all    d ,
       ar_distributions_all              e
WHERE
       a.customer_id                 =  b.BILL_TO_CUSTOMER_ID
AND    b.customer_trx_id             =  d.APPLIED_CUSTOMER_TRX_ID
AND    c.cash_receipt_id             =  d.cash_receipt_id
AND    e.SOURCE_ID                   =  d.receivable_application_id
AND    b.org_id                      =  :p_org_id
AND    B.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,B.SET_OF_BOOKS_ID)
AND    e.source_Type                 IN ('EXCH_LOSS','EXCH_GAIN' )
AND    B.CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND    b.invoice_currency_code       =  :curr_code
AND    a.customer_id                 =  :customer_id
--AND    TRUNC(c.receipt_date)         <  trunc(:P_END_DATE);
AND    TRUNC(d.gl_date)              <  TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR'))
) v_tran_loss_amt
, (
(
SELECT 
       sum(e.ACCTD_AMOUNT_cr)        sum_exchange_amount
FROM
       RA_customers                      a ,
       ra_customer_trx_all               b ,
       ar_cash_receipts_all              c ,
       ar_receivable_applications_all    d ,
       ar_distributions_all              e
WHERE
       a.customer_id                 =  b.BILL_TO_CUSTOMER_ID
AND    b.customer_trx_id             =  d.APPLIED_CUSTOMER_TRX_ID
AND    c.cash_receipt_id             =  d.cash_receipt_id
AND    e.SOURCE_ID                   =  d.receivable_application_id
AND    b.org_id                      =  :p_org_id
AND    B.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,B.SET_OF_BOOKS_ID)
AND    e.source_Type                 IN ('EXCH_LOSS','EXCH_GAIN' )
AND    B.CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND    b.invoice_currency_code       =  :curr_code
AND    a.customer_id                 =  :customer_id
--AND    TRUNC(c.receipt_date)         <  trunc(:P_END_DATE);
AND    TRUNC(d.gl_date)              <  TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR'))
)) v_func_loss_amt
, (SELECT
       sum(e.amount_dr)             sum_amount
FROM
       ra_customers                      a ,
       ra_customer_trx_all               b ,
       ar_cash_receipts_all              c,
       ar_receivable_applications_all    d,
       ar_distributions_all              e
WHERE
       a.customer_id                 =  b.BILL_TO_CUSTOMER_ID
AND    b.customer_trx_id             =  d.APPLIED_CUSTOMER_TRX_ID
AND    c.cash_receipt_id             =  d.cash_receipt_id
AND    e.SOURCE_ID                   =  d.receivable_application_id
AND    b.org_id                      =  :p_org_id
AND    B.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,B.SET_OF_BOOKS_ID)
AND    B.CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND    e.source_Type                IN  ('EXCH_GAIN','EXCH_LOSS' )
AND    b.invoice_currency_code       = :curr_code
AND    a.customer_id                 =:customer_id
--AND    TRUNC(c.receipt_date)         < trunc(:P_END_DATE) ;
AND    TRUNC(d.gl_date)              < TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR'))) v_tran_gain_amt
, (SELECT
       sum(e.acctd_amount_dr)       sum_exchange_amount
FROM
       ra_customers                      a ,
       ra_customer_trx_all               b ,
       ar_cash_receipts_all              c,
       ar_receivable_applications_all    d,
       ar_distributions_all              e
WHERE
       a.customer_id                 =  b.BILL_TO_CUSTOMER_ID
AND    b.customer_trx_id             =  d.APPLIED_CUSTOMER_TRX_ID
AND    c.cash_receipt_id             =  d.cash_receipt_id
AND    e.SOURCE_ID                   =  d.receivable_application_id
AND    b.org_id                      =  :p_org_id
AND    B.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,B.SET_OF_BOOKS_ID)
AND    B.CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND    e.source_Type                IN  ('EXCH_GAIN','EXCH_LOSS' )
AND    b.invoice_currency_code       = :curr_code
AND    a.customer_id                 =:customer_id
--AND    TRUNC(c.receipt_date)         < trunc(:P_END_DATE) ;
AND    TRUNC(d.gl_date)              < TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR'))) v_func_gain_amt
, (Select 
	   sum(c.amount_applied)                             sum_amount
From
	   ar_cash_receipts_all              A
	   , ar_cash_receipt_history_all       B
	   , ar_receivable_applications_all    c
Where 1=1
AND       a.pay_from_customer           = :customer_id
AND	   trunc(b.gl_date)              < TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR'))
AND    a.cash_receipt_id             = b.cash_receipt_id
and    a.cash_receipt_id             = c .cash_receipt_id
and    c.cash_receipt_history_id     = b.cash_receipt_history_id
and    c.applied_payment_schedule_id = -3
and    c.status                      = 'ACTIVITY'
AND    a.currency_code               = :curr_code
--AND    B.REVERSAL_GL_DATE IS NULL --- commented by mohinder paul singh
AND    b.current_record_flag         = 'Y'
AND    a.org_id                      = :p_org_id
AND    A.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,A.SET_OF_BOOKS_ID) 
and    not exists
 ( select 1
   from   ar_cash_receipt_history_all
   where  cash_receipt_id = b.cash_receipt_id
   and    status = 'REVERSED'
 )) v_tran_rcp_w_off
 ,(Select 
	   sum(c.amount_applied * NVL(a.exchange_rate,1.00)) sum_amount_exchange
From
	   ar_cash_receipts_all              A
	   , ar_cash_receipt_history_all       B
	   , ar_receivable_applications_all    c
Where 1=1
AND       a.pay_from_customer           = :customer_id
AND	   trunc(b.gl_date)              < TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR'))
AND    a.cash_receipt_id             = b.cash_receipt_id
and    a.cash_receipt_id             = c .cash_receipt_id
and    c.cash_receipt_history_id     = b.cash_receipt_history_id
and    c.applied_payment_schedule_id = -3
and    c.status                      = 'ACTIVITY'
AND    a.currency_code               = :curr_code
--AND    B.REVERSAL_GL_DATE IS NULL --- commented by mohinder paul singh
AND    b.current_record_flag         = 'Y'
AND    a.org_id                      = :p_org_id
AND    A.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,A.SET_OF_BOOKS_ID) 
and    not exists
 ( select 1
   from   ar_cash_receipt_history_all
   where  cash_receipt_id = b.cash_receipt_id
   and    status = 'REVERSED'
 )) v_func_rcp_w_off
 , (Select 
	       sum((b.amount)) sum_ext_amount
   From
           ra_customer_trx_all           A,
           ar_payment_schedules_all      C,
           ra_cust_trx_line_gl_dist_all  B
Where
           a.bill_to_customer_id        = :customer_id
--AND 	   trunc(a.trx_date)            < trunc(:P_END_DATE)
AND 	   trunc(c.gl_date)             < TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR'))
AND 	   a.invoice_currency_code      = :curr_code
AND 	   a.complete_flag              = 'Y'
AND 	   b.customer_trx_id            = a.customer_trx_id
AND 	   b.account_class              = 'REC'
AND        b.LATEST_REC_FLAG            = 'Y'
AND        A.customer_trx_id            = C.customer_trx_id
AND        C.class In('CM')
AND    A.CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND        a.org_id                     =:p_org_id
AND        A.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,A.SET_OF_BOOKS_ID)
AND        c.payment_schedule_id
IN         (SELECT MIN(PAYMENT_SCHEDULE_ID)
            FROM   AR_PAYMENT_SCHEDULES_ALL
	        WHERE  CUSTOMER_TRX_ID = C.CUSTOMER_TRX_ID
	       )) v_cre_memo_amt
, (Select 
	       sum((b.amount) * NVL(A.exchange_rate,1))
   From
           ra_customer_trx_all           A,
           ar_payment_schedules_all      C,
           ra_cust_trx_line_gl_dist_all  B
Where
           a.bill_to_customer_id        = :customer_id
--AND 	   trunc(a.trx_date)            < trunc(:P_END_DATE)
AND 	   trunc(c.gl_date)             < TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR'))
AND 	   a.invoice_currency_code      = :curr_code
AND 	   a.complete_flag              = 'Y'
AND 	   b.customer_trx_id            = a.customer_trx_id
AND 	   b.account_class              = 'REC'
AND        b.LATEST_REC_FLAG            = 'Y'
AND        A.customer_trx_id            = C.customer_trx_id
AND        C.class In('CM')
AND    A.CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND        a.org_id                     =:p_org_id
AND        A.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,A.SET_OF_BOOKS_ID)
AND        c.payment_schedule_id
IN         (SELECT MIN(PAYMENT_SCHEDULE_ID)
            FROM   AR_PAYMENT_SCHEDULES_ALL
	        WHERE  CUSTOMER_TRX_ID = C.CUSTOMER_TRX_ID
	       )) v_cre_memo_func_amt
FROM DUAL
)))
)
------------------------------------------------------------------------------------------------------------------------
-- CLOSING RELATED QUERY
SELECT
CASE WHEN  NVL(func_CL_bal_tot_dr,0) - NVL(func_CL_bal_tot_cr,0) < 0 THEN
   ABS( NVL(func_CL_bal_tot_dr,0) - NVL(func_CL_bal_tot_cr,0))
ELSE
   0
END CL_TOT_CR 
, CASE WHEN  NVL(FUNC_CL_BAL_TOT_DR,0) - NVL(FUNC_CL_BAL_TOT_CR,0) < 0 THEN
   0
ELSE
   nvl(abs( NVL(func_CL_bal_tot_dr,0) - NVL(func_CL_bal_tot_cr,0)),0)
END CL_TOT_DR 
, CLOSE_BAL_TR
, (SELECT NVL(SUM(NVL(acctd_amount_applied_from,0)),0) FROM (
select BILL_TO_CUSTOMER_ID customer_id,(SELECT CUSTOMER_NAME FROM RA_CUSTOMERS WHERE CUSTOMER_ID=PAY_FROM_CUSTOMER) RECEIPT_CUSTOMER
,RECEIPT_NUMBER,t.trx_number,(select sum(revenue_amount) from ra_customer_trx_lines_all
where interface_line_attribute2=t.trx_number) INVOICE_amount,
invoice_currency_code INV_CURR,t.exchange_rate INV_RATE,
amount_applied APPLY_AMT,gl_date,gl_posted_date,NVL(acctd_amount_applied_from,0) acctd_amount_applied_from,acctd_amount_applied_to
,acctd_amount_applied_from-acctd_amount_applied_to "Gain/Loss" from
AR_RECEIVABLE_APPLICATIONS_all a,
ar_cash_receipts_all c,
ra_customer_trx_all t
WHERE a.cash_receipt_id=c.cash_receipt_id
AND INVOICE_CURRENCY_CODE = :curr_code
and t.CUSTOMER_TRX_ID=APPLIED_CUSTOMER_TRX_ID
 anD APPLIED_CUSTOMER_TRX_ID IN (
select CUSTOMER_TRX_ID from ra_customer_trx_all
where  BILL_TO_CUSTOMER_ID=:p_customer_id2
)
and gl_date<=:p_end_date_R
AND DISPLAY='Y'
AND PAY_FROM_CUSTOMER<>:p_customer_id2
union all
select BILL_TO_CUSTOMER_ID customer_id,(SELECT CUSTOMER_NAME FROM AR_CUSTOMERS WHERE CUSTOMER_ID=BILL_TO_CUSTOMER_ID) RECEIPT_CUSTOMER
,RECEIPT_NUMBER,t.trx_number,(select sum(revenue_amount) from ra_customer_trx_lines_all
where interface_line_attribute2=t.trx_number) INVOICE_amount,
invoice_currency_code INV_CURR,t.exchange_rate INV_RATE,
amount_applied APPLY_AMT,gl_date,gl_posted_date,NVL(acctd_amount_applied_from*-1,0),acctd_amount_applied_to
,acctd_amount_applied_from-acctd_amount_applied_to "Gain/Loss" from
AR_RECEIVABLE_APPLICATIONS_all a,
ar_cash_receipts_all c,
ra_customer_trx_all t
WHERE a.cash_receipt_id=c.cash_receipt_id
AND INVOICE_CURRENCY_CODE = :curr_code
and t.CUSTOMER_TRX_ID=APPLIED_CUSTOMER_TRX_ID
 anD APPLIED_CUSTOMER_TRX_ID not IN (
select CUSTOMER_TRX_ID from ra_customer_trx_all
where  BILL_TO_CUSTOMER_ID=:p_customer_id2
)
and gl_date<=:p_end_date_R
AND DISPLAY='Y'
AND PAY_FROM_CUSTOMER=:p_customer_id2
UNION ALL
SELECT 
PAY_FROM_CUSTOMER,
NULL,
RECEIPT_NUMBER,
RECEIPT_NUMBER,
NVL(H.FACTOR_DISCOUNT_AMOUNT,0),
C.CURRENCY_CODE,
C.EXCHANGE_RATE,NULL,NULL,NULL,
NVL(NVL(H.FACTOR_DISCOUNT_AMOUNT,0)*NVL(C.EXCHANGE_RATE,1)*-1,0) acctd_amount_applied_from,NULL,NULL
FROM ar_cash_receipt_history_all H,ar_cash_receipts_all C
WHERE C.cash_receipt_id IN (
select cash_receipt_id from ar_cash_receipts_all
where RECEIPT_date<=:p_end_date_R
)
AND C.CURRENCY_CODE = :curr_code
and gl_date>:p_end_date_R
AND C.cash_receipt_id=H.cash_receipt_id
AND  PAY_FROM_CUSTOMER=:p_customer_id2
AND  PAY_FROM_CUSTOMER<>'7730'
AND CURRENT_RECORD_FLAG='Y'
)) CF_APPLIEF_FROM_FUNC
FROM ( 
SELECT SUM(FUNC_CLOSE_BAL_CR) FUNC_CL_BAL_TOT_CR
, SUM(FUNC_CLOSE_BAL_DR) FUNC_CL_BAL_TOT_DR
, SUM(TRAN_CLOSE_BAL_CR)
, SUM(CLOSE_BAL_TR) CLOSE_BAL_TR
FROM 
(SELECT  CASE WHEN NVL(v_func_tot_amt,0) < 0  THEN ABS(v_func_tot_amt) ELSE 0 END FUNC_CLOSE_BAL_CR
, CASE WHEN NVL(v_func_tot_amt,0) < 0  THEN 0 ELSE ABS(v_func_tot_amt) END FUNC_CLOSE_BAL_DR
, CASE WHEN NVL(v_tran_tot_amt,0) < 0  THEN ABS(NVL(v_tran_tot_amt,0)) ELSE 0 END TRAN_CLOSE_BAL_CR
--, CASE WHEN NVL(v_tran_tot_amt,0) < 0  THEN ABS(NVL(v_tran_tot_amt,0)) ELSE 0 END tran_CLOSE_bal_cr
, CASE WHEN NVL(v_tran_tot_amt,0) < 0  THEN 0 ELSE (ABS(NVL(v_tran_tot_amt,0))) END CLOSE_BAL_TR
FROM (
SELECT ( NVL(v_func_dr_amt,0      )
                      + nvl(v_cre_memo_func_amt,0)
                      + NVL(v_func_rev_amt,0     )
                      - NVL(v_func_cr_amt,0      )
                      + NVL(v_func_rcp_w_off,0   )
                      + (NVL(v_func_adj_amt,0   ))
                      - NVL(v_func_disc_cr_amt,0 )
                      - NVL(v_func_gain_amt,0    )
                      + NVL(v_func_loss_amt,0    )
                      ) v_func_tot_amt
, ( (NVL(v_tr_dr_amt,0)     )
                       + nvl(v_cre_memo_amt,0   )
                       +(NVL(v_tr_rev_amt,0    ))
                       - NVL(v_tr_cr_amt,0      )
                       + NVL(v_tran_rcp_w_off,0 )
                       - abs(NVL(v_tr_adj_amt,0))
                       - NVL(v_tr_disc_cr_amt,0)) v_tran_tot_amt
FROM (
SELECT 
(Select
	  sum((b.amount)) sum_ext_amount
From
      ra_customer_trx_all                A,
      ar_payment_schedules_all           C,
      ra_cust_trx_line_gl_dist_all       B
Where
	    a.bill_to_customer_id        = :customer_id
-- AND 	trunc(a.trx_date)            < trunc(:P_END_DATE)
AND 	trunc(c.gl_date)            < TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND 	a.invoice_currency_code      = :curr_code
AND 	a.complete_flag              = 'Y'
AND 	b.customer_trx_id            = a.customer_trx_id
AND 	b.account_class              = 'REC'
AND     b.LATEST_REC_FLAG            = 'Y'
AND     A.customer_trx_id            = C.customer_trx_id
AND     C.class In('INV','DM','DEP')
AND    A.CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND     a.org_id                     =:p_org_id
AND     A.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,A.SET_OF_BOOKS_ID)
AND c.Payment_schedule_id
IN (SELECT MIN(PAYMENT_SCHEDULE_ID)
    FROM   AR_PAYMENT_SCHEDULES_ALL
  	WHERE  CUSTOMER_TRX_ID = C.CUSTOMER_TRX_ID
   )) v_tr_dr_amt
, (Select
	  sum((b.amount) * NVL(A.exchange_rate,1))
From
      ra_customer_trx_all                A,
      ar_payment_schedules_all           C,
      ra_cust_trx_line_gl_dist_all       B
Where
	    a.bill_to_customer_id        = :customer_id
-- AND 	trunc(a.trx_date)            < trunc(:p_start_date)
AND 	trunc(c.gl_date)            < TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND 	a.invoice_currency_code      = :curr_code
AND 	a.complete_flag              = 'Y'
AND 	b.customer_trx_id            = a.customer_trx_id
AND 	b.account_class              = 'REC'
AND     b.LATEST_REC_FLAG            = 'Y'
AND     A.customer_trx_id            = C.customer_trx_id
AND     C.class In('INV','DM','DEP')
AND    A.CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND     a.org_id                     =:p_org_id
AND     A.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,A.SET_OF_BOOKS_ID)
AND c.Payment_schedule_id
IN (SELECT MIN(PAYMENT_SCHEDULE_ID)
    FROM   AR_PAYMENT_SCHEDULES_ALL
  	WHERE  CUSTOMER_TRX_ID = C.CUSTOMER_TRX_ID
   ))   
v_func_dr_amt 
, (
SELECT 
   	   sum((b.amount)) sum_adj_amount
FROM
       ra_customers                      a
   , ar_adjustments_all                b
   , ra_customer_trx_all               c
   , ar_payment_schedules_all          d
   , gl_code_combinations              e
WHERE
    	a.customer_id                =  :customer_id
AND 	b.customer_trx_id            =  c.customer_trx_id
AND 	c.bill_to_customer_id        =  a.customer_id
and     e.code_combination_id        = b.code_combination_id
AND 	trunc(b.apply_date)          < TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR'))
AND 	trunc(b.gl_date)          < TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
 AND     c.invoice_currency_code      = :curr_code
AND 	b.status                     = 'A'
AND    C.CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND	    b.customer_trx_id            = d.customer_trx_id
AND     c.org_id                     =:p_org_id
AND     B.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,B.SET_OF_BOOKS_ID)
and     d.payment_schedule_id
IN      (SELECT MIN(PAYMENT_SCHEDULE_ID)
         FROM   AR_PAYMENT_SCHEDULES_ALL
	     WHERE  CUSTOMER_TRX_ID = d.CUSTOMER_TRX_ID
	    )
) v_tr_adj_amt
, 
(
SELECT 
	   sum((b.amount) * NVL(C.exchange_rate,1)) --sum_extended_amount_exchange
FROM
       ra_customers                      a
   , ar_adjustments_all                b
   , ra_customer_trx_all               c
   , ar_payment_schedules_all          d
   , gl_code_combinations              e
WHERE
    	a.customer_id                =  :customer_id
AND 	b.customer_trx_id            =  c.customer_trx_id
AND 	c.bill_to_customer_id        =  a.customer_id
and     e.code_combination_id        = b.code_combination_id
AND 	trunc(b.apply_date)          < TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR'))
AND 	trunc(b.gl_date)          < TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
 AND     c.invoice_currency_code      = :curr_code
AND 	b.status                     = 'A'
AND    C.CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND	    b.customer_trx_id            = d.customer_trx_id
AND     c.org_id                     =:p_org_id
AND     B.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,B.SET_OF_BOOKS_ID)
and     d.payment_schedule_id
IN      (SELECT MIN(PAYMENT_SCHEDULE_ID)
         FROM   AR_PAYMENT_SCHEDULES_ALL
	     WHERE  CUSTOMER_TRX_ID = d.CUSTOMER_TRX_ID
	    )
) v_func_adj_amt
, (
Select  --DISTINCT a.currency_code 
	   	sum(a.amount)                             
From
	   	ar_cash_receipts_all              A
Where 1=1
AND   a.pay_from_customer           = :customer_id
 AND   a.currency_code               = :curr_code
AND   a.org_id=:p_org_id
AND   A.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,A.SET_OF_BOOKS_ID)
--Added the below by Sanjikum for Bug #3962497
AND 		EXISTS (	SELECT	1 
									FROM 		ar_cash_receipt_history_all
									WHERE		cash_receipt_id = a.cash_receipt_id
									AND  		org_id = :p_org_id
									AND 		trunc(gl_date) < TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
							 )) v_tr_cr_amt
, (
Select  
	   	sum(a.amount * NVL(a.exchange_rate,1.00)) sum_amount_exchange
From
	   	ar_cash_receipts_all              A
Where 1=1
AND   a.pay_from_customer           = :customer_id
 AND   a.currency_code               = :curr_code
AND   a.org_id=:p_org_id
AND   A.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,A.SET_OF_BOOKS_ID)
--Added the below by Sanjikum for Bug #3962497
AND 		EXISTS (	SELECT	1 
									FROM 		ar_cash_receipt_history_all
									WHERE		cash_receipt_id = a.cash_receipt_id
									AND  		org_id = :p_org_id
									AND 		trunc(gl_date) < TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
							 )) v_func_cr_amt
, (
Select 
	   sum(a.amount)                             sum_amount
From
	   ar_cash_receipts_all              A
	   , ar_cash_receipt_history_all       b -- added by sriram - 3328962
Where 1=1
AND    a.cash_receipt_id             = b.cash_receipt_id
AND    a.pay_from_customer           = :customer_id
AND	   trunc(b.gl_date)              < TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR'))
AND    a.reversal_date                 is not null
AND    a.currency_code               = :curr_code
--AND    b.current_record_flag         = 'Y' --Commented by Sanjikum for Bug #3962497
AND 	 b.status                      = 'REVERSED' --Added by Sanjikum for Bug #3962497
AND    a.org_id                      = :p_org_id
AND     A.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,A.SET_OF_BOOKS_ID) 
) v_tr_rev_amt
, (
Select 
	   sum(a.amount * NVL(a.exchange_rate,1.00)) sum_amount_exchange -- a. added by sriram 
From
	   ar_cash_receipts_all              A
	   , ar_cash_receipt_history_all       b -- added by sriram - 3328962
Where 1=1
AND    a.cash_receipt_id             = b.cash_receipt_id
AND    a.pay_from_customer           = :customer_id
AND	   trunc(b.gl_date)              < TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR'))
AND    a.reversal_date                 is not null
AND    a.currency_code               = :curr_code
--AND    b.current_record_flag         = 'Y' --Commented by Sanjikum for Bug #3962497
AND 	 b.status                      = 'REVERSED' --Added by Sanjikum for Bug #3962497
AND    a.org_id                      = :p_org_id
AND     A.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,A.SET_OF_BOOKS_ID) 
)  v_func_rev_amt
, (
Select
   	   nvl(sum(abs(NVL(d.EARNED_DISCOUNT_TAKEN,0))),0)   
From
	   ra_customers                      a,
	   ra_customer_trx_ALL               B,
	   ar_receivable_applications_all    D
Where
	   a.customer_id                 = :customer_id
AND	   b.bill_to_customer_id         = a.customer_id
AND	   b.complete_flag               = 'Y'
AND    trunc(d.GL_DATE)              < TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR'))
AND    d.applied_customer_trx_id             = b.customer_trx_id
AND    b.invoice_currency_code       = :curr_code
AND    d.earned_DISCOUNT_TAKEN         is not  null 
and    d.earned_DISCOUNT_TAKEN       <> 0
AND    D.APPLIED_CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND    B.org_id                      = :p_org_id
AND    B.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,B.SET_OF_BOOKS_ID)
and    d.application_type = 'CASH' 
and    d.display = 'Y'
) v_tr_disc_cr_amt
, (
Select
	   nvl(sum(abs(NVL(d.ACCTD_EARNED_DISCOUNT_TAKEN,0))),0)  sum_amount_exchange
From
	   ra_customers                      a,
	   ra_customer_trx_ALL               B,
	   ar_receivable_applications_all    D
Where
	   a.customer_id                 = :customer_id
AND	   b.bill_to_customer_id         = a.customer_id
AND	   b.complete_flag               = 'Y'
AND    trunc(d.GL_DATE)              < TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR'))
AND    d.applied_customer_trx_id             = b.customer_trx_id
AND    b.invoice_currency_code       = :curr_code
AND    d.earned_DISCOUNT_TAKEN         is not  null 
and    d.earned_DISCOUNT_TAKEN       <> 0
AND    D.APPLIED_CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND    B.org_id                      = :p_org_id
AND    B.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,B.SET_OF_BOOKS_ID)
and    d.application_type = 'CASH' 
and    d.display = 'Y'
)  v_func_disc_cr_amt 
, (
SELECT 
       sum(e.AMOUNT_cr)              sum_amount 
FROM
       RA_customers                      a ,
       ra_customer_trx_all               b ,
       ar_cash_receipts_all              c ,
       ar_receivable_applications_all    d ,
       ar_distributions_all              e
WHERE
       a.customer_id                 =  b.BILL_TO_CUSTOMER_ID
AND    b.customer_trx_id             =  d.APPLIED_CUSTOMER_TRX_ID
AND    c.cash_receipt_id             =  d.cash_receipt_id
AND    e.SOURCE_ID                   =  d.receivable_application_id
AND    b.org_id                      =  :p_org_id
AND    B.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,B.SET_OF_BOOKS_ID)
AND    e.source_Type                 IN ('EXCH_LOSS','EXCH_GAIN' )
AND    B.CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND    b.invoice_currency_code       =  :curr_code
AND    a.customer_id                 =  :customer_id
--AND    TRUNC(c.receipt_date)         <  trunc(:P_END_DATE);
AND    TRUNC(d.gl_date)              <  TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR'))
) v_tran_loss_amt
, (
(
SELECT 
       sum(e.ACCTD_AMOUNT_cr)        sum_exchange_amount
FROM
       RA_customers                      a ,
       ra_customer_trx_all               b ,
       ar_cash_receipts_all              c ,
       ar_receivable_applications_all    d ,
       ar_distributions_all              e
WHERE
       a.customer_id                 =  b.BILL_TO_CUSTOMER_ID
AND    b.customer_trx_id             =  d.APPLIED_CUSTOMER_TRX_ID
AND    c.cash_receipt_id             =  d.cash_receipt_id
AND    e.SOURCE_ID                   =  d.receivable_application_id
AND    b.org_id                      =  :p_org_id
AND    B.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,B.SET_OF_BOOKS_ID)
AND    e.source_Type                 IN ('EXCH_LOSS','EXCH_GAIN' )
AND    B.CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND    b.invoice_currency_code       =  :curr_code
AND    a.customer_id                 =  :customer_id
--AND    TRUNC(c.receipt_date)         <  trunc(:P_END_DATE);
AND    TRUNC(d.gl_date)              <  TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR'))
)) v_func_loss_amt
, (SELECT
       sum(e.amount_dr)             sum_amount
FROM
       ra_customers                      a ,
       ra_customer_trx_all               b ,
       ar_cash_receipts_all              c,
       ar_receivable_applications_all    d,
       ar_distributions_all              e
WHERE
       a.customer_id                 =  b.BILL_TO_CUSTOMER_ID
AND    b.customer_trx_id             =  d.APPLIED_CUSTOMER_TRX_ID
AND    c.cash_receipt_id             =  d.cash_receipt_id
AND    e.SOURCE_ID                   =  d.receivable_application_id
AND    b.org_id                      =  :p_org_id
AND    B.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,B.SET_OF_BOOKS_ID)
AND    B.CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND    e.source_Type                IN  ('EXCH_GAIN','EXCH_LOSS' )
AND    b.invoice_currency_code       = :curr_code
AND    a.customer_id                 =:customer_id
--AND    TRUNC(c.receipt_date)         < trunc(:P_END_DATE) ;
AND    TRUNC(d.gl_date)              < TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR'))) v_tran_gain_amt
, (SELECT
       sum(e.acctd_amount_dr)       sum_exchange_amount
FROM
       ra_customers                      a ,
       ra_customer_trx_all               b ,
       ar_cash_receipts_all              c,
       ar_receivable_applications_all    d,
       ar_distributions_all              e
WHERE
       a.customer_id                 =  b.BILL_TO_CUSTOMER_ID
AND    b.customer_trx_id             =  d.APPLIED_CUSTOMER_TRX_ID
AND    c.cash_receipt_id             =  d.cash_receipt_id
AND    e.SOURCE_ID                   =  d.receivable_application_id
AND    b.org_id                      =  :p_org_id
AND    B.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,B.SET_OF_BOOKS_ID)
AND    B.CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND    e.source_Type                IN  ('EXCH_GAIN','EXCH_LOSS' )
AND    b.invoice_currency_code       = :curr_code
AND    a.customer_id                 =:customer_id
--AND    TRUNC(c.receipt_date)         < trunc(:P_END_DATE) ;
AND    TRUNC(d.gl_date)              < TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR'))) v_func_gain_amt
, (Select 
	   sum(c.amount_applied)                             sum_amount
From
	   ar_cash_receipts_all              A
	   , ar_cash_receipt_history_all       B
	   , ar_receivable_applications_all    c
Where 1=1
AND       a.pay_from_customer           = :customer_id
AND	   trunc(b.gl_date)              < TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR'))
AND    a.cash_receipt_id             = b.cash_receipt_id
and    a.cash_receipt_id             = c .cash_receipt_id
and    c.cash_receipt_history_id     = b.cash_receipt_history_id
and    c.applied_payment_schedule_id = -3
and    c.status                      = 'ACTIVITY'
AND    a.currency_code               = :curr_code
--AND    B.REVERSAL_GL_DATE IS NULL --- commented by mohinder paul singh
AND    b.current_record_flag         = 'Y'
AND    a.org_id                      = :p_org_id
AND    A.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,A.SET_OF_BOOKS_ID) 
and    not exists
 ( select 1
   from   ar_cash_receipt_history_all
   where  cash_receipt_id = b.cash_receipt_id
   and    status = 'REVERSED'
 )) v_tran_rcp_w_off
 ,(Select 
	   sum(c.amount_applied * NVL(a.exchange_rate,1.00)) sum_amount_exchange
From
	   ar_cash_receipts_all              A
	   , ar_cash_receipt_history_all       B
	   , ar_receivable_applications_all    c
Where 1=1
AND       a.pay_from_customer           = :customer_id
AND	   trunc(b.gl_date)              < TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR'))
AND    a.cash_receipt_id             = b.cash_receipt_id
and    a.cash_receipt_id             = c .cash_receipt_id
and    c.cash_receipt_history_id     = b.cash_receipt_history_id
and    c.applied_payment_schedule_id = -3
and    c.status                      = 'ACTIVITY'
AND    a.currency_code               = :curr_code
--AND    B.REVERSAL_GL_DATE IS NULL --- commented by mohinder paul singh
AND    b.current_record_flag         = 'Y'
AND    a.org_id                      = :p_org_id
AND    A.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,A.SET_OF_BOOKS_ID) 
and    not exists
 ( select 1
   from   ar_cash_receipt_history_all
   where  cash_receipt_id = b.cash_receipt_id
   and    status = 'REVERSED'
 )) v_func_rcp_w_off
 , (Select 
	       sum((b.amount)) sum_ext_amount
   From
           ra_customer_trx_all           A,
           ar_payment_schedules_all      C,
           ra_cust_trx_line_gl_dist_all  B
Where
           a.bill_to_customer_id        = :customer_id
--AND 	   trunc(a.trx_date)            < trunc(:P_END_DATE)
AND 	   trunc(c.gl_date)             < TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR'))
AND 	   a.invoice_currency_code      = :curr_code
AND 	   a.complete_flag              = 'Y'
AND 	   b.customer_trx_id            = a.customer_trx_id
AND 	   b.account_class              = 'REC'
AND        b.LATEST_REC_FLAG            = 'Y'
AND        A.customer_trx_id            = C.customer_trx_id
AND        C.class In('CM')
AND    A.CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND        a.org_id                     =:p_org_id
AND        A.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,A.SET_OF_BOOKS_ID)
AND        c.payment_schedule_id
IN         (SELECT MIN(PAYMENT_SCHEDULE_ID)
            FROM   AR_PAYMENT_SCHEDULES_ALL
	        WHERE  CUSTOMER_TRX_ID = C.CUSTOMER_TRX_ID
	       )) v_cre_memo_amt
, (Select 
	       sum((b.amount) * NVL(A.exchange_rate,1))
   From
           ra_customer_trx_all           A,
           ar_payment_schedules_all      C,
           ra_cust_trx_line_gl_dist_all  B
Where
           a.bill_to_customer_id        = :customer_id
--AND 	   trunc(a.trx_date)            < trunc(:P_END_DATE)
AND 	   trunc(c.gl_date)             < TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR'))
AND 	   a.invoice_currency_code      = :curr_code
AND 	   a.complete_flag              = 'Y'
AND 	   b.customer_trx_id            = a.customer_trx_id
AND 	   b.account_class              = 'REC'
AND        b.LATEST_REC_FLAG            = 'Y'
AND        A.customer_trx_id            = C.customer_trx_id
AND        C.class In('CM')
AND    A.CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND        a.org_id                     =:p_org_id
AND        A.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,A.SET_OF_BOOKS_ID)
AND        c.payment_schedule_id
IN         (SELECT MIN(PAYMENT_SCHEDULE_ID)
            FROM   AR_PAYMENT_SCHEDULES_ALL
	        WHERE  CUSTOMER_TRX_ID = C.CUSTOMER_TRX_ID
	       )) v_cre_memo_func_amt
FROM DUAL
)))
)

--------------------------------------------------------------------------------------------------------------------------------------------
SELECT
CASE WHEN  NVL(func_CL_bal_tot_dr,0) - NVL(func_CL_bal_tot_cr,0) < 0 THEN
   ABS( NVL(func_CL_bal_tot_dr,0) - NVL(func_CL_bal_tot_cr,0))
ELSE
   0
END CL_TOT_CR 
, CASE WHEN  NVL(FUNC_CL_BAL_TOT_DR,0) - NVL(FUNC_CL_BAL_TOT_CR,0) < 0 THEN
   0
ELSE
   nvl(abs( NVL(func_CL_bal_tot_dr,0) - NVL(func_CL_bal_tot_cr,0)),0)
END CL_TOT_DR 
, CLOSE_BAL_TR
FROM ( 
SELECT SUM(FUNC_CLOSE_BAL_CR) FUNC_CL_BAL_TOT_CR
, SUM(FUNC_CLOSE_BAL_DR) FUNC_CL_BAL_TOT_DR
, SUM(TRAN_CLOSE_BAL_CR)
, SUM(CLOSE_BAL_TR) CLOSE_BAL_TR
FROM 
(SELECT  CASE WHEN NVL(v_func_tot_amt,0) < 0  THEN ABS(v_func_tot_amt) ELSE 0 END FUNC_CLOSE_BAL_CR
, CASE WHEN NVL(v_func_tot_amt,0) < 0  THEN 0 ELSE ABS(v_func_tot_amt) END FUNC_CLOSE_BAL_DR
, CASE WHEN NVL(v_tran_tot_amt,0) < 0  THEN ABS(NVL(v_tran_tot_amt,0)) ELSE 0 END TRAN_CLOSE_BAL_CR
--, CASE WHEN NVL(v_tran_tot_amt,0) < 0  THEN ABS(NVL(v_tran_tot_amt,0)) ELSE 0 END tran_CLOSE_bal_cr
, CASE WHEN NVL(v_tran_tot_amt,0) < 0  THEN 0 ELSE (ABS(NVL(v_tran_tot_amt,0))) END CLOSE_BAL_TR
FROM (
SELECT ( NVL(v_func_dr_amt,0      )
                      + nvl(v_cre_memo_func_amt,0)
                      + NVL(v_func_rev_amt,0     )
                      - NVL(v_func_cr_amt,0      )
                      + NVL(v_func_rcp_w_off,0   )
                      + (NVL(v_func_adj_amt,0   ))
                      - NVL(v_func_disc_cr_amt,0 )
                      - NVL(v_func_gain_amt,0    )
                      + NVL(v_func_loss_amt,0    )
                      ) v_func_tot_amt
, ( (NVL(v_tr_dr_amt,0)     )
                       + nvl(v_cre_memo_amt,0   )
                       +(NVL(v_tr_rev_amt,0    ))
                       - NVL(v_tr_cr_amt,0      )
                       + NVL(v_tran_rcp_w_off,0 )
                       - abs(NVL(v_tr_adj_amt,0))
                       - NVL(v_tr_disc_cr_amt,0)) v_tran_tot_amt
FROM (
SELECT 
(Select
	  sum((b.amount)) sum_ext_amount
From
      ra_customer_trx_all                A,
      ar_payment_schedules_all           C,
      ra_cust_trx_line_gl_dist_all       B
Where
	    a.bill_to_customer_id        = :customer_id
-- AND 	trunc(a.trx_date)            < trunc(:P_END_DATE)
AND 	trunc(c.gl_date)            < TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND 	a.invoice_currency_code      = :curr_code
AND 	a.complete_flag              = 'Y'
AND 	b.customer_trx_id            = a.customer_trx_id
AND 	b.account_class              = 'REC'
AND     b.LATEST_REC_FLAG            = 'Y'
AND     A.customer_trx_id            = C.customer_trx_id
AND     C.class In('INV','DM','DEP')
AND    A.CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND     a.org_id                     =:p_org_id
AND     A.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,A.SET_OF_BOOKS_ID)
AND c.Payment_schedule_id
IN (SELECT MIN(PAYMENT_SCHEDULE_ID)
    FROM   AR_PAYMENT_SCHEDULES_ALL
  	WHERE  CUSTOMER_TRX_ID = C.CUSTOMER_TRX_ID
   )) v_tr_dr_amt
, (Select
	  sum((b.amount) * NVL(A.exchange_rate,1))
From
      ra_customer_trx_all                A,
      ar_payment_schedules_all           C,
      ra_cust_trx_line_gl_dist_all       B
Where
	    a.bill_to_customer_id        = :customer_id
-- AND 	trunc(a.trx_date)            < trunc(:p_start_date)
AND 	trunc(c.gl_date)            < TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
AND 	a.invoice_currency_code      = :curr_code
AND 	a.complete_flag              = 'Y'
AND 	b.customer_trx_id            = a.customer_trx_id
AND 	b.account_class              = 'REC'
AND     b.LATEST_REC_FLAG            = 'Y'
AND     A.customer_trx_id            = C.customer_trx_id
AND     C.class In('INV','DM','DEP')
AND    A.CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND     a.org_id                     =:p_org_id
AND     A.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,A.SET_OF_BOOKS_ID)
AND c.Payment_schedule_id
IN (SELECT MIN(PAYMENT_SCHEDULE_ID)
    FROM   AR_PAYMENT_SCHEDULES_ALL
  	WHERE  CUSTOMER_TRX_ID = C.CUSTOMER_TRX_ID
   ))   
v_func_dr_amt 
, (
SELECT 
   	   sum((b.amount)) sum_adj_amount
FROM
       ra_customers                      a
   , ar_adjustments_all                b
   , ra_customer_trx_all               c
   , ar_payment_schedules_all          d
   , gl_code_combinations              e
WHERE
    	a.customer_id                =  :customer_id
AND 	b.customer_trx_id            =  c.customer_trx_id
AND 	c.bill_to_customer_id        =  a.customer_id
and     e.code_combination_id        = b.code_combination_id
AND 	trunc(b.apply_date)          < TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR'))
AND 	trunc(b.gl_date)          < TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
 AND     c.invoice_currency_code      = :curr_code
AND 	b.status                     = 'A'
AND    C.CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND	    b.customer_trx_id            = d.customer_trx_id
AND     c.org_id                     =:p_org_id
AND     B.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,B.SET_OF_BOOKS_ID)
and     d.payment_schedule_id
IN      (SELECT MIN(PAYMENT_SCHEDULE_ID)
         FROM   AR_PAYMENT_SCHEDULES_ALL
	     WHERE  CUSTOMER_TRX_ID = d.CUSTOMER_TRX_ID
	    )
) v_tr_adj_amt
, 
(
SELECT 
	   sum((b.amount) * NVL(C.exchange_rate,1)) --sum_extended_amount_exchange
FROM
       ra_customers                      a
   , ar_adjustments_all                b
   , ra_customer_trx_all               c
   , ar_payment_schedules_all          d
   , gl_code_combinations              e
WHERE
    	a.customer_id                =  :customer_id
AND 	b.customer_trx_id            =  c.customer_trx_id
AND 	c.bill_to_customer_id        =  a.customer_id
and     e.code_combination_id        = b.code_combination_id
AND 	trunc(b.apply_date)          < TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR'))
AND 	trunc(b.gl_date)          < TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
 AND     c.invoice_currency_code      = :curr_code
AND 	b.status                     = 'A'
AND    C.CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND	    b.customer_trx_id            = d.customer_trx_id
AND     c.org_id                     =:p_org_id
AND     B.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,B.SET_OF_BOOKS_ID)
and     d.payment_schedule_id
IN      (SELECT MIN(PAYMENT_SCHEDULE_ID)
         FROM   AR_PAYMENT_SCHEDULES_ALL
	     WHERE  CUSTOMER_TRX_ID = d.CUSTOMER_TRX_ID
	    )
) v_func_adj_amt
, (
Select  --DISTINCT a.currency_code 
	   	sum(a.amount)                             
From
	   	ar_cash_receipts_all              A
Where 1=1
AND   a.pay_from_customer           = :customer_id
 AND   a.currency_code               = :curr_code
AND   a.org_id=:p_org_id
AND   A.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,A.SET_OF_BOOKS_ID)
--Added the below by Sanjikum for Bug #3962497
AND 		EXISTS (	SELECT	1 
									FROM 		ar_cash_receipt_history_all
									WHERE		cash_receipt_id = a.cash_receipt_id
									AND  		org_id = :p_org_id
									AND 		trunc(gl_date) < TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
							 )) v_tr_cr_amt
, (
Select  
	   	sum(a.amount * NVL(a.exchange_rate,1.00)) sum_amount_exchange
From
	   	ar_cash_receipts_all              A
Where 1=1
AND   a.pay_from_customer           = :customer_id
 AND   a.currency_code               = :curr_code
AND   a.org_id=:p_org_id
AND   A.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,A.SET_OF_BOOKS_ID)
--Added the below by Sanjikum for Bug #3962497
AND 		EXISTS (	SELECT	1 
									FROM 		ar_cash_receipt_history_all
									WHERE		cash_receipt_id = a.cash_receipt_id
									AND  		org_id = :p_org_id
									AND 		trunc(gl_date) < TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR')) 
							 )) v_func_cr_amt
, (
Select 
	   sum(a.amount)                             sum_amount
From
	   ar_cash_receipts_all              A
	   , ar_cash_receipt_history_all       b -- added by sriram - 3328962
Where 1=1
AND    a.cash_receipt_id             = b.cash_receipt_id
AND    a.pay_from_customer           = :customer_id
AND	   trunc(b.gl_date)              < TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR'))
AND    a.reversal_date                 is not null
AND    a.currency_code               = :curr_code
--AND    b.current_record_flag         = 'Y' --Commented by Sanjikum for Bug #3962497
AND 	 b.status                      = 'REVERSED' --Added by Sanjikum for Bug #3962497
AND    a.org_id                      = :p_org_id
AND     A.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,A.SET_OF_BOOKS_ID) 
) v_tr_rev_amt
, (
Select 
	   sum(a.amount * NVL(a.exchange_rate,1.00)) sum_amount_exchange -- a. added by sriram 
From
	   ar_cash_receipts_all              A
	   , ar_cash_receipt_history_all       b -- added by sriram - 3328962
Where 1=1
AND    a.cash_receipt_id             = b.cash_receipt_id
AND    a.pay_from_customer           = :customer_id
AND	   trunc(b.gl_date)              < TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR'))
AND    a.reversal_date                 is not null
AND    a.currency_code               = :curr_code
--AND    b.current_record_flag         = 'Y' --Commented by Sanjikum for Bug #3962497
AND 	 b.status                      = 'REVERSED' --Added by Sanjikum for Bug #3962497
AND    a.org_id                      = :p_org_id
AND     A.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,A.SET_OF_BOOKS_ID) 
)  v_func_rev_amt
, (
Select
   	   nvl(sum(abs(NVL(d.EARNED_DISCOUNT_TAKEN,0))),0)   
From
	   ra_customers                      a,
	   ra_customer_trx_ALL               B,
	   ar_receivable_applications_all    D
Where
	   a.customer_id                 = :customer_id
AND	   b.bill_to_customer_id         = a.customer_id
AND	   b.complete_flag               = 'Y'
AND    trunc(d.GL_DATE)              < TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR'))
AND    d.applied_customer_trx_id             = b.customer_trx_id
AND    b.invoice_currency_code       = :curr_code
AND    d.earned_DISCOUNT_TAKEN         is not  null 
and    d.earned_DISCOUNT_TAKEN       <> 0
AND    D.APPLIED_CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND    B.org_id                      = :p_org_id
AND    B.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,B.SET_OF_BOOKS_ID)
and    d.application_type = 'CASH' 
and    d.display = 'Y'
) v_tr_disc_cr_amt
, (
Select
	   nvl(sum(abs(NVL(d.ACCTD_EARNED_DISCOUNT_TAKEN,0))),0)  sum_amount_exchange
From
	   ra_customers                      a,
	   ra_customer_trx_ALL               B,
	   ar_receivable_applications_all    D
Where
	   a.customer_id                 = :customer_id
AND	   b.bill_to_customer_id         = a.customer_id
AND	   b.complete_flag               = 'Y'
AND    trunc(d.GL_DATE)              < TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR'))
AND    d.applied_customer_trx_id             = b.customer_trx_id
AND    b.invoice_currency_code       = :curr_code
AND    d.earned_DISCOUNT_TAKEN         is not  null 
and    d.earned_DISCOUNT_TAKEN       <> 0
AND    D.APPLIED_CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND    B.org_id                      = :p_org_id
AND    B.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,B.SET_OF_BOOKS_ID)
and    d.application_type = 'CASH' 
and    d.display = 'Y'
)  v_func_disc_cr_amt 
, (
SELECT 
       sum(e.AMOUNT_cr)              sum_amount 
FROM
       RA_customers                      a ,
       ra_customer_trx_all               b ,
       ar_cash_receipts_all              c ,
       ar_receivable_applications_all    d ,
       ar_distributions_all              e
WHERE
       a.customer_id                 =  b.BILL_TO_CUSTOMER_ID
AND    b.customer_trx_id             =  d.APPLIED_CUSTOMER_TRX_ID
AND    c.cash_receipt_id             =  d.cash_receipt_id
AND    e.SOURCE_ID                   =  d.receivable_application_id
AND    b.org_id                      =  :p_org_id
AND    B.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,B.SET_OF_BOOKS_ID)
AND    e.source_Type                 IN ('EXCH_LOSS','EXCH_GAIN' )
AND    B.CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND    b.invoice_currency_code       =  :curr_code
AND    a.customer_id                 =  :customer_id
--AND    TRUNC(c.receipt_date)         <  trunc(:P_END_DATE);
AND    TRUNC(d.gl_date)              <  TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR'))
) v_tran_loss_amt
, (
(
SELECT 
       sum(e.ACCTD_AMOUNT_cr)        sum_exchange_amount
FROM
       RA_customers                      a ,
       ra_customer_trx_all               b ,
       ar_cash_receipts_all              c ,
       ar_receivable_applications_all    d ,
       ar_distributions_all              e
WHERE
       a.customer_id                 =  b.BILL_TO_CUSTOMER_ID
AND    b.customer_trx_id             =  d.APPLIED_CUSTOMER_TRX_ID
AND    c.cash_receipt_id             =  d.cash_receipt_id
AND    e.SOURCE_ID                   =  d.receivable_application_id
AND    b.org_id                      =  :p_org_id
AND    B.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,B.SET_OF_BOOKS_ID)
AND    e.source_Type                 IN ('EXCH_LOSS','EXCH_GAIN' )
AND    B.CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND    b.invoice_currency_code       =  :curr_code
AND    a.customer_id                 =  :customer_id
--AND    TRUNC(c.receipt_date)         <  trunc(:P_END_DATE);
AND    TRUNC(d.gl_date)              <  TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR'))
)) v_func_loss_amt
, (SELECT
       sum(e.amount_dr)             sum_amount
FROM
       ra_customers                      a ,
       ra_customer_trx_all               b ,
       ar_cash_receipts_all              c,
       ar_receivable_applications_all    d,
       ar_distributions_all              e
WHERE
       a.customer_id                 =  b.BILL_TO_CUSTOMER_ID
AND    b.customer_trx_id             =  d.APPLIED_CUSTOMER_TRX_ID
AND    c.cash_receipt_id             =  d.cash_receipt_id
AND    e.SOURCE_ID                   =  d.receivable_application_id
AND    b.org_id                      =  :p_org_id
AND    B.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,B.SET_OF_BOOKS_ID)
AND    B.CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND    e.source_Type                IN  ('EXCH_GAIN','EXCH_LOSS' )
AND    b.invoice_currency_code       = :curr_code
AND    a.customer_id                 =:customer_id
--AND    TRUNC(c.receipt_date)         < trunc(:P_END_DATE) ;
AND    TRUNC(d.gl_date)              < TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR'))) v_tran_gain_amt
, (SELECT
       sum(e.acctd_amount_dr)       sum_exchange_amount
FROM
       ra_customers                      a ,
       ra_customer_trx_all               b ,
       ar_cash_receipts_all              c,
       ar_receivable_applications_all    d,
       ar_distributions_all              e
WHERE
       a.customer_id                 =  b.BILL_TO_CUSTOMER_ID
AND    b.customer_trx_id             =  d.APPLIED_CUSTOMER_TRX_ID
AND    c.cash_receipt_id             =  d.cash_receipt_id
AND    e.SOURCE_ID                   =  d.receivable_application_id
AND    b.org_id                      =  :p_org_id
AND    B.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,B.SET_OF_BOOKS_ID)
AND    B.CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND    e.source_Type                IN  ('EXCH_GAIN','EXCH_LOSS' )
AND    b.invoice_currency_code       = :curr_code
AND    a.customer_id                 =:customer_id
--AND    TRUNC(c.receipt_date)         < trunc(:P_END_DATE) ;
AND    TRUNC(d.gl_date)              < TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR'))) v_func_gain_amt
, (Select 
	   sum(c.amount_applied)                             sum_amount
From
	   ar_cash_receipts_all              A
	   , ar_cash_receipt_history_all       B
	   , ar_receivable_applications_all    c
Where 1=1
AND       a.pay_from_customer           = :customer_id
AND	   trunc(b.gl_date)              < TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR'))
AND    a.cash_receipt_id             = b.cash_receipt_id
and    a.cash_receipt_id             = c .cash_receipt_id
and    c.cash_receipt_history_id     = b.cash_receipt_history_id
and    c.applied_payment_schedule_id = -3
and    c.status                      = 'ACTIVITY'
AND    a.currency_code               = :curr_code
--AND    B.REVERSAL_GL_DATE IS NULL --- commented by mohinder paul singh
AND    b.current_record_flag         = 'Y'
AND    a.org_id                      = :p_org_id
AND    A.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,A.SET_OF_BOOKS_ID) 
and    not exists
 ( select 1
   from   ar_cash_receipt_history_all
   where  cash_receipt_id = b.cash_receipt_id
   and    status = 'REVERSED'
 )) v_tran_rcp_w_off
 ,(Select 
	   sum(c.amount_applied * NVL(a.exchange_rate,1.00)) sum_amount_exchange
From
	   ar_cash_receipts_all              A
	   , ar_cash_receipt_history_all       B
	   , ar_receivable_applications_all    c
Where 1=1
AND       a.pay_from_customer           = :customer_id
AND	   trunc(b.gl_date)              < TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR'))
AND    a.cash_receipt_id             = b.cash_receipt_id
and    a.cash_receipt_id             = c .cash_receipt_id
and    c.cash_receipt_history_id     = b.cash_receipt_history_id
and    c.applied_payment_schedule_id = -3
and    c.status                      = 'ACTIVITY'
AND    a.currency_code               = :curr_code
--AND    B.REVERSAL_GL_DATE IS NULL --- commented by mohinder paul singh
AND    b.current_record_flag         = 'Y'
AND    a.org_id                      = :p_org_id
AND    A.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,A.SET_OF_BOOKS_ID) 
and    not exists
 ( select 1
   from   ar_cash_receipt_history_all
   where  cash_receipt_id = b.cash_receipt_id
   and    status = 'REVERSED'
 )) v_func_rcp_w_off
 , (Select 
	       sum((b.amount)) sum_ext_amount
   From
           ra_customer_trx_all           A,
           ar_payment_schedules_all      C,
           ra_cust_trx_line_gl_dist_all  B
Where
           a.bill_to_customer_id        = :customer_id
--AND 	   trunc(a.trx_date)            < trunc(:P_END_DATE)
AND 	   trunc(c.gl_date)             < TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR'))
AND 	   a.invoice_currency_code      = :curr_code
AND 	   a.complete_flag              = 'Y'
AND 	   b.customer_trx_id            = a.customer_trx_id
AND 	   b.account_class              = 'REC'
AND        b.LATEST_REC_FLAG            = 'Y'
AND        A.customer_trx_id            = C.customer_trx_id
AND        C.class In('CM')
AND    A.CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND        a.org_id                     =:p_org_id
AND        A.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,A.SET_OF_BOOKS_ID)
AND        c.payment_schedule_id
IN         (SELECT MIN(PAYMENT_SCHEDULE_ID)
            FROM   AR_PAYMENT_SCHEDULES_ALL
	        WHERE  CUSTOMER_TRX_ID = C.CUSTOMER_TRX_ID
	       )) v_cre_memo_amt
, (Select 
	       sum((b.amount) * NVL(A.exchange_rate,1))
   From
           ra_customer_trx_all           A,
           ar_payment_schedules_all      C,
           ra_cust_trx_line_gl_dist_all  B
Where
           a.bill_to_customer_id        = :customer_id
--AND 	   trunc(a.trx_date)            < trunc(:P_END_DATE)
AND 	   trunc(c.gl_date)             < TRUNC(TO_DATE(:P_END_DATE,'MM/DD/RRRR'))
AND 	   a.invoice_currency_code      = :curr_code
AND 	   a.complete_flag              = 'Y'
AND 	   b.customer_trx_id            = a.customer_trx_id
AND 	   b.account_class              = 'REC'
AND        b.LATEST_REC_FLAG            = 'Y'
AND        A.customer_trx_id            = C.customer_trx_id
AND        C.class In('CM')
AND    A.CUSTOMER_TRX_ID NOT IN (325518,330653)     --------------------------------
AND        a.org_id                     =:p_org_id
AND        A.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,A.SET_OF_BOOKS_ID)
AND        c.payment_schedule_id
IN         (SELECT MIN(PAYMENT_SCHEDULE_ID)
            FROM   AR_PAYMENT_SCHEDULES_ALL
	        WHERE  CUSTOMER_TRX_ID = C.CUSTOMER_TRX_ID
	       )) v_cre_memo_func_amt
FROM DUAL
)))
)

--------------------------------------------------------
--CL_TOT_DR
v_bal := NVL(:func_cl_bal_dr,0) - NVL(:func_cl_bal_cr,0);  
IF v_bal < 0 THEN
	if :p_customer_id2 is not null then
	 :CL_TOT_CR := ABS(v_bal)+:CS_sum_applied_others;
   RETURN(0);
	else
	 :cl_tot_cr := ABS(v_bal)+:CF_applief_from_func;
   RETURN(0);
	end if;	
ELSE
		if :p_customer_id2 is not null then
	 :cl_tot_cr := 0;
   RETURN(abs(NVL(v_bal,0))-:CS_sum_applied_others);
		else
			 :cl_tot_cr := 0;
   RETURN(abs(NVL(v_bal,0))-:CF_applief_from_func);
   end if;
			
END IF;

CASE WHEN NVL(FUNC_CL_BAL_DR,0) - NVL(FUNC_CL_BAL_CR,0) < 0
THEN
	CASE WHEN :p_customer_id2 IS NOT NULL THEN ABS(NVL(FUNC_CL_BAL_DR,0) - NVL(FUNC_CL_BAL_CR,0))+:CS_SUM_APPLIED_OTHERS ELSE ABS(NVL(FUNC_CL_BAL_DR,0) - NVL(FUNC_CL_BAL_CR,0))+ CF_APPLIEF_FROM_FUNC END
	ELSE CASE WHEN :p_customer_id2 IS NOT NULL THEN 0 ELSE 0 END
END CL_TOT_CR
, CASE WHEN NVL(FUNC_CL_BAL_DR,0) - NVL(FUNC_CL_BAL_CR,0) < 0
THEN
	CASE WHEN :p_customer_id2 IS NOT NULL THEN 0 ELSE 0 END
	ELSE CASE WHEN :p_customer_id2 IS NOT NULL THEN (abs(NVL(NVL(FUNC_CL_BAL_DR,0) - NVL(FUNC_CL_BAL_CR,0),0))-:CS_SUM_APPLIED_OTHERS) ELSE (abs(NVL(NVL(FUNC_CL_BAL_DR,0) - NVL(FUNC_CL_BAL_CR,0),0))-CF_APPLIEF_FROM_FUNC) END
END CL_TOT_DR 