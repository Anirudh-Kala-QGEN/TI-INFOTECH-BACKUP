DECLARE
   l_return_status VARCHAR2(1);
   l_msg_count NUMBER;
   l_msg_data VARCHAR2(240);
   l_cash_receipt_id NUMBER;
   p_count number := 0;

BEGIN
    -- 1) Set the applications context
    mo_global.init('AR');
    mo_global.set_policy_context('S','204');
    fnd_global.apps_initialize(1011902, 50559, 222,0);

   AR_RECEIPT_API_PUB.CREATE_APPLY_ON_ACC
   ( p_api_version => 1.0,
     p_init_msg_list => FND_API.G_TRUE,
     p_commit => FND_API.G_TRUE,
     p_validation_level => FND_API.G_VALID_LEVEL_FULL,
     x_return_status => l_return_status,
     x_msg_count => l_msg_count,
     x_msg_data => l_msg_data,
     p_amount => 555.00,
     p_receipt_number => 'rct-api12',
     p_receipt_date => '22-JUL-2011',
     p_gl_date => '22-JUL-2011',
     p_customer_number => 1007,
     p_receipt_method_id => 1001,
     p_cr_id => l_cash_receipt_id );

    -- 3) Review the API output
    dbms_output.put_line('Status ' || l_return_status);
    dbms_output.put_line('Message count ' || l_msg_count);
    dbms_output.put_line('Cash Receipt Id ' || l_cash_receipt_id);

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