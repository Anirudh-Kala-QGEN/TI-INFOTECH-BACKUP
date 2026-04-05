--LAST_QUERY
SELECT
CASE WHEN  NVL(func_op_bal_tot_dr,0) - NVL(func_op_bal_tot_cr,0) < 0 THEN
   ABS( NVL(func_op_bal_tot_dr,0) - NVL(func_op_bal_tot_cr,0))
ELSE
   0
END OP_TOT_CR 
, CASE WHEN  NVL(FUNC_OP_BAL_TOT_DR,0) - NVL(FUNC_OP_BAL_TOT_CR,0) < 0 THEN
   0
ELSE
   nvl(abs( NVL(func_op_bal_tot_dr,0) - NVL(func_op_bal_tot_cr,0)),0)
END OP_TOT_DR 
, OPEN_BAL_TR
FROM ( 
SELECT SUM(FUNC_OPEN_BAL_CR) FUNC_OP_BAL_TOT_CR
, SUM(FUNC_OPEN_BAL_DR) FUNC_OP_BAL_TOT_DR
, SUM(TRAN_OPEN_BAL_CR)
, SUM(OPEN_BAL_TR) OPEN_BAL_TR
FROM 
(SELECT  CASE WHEN NVL(v_func_tot_amt,0) < 0  THEN ABS(v_func_tot_amt) ELSE 0 END FUNC_OPEN_BAL_CR
, CASE WHEN NVL(v_func_tot_amt,0) < 0  THEN 0 ELSE ABS(v_func_tot_amt) END FUNC_OPEN_BAL_DR
, CASE WHEN NVL(v_tran_tot_amt,0) < 0  THEN ABS(NVL(v_tran_tot_amt,0)) ELSE 0 END TRAN_OPEN_BAL_CR
--, CASE WHEN NVL(v_tran_tot_amt,0) < 0  THEN ABS(NVL(v_tran_tot_amt,0)) ELSE 0 END tran_open_bal_cr
, CASE WHEN NVL(v_tran_tot_amt,0) < 0  THEN 0 ELSE (ABS(NVL(v_tran_tot_amt,0))) END OPEN_BAL_TR
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
-- AND 	trunc(a.trx_date)            < trunc(:p_start_date)
AND 	trunc(c.gl_date)            < TRUNC(TO_DATE(:p_start_date,'MM/DD/RRRR')) 
--AND 	a.invoice_currency_code      = :curr_code
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
AND 	trunc(c.gl_date)            < TRUNC(TO_DATE(:p_start_date,'MM/DD/RRRR')) 
--AND 	a.invoice_currency_code      = :curr_code
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
AND 	trunc(b.apply_date)          < TRUNC(TO_DATE(:p_start_date,'MM/DD/RRRR'))
AND 	trunc(b.gl_date)          < TRUNC(TO_DATE(:p_start_date,'MM/DD/RRRR')) 
-- AND     c.invoice_currency_code      = :curr_code
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
AND 	trunc(b.apply_date)          < TRUNC(TO_DATE(:p_start_date,'MM/DD/RRRR'))
AND 	trunc(b.gl_date)          < TRUNC(TO_DATE(:p_start_date,'MM/DD/RRRR')) 
-- AND     c.invoice_currency_code      = :curr_code
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
-- AND   a.currency_code               = :curr_code
AND   a.org_id=:p_org_id
AND   A.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,A.SET_OF_BOOKS_ID)
--Added the below by Sanjikum for Bug #3962497
AND 		EXISTS (	SELECT	1 
									FROM 		ar_cash_receipt_history_all
									WHERE		cash_receipt_id = a.cash_receipt_id
									AND  		org_id = :p_org_id
									AND 		trunc(gl_date) < TRUNC(TO_DATE(:p_start_date,'MM/DD/RRRR')) 
							 )) v_tr_cr_amt
