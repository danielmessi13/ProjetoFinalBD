create or replace function sacar(valor int, numero_da_conta int, senha_da_conta int) 
returns void as $$
declare
	_conta record;
	_cod_tipo_movimentacao int;
begin 
	if exists(select * from conta where numero_conta = numero_da_conta and senha = senha_da_conta) then
		select cod_tipo_movimentacao into _cod_tipo_movimentacao from tipo_movimentacao where descricao_tipo_movimentacao ilike 'Saque';
		
		select * into _conta from conta where numero_conta = numero_da_conta and senha = senha_da_conta;
		if valor <= 0 then
			raise exception 'Você não pode sacar valores negativos ou nulos';
		elsif _conta.saldo - valor < 0 then
			raise exception 'Você não tem saldo suficiente pra sacar essa quantidade';
		else
			update conta set saldo = saldo - valor where numero_conta = numero_da_conta and senha = senha_da_conta;
			insert into movimentacao values(
			_conta.senha,
			_conta.letras,
			_cod_tipo_movimentacao,
			default,
			valor);
			
		end if;
	else
		raise exception 'Numero da conta ou senha incorreta';
	end if;

end $$ language plpgsql;


create or replace function depositar(valor int, numero_da_conta int, senha_da_conta int) 
returns void as $$
declare
	_conta record;
	_cod_tipo_movimentacao int;
begin 
	if exists(select * from conta where numero_conta = numero_da_conta and senha = senha_da_conta) then
		select cod_tipo_movimentacao into _cod_tipo_movimentacao from tipo_movimentacao
		where descricao_tipo_movimentacao ilike 'Deposito';

		select * into _conta from conta where numero_conta = numero_da_conta and senha = senha_da_conta;
		
		if valor <= 0 then
			raise exception 'Você não pode depositar valores negativos ou nulos';
		else
			update conta set saldo = saldo + valor where numero_conta = numero_da_conta and senha = senha_da_conta;

			insert into movimentacao values(
			_conta.senha,
			_conta.letras,
			_cod_tipo_movimentacao,
			default,
			valor);
		end if;
	else
		raise exception 'Numero da conta ou senha incorreta';
	end if;

end $$ language plpgsql;


-----Emprestimo-----
create or replace function fazer_emprestimo(valor int, numero_da_conta int, senha_da_conta int, tipo_de_emprestimo varchar(30), numero_de_parcelas int)
returns void as $$
declare
	_conta int;
	_tipo_emprestimo record;
	_cod_emprestimo int;
	data_parcela date;
	valor_parcela float;
begin

	if exists(select * from conta where numero_conta = numero_da_conta and senha = senha_da_conta) then
	
		--criar emprestimo
		select numero_conta into _conta from conta where numero_conta = numero_da_conta;
		select cod_tipo_emprestimo, taxa, numero_maximo_parcelas into _tipo_emprestimo from tipo_emprestimo where descricao_tipo_emprestimo ilike tipo_de_emprestimo;
		if numero_de_parcelas > _tipo_emprestimo.numero_maximo_parcelas or numero_de_parcelas < 1 then
			raise exception 'Numero de parcelas invalido';
		end if;
		insert into emprestimo values (default,
									   valor,
									   _conta,
									   _tipo_emprestimo.cod_tipo_emprestimo) returning cod_emprestimo into _cod_emprestimo;
		update conta set saldo = saldo + valor where numero_conta = _conta;
		
		--criar parcelas
		data_parcela:= current_date + 30;
		valor_parcela:= (valor * ((_tipo_emprestimo.taxa / 100) + 1)) / numero_de_parcelas;--estou considerando q a taxa é uma porcentagem
		for i in 1..numero_de_parcelas loop
			insert into parcela values (default, data_parcela, valor_parcela, _cod_emprestimo);
			data_parcela:= data_parcela + 30;
		end loop;
	else
		raise exception 'Numero da conta ou senha incorreta';
	end if;
end $$ language plpgsql;


select * from parcela;
---Testes

select depositar(10,'ABCDEF',123);
select sacar(10,'ABCDEF',123);
select fazer_emprestimo(2000, 1, 1234, 'Consiguinado', 9);

select * from emprestimo;
select * from parcela;
select * from conta;