select criar_conta('Filipe', '123.123.123-46', 123, 'Corrente', 'Codó', 'Daniel');

create or replace function criar_conta (nome varchar(30), cpf varchar(14), senha_da_conta int, descricao_do_tipo_conta varchar(40), nome_da_agencia text, nome_do_funcionario varchar(40))
returns void as $$
  declare
    _agencia record;
    _cod_tipo_conta int;
    _funcionario record;
  begin
		if exists(select * from funcionario where nome_funcionario = nome_do_funcionario) then
			select * into _funcionario from funcionario where nome_funcionario=  nome_do_funcionario;
		else
			raise exception 'Funcionario não cadastrado';
		end if;

		if exists(select * from agencia where descricao_agencia = nome_da_agencia)then
      select * into _agencia from agencia where descricao_agencia = nome_da_agencia;
    else
		  raise exception 'Agencia inexistente';
    end if;

    if exists(select * from tipo_conta where descricao_conta = descricao_do_tipo_conta) then
      select cod_tipo_conta into _cod_tipo_conta from tipo_conta where descricao_conta = descricao_do_tipo_conta;
    else
      raise exception 'tipo de conta inexistente';
    end if;
    if _funcionario.cod_agencia = _agencia.cod_agencia then
      insert into cliente values (cpf, nome);
			insert into conta values (default , cpf, senha_da_conta, default, _cod_tipo_conta, _agencia.cod_agencia);
		ELSE
		  RAISE exception 'funcionario não altorizado';
		end if;


	end;
$$ language plpgsql;



create or replace function sacar(valor int, numero_da_conta int, senha_da_conta int)
returns void as $$
declare
	_conta record;
	_cod_tipo_movimentacao int;
  _cod_movimentacao int;
begin 
	if exists(select * from conta where numero_conta = numero_da_conta and senha = senha_da_conta) then
	  select cod_tipo_movimentacao into _cod_tipo_movimentacao from tipo_movimentacao where descricao_tipo_movimentacao ilike 'Saque';
		if (select count(*) from partes_movimentacao natural join movimentacao where cod_tipo_movimentacao = _cod_tipo_movimentacao and numero_conta = numero_da_conta and data = current_date) < 4 then
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
		  raise exception 'numero maximo de saques exedido';
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

create or replace function transferir(numero_conta_caridosa int, senha_conta_caridosa int, numero_conta_sortuda int, valor float)
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
		if exists(select * from tipo_emprestimo where descricao_tipo_emprestimo ilike tipo_de_emprestimo) then
			select cod_tipo_emprestimo, taxa, numero_maximo_parcelas into _tipo_emprestimo from tipo_emprestimo where descricao_tipo_emprestimo ilike tipo_de_emprestimo;
		else
		  raise exception 'tipo de emprestimo não valido';
		end if;
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
			perform atualiza_emprestimo(_cod_emprestimo);
			select * into _parcela from parcela where codigo_emprestimo = _cod_emprestimo and data_pagamento_parcela = (select min(data_pagamento_parcela) from parcela where codigo_emprestimo = _cod_emprestimo);

    	if _conta.saldo < _parcela.valor_parcela then
				raise exception 'Saldo insuficiente';
			else
    	  update conta set saldo = saldo - _parcela.valor_parcela where numero_conta = numero_da_conta;
    	  update emprestimo set valor_emprestimo = valor_emprestimo - _parcela.valor_parcela where cod_emprestimo = _cod_emprestimo;
				delete from parcela where cod_parcela = _parcela.cod_parcela;
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
	for parcelita in (select * from parcela where codigo_emprestimo = cod_emprestimo) loop
		if parcelita.data_pagamento_parcela < current_date then
			select current_date - parcelita.data_pagamento_parcela into cast(dias_atrasada);
			update parcela set valor_parcela = valor_parcela * (1 +(0.01 * dias_atrasada)), data_pagamento_parcela = current_date;
		end if;
	end loop;
end $$ language plpgsql;

drop function atualiza_emprestimo(codigo_emprestimo int);


---Testes

insert into cliente values ('123.123.123-45', 'Micael');
insert into agencia values (default, 'Codó');
insert into tipo_conta values (default, 'Corrente', 1, 1);
insert into conta values (default, '123.123.123-45', 123, default, 1, 1, 10);
insert into tipo_movimentacao values (default, 'Saque');
insert into tipo_movimentacao values (default, 'Deposito');
insert into tipo_movimentacao values (default, 'Transferencia');

insert into funcionario values (default, 'Daniel', 1);

insert into tipo_emprestimo values (default, 'Consiguinado', 8, 30);

insert into parcela values (default,  current_date - 10,  30, 1);

select depositar(4000, 1);
select sacar(10,'ABCDEF',123);
select fazer_emprestimo(500, 1, 123, 'Consiguinado', 5);
select pagar_emprestimo(1, 123);

delete from conta where numero_conta = numero_conta;
delete from cliente where cpf = cpf;
delete from emprestimo where cod_emprestimo = cod_emprestimo;
delete from parcela where cod_parcela = cod_parcela;
delete from movimentacao where cod_movimentacao = cod_movimentacao;
delete from partes_movimentacao where cod_partes_movimentacao = cod_partes_movimentacao;
delete from agencia where cod_agencia = cod_agencia;
delete from funcionario where cod_funcionario = cod_funcionario;


select * from agencia;
select * from cliente;
select * from tipo_conta;
select * from conta;
select * from proprietario;
select * from tipo_movimentacao;
select * from movimentacao;
select * from partes_movimentacao;
select * from tipo_emprestimo;
select * from emprestimo;
select * from parcela;
select * from funcionario;

drop table agencia cascade ;
drop table cliente cascade ;
drop table tipo_conta cascade ;
drop table conta cascade ;
drop table proprietario cascade ;
drop table tipo_movimentacao cascade ;
drop table movimentacao cascade ;
drop table partes_movimentacao cascade ;
drop table tipo_emprestimo cascade ;
drop table emprestimo cascade ;
drop table parcela cascade ;
drop table funcionario cascade ;

