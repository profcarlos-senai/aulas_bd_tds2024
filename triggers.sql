--  cria hora_alterado em usuario
alter table usuario add hora_alterado timestamp default current_timestamp;

-- cria o trigger
CREATE OR REPLACE FUNCTION func_hora_alterado()
RETURNS TRIGGER AS $$
BEGIN
    NEW.hora_alterado = current_timestamp;
    RETURN NEW;
END;
$$ language 'plpgsql';
                      
------------------------------------------------------------------------------------
-- EXERCICIO 1
------------------------------------------------------------------------------------
-- adicione hora_atualizado em quarto
-- adicione o trigger before update em quarto
-- apontando para a mesma função
-- altere um único quarto e veja se botou a hora

------------------------------------------------------------------------------------
-- EXERCICIO 2 (pra fazer juntos)
------------------------------------------------------------------------------------
- crie total_consumo decimal(10,2) em locacao
alter table locacao add total_consumo numeric(10,2);

- faça um update que jogue a soma de consumo.valor em locacao.total_consumo
update locacao L 
	set total_consumo = (
		select sum(c.preco*c.quantidade) 
		from consumo c 
		where c.id_locacao=l.id);

- vamos escrever uma função que atualiza o total_consumo toda vez que altera consumo
CREATE OR REPLACE FUNCTION func_atu_total_consumo()
RETURNS TRIGGER AS $$
BEGIN
	if TG_OP = 'INSERT' THEN
	    update locacao 
		set total_consumo = COALESCE(total_consumo, 0) + (NEW.preco*NEW.quantidade);
	elsif TG_OP = 'UPDATE' THEN
	    update locacao 
		set total_consumo = COALESCE(total_consumo, 0) 
		  - (OLD.preco*old.quantidade) 
		  + (NEW.preco*NEW.quantidade);
	elsif TG_OP = 'DELETE' THEN
	    update locacao 
		set total_consumo = COALESCE(total_consumo, 0) - (OLD.preco*OLD.quantidade);
	end if;
	RETURN NEW;
END;
$$ language 'plpgsql';

- escrever os triggers update, insert e delete de consumo pra atualizar locacao.total_consumo

CREATE OR REPLACE TRIGGER consumo_ins_atu_total
    AFTER INSERT ON consumo
    FOR EACH ROW EXECUTE FUNCTION func_atu_total_consumo();
CREATE OR REPLACE TRIGGER consumo_atu_atu_total
    AFTER UPDATE ON consumo
    FOR EACH ROW EXECUTE FUNCTION func_atu_total_consumo();
CREATE OR REPLACE TRIGGER consumo_del_atu_total
    AFTER DELETE ON consumo
    FOR EACH ROW EXECUTE FUNCTION func_atu_total_consumo();

-- vamos testar se a inclusão funciona. a locação 2400 não tem consumos

insert into consumo(data, preco, quantidade, id_locacao, id_produto)
values(now(), 6, 1, 1934, 1);

select total_consumo from locacao where id=1934;

-- agora o update

update consumo set quantidade=quantidade*2 where id_locacao=1934;
select total_consumo from locacao where id=1934;

-- e finalmente o delete

delete from consumo where id_locacao=1934;
select total_consumo from locacao where id=1934;
