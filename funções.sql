
create or replace function criar_conta (nome varchar(30), cpf varchar(14), senha_da_conta int, descricao_do_tipo_conta varchar(40), nome_da_agencia text, nome_do_funcionario varchar(40))
returns void as $$
  declare
    _agencia record;
    _cod_tipo_conta int;
    _funcionario record;
  begin
		if exists(select * from funcionario where nome_funcionario = nome_do_funcionario) then
			select * into _funcionario from funcionario where nome_funcionario =  nome_do_funcionario;
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
      perform insert_generico('cliente', ''''
                                        || cpf
                                        || ''', '''
                                        || nome
                                        || '''');
			perform insert_generico('conta', 'default,'''
			                                || cpf
			                                || ''','
			                                || senha_da_conta
			                                || ',default,'
			                                || _cod_tipo_conta
			                                || ','
			                                || _agencia.cod_agencia
			                                || ',default');
		ELSE
		  RAISE exception 'funcionario não altorizado';
		end if;


	end;
$$ language plpgsql;


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
			perform insert_generico('partes_movimentacao', 'default, '
			                                                 || _cod_movimentacao
			                                                 || ','
			                                                 || _conta.numero_conta
			                                                 || ','
			                                                 || valor);
		end if;
	else
		raise exception 'Numero da conta ou senha incorreta';
	end if;

end $$ language plpgsql;


create or replace function sacar(valor int, numero_da_conta int, senha_da_conta int)
returns void as $$
declare
	_conta record;
	_cod_tipo_movimentacao int;
  _cod_movimentacao int;
begin 
	if exists(select * from conta where numero_conta = numero_da_conta and senha = senha_da_conta) then
	  select cod_tipo_movimentacao into _cod_tipo_movimentacao from tipo_movimentacao where descricao_tipo_movimentacao ilike 'Saque';
		select * into _conta from conta natural join tipo_conta where numero_conta = numero_da_conta and senha = senha_da_conta;
		if (select count(*) from partes_movimentacao natural join movimentacao where cod_tipo_movimentacao = _cod_tipo_movimentacao and numero_conta = numero_da_conta and data = current_date) < _conta.limite_de_saque then
			if valor <= 0 then
				raise exception 'Você não pode sacar valores negativos ou nulos';
			elsif _conta.saldo - valor < 0 then
				raise exception 'Você não tem saldo suficiente pra sacar essa quantidade';
			else
				update conta set saldo = saldo - valor where numero_conta = numero_da_conta and senha = senha_da_conta;
				insert into movimentacao values(default,
																				_cod_tipo_movimentacao,
																				default) returning cod_movimentacao into _cod_movimentacao;

				perform insert_generico('partes_movimentacao', 'default,'
				                                                 || _cod_movimentacao
				                                                 || ','
				                                                 || _conta.numero_conta
				                                                 || ','
				                                                 || valor);

			end if;
		else
		  raise exception 'numero maximo de saques exedido';
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
		select cod_tipo_movimentacao into _cod_tipo_movimentacao from tipo_movimentacao where descricao_tipo_movimentacao = 'Transferencia';

		if valor <= 0 then
				raise exception 'Você não pode transferir valores negativos ou nulos';
		elsif _conta_caridosa.saldo - valor < 0 then
				raise exception 'Você não tem saldo suficiente pra transferir essa quantidade';
		end if;

		update conta set saldo = saldo + valor where numero_conta = numero_conta_sortuda;
		update conta set saldo = saldo - valor where numero_conta = numero_conta_caridosa;

		insert into movimentacao values (default, _cod_tipo_movimentacao, default) returning cod_movimentacao into _cod_movimentacao;
		perform insert_generico('partes_movimentacao', 'default,'
				                                                 || _cod_movimentacao
				                                                 || ','
				                                                 || _conta_caridosa.numero_conta
				                                                 || ','
				                                                 || valor * -1);
		perform insert_generico('partes_movimentacao', 'default,'
																														 || _cod_movimentacao
																														 || ','
																														 || _cod_conta_sortuda
																														 || ','
																														 || valor);

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


create or replace function pagar_emprestimo(numero_da_conta int, senha_da_conta int, nome_func varchar(40) default '')
returns void as $$
  declare
    _conta record;
    _funcionario record;
    _cod_emprestimo int;
    _parcela record;
  begin
    if exists(select * from conta where numero_conta = numero_da_conta and senha = senha_da_conta) then

			select * into _conta from conta where numero_conta = numero_da_conta;
			select cod_emprestimo into _cod_emprestimo from emprestimo where numero_conta = numero_da_conta and data = (select min(data) from emprestimo where numero_conta = numero_da_conta);
			select * into _parcela from parcela where codigo_emprestimo = _cod_emprestimo and data_pagamento_parcela = (select min(data_pagamento_parcela) from parcela where codigo_emprestimo = _cod_emprestimo);

      if _parcela.data_pagamento_parcela < current_date then
        raise notice 'Parcela atrasada';
        if nome_func = '' then
          raise exception 'Parcelas atrasadas precisam ser pagas junto com o funcionario';
        else
          if exists(select * from funcionario where nome_funcionario = nome_func) then
            select * into _funcionario from funcionario where nome_funcionario = nome_func;
            if _conta.cod_agencia != _funcionario.cod_agencia then
              raise exception 'Funcionario precisa ser da mesma agencia';
            end if;
						perform atualiza_emprestimo(_cod_emprestimo);
						select * into _parcela from parcela where cod_parcela = _parcela.cod_parcela;

          else
            raise exception 'Funcionario não existe';
          end if;

        end if;
      end if;

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

select extract(days from (current_date - current_date));
select current_date::date - '2019-02-10'::date;

create or replace function atualiza_emprestimo(cod_emprestimo int)
	returns void as $$
declare
	parcelita record;
	dias_atrasada int;
begin
	for parcelita in (select * from parcela where codigo_emprestimo = cod_emprestimo) loop
		if parcelita.data_pagamento_parcela < current_date then
			select current_date::date - parcelita.data_pagamento_parcela::date into dias_atrasada;
			update parcela set valor_parcela = (valor_parcela * ((0.01 * dias_atrasada) + 1)), data_pagamento_parcela = current_date where cod_parcela = parcelita.cod_parcela;
		end if;
	end loop;
end $$ language plpgsql;


create or replace function extrato(codigo_conta int, senha_da_conta int)
returns table (descricao varchar(30), valor float) as $$
  begin
		if exists(select * from conta where numero_conta = codigo_conta and senha = senha_da_conta) then
			if exists(select * from partes_movimentacao natural join movimentacao natural join tipo_movimentacao where numero_conta = codigo_conta) then
				return query select descricao_tipo_movimentacao, partes_movimentacao.valor from partes_movimentacao natural join movimentacao natural join tipo_movimentacao where numero_conta = codigo_conta;

			else
			  raise exception 'Não há transações';
			end if;

		else
		  raise exception 'Senha ou conta incorreta';
		end if;
	end $$ language plpgsql;

drop function extrato(codigo_conta int, senha_da_conta int);

---Testes
select extrato(7,123);
-- cpf, nome
insert into cliente values ('123.123.123-45', 'Micael');
-- cod, nome
insert into agencia values (default, 'Codó');
-- cod, nome, limite saque, porcentagem
insert into tipo_conta values (default, 'Corrente', 1, 1);
-- cod, cpf, senha, saldo, limite emprestimo*, tipo conta, agencia, saldo*
insert into conta values (default, '123.123.123-45', 123, default, 1, 1, 10);
-- cod, descrição
insert into tipo_movimentacao values (default, 'Saque');
insert into tipo_movimentacao values (default, 'Deposito');
insert into tipo_movimentacao values (default, 'Transferencia');
-- cod, nome, agencia
insert into funcionario values (default, 'Daniel', 1);
-- cod, descrição, limite parcela, taxa
insert into tipo_emprestimo values (default, 'Consiguinado', 8, 30);
-- cod, data de pagamento, valor, emprestimo1
insert into parcela values (default,  current_date - 10,  50, 1);


select * from conta
select * from movimentacao
select * from partes_movimentacao

-- valor, numero da conta
select depositar(4000, 7);
select * from conta;
-- valor, numero da conta, senha
select sacar(4000,7,123);
select * from conta;
-- nome, cpf, senha, tipo da conta, agencia, funcionario
select criar_conta('Filipe', '066.018.183-56', 123, 'Corrente', 'teste', 'Daniel');
select * from conta;
-- numero_conta1 , senha_conta1, numero_conta2, valor
select transferir(7,123,8,5);
select * from conta;

-- valor do emprestimo, numero conta, senha, tipo emprestimo, quant parcela
select fazer_emprestimo(500, 8, 123, 'Consiguinado', 5);
select * from conta
select * from emprestimo
select * from parcela

select pagar_emprestimo(8, 123, 'Daniel');

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

