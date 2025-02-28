import psycopg2
import random
import numpy as np
from datetime import datetime, timedelta

# Dados de conexão com o banco de dados
DB_HOST = "localhost"
DB_NAME = "hotel"
DB_USER = "postgres"
DB_PASSWORD = "postgres"

produtos = []

def criar_locacao(cur, id_quarto, preco_quarto, id_usuario, data_inicio, data_fim):
    """Cria uma locação e retorna o ID da locação criada."""
    
    print(f"Criando locação para o quarto {id_quarto} e usuário {id_usuario} de {data_inicio} a {data_fim}...")

    # se checkin for for maior que hoje só cria dez por cento das locações
    if data_inicio > datetime.now() and random.randint(1, 10) != 1:
        return
    
    # o checkin é às 14:00 e o checkout é às 12:00
    data_inicio = datetime(data_inicio.year, data_inicio.month, data_inicio.day, 14, 0, 0)
    data_fim = datetime(data_fim.year, data_fim.month, data_fim.day, 12, 0, 0)

    cur.execute("""
        INSERT INTO locacao (id_usuario, id_quarto, preco, check_in, check_out, senha)
        VALUES (%s, %s, %s, %s, %s, '1234')
        RETURNING id
    """, (id_usuario, id_quarto, preco_quarto, data_inicio, data_fim))
    id_locacao = cur.fetchone()[0]
    return id_locacao


def criar_consumo(cur, id_locacao, data_inicio, data_fim):
    """Cria no máximo três consumos únicos por dia para a locação."""
    
    # uma em cada três não tem consumo
    if random.randint(1, 3) == 1:
        return
    
    # se a data de inicio for maior que hoje retorna
    if data_inicio > datetime.today():
        return
    
    print(f"Criando consumos para a locação {id_locacao} de {data_inicio} a {data_fim}...")

    duracao_locacao = (data_fim - data_inicio).days + 1

    for dia in range(duracao_locacao):
        data_dia = data_inicio + timedelta(days=dia)
        data_dia_fim = data_dia + timedelta(days=1)

        # Define o número de consumos para o dia (máximo 3)
        max = int(np.ceil(np.random.power(0.5) * 3))
        num_consumos = min(random.randint(0, max), len(produtos))  # Garante no máximo 3

        if num_consumos > 0:
            # Escolhe produtos aleatórios **e únicos** para o dia
            produtos_escolhidos = random.sample(produtos, num_consumos)

            for id_produto, preco_produto in produtos_escolhidos:
                # Gera timestamp aleatória dentro do dia
                timestamp_consumo = data_dia + timedelta(seconds=random.randint(0, int((data_dia_fim - data_dia).total_seconds())))

                # Gera quantidade aleatória entre 1 e 5
                quantidade = random.randint(1, 5)

                cur.execute("""
                    INSERT INTO consumo (id_locacao, id_produto, quantidade, preco, data)
                    VALUES (%s, %s, %s, %s, %s)
                """, (id_locacao, id_produto, quantidade, preco_produto, timestamp_consumo))

try:
    # Conecta-se ao banco de dados
    conn = psycopg2.connect(host=DB_HOST, database=DB_NAME, user=DB_USER, password=DB_PASSWORD)
    cur = conn.cursor()

    # Busca todos os produtos
    cur.execute("SELECT id, preco FROM produto")
    produtos = cur.fetchall()

    # Busca todos os quartos
    cur.execute("SELECT id, preco FROM quarto")
    quartos = cur.fetchall()

    # Busca todos os usuários
    cur.execute("SELECT id FROM usuario")
    usuarios = cur.fetchall()
    ids_usuarios = [usuario[0] for usuario in usuarios] # Cria uma lista com os IDs dos usuários

    data_inicio_periodo = datetime(2024, 1, 1)
    data_fim_periodo = datetime(2025, 6, 30)

    # Para cada quarto, cria 50 locações
    for quarto in quartos:
        id_quarto = quarto[0]        
        preco_quarto = quarto[1]
        data_checkin = data_inicio_periodo

        for _ in range(50):
            # Escolhe um usuário aleatório
            id_usuario = random.choice(ids_usuarios)

            # Calcula data de check-out (1 a 10 dias após o check-in)
            duracao = int(np.ceil(np.random.power(0.5) * 10))
            data_checkout = data_checkin + timedelta(days=duracao)            

            # Cria a locação
            id_locacao = criar_locacao(cur, id_quarto, preco_quarto, id_usuario, data_checkin, data_checkout)

            # se a data do checkin for menor que hoje
            if data_checkin < datetime.now():
                
                # Cria o consumo (usando o ID da locação)
                criar_consumo(cur, id_locacao, data_checkin, data_checkout)

            # Calcula o próximo check-in (0 a 10 dias após o check-out)
            intervalo = random.randint(0, 10)
            data_checkin = data_checkout + timedelta(days=intervalo)

            # Garante que a data de check-in não ultrapasse o período definido
            if data_checkin > data_fim_periodo:
                data_checkin = data_inicio_periodo # Volta para o início do período se ultrapassar

    # Salva as alterações
    conn.commit()
    print("Locações e consumos criados com sucesso!")

except (Exception, psycopg2.Error) as error:
    print(f"Erro ao criar locações e consumos: {error}")

finally:
    if conn:
        cur.close()
        conn.close()
        print("Conexão com o banco de dados encerrada.")