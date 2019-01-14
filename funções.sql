create or replace function sacar(valor int, letras_conta varchar(6), senha_conta int) 
returns void as $$
declare
	_saldo float;
begin 
	if exists(select * from conta where letras ilike letras_conta and senha = senha_conta) then
		_saldo := (select saldo from conta where letras ilike letras_conta and senha = senha_conta);
		if valor <= 0 or _saldo - valor < 0 then
			raise exception 'Você não pode sacar valores negativos ou nulos';
		else
			update conta set saldo = saldo - valor where letras ilike letras_conta and senha = senha_conta;
		end if;
	end if;

end $$ language plpgsql;