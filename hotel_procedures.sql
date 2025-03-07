----------------------------------------------------
-- FUNÇÃO LOCACOES_DIA (DIA DATE)
-- retorna as locações em andamento na data informada
-- se informar NULL retorna do dia de hoje
----------------------------------------------------

create or replace function locacoes_dia (dia date)
returns table(
	id bigint,
	check_in timestamp,
	check_out timestamp,
	id_quarto bigint,
	id_usuario bigint
) as $$
begin
	if dia is null then
		dia := current_date;
	end if;
	return query
	select l.id,l.check_in,l.check_out,l.id_quarto,l.id_usuario 
	from locacao l 
	where ((l.check_in < dia and l.check_out > dia+1));
end;
$$ language plpgsql;


----------------------------------------------------
-- FUNÇÃO IMPORTAR_CONSUMO(ARQ_CSV TEXT)
-- insere consumos a partir de um arquivo CSV
----------------------------------------------------

create or replace procedure importar_consumo(arq_csv text)
language plpgsql as $$

declare 
	coisa record;
	preco double precision;
	novo_id bigint;
begin
	
	-- importar o csv pra dentro de uma tabela temporaria
	create temp table seesseve(
	id_locacao bigint, id_produto bigint, quantidade int 
	);
	EXECUTE format(
		'COPY seesseve(id_locacao, id_produto, quantidade)
		FROM %L WITH (FORMAT csv, HEADER false, DELIMITER E''\t'', ENCODING ''UTF8'')',
		arq_csv
	);	
	-- interar o csv e verificar cada registro e fazer o log

	for coisa in select * from seesseve loop
		--------------------------------- DEBUG
		raise notice 'locacao: %, produto: %, quant: %', coisa.id_locacao, coisa.id_produto, coisa.quantidade;
		--------------------------------- DEBUG
		
		-- descobre o preço do produto
		select p.preco from produto p where p.id = coisa.id_produto
		into preco;
		-- não vou verificar se a locação existe pq tô com preguiça
		-- agora cria o consumo
		-- (eu poderia ter feito um select com um join mas quis mostrar o select into acima) 
		insert into consumo(data, id_locacao, id_produto, preco, quantidade) values
		(current_timestamp, coisa.id_locacao, coisa.id_produto, preco, coisa.quantidade)
		returning id into novo_id;
		
		--------------------------------- DEBUG
		raise notice 'novo consumo: %', novo_id;
		--------------------------------- DEBUG
		
	end loop;

end;
$$;