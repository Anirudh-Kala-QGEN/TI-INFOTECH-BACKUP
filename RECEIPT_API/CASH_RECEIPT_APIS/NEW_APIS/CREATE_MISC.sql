DECLARE
   l_return_status VARCHAR2(1);
   l_msg_count NUMBER;
   l_msg_data VARCHAR2(240);
   l_cash_receipt_id NUMBER;
   p_count number := 0;
   l_receipt_number varchar(10);

BEGIN
    -- 1) Set the applications context
    mo_global.init('AR');
    mo_global.set_policy_context('S','204');
    fnd_global.apps_initialize(1011902, 50559, 222,0);

   l_receipt_number := 'misc-api1';

   AR_RECEIPT_API_PUB.CREATE_MISC
   ( p_api_version => 1.0,
     p_init_msg_list => FND_API.G_TRUE,
     p_commit => FND_API.G_TRUE,
     p_validation_level => FND_API.G_VALID_LEVEL_FULL,
     x_return_status => l_return_status,
     x_msg_count => l_msg_count,
     x_msg_data => l_msg_data,
     p_amount => 4560.00,
     p_receipt_date => '22-JUL-2011',
     p_gl_date => '22-JUL-2011',
     p_receipt_method_id => 1001,
     p_activity => 'Interest Income',
     p_misc_receipt_id => l_cash_receipt_id ,
     p_receipt_number => l_receipt_number);

    -- 3) Review the API output
    dbms_output.put_line('Status ' || l_return_status);
    dbms_output.put_line('Message count ' || l_msg_count);
    dbms_output.put_line('Cash Receipt ID ' || l_cash_receipt_id );

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

Provide the value for the Receivable activity name for which you are creating a Miscellaneous cash receipt. Valid values are returned by the select:

select name, receivables_trx_id
from ar_receivables_trx_all
where org_id = &ORG_ID
and type = 'MISCCASH';


*/