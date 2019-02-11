create or replace function controle_conta() 
returns trigger as $$
begin 
	if tg_op = 'INSERT':
	  --um cliente não pode ser dono e proprietario da mesma conta

	if tg_op = 'UPDATE':

	if tg_op = 'DELETE':
		
	
end $$ language plpgsql;

CREATE TRIGGER controle_conta_trigger BEFORE INSERT OR UPDATE OR DELETE ON conta FOR EACH ROW EXECUTE PROCEDURE controle_conta();



create or replace function controle_parcela() 
returns trigger as $$
begin 
	if tg_op = 'INSERT':
		
	if tg_op = 'UPDATE':

	if tg_op = 'DELETE':
		
	
end $$ language plpgsql;

CREATE TRIGGER controle_parcela_trigger BEFORE INSERT OR UPDATE OR DELETE ON parcela FOR EACH ROW EXECUTE PROCEDURE controle_parcela();




create or replace function controle_emprestimo() 
returns trigger as $$
begin 
	if tg_op = 'INSERT' then
		if new.valor_emprestimo > 500 then
			raise exception 'Valor de emprestimo acima do limite';
		elsif new.valor_emprestimo = 0 then
			raise exception 'Quantidade insuficiente';
		end if;

		return new;

	elsif tg_op = 'UPDATE' then
		if new.valor_emprestimo > 500 then
			raise exception 'Valor de emprestimo acima do limite';
		elsif new.valor_emprestimo = 0 then
			delete from emprestimo where valor_emprestimo = 0;
			raise notice 'Emprestimo quitado';
		end if;
	
		return new;

	else
		if old.valor_emprestimo > 0 then
			raise exception 'Emprestimo ainda não quitado';
		end if;

		return old;
	end if;
	
end $$ language plpgsql;

insert into tipo_emprestimo values (default,'Consignado',10);
insert into emprestimo values (default,10,1);
delete from emprestimo where cod_emprestimo = 6;
update emprestimo set valor_emprestimo = 0 where cod_emprestimo = 6;


CREATE TRIGGER controle_emprestimo_trigger AFTER INSERT OR UPDATE OR DELETE ON emprestimo FOR EACH ROW EXECUTE PROCEDURE controle_emprestimo()

drop trigger controle_emprestimo_trigger on emprestimo;