, (
Select  
	   	sum(a.amount * NVL(a.exchange_rate,1.00)) sum_amount_exchange
From
	   	ar_cash_receipts_all              A
Where 1=1
AND   a.pay_from_customer           = :customer_id
-- AND   a.currency_code               = :curr_code
AND   a.org_id=:p_org_id
AND   A.SET_OF_BOOKS_ID 				   = NVL(:P_SOB_ID,A.SET_OF_BOOKS_ID)
--Added the below by Sanjikum for Bug #3962497
AND 		EXISTS (	SELECT	1 
									FROM 		ar_cash_receipt_history_all
									WHERE		cash_receipt_id = a.cash_receipt_id
									AND  		org_id = :p_org_id
									AND 		trunc(gl_date) < TRUNC(TO_DATE(:p_start_date,'MM/DD/RRRR')) 
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
AND	   trunc(b.gl_date)              < TRUNC(TO_DATE(:p_start_date,'MM/DD/RRRR'))
AND    a.reversal_date                 is not null
--AND    a.currency_code               = :curr_code
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
AND	   trunc(b.gl_date)              < TRUNC(TO_DATE(:p_start_date,'MM/DD/RRRR'))
AND    a.reversal_date                 is not null
--AND    a.currency_code               = :curr_code
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
AND    trunc(d.GL_DATE)              < TRUNC(TO_DATE(:p_start_date,'MM/DD/RRRR'))
AND    d.applied_customer_trx_id             = b.customer_trx_id
--AND    b.invoice_currency_code       = :curr_code
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
AND    trunc(d.GL_DATE)              < TRUNC(TO_DATE(:p_start_date,'MM/DD/RRRR'))
AND    d.applied_customer_trx_id             = b.customer_trx_id
--AND    b.invoice_currency_code       = :curr_code
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
--AND    b.invoice_currency_code       =  :curr_code
AND    a.customer_id                 =  :customer_id
--AND    TRUNC(c.receipt_date)         <  trunc(:p_start_date);
AND    TRUNC(d.gl_date)              <  TRUNC(TO_DATE(:p_start_date,'MM/DD/RRRR'))
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
--AND    b.invoice_currency_code       =  :curr_code
AND    a.customer_id                 =  :customer_id
--AND    TRUNC(c.receipt_date)         <  trunc(:p_start_date);
AND    TRUNC(d.gl_date)              <  TRUNC(TO_DATE(:p_start_date,'MM/DD/RRRR'))
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
--AND    b.invoice_currency_code       = :curr_code
AND    a.customer_id                 =:customer_id
--AND    TRUNC(c.receipt_date)         < trunc(:p_start_date) ;
AND    TRUNC(d.gl_date)              < TRUNC(TO_DATE(:p_start_date,'MM/DD/RRRR'))) v_tran_gain_amt
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
--AND    b.invoice_currency_code       = :curr_code
AND    a.customer_id                 =:customer_id
--AND    TRUNC(c.receipt_date)         < trunc(:p_start_date) ;
AND    TRUNC(d.gl_date)              < TRUNC(TO_DATE(:p_start_date,'MM/DD/RRRR'))) v_func_gain_amt
, (Select 
	   sum(c.amount_applied)                             sum_amount
From
	   ar_cash_receipts_all              A
	   , ar_cash_receipt_history_all       B
	   , ar_receivable_applications_all    c
Where 1=1
AND       a.pay_from_customer           = :customer_id
AND	   trunc(b.gl_date)              < TRUNC(TO_DATE(:p_start_date,'MM/DD/RRRR'))
AND    a.cash_receipt_id             = b.cash_receipt_id
and    a.cash_receipt_id             = c .cash_receipt_id
and    c.cash_receipt_history_id     = b.cash_receipt_history_id
and    c.applied_payment_schedule_id = -3
and    c.status                      = 'ACTIVITY'
--AND    a.currency_code               = :curr_code
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
AND	   trunc(b.gl_date)              < TRUNC(TO_DATE(:p_start_date,'MM/DD/RRRR'))
AND    a.cash_receipt_id             = b.cash_receipt_id
and    a.cash_receipt_id             = c .cash_receipt_id
and    c.cash_receipt_history_id     = b.cash_receipt_history_id
and    c.applied_payment_schedule_id = -3
and    c.status                      = 'ACTIVITY'
--AND    a.currency_code               = :curr_code
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
--AND 	   trunc(a.trx_date)            < trunc(:p_start_date)
AND 	   trunc(c.gl_date)             < TRUNC(TO_DATE(:p_start_date,'MM/DD/RRRR'))
--AND 	   a.invoice_currency_code      = :curr_code
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
--AND 	   trunc(a.trx_date)            < trunc(:p_start_date)
AND 	   trunc(c.gl_date)             < TRUNC(TO_DATE(:p_start_date,'MM/DD/RRRR'))
--AND 	   a.invoice_currency_code      = :curr_code
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


-- OPENING RELATED QUERY
SELECT
CASE WHEN  NVL(func_op_bal_tot_dr,0) - NVL(func_op_bal_tot_cr,0) < 0 THEN
   ABS( NVL(func_op_bal_tot_dr,0) - NVL(func_op_bal_tot_cr,0))
ELSE
   0
END OP_TOT_CR 
, CASE WHEN  NVL(FUNC_OP_BAL_TOT_DR,0) - NVL(FUNC_OP_BAL_TOT_CR,0) < 0 THEN
   0
ELSE
   nvl(abs( NVL(func_op_bal_tot_dr,0) - NVL(func_op_bal_tot_cr,0)),0)
END OP_TOT_DR 
, OPEN_BAL_TR
FROM ( 
SELECT SUM(FUNC_OPEN_BAL_CR) FUNC_OP_BAL_TOT_CR
, SUM(FUNC_OPEN_BAL_DR) FUNC_OP_BAL_TOT_DR
, SUM(TRAN_OPEN_BAL_CR)
, SUM(OPEN_BAL_TR) OPEN_BAL_TR
FROM 
(SELECT  CASE WHEN NVL(v_func_tot_amt,0) < 0  THEN ABS(v_func_tot_amt) ELSE 0 END FUNC_OPEN_BAL_CR
, CASE WHEN NVL(v_func_tot_amt,0) < 0  THEN 0 ELSE ABS(v_func_tot_amt) END FUNC_OPEN_BAL_DR
, CASE WHEN NVL(v_tran_tot_amt,0) < 0  THEN ABS(NVL(v_tran_tot_amt,0)) ELSE 0 END TRAN_OPEN_BAL_CR
--, CASE WHEN NVL(v_tran_tot_amt,0) < 0  THEN ABS(NVL(v_tran_tot_amt,0)) ELSE 0 END tran_open_bal_cr
, CASE WHEN NVL(v_tran_tot_amt,0) < 0  THEN 0 ELSE (ABS(NVL(v_tran_tot_amt,0))) END OPEN_BAL_TR
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
-- AND 	trunc(a.trx_date)            < trunc(:p_start_date)
AND 	trunc(c.gl_date)            < TRUNC(TO_DATE(:p_start_date,'MM/DD/RRRR')) 
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
AND 	trunc(c.gl_date)            < TRUNC(TO_DATE(:p_start_date,'MM/DD/RRRR')) 
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
AND 	trunc(b.apply_date)          < TRUNC(TO_DATE(:p_start_date,'MM/DD/RRRR'))
AND 	trunc(b.gl_date)          < TRUNC(TO_DATE(:p_start_date,'MM/DD/RRRR')) 
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
AND 	trunc(b.apply_date)          < TRUNC(TO_DATE(:p_start_date,'MM/DD/RRRR'))
AND 	trunc(b.gl_date)          < TRUNC(TO_DATE(:p_start_date,'MM/DD/RRRR')) 
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
									AND 		trunc(gl_date) < TRUNC(TO_DATE(:p_start_date,'MM/DD/RRRR')) 
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
									AND 		trunc(gl_date) < TRUNC(TO_DATE(:p_start_date,'MM/DD/RRRR')) 
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
AND	   trunc(b.gl_date)              < TRUNC(TO_DATE(:p_start_date,'MM/DD/RRRR'))
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
AND	   trunc(b.gl_date)              < TRUNC(TO_DATE(:p_start_date,'MM/DD/RRRR'))
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
AND    trunc(d.GL_DATE)              < TRUNC(TO_DATE(:p_start_date,'MM/DD/RRRR'))
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
AND    trunc(d.GL_DATE)              < TRUNC(TO_DATE(:p_start_date,'MM/DD/RRRR'))
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
--AND    TRUNC(c.receipt_date)         <  trunc(:p_start_date);
AND    TRUNC(d.gl_date)              <  TRUNC(TO_DATE(:p_start_date,'MM/DD/RRRR'))
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
--AND    TRUNC(c.receipt_date)         <  trunc(:p_start_date);
AND    TRUNC(d.gl_date)              <  TRUNC(TO_DATE(:p_start_date,'MM/DD/RRRR'))
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
--AND    TRUNC(c.receipt_date)         < trunc(:p_start_date) ;
AND    TRUNC(d.gl_date)              < TRUNC(TO_DATE(:p_start_date,'MM/DD/RRRR'))) v_tran_gain_amt
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
--AND    TRUNC(c.receipt_date)         < trunc(:p_start_date) ;
AND    TRUNC(d.gl_date)              < TRUNC(TO_DATE(:p_start_date,'MM/DD/RRRR'))) v_func_gain_amt
, (Select 
	   sum(c.amount_applied)                             sum_amount
From
	   ar_cash_receipts_all              A
	   , ar_cash_receipt_history_all       B
	   , ar_receivable_applications_all    c
Where 1=1
AND       a.pay_from_customer           = :customer_id
AND	   trunc(b.gl_date)              < TRUNC(TO_DATE(:p_start_date,'MM/DD/RRRR'))
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
AND	   trunc(b.gl_date)              < TRUNC(TO_DATE(:p_start_date,'MM/DD/RRRR'))
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
--AND 	   trunc(a.trx_date)            < trunc(:p_start_date)
AND 	   trunc(c.gl_date)             < TRUNC(TO_DATE(:p_start_date,'MM/DD/RRRR'))
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
--AND 	   trunc(a.trx_date)            < trunc(:p_start_date)
AND 	   trunc(c.gl_date)             < TRUNC(TO_DATE(:p_start_date,'MM/DD/RRRR'))
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

--------------------------------------------


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
, CASE WHEN NVL(( NVL(v_func_dr_amt,0      )
                      + nvl(v_cre_memo_func_amt,0)
                      + NVL(v_func_rev_amt,0     )
                      - NVL(v_func_cr_amt,0      )
                      + NVL(v_func_rcp_w_off,0   )
                      + (NVL(v_func_adj_amt,0   ))
                      - NVL(v_func_disc_cr_amt,0 )
                      - NVL(v_func_gain_amt,0    )
                      + NVL(v_func_loss_amt,0    )
                      ),0) < 0  THEN ABS(( NVL(v_func_dr_amt,0      )
                      + nvl(v_cre_memo_func_amt,0)
                      + NVL(v_func_rev_amt,0     )
                      - NVL(v_func_cr_amt,0      )
                      + NVL(v_func_rcp_w_off,0   )
                      + (NVL(v_func_adj_amt,0   ))
                      - NVL(v_func_disc_cr_amt,0 )
                      - NVL(v_func_gain_amt,0    )
                      + NVL(v_func_loss_amt,0    )
                      )) ELSE 0 END FUNC_OPEN_BAL_CR
, CASE WHEN NVL(( NVL(v_func_dr_amt,0      )
                      + nvl(v_cre_memo_func_amt,0)
                      + NVL(v_func_rev_amt,0     )
                      - NVL(v_func_cr_amt,0      )
                      + NVL(v_func_rcp_w_off,0   )
                      + (NVL(v_func_adj_amt,0   ))
                      - NVL(v_func_disc_cr_amt,0 )
                      - NVL(v_func_gain_amt,0    )
                      + NVL(v_func_loss_amt,0    )
                      ),0) < 0  THEN 0 ELSE ABS(( NVL(v_func_dr_amt,0      )
                      + nvl(v_cre_memo_func_amt,0)
                      + NVL(v_func_rev_amt,0     )
                      - NVL(v_func_cr_amt,0      )
                      + NVL(v_func_rcp_w_off,0   )
                      + (NVL(v_func_adj_amt,0   ))
                      - NVL(v_func_disc_cr_amt,0 )
                      - NVL(v_func_gain_amt,0    )
                      + NVL(v_func_loss_amt,0    )
                      )) END FUNC_OPEN_BAL_DR
, CASE WHEN NVL(( (NVL(v_tr_dr_amt,0)     )
                       + nvl(v_cre_memo_amt,0   )
                       +(NVL(v_tr_rev_amt,0    ))
                       - NVL(v_tr_cr_amt,0      )
                       + NVL(v_tran_rcp_w_off,0 )
                       - abs(NVL(v_tr_adj_amt,0))
                       - NVL(v_tr_disc_cr_amt,0)),0) < 0  THEN ABS(NVL(( (NVL(v_tr_dr_amt,0)     )
                       + nvl(v_cre_memo_amt,0   )
                       +(NVL(v_tr_rev_amt,0    ))
                       - NVL(v_tr_cr_amt,0      )
                       + NVL(v_tran_rcp_w_off,0 )
                       - abs(NVL(v_tr_adj_amt,0))
                       - NVL(v_tr_disc_cr_amt,0)),0)) ELSE 0 END tran_open_bal_cr
, CASE WHEN NVL(( (NVL(v_tr_dr_amt,0)     )
                       + nvl(v_cre_memo_amt,0   )
                       +(NVL(v_tr_rev_amt,0    ))
                       - NVL(v_tr_cr_amt,0      )
                       + NVL(v_tran_rcp_w_off,0 )
                       - abs(NVL(v_tr_adj_amt,0))
                       - NVL(v_tr_disc_cr_amt,0)),0) < 0  THEN ABS(NVL(( (NVL(v_tr_dr_amt,0)     )
                       + nvl(v_cre_memo_amt,0   )
                       +(NVL(v_tr_rev_amt,0    ))
                       - NVL(v_tr_cr_amt,0      )
                       + NVL(v_tran_rcp_w_off,0 )
                       - abs(NVL(v_tr_adj_amt,0))
                       - NVL(v_tr_disc_cr_amt,0)),0)) ELSE 0 END tran_open_bal_cr
, CASE WHEN NVL(( (NVL(v_tr_dr_amt,0)     )
                       + nvl(v_cre_memo_amt,0   )
                       +(NVL(v_tr_rev_amt,0    ))
                       - NVL(v_tr_cr_amt,0      )
                       + NVL(v_tran_rcp_w_off,0 )
                       - abs(NVL(v_tr_adj_amt,0))
                       - NVL(v_tr_disc_cr_amt,0)),0) < 0  THEN 0 ELSE (ABS(NVL(( (NVL(v_tr_dr_amt,0)     )
                       + nvl(v_cre_memo_amt,0   )
                       +(NVL(v_tr_rev_amt,0    ))
                       - NVL(v_tr_cr_amt,0      )
                       + NVL(v_tran_rcp_w_off,0 )
                       - abs(NVL(v_tr_adj_amt,0))
                       - NVL(v_tr_disc_cr_amt,0)),0))) END open_bal_tr
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
-- AND 	trunc(a.trx_date)            < trunc(:p_start_date)
AND 	trunc(c.gl_date)            < TRUNC(TO_DATE(:p_start_date,'MM/DD/RRRR')) 
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
AND 	trunc(c.gl_date)            < TRUNC(TO_DATE(:p_start_date,'MM/DD/RRRR')) 
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
AND 	trunc(b.apply_date)          < TRUNC(TO_DATE(:p_start_date,'MM/DD/RRRR'))
AND 	trunc(b.gl_date)          < TRUNC(TO_DATE(:p_start_date,'MM/DD/RRRR')) 
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
AND 	trunc(b.apply_date)          < TRUNC(TO_DATE(:p_start_date,'MM/DD/RRRR'))
AND 	trunc(b.gl_date)          < TRUNC(TO_DATE(:p_start_date,'MM/DD/RRRR')) 
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
									AND 		trunc(gl_date) < TRUNC(TO_DATE(:p_start_date,'MM/DD/RRRR')) 
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
									AND 		trunc(gl_date) < TRUNC(TO_DATE(:p_start_date,'MM/DD/RRRR')) 
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
AND	   trunc(b.gl_date)              < TRUNC(TO_DATE(:p_start_date,'MM/DD/RRRR'))
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
AND	   trunc(b.gl_date)              < TRUNC(TO_DATE(:p_start_date,'MM/DD/RRRR'))
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
AND    trunc(d.GL_DATE)              < TRUNC(TO_DATE(:p_start_date,'MM/DD/RRRR'))
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
AND    trunc(d.GL_DATE)              < TRUNC(TO_DATE(:p_start_date,'MM/DD/RRRR'))
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
--AND    TRUNC(c.receipt_date)         <  trunc(:p_start_date);
AND    TRUNC(d.gl_date)              <  TRUNC(TO_DATE(:p_start_date,'MM/DD/RRRR'))
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
--AND    TRUNC(c.receipt_date)         <  trunc(:p_start_date);
AND    TRUNC(d.gl_date)              <  TRUNC(TO_DATE(:p_start_date,'MM/DD/RRRR'))
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
--AND    TRUNC(c.receipt_date)         < trunc(:p_start_date) ;
AND    TRUNC(d.gl_date)              < TRUNC(TO_DATE(:p_start_date,'MM/DD/RRRR'))) v_tran_gain_amt
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
--AND    TRUNC(c.receipt_date)         < trunc(:p_start_date) ;
AND    TRUNC(d.gl_date)              < TRUNC(TO_DATE(:p_start_date,'MM/DD/RRRR'))) v_func_gain_amt
, (Select 
	   sum(c.amount_applied)                             sum_amount
From
	   ar_cash_receipts_all              A
	   , ar_cash_receipt_history_all       B
	   , ar_receivable_applications_all    c
Where 1=1
AND       a.pay_from_customer           = :customer_id
AND	   trunc(b.gl_date)              < TRUNC(TO_DATE(:p_start_date,'MM/DD/RRRR'))
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
AND	   trunc(b.gl_date)              < TRUNC(TO_DATE(:p_start_date,'MM/DD/RRRR'))
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
--AND 	   trunc(a.trx_date)            < trunc(:p_start_date)
AND 	   trunc(c.gl_date)             < TRUNC(TO_DATE(:p_start_date,'MM/DD/RRRR'))
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
--AND 	   trunc(a.trx_date)            < trunc(:p_start_date)
AND 	   trunc(c.gl_date)             < TRUNC(TO_DATE(:p_start_date,'MM/DD/RRRR'))
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
)

