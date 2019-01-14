create or replace function controle_conta() 
returns trigger as $$
begin 
	if tg_op == 'INSERT':
		
	
end $$ language plpgsql;

CREATE TRIGGER controle_conta_trigger BEFORE INSERT OR UPDATE OR DELETE ON conta FOR EACH ROW EXECUTE PROCEDURE controle_conta()