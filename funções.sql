

create or replace function sacar(valor int, numero_da_conta int, senha_da_conta int)
returns void as $$
declare
	_conta record;
	_cod_tipo_movimentacao int;
  _cod_movimentacao int;
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
			insert into movimentacao values(default,
																			_cod_tipo_movimentacao,
																			default) returning cod_movimentacao into _cod_movimentacao;

			insert into partes_movimentacao values (default,
			                                        _cod_movimentacao,
			                                        _conta.numero_conta,
			                                        valor * -1);
			
		end if;
	else
		raise exception 'Numero da conta ou senha incorreta';
	end if;

end $$ language plpgsql;


create or replace function depositar(valor int, numero_da_conta int)
returns void as $$
declare
	_conta record;
	_cod_tipo_movimentacao int;
  _cod_movimentacao int;
begin 
	if exists(select * from conta where numero_conta = numero_da_conta) then
		select cod_tipo_movimentacao into _cod_tipo_movimentacao from tipo_movimentacao
		where descricao_tipo_movimentacao ilike 'Deposito';

		select * into _conta from conta where numero_conta = numero_da_conta;
		
		if valor <= 0 then
			raise exception 'Você não pode depositar valores negativos ou nulos';
		else
			update conta set saldo = saldo + valor where numero_conta = numero_da_conta;

			insert into movimentacao values(default,
																			_cod_tipo_movimentacao,
																			default) returning cod_movimentacao into _cod_movimentacao;
			insert into partes_movimentacao values (default,
			                                        _cod_movimentacao,
			                                        _conta.numero_conta,
			                                        valor);
		end if;
	else
		raise exception 'Numero da conta ou senha incorreta';
	end if;

end $$ language plpgsql;

create function transferir(numero_conta_caridosa int, senha_conta_caridosa int, numero_conta_sortuda int, valor float)
returns void as $$
declare
	_conta_caridosa record;
  _cod_movimentacao int;
  _cod_tipo_movimentacao int;
  _cod_conta_sortuda int;
begin
	if exists(select * from conta where numero_conta = numero_conta_caridosa and senha = senha_conta_caridosa) and
	   exists(select * from conta where numero_conta = numero_conta_sortuda) then

	  select * into _conta_caridosa from conta where numero_conta = numero_conta_caridosa;
		select numero_conta into _cod_conta_sortuda from conta where numero_conta = numero_conta_sortuda;
		select cod_tipo_movimentacao from tipo_movimentacao where descricao_tipo_movimentacao = 'Transferencia';

		if valor <= 0 then
				raise exception 'Você não pode transferir valores negativos ou nulos';
		elsif _conta_caridosa.saldo - valor < 0 then
				raise exception 'Você não tem saldo suficiente pra transferir essa quantidade';
		end if;

		update conta set saldo = saldo + valor where numero_conta = numero_conta_sortuda;
		update conta set saldo = saldo - valor where numero_conta = numero_conta_caridosa;

		insert into movimentacao values (default, _cod_tipo_movimentacao, default) returning cod_movimentacao into _cod_movimentacao;
		insert into partes_movimentacao values (default, _cod_movimentacao, _conta_caridosa.numero_conta, valor * -1);
		insert into partes_movimentacao values (default, _cod_movimentacao, _cod_conta_sortuda, valor);

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
																	 _tipo_emprestimo.cod_tipo_emprestimo)
																	 returning cod_emprestimo into _cod_emprestimo;
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


create or replace function pagar_emprestimo(numero_da_conta int, senha_da_conta int)
returns void as $$
  declare
    _conta record;
    _cod_emprestimo int;
    _parcela record;
  begin
    if exists(select * from conta where numero_conta = numero_da_conta and senha = senha_da_conta) then

			select * into _conta from conta where numero_conta = numero_da_conta;
			select cod_emprestimo into _cod_emprestimo from emprestimo where numero_conta = numero_da_conta and data = (select min(data) from emprestimo where numero_conta = numero_da_conta);
			select atualiza_emprestimo(_cod_emprestimo);
			select * into _parcela from parcela where cod_emprestimo = _cod_emprestimo and data_pagamento_parcela = (select min(data_pagamento_parcela) from parcela where cod_emprestimo = _cod_emprestimo);
    	if _conta.saldo < _parcela.valor_parcela then
				raise exception 'Saldo insuficiente';
			else
    	  update conta set saldo = saldo - _parcela.valor_parcela where numero_conta = numero_da_conta;
    	  --deletar a parcela, mais eu num sei deletar
			end if;
    else
      raise exception 'Numero da conta ou senha invalida';
		end if;
	end;
$$ language plpgsql;


create or replace function atualiza_emprestimo(cod_emprestimo int)
	returns void as $$
declare
	parcelita record;
	dias_atrasada int;
begin
	for parcelita in (select * from parcela where cod_emprestimo = cod_emprestimo) loop
		if parcelita.data_pagamento_parcela > current_date then
			select parcelita.data_pagamento_parcela - current_date into dias_atrasada;
			update parcela set valor_parcela = valor_parcela * (1 +(0.01 * dias_atrasada)), data_pagamento_parcela = data_pagamento_parcela + dias_atrasada;
		end if;
	end loop;
end $$ language plpgsql;


---Testes

select depositar(10,'ABCDEF',123);
select sacar(10,'ABCDEF',123);
select fazer_emprestimo(2000, 1, 1234, 'Consiguinado', 9);

select * from agencia;
select * from parcela;
select * from conta;
