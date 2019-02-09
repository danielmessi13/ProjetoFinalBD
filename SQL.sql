﻿create table agencia
(
  cod_agencia       serial not null primary key,
  descricao_agencia text not null
);


create table cliente
(
  cpf          varchar(14) not null primary key,
  nome_cliente varchar(30) not null
);


create table proprietario
(
  cpf    varchar(14) not null references cliente (cpf),
  senha  int not null,
  letras varchar(6) not null,
  foreign key (senha, letras) references conta (senha, letras)
);

select * from proprietario


create table conta
(
  senha             int,
  letras            varchar(6),
  limite_emprestimo float default 500,
  cod_tipo_conta    int not null references tipo_conta (cod_tipo_conta),
  cod_agencia       int not null references agencia (cod_agencia),
  saldo             int not null,
  primary key (senha, letras)
);


create table tipo_conta
(
  cod_tipo_conta  serial      not null primary key,
  descricao_conta varchar(40) not null
);

insert into agencia
values (default)
insert into conta
values (123, 'ABCDEF', default, 1, 1, 200)
select *
from conta
select *
from movimentacao
select *
from tipo_movimentacao INSERT INTO TIPO_CONTA
VALUES (1,
        'poupança')
insert into tipo_movimentacao
values (default, 'saque')
insert into tipo_movimentacao
values (default, 'deposito')


-- acho que ta errado
create table transferencia_movimentacao
(
  senha_conta_tranferida  int,
  letras_conta_tranferida varchar(6),
  cod_movimentacao        int not null references movimentacao (cod_movimentacao),
  foreign key (senha_conta, letras_conta) references conta (senha, letras)
)

create table movimentacao
(
  cod_movimentacao      serial not null primary key,
  senha_conta           int,
  letras_conta          varchar(6),
  cod_tipo_movimentacao int    not null references tipo_movimentacao (cod_tipo_movimentacao),
  data                  timestamp default current_timestamp,
  foreign key (senha_conta, letras_conta) references conta (senha, letras),
  valor                 float  not null
);



create table tipo_movimentacao
(
  cod_tipo_movimentacao       serial      not null primary key,
  descricao_tipo_movimentacao varchar(40) not null
);


create table emprestimo
(
  cod_emprestimo      serial not null primary key,
  valor_emprestimo    float  not null,
  senha_conta         int,
  letras_conta        varchar(6),
  cod_tipo_emprestimo int    not null references tipo_emprestimo (cod_tipo_emprestimo),
  foreign key (senha_conta, letras_conta) references conta (senha, letras)
)


create table tipo_emprestimo
(
  cod_tipo_emprestimo       serial      not null primary key,
  descricao_tipo_emprestimo varchar(30) not null,
  taxa                      float       not null
);

select *
from emprestimo

create table parcela
(
  cod_parcela            serial    not null primary key,
  data_pagamento_parcela timestamp not null,
  valor_parcela          float     not null,
  cod_emprestimo         int       not null references emprestimo (cod_emprestimo)
);



create table funcionario
(
  cod_funcionario  serial      not null primary key,
  nome_funcionario varchar(40) not null,
  cod_agencia      int         not null references agencia (cod_agencia)
);


--- Triggers


