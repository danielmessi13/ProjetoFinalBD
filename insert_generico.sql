CREATE OR REPLACE FUNCTION toStr(col anyelement)
  RETURNS character varying 
AS $$
begin 
	if pg_typeof(col) = 'character varying'::regtype then
		col:= character varying);
	else if pg_typeof(col) = 'numeric'::regtype then
		 to_char(col::numeric, '999');
	else 'Unsupported type';
	end if;
end;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION toStr(anyelement) RETURNS regtype AS $$
begin 
	if pg_typeof($1) = 'unknown' then
		return integer;
	end if;
	return pg_typeof($1);
end;
$$
LANGUAGE plpgsql;

drop function toStr(anyelement)

select toStr('A');

SELECT pg_typeof('filipe');

create or replace function teste_insert(varchar(30)='null'
,varchar(30)='null',varchar(30)='null'
,varchar(30)='null',varchar(30)='null') 
returns varchar(30) as $$
begin 
	
end $$ language plpgsql;