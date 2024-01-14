# Balanceamento entre clientes e Customer Success (CSs)
-------------------------------------------------------------------
# Preparação para execução:

## Instalar a gem minitest:
     gem install minitest

## Como rodar os testes
  No terminal, execute os comandos:
  ```
  cd ruby
  ruby customer_success_balancing.rb
  ```
-------------------------------------------------------------------
# Regras Atendidas:

  ## Validação para os Gerente(CS):   
     0 < qtd cs < 1.000               &&    0 < id do cs < 1.000              &&      0 < nível do cs < 10.000
     
  ## Validação para os Cliente:   
    0 < qtd clientes < 1.000.000      &&    0 < id do cliente < 1.000.000     &&      0 < tamanho do cliente < 100.000

  ## Quantidade Máxima de CS ausentes
    qtd clientes /2
-------------------------------------------------------------------
# Observações:

## Inicialização
 ### Para cada validação da regra, foi adicionado as variaveis para receber os possíveis erros encontrados durante a validação
    @errors_customer_success = []
    @errors_customer = []
    @errors_away_customer_success =  [] 


-------------------------------------------------------------------
## Execução
 ### Retornos
 #### 0  => Empate 
  Caso a maior quantidade de clientes atendidas seja por mais de 1 gerente.
 #### -1 => Falha 
  Caso durante a validação tenha sido identificado alguma inconsistência, as variaveis @errors_customer_success, @errors_customer, @errors_away_customer_success, irão ser exibidas em telas, para que o usuário possa validar o motivo da falha.
 #### Outros valores 
  Corresponde ao Id do CS que atende o maior numero de cliente