--------------------------------------------------------------------------------------------------------------

SELECT  CASE WHEN NVL(v_func_tot_amt,0) < 0  THEN ABS(v_func_tot_amt) ELSE 0 END FUNC_OPEN_BAL_CR
, CASE WHEN NVL(v_func_tot_amt,0) < 0  THEN 0 ELSE ABS(v_func_tot_amt) END FUNC_OPEN_BAL_DR
, CASE WHEN NVL(v_tran_tot_amt,0) < 0  THEN ABS(NVL(v_tran_tot_amt,0)) ELSE 0 END tran_open_bal_cr
, CASE WHEN NVL(v_tran_tot_amt,0) < 0  THEN ABS(NVL(v_tran_tot_amt,0)) ELSE 0 END tran_open_bal_cr
, CASE WHEN NVL(v_tran_tot_amt,0) < 0  THEN 0 ELSE (ABS(NVL(v_tran_tot_amt,0))) END open_bal_tr
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
-- AND 	trunc(a.trx_date)            < trunc(:p_start_date)
AND 	trunc(c.gl_date)            < TRUNC(TO_DATE(:p_start_date,'MM/DD/RRRR')) 
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
AND 	trunc(c.gl_date)            < TRUNC(TO_DATE(:p_start_date,'MM/DD/RRRR')) 
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
AND 	trunc(b.apply_date)          < TRUNC(TO_DATE(:p_start_date,'MM/DD/RRRR'))
AND 	trunc(b.gl_date)          < TRUNC(TO_DATE(:p_start_date,'MM/DD/RRRR')) 
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
AND 	trunc(b.apply_date)          < TRUNC(TO_DATE(:p_start_date,'MM/DD/RRRR'))
AND 	trunc(b.gl_date)          < TRUNC(TO_DATE(:p_start_date,'MM/DD/RRRR')) 
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
									AND 		trunc(gl_date) < TRUNC(TO_DATE(:p_start_date,'MM/DD/RRRR')) 
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
									AND 		trunc(gl_date) < TRUNC(TO_DATE(:p_start_date,'MM/DD/RRRR')) 
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
AND	   trunc(b.gl_date)              < TRUNC(TO_DATE(:p_start_date,'MM/DD/RRRR'))
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
AND	   trunc(b.gl_date)              < TRUNC(TO_DATE(:p_start_date,'MM/DD/RRRR'))
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
AND    trunc(d.GL_DATE)              < TRUNC(TO_DATE(:p_start_date,'MM/DD/RRRR'))
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
AND    trunc(d.GL_DATE)              < TRUNC(TO_DATE(:p_start_date,'MM/DD/RRRR'))
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
--AND    TRUNC(c.receipt_date)         <  trunc(:p_start_date);
AND    TRUNC(d.gl_date)              <  TRUNC(TO_DATE(:p_start_date,'MM/DD/RRRR'))
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
--AND    TRUNC(c.receipt_date)         <  trunc(:p_start_date);
AND    TRUNC(d.gl_date)              <  TRUNC(TO_DATE(:p_start_date,'MM/DD/RRRR'))
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
--AND    TRUNC(c.receipt_date)         < trunc(:p_start_date) ;
AND    TRUNC(d.gl_date)              < TRUNC(TO_DATE(:p_start_date,'MM/DD/RRRR'))) v_tran_gain_amt
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
--AND    TRUNC(c.receipt_date)         < trunc(:p_start_date) ;
AND    TRUNC(d.gl_date)              < TRUNC(TO_DATE(:p_start_date,'MM/DD/RRRR'))) v_func_gain_amt
, (Select 
	   sum(c.amount_applied)                             sum_amount
From
	   ar_cash_receipts_all              A
	   , ar_cash_receipt_history_all       B
	   , ar_receivable_applications_all    c
Where 1=1
AND       a.pay_from_customer           = :customer_id
AND	   trunc(b.gl_date)              < TRUNC(TO_DATE(:p_start_date,'MM/DD/RRRR'))
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
AND	   trunc(b.gl_date)              < TRUNC(TO_DATE(:p_start_date,'MM/DD/RRRR'))
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
--AND 	   trunc(a.trx_date)            < trunc(:p_start_date)
AND 	   trunc(c.gl_date)             < TRUNC(TO_DATE(:p_start_date,'MM/DD/RRRR'))
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
--AND 	   trunc(a.trx_date)            < trunc(:p_start_date)
AND 	   trunc(c.gl_date)             < TRUNC(TO_DATE(:p_start_date,'MM/DD/RRRR'))
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
))

