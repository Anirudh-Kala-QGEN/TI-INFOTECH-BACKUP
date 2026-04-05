DECLARE
   cursor c1 is
   select line.customer_trx_line_id,
          line.line_number,
          line.extended_amount line_amount,
          tax.extended_amount tax_amount
   from ra_customer_trx_lines line,
       (select link_to_cust_trx_line_id,
        sum(nvl(extended_amount,0)) extended_amount
        from ra_customer_trx_lines
        where customer_trx_id = 528349
        and line_type = 'TAX'
        group by link_to_cust_trx_line_id) tax
   where line.customer_trx_id = 528349
   and line.line_type = 'LINE'
   and line.customer_trx_line_id = tax.LINK_TO_CUST_TRX_LINE_ID(+);

   l_llca_trx_lines_tbl ar_receipt_api_pub.llca_trx_lines_tbl_type;
   l_return_status VARCHAR2(1);
   l_msg_count NUMBER;
   l_msg_data VARCHAR2(240);
   p_count NUMBER := 0;
   l_cnt NUMBER := 0;


BEGIN
    -- 1) Set the applications context
    mo_global.init('AR');
    mo_global.set_policy_context('S','204');
    fnd_global.apps_initialize(1011902, 50559, 222,0);

   -- 2)  define the amounts to apply, for illustration purposes we will apply 10% of the original amounts
   for i in c1 loop
      l_cnt := l_cnt + 1;

      l_llca_trx_lines_tbl(l_cnt).customer_trx_line_id := i.customer_trx_line_id ;
      l_llca_trx_lines_tbl(l_cnt).line_amount := i.line_amount * .10;
      l_llca_trx_lines_tbl(l_cnt).amount_applied := i.line_amount * .10;
      l_llca_trx_lines_tbl(l_cnt).tax_amount := i.tax_amount *.10;
   end loop;

   AR_RECEIPT_API_PUB.APPLY_IN_DETAIL
   ( p_api_version => 1.0,
     p_init_msg_list => FND_API.G_TRUE,
     p_commit => FND_API.G_TRUE,
     p_validation_level => FND_API.G_VALID_LEVEL_FULL,
     x_return_status => l_return_status,
     x_msg_count => l_msg_count,
     x_msg_data => l_msg_data,
     p_cash_receipt_id => 84003,
     p_customer_trx_id => 528349,
     p_llca_type => 'L',
     p_org_id => 204,
     p_llca_trx_lines_tbl => l_llca_trx_lines_tbl );
   

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