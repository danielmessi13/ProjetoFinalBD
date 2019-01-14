create or replace function sacar(valor int, letras_conta varchar(6), senha_conta int) 
returns void as $$
declare
	_conta record;
	_cod_tipo_movimentacao int;
begin 
	if exists(select * from conta where letras ilike letras_conta and senha = senha_conta) then
		select cod_tipo_movimentacao from tipo_movimentacao into _cod_tipo_movimentacao 
		where descricao_tipo_movimentacao ilike 'Saque';
		
		select * from conta into _conta where letras ilike letras_conta and senha = senha_conta;
		if valor <= 0 then
			raise exception 'Você não pode sacar valores negativos ou nulos';
		elsif _conta.saldo - valor < 0 then
			raise exception 'Você não tem saldo suficiente pra sacar essa quantidade';
		else
			update conta set saldo = saldo - valor where letras ilike letras_conta and senha = senha_conta;
			insert into movimentacao values(
			_conta.senha,
			_conta.letras,
			_cod_tipo_movimentacao,
			default,
			valor);
			
		end if;
	else
		raise exception 'Senha ou Letras incorreta';
	end if;

end $$ language plpgsql;


create or replace function depositar(valor int, letras_conta varchar(6), senha_conta int) 
returns void as $$
declare
	_conta record;
	_cod_tipo_movimentacao int;
begin 
	if exists(select * from conta where letras ilike letras_conta and senha = senha_conta) then
		select cod_tipo_movimentacao from tipo_movimentacao into _cod_tipo_movimentacao 
		where descricao_tipo_movimentacao ilike 'Deposito';

		select * from conta into _conta where letras ilike letras_conta and senha = senha_conta;
		
		if valor <= 0 then
			raise exception 'Você não pode depositar valores negativos ou nulos';
		else
			update conta set saldo = saldo + valor where letras ilike letras_conta and senha = senha_conta;

			insert into movimentacao values(
			_conta.senha,
			_conta.letras,
			_cod_tipo_movimentacao,
			default,
			valor);
		end if;
	else
		raise exception 'Senha ou Letras incorreta';
	end if;

end $$ language plpgsql;



---Testes

select depositar(10,'ABCDEF',123)
select sacar(10,'ABCDEF',123)