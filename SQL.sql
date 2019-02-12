create table agencia
(
  cod_agencia       serial not null primary key,
  descricao_agencia text not null
);

create table cliente
(
  cpf          varchar(14) not null primary key,
  nome_cliente varchar(30) not null
);

create table tipo_conta
(
  cod_tipo_conta  serial      not null primary key,
  descricao_conta varchar(40) not null,
  limite_de_saque int not null,
  porcetagem      int not null
);

create table conta
(
  numero_conta 		  serial not null primary key,
  dono              varchar(14) not null references cliente(cpf),
  senha             int not null ,
  limite_emprestimo float default 500,
  cod_tipo_conta    int not null references tipo_conta (cod_tipo_conta),
  cod_agencia       int not null references agencia (cod_agencia),
  saldo             float default 0
);


create table proprietario
(
cpf    varchar(14) not null references cliente (cpf),
numero_conta int not null references conta (numero_conta)
);



create table tipo_movimentacao
(
  cod_tipo_movimentacao       serial      not null primary key,
  descricao_tipo_movimentacao varchar(40) not null
);

--acho q tem q ser assim
create table movimentacao
(
cod_movimentacao      serial not null primary key,
cod_tipo_movimentacao int    not null references tipo_movimentacao (cod_tipo_movimentacao),
data                  timestamp default current_timestamp
);

create table partes_movimentacao --precisa de um nome melhor
(
cod_partes_movimentacao serial not null primary key,
cod_movimentacao 		    int not null references movimentacao (cod_movimentacao),
numero_conta 			      int not null references conta (numero_conta),
valor                 	float  not null
);--bom, parando pra pensar acho q ta errado tbm


create table tipo_emprestimo
(
  cod_tipo_emprestimo       serial      not null primary key,
  descricao_tipo_emprestimo varchar(30) not null,
  numero_maximo_parcelas 	  int not null,
  taxa                      float       not null
);


create table emprestimo
(
cod_emprestimo      serial not null primary key,
valor_emprestimo    float  not null,
numero_conta 		    int not null references conta (numero_conta),
cod_tipo_emprestimo int    not null references tipo_emprestimo (cod_tipo_emprestimo),
data                timestamp default current_timestamp

);


create table parcela
(
  cod_parcela            serial    not null primary key,
  data_pagamento_parcela timestamp not null,
  valor_parcela          float     not null,
  codigo_emprestimo         int       not null references emprestimo (cod_emprestimo)
);



create table funcionario
(
  cod_funcionario  serial      not null primary key,
  nome_funcionario varchar(40) not null,
  cod_agencia      int         not null references agencia (cod_agencia)
);

