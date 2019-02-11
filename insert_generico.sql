create or replace function teste_insert(nome_tabela text, atributos text)
returns record as $$
declare
	inserir text;
	retorno record;
begin
  inserir:= 'insert into ' || nome_tabela || ' values(' || atributos  || ') returning * into retorno;';
  execute inserir;
	return retorno;
	
end $$ language plpgsql;


--Exemplo
select teste_insert('agencia','1,''teste''');