----------------------------------------------------
-- FUNÇÃO GET_QUARTO_VAGO
-- retorna um quarto do tipo TIPO que esteja
-- vago entre as datas DATEIN_REQ e DATEOUT_REQ
----------------------------------------------------

CREATE FUNCTION get_quarto_vago(tipo integer, datein_req date, dateout_req date) RETURNS integer
    LANGUAGE plpgsql
    AS $$
declare 
    -- inclui a hora do checkin e checkout nas datas
    checkin_req timestamp = datein_req + interval '14 hour';
    checkout_req timestamp = dateout_req + interval '12 hour';
	
	-- faz um select dos quartos disponíveis
    cursor_loca cursor for 
        select q.id from quarto q 
        join locacao l on q.id=l.id_quarto
        where NOT((l.check_in < checkout_req and l.check_out > checkin_req))
        and (q.id_tipo = tipo)
        limit 1;
	-- armazena a linha retornada pelo cursor dentro do loop
    registro locacao%rowtype;
begin
	-- vasculha os quartos disponíveis
    for registro in cursor_loca loop
		-- retorna o primeiro que encontrar
        return registro.id;
    end loop;
	-- se não achou nenhum
    return null;
end;
$$;

----------------------------------------------------
-- FUNÇÃO IS_QUARTO_VAGO
-- retorna VERDADEIRO se QUARTO_REQ estiver
-- vago entre as datas DATEIN_REQ e DATEOUT_REQ
----------------------------------------------------

CREATE FUNCTION is_quarto_vago(quarto_req integer, datein_req date, dateout_req date) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
	-- coloca os horarios padrão de checkin e checkout
	declare checkin_req timestamp = datein_req + interval '14 hour';
	declare checkout_req timestamp = dateout_req + interval '12 hour'
	-- quantidade de locações desse quarto no período
	declare quant int;
begin		
	-- descobre se tem locacao nessa data	
	select count(id) from locacao 
	where (check_in < checkin_req and check_out > checkout_req) 
	AND (id_quarto = quarto_req)
	into quant;

	-- registra o que achou pra facilitar o debug
	RAISE NOTICE 'achei % registros etre % e %', quant, checkin_req, checkout_req; 

	-- retorna TRUE se tiver zero locações
	return quant = 0;
end;

$$;