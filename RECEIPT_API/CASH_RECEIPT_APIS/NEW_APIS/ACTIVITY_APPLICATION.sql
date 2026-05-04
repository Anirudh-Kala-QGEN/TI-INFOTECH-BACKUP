DECLARE
   l_return_status VARCHAR2(1);
   l_msg_count NUMBER;
   l_msg_data VARCHAR2(240);
   l_cash_receipt_id NUMBER;
   p_count number := 0;
   l_application_ref_type ar_receivable_applications.application_ref_type%TYPE;
   l_application_ref_id ar_receivable_applications.application_ref_id%TYPE;
   l_application_ref_num ar_receivable_applications.application_ref_num%TYPE;
   l_secondary_application_ref_id ar_receivable_applications.secondary_application_ref_id%TYPE;
   l_receivable_application_id ar_receivable_applications.receivable_application_id%TYPE;

BEGIN
    -- 1) Set the applications context
    mo_global.init('AR');
    mo_global.set_policy_context('S','204');
    fnd_global.apps_initialize(1011902, 50559, 222,0);

   AR_RECEIPT_API_PUB.ACTIVITY_APPLICATION
   ( p_api_version => 1.0,
     p_init_msg_list => FND_API.G_TRUE,
     p_commit => FND_API.G_TRUE,
     p_validation_level => FND_API.G_VALID_LEVEL_FULL,
     x_return_status => l_return_status,
     x_msg_count => l_msg_count,
     x_msg_data => l_msg_data,
     p_cash_receipt_id => 83994,
     p_applied_payment_schedule_id => -3,
     p_receivables_trx_id => 2536,
     p_receivable_application_id => l_receivable_application_id
     p_application_ref_type => l_application_ref_type,
     p_application_ref_id => l_application_ref_id,
     p_application_ref_num => l_application_ref_num,
     p_secondary_application_ref_id => l_secondary_application_ref_id);

    -- 3) Review the API output
    dbms_output.put_line('Status ' || l_return_status);
    dbms_output.put_line('Message count ' || l_msg_count);
    dbms_output.put_line('Application ID ' || l_receivable_application_id;

    if l_msg_count = 1 Then
       dbms_output.put_line('l_msg_data '|| l_msg_data);
    elsif l_msg_count > 1 Then
       loop
          p_count := p_count + 1;
          l_msg_data := FND_MSG_PUB.Get(FND_MSG_PUB.G_NEXT,FND_API.G_FALSE);
          if l_msg_data is NULL Then
             exit;
          end if;
          dbms_output.put_line('Message ' || p_count ||'. '||l_msg_data);
       end loop;
    end if;
END;
/

/*


Payment_Schedule_Id	Transaction Number
-2	Short Term Debt
-3	Receipt Write-off
-4	Claim Investigation
-5	Chargeback
-6	Credit Card Refund
-7	Prepayment
-8	Refund
-9	Credit Card Chargeback


Provide the cash_receipt_id of an existing receipt you want to apply to a Receivable activity. The value you enter here must exist in the select:

select cash_receipt_id
from ar_cash_receipts_all
where org_id = &org_id
and status <> 'REV';

*/