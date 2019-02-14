create or replace function insert_generico(nome_tabela text, atributos text)
returns record as $$
declare
	inserir text;
  valores record;
begin
  inserir:= 'insert into ' || nome_tabela || ' values(' || atributos  || ')';
  execute inserir;

  return valores;

end $$ language plpgsql;


--Exemplo
select insert_generico('agencia','default,''teste''') ;
select teste_insert('conta', 'default, ''123.123.123-45'', 123, default, 1 ,1, default');