---------------------------------------------------------------------------------------------------------


, CASE WHEN NVL(v_func_tot_amt,0) < 0  THEN ABS(v_func_tot_amt) ELSE 0 END FUNC_OPEN_BAL_CR
, CASE WHEN NVL(v_func_tot_amt,0) < 0  THEN 0 ELSE ABS(v_func_tot_amt) END FUNC_OPEN_BAL_DR
, CASE WHEN NVL(v_tran_tot_amt,0) < 0  THEN ABS(NVL(v_tran_tot_amt,0)) ELSE 0 END tran_open_bal_cr
, CASE WHEN NVL(v_tran_tot_amt,0) < 0  THEN ABS(NVL(v_tran_tot_amt,0)) ELSE 0 END tran_open_bal_cr
, CASE WHEN NVL(v_tran_tot_amt,0) < 0  THEN 0 ELSE (ABS(NVL(v_tran_tot_amt,0))) END open_bal_tr



CASE WHEN  NVL(func_op_bal_tot_dr,0) - NVL(func_op_bal_tot_cr,0) < 0 THEN
   ABS( NVL(func_op_bal_tot_dr,0) - NVL(func_op_bal_tot_cr,0))
ELSE
   0
END OP_TOT_CR 
, CASE WHEN  NVL(func_op_bal_tot_dr,0) - NVL(func_op_bal_tot_cr,0) < 0 THEN
   0
ELSE
   nvl(abs( NVL(func_op_bal_tot_dr,0) - NVL(func_op_bal_tot_cr,0)),0)
END OP_TOT_DR