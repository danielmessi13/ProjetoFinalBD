create or replace function teste_insert(nome_tabela text, atributos text)
returns text as $$
declare
	inserir text;
begin
  inserir:= 'insert into ' || nome_tabela || ' values(' || atributos  || ');';
  execute inserir;
	return inserir;
	
end $$ language plpgsql;


--Exemplo
select teste_insert('agencia','1,''teste''');