create table agencia(
cod_agencia serial not null primary key
)

create table cliente(
cpf varchar(16) not null primary key,
nome_cliente varchar(30) not null
);


create table proprietario(
cod_cliente int not null references cliente(cod_cliente),
senha int not null references conta(senha),
letras int not null references conta(letras)
);


create table conta(
senha int,
letras varchar(6),
limite_emprestimo float default 500,
cod_tipo_conta int not null references tipo_conta(cod_tipo_conta),
cod_agencia int not null references agencia(cod_agencia),
saldo int not null,
primary key (senha,letras)
);


create table tipo_conta(
cod_tipo_conta serial not null primary key,
descricao_conta varchar(40) not null
);

insert into agencia values(default)
insert into conta values (123,'ABCDEF',default,1,1,200)
select * from conta
select * from movimentacao
select * from tipo_movimentacao
INSERT INTO TIPO_CONTA VALUES (1,'poupança')
insert into tipo_movimentacao values (default,'saque')
insert into tipo_movimentacao values (default,'deposito')




create table movimentacao(
senha_conta int, 
letras_conta varchar(6), 
cod_tipo_movimentacao int not null references tipo_movimentacao(cod_tipo_movimentacao), 
data timestamp default current_timestamp,
foreign key (senha_conta, letras_conta) references conta(senha,letras),
valor float not null
);

drop table movimentacao


create table tipo_movimentacao(
cod_tipo_movimentacao serial not null primary key,
descricao_tipo_movimentacao varchar(40) not null
);


create table emprestimo(
cod_emprestimo serial not null primary key,
valor float not null,
cod_tipo_emprestimo int not null references tipo_emprestimo(cod_tipo_emprestimo)
)


create table tipo_emprestimo(
cod_tipo_emprestimo serial not null primary key,
descricao_tipo_emprestimo varchar(30) not null,
taxa float not null
); 


create table funcionario(
cod_funcionario serial not null primary key,
nome_funcionario varchar(40) not null,
cod_agencia int not null references agencia(cod_agencia)
);


--- Triggers 
create or replace function fazer_emprestimo(int senha_conta, int agencia_cod) returns int as $$
begin
	if exists(select * from conta where conta.senha = senha_conta and cod_agencia = agencia_cod) then:

	else
		


