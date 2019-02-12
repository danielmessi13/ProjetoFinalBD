
create or replace function controle_conta()
returns trigger as $$
begin 
	if tg_op = 'INSERT' or 'UPDATE' then
		if new.cod_agencia not in (select cod_agencia from agencia) then
			raise exception 'Agencia inexistente';
		else if new.cod_tipo_conta not in (select cod_tipo_conta from tipo_conta) then
			raise exception 'Tipo de conta inexistente';
		end if;
		end if;
	end if;

	if tg_op = 'DELETE' then
		if exists(select * from emprestimo where numero_conta = old.numero_conta) then
			raise exception 'existem emprestimo a serem quitados';
		end if;
	end if;
		
	
end $$ language plpgsql;

CREATE TRIGGER controle_conta_trigger BEFORE INSERT OR UPDATE OR DELETE ON conta FOR EACH ROW EXECUTE PROCEDURE controle_conta();

create function controle_cliente()
returns trigger as $$
  begin
    if tg_op = 'INSERT' then
			if new.cpf in (select cpf from cliente) then
				raise exception 'cpf ja cadastrado';
			end if;
		end if;
	end
$$ language plpgsql;

create trigger controle_cliente_trigger before insert or update or delete on cliente for each row execute procedure controle_cliente();

create function controle_deposito()
returns trigger as $$
  begin
    if tg_op = 'INSERT' or tg_op == 'UPDATE' then
      if (select count(*) from partes_movimentacao where numero_conta = new.numero_conta) < 4 then
        return new;
      end if;
      else if new.saldo > ((select avg(valor) from partes_movimentacao where numero_conta = new.numero_conta)+ 500) then
           raise exception 'valor muito acima do que normalmete é depositado';
      end if;
      return new;
    end if;
  end $$ language plpgsql;

create trigger controle_deposito_trigger before insert or update or delete on conta for each row execute procedure controle_deposito();

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
		elsif new.valor_emprestimo <= 0 then
			raise exception 'Quantidade invalida';
		end if;

		return new;

	elsif tg_op = 'UPDATE' then
		if new.valor_emprestimo > 500 then
			raise exception 'Valor de emprestimo acima do limite';
		elsif new.valor_emprestimo <= 0 then
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