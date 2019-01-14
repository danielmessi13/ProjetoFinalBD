create table agencia(
cod_agencia serial not null primary key,
)

create table cliente(
cpf varchar(16) not null primary key,
nome_cliente varchar(30) not null
);


create table proprietario(
cod_cliente int not null references cliente(cod_cliente),
cod_conta int not null references conta(cod_conta)
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


create table movimentacao(
cod_conta_principal int not null references conta(cod_conta), 
data timestamp default current_timestamp,
valor float not null
);


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
		


