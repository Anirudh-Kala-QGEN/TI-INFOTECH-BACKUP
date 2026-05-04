DECLARE
   l_return_status VARCHAR2(1);
   l_msg_count NUMBER;
   l_msg_data VARCHAR2(240);
   p_count NUMBER;
   x_receivable_application_id NUMBER;
   x_application_ref_id NUMBER;
   x_application_ref_num VARCHAR2(30);
   x_secondary_application_ref_id NUMBER;

BEGIN
    -- 1) Set the applications context
    mo_global.init('AR');
    mo_global.set_policy_context('S','204');
    fnd_global.apps_initialize(1011902, 50559, 222,0);

   -- 2) Call the API
   AR_RECEIPT_API_PUB.APPLY_OTHER_ACCOUNT
   ( p_api_version => 1.0,
     p_init_msg_list => FND_API.G_TRUE,
     p_commit => FND_API.G_TRUE,
     p_validation_level => FND_API.G_VALID_LEVEL_FULL,
     x_return_status => l_return_status,
     x_msg_count => l_msg_count,
     x_msg_data => l_msg_data,
     p_receivable_application_id => x_receivable_application_id,
     p_cash_receipt_id => 83997,
     p_receivables_trx_id => 1747,
     p_applied_payment_schedule_id => -4,
     p_amount_applied => 500.00,
     p_application_ref_id => x_application_ref_id,
     p_application_ref_num => x_application_ref_num,
     p_secondary_application_ref_id => x_secondary_application_ref_id,
     p_called_from => null);

    -- 3) Review the API output
    dbms_output.put_line('Status ' || l_return_status);
    dbms_output.put_line('Message count ' || l_msg_count);
    dbms_output.put_line('Receivable Application Id ' || x_receivable_application_id);

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

select name, receivables_trx_id
from ar_receivables_trx_all
where org_id = &ORG_ID
and type = 'CLAIM_INVESTIGATION';

*/