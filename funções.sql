--Sacar
create or replace function sacar(valor float, numero_da_conta int, senha_da_conta int)
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

--depositar ; não precisa da senha da conta
create or replace function depositar(valor float, numero_da_conta int)
returns void as $$
declare
	_conta record;
	_dono record;
	_cod_tipo_movimentacao int;
begin 
	if exists(select * from conta where numero_conta = numero_da_conta) then
		select cod_tipo_movimentacao into _cod_tipo_movimentacao from tipo_movimentacao
		where descricao_tipo_movimentacao ilike 'Deposito';

		select * into _conta from conta where numero_conta = numero_da_conta;
		
		if valor <= 0 then
			raise exception 'Você não pode depositar valores negativos ou nulos';
		else
		  select * into _dono from proprietario natural join cliente where numero_conta = numero_da_conta;
			update conta set saldo = saldo + valor where numero_conta = numero_da_conta;

      --concatenar
			--raise notice 'Deposito feito na conta de ' || _dono.nome_cliente || ', numero da conta:' || _conta.numero_conta;

-- 			insert into movimentacao values(
-- 			_conta.senha,
-- 			_conta.letras,
-- 			_cod_tipo_movimentacao,
-- 			default,
-- 			valor);
		end if;
	else
		raise exception 'Numero da conta ou senha incorreta';
	end if;

end $$ language plpgsql;


-----Emprestimo-----
create or replace function fazer_emprestimo(valor float, numero_da_conta int, senha_da_conta int, tipo_de_emprestimo varchar(30), numero_de_parcelas int)
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

create or replace function ver_saldo(numero_da_conta int, senha_da_conta int) returns float as $$
declare
  _saldo float;
begin
  --Conta existe--
  if exists(select * from conta where numero_conta = numero_da_conta and senha = senha_da_conta) then
    select saldo into _saldo from conta where numero_conta = numero_da_conta and senha = senha_da_conta;
    return _saldo;
  end if;

  raise exception 'Numero da conta ou senha incorreta';

end
$$ language 'plpgsql';

create or replace function pagar_fatura(numero_da_conta int, senha_da_conta int, valor_fatura float) returns void as $$
declare
  _saldo float;
begin
  --Conta existe--
  if exists(select * from conta where numero_conta = numero_da_conta and senha = senha_da_conta) then
    select saldo into _saldo from conta where numero_conta = numero_da_conta and senha = senha_da_conta;
    if valor_fatura <= saldo then
      update conta set saldo = saldo - valor_fatura where numero_conta = numero_da_conta and senha = senha_da_conta;
    end if;
    raise exception 'Voce não tem saldo suficiente pra pagar essa fatura';
  end if;

  raise exception 'Numero da conta ou senha incorreta';

end
$$ language 'plpgsql';

create or replace function transferencia(numero_da_conta1 int, senha_da_conta1 int, numero_da_conta2 int, valor float) returns void as $$
declare
  _conta record;
begin
  --Conta existe--
  if exists(select * from conta where numero_conta = numero_da_conta1 and senha = senha_da_conta1) then
-- 		select cod_tipo_movimentacao into _cod_tipo_movimentacao from tipo_movimentacao where descricao_tipo_movimentacao ilike 'Saque';

		select * into _conta from conta where numero_conta = numero_da_conta and senha = senha_da_conta;
		if valor <= 0 then
			raise exception 'Você não pode transferir valores negativos ou nulos';
		elsif _conta.saldo - valor < 0 then
			raise exception 'Você não tem saldo suficiente pra transferir essa quantidade';
		else
			update conta set saldo = saldo - valor where numero_conta = numero_da_conta1 and senha = senha_da_conta1;
			update conta set saldo = saldo + valor where numero_conta = numero_da_conta2;
			insert into movimentacao values(
			_conta.senha,
			_conta.letras,
			_cod_tipo_movimentacao,
			default,
			valor);

		end if;
	end if;

  raise exception 'Numero da conta ou senha incorreta';

end
$$ language 'plpgsql';


---Testes


--ver saldo ok
--transferencia
--ver extrato
--pagar fatura ok
--pagar parcela
select depositar(10,'ABCDEF',123);
select sacar(10,'ABCDEF',123);
select fazer_emprestimo(2000, 1, 1234, 'Consiguinado', 9);