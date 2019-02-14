create or replace function insert_generico(nome_tabela text, atributos text)
returns void as $$
declare
	inserir text;
begin
  inserir:= 'insert into ' || nome_tabela || ' values(' || atributos  || ')';
  execute inserir;

end $$ language plpgsql;

drop function teste_insert(nome_tabela text, atributos text);

--Exemplo
select teste_insert('agencia','default,''teste''') ;
select teste_insert('conta', 'default, ''123.123.123-45'', 123, default, 1 ,1, default');

