require 'minitest/autorun'
require 'timeout'

class CustomerSuccessBalancing
  def initialize(customer_success, customers, away_customer_success)
    @customer_success = customer_success # CSs _> são os Gerentes de Sucesso
    @customers = customers
    @away_customer_success = away_customer_success

    @errors_customer_success = []
    @errors_customer = []
    @errors_away_customer_success =  [] 
  end

  def execute
    if can_execute?
      validate_customer_success_with_most_customers
    else
      -1
    end
  rescue Timeout::Error
    'TIMEOUT'
  end

  def can_execute?
    customer_valid? && customer_success_valid? && away_customer_success_is_valid?
  end

  def return_errors
    (@errors_customer_success + @errors_customer + @errors_away_customer_success ).join(', ')
  end

  private

  def customer_success_valid?
    @errors_customer_success = []

    return add_errors('customer_success', 'Deve existir ao menos 1 CS informado') if @customer_success.empty?
    return add_errors('customer_success', 'Quantidade de CSs informada é inválida') unless customer_success_length_is_valid?
    return add_errors('customer_success', 'IDs dos CSs são inválidos') unless customer_success_ids_is_valid?
    return add_errors('customer_success', 'Nível dos CSs são inválidos') unless customer_success_score_is_valid?
    return add_errors('customer_success', 'Não é permitido ter CSs com níveis idênticos.') if customer_success_score_duplicated?

    true
  end

  def customer_valid?
    @errors_customer = []
    return add_errors('customer', 'Deve existir ao menos 1 cliente informado') if @customers.empty?
    return add_errors('customer', 'Quantidade de clientes informada é inválida') unless  customers_length_is_valid?
    return add_errors('customer', 'IDs dos clientes são inválidos') unless customers_ids_is_valid?
    return add_errors('customer', 'O Tamanho dos clientes é inválido') unless  customer_score_is_valid?

    true
  end

  def away_customer_success_is_valid?
    @errors_away_customer_success = []
    return add_errors('away_customer_success', 'Quantidade de CSs ausentes ultrapassou a quantidade máxima permitida') if @away_customer_success.length > away_customer_success_maximum

    true
  end

  def validate_customer_success_with_most_customers
    count_customers_for_customer_success  =  set_count_customers_for_customer_success
    most_value = count_customers_for_customer_success.values.max
    most_cs = count_customers_for_customer_success.select { |key, value|  value == most_value }

    most_cs.length == 1 && !most_cs.keys.include?(nil) ? most_cs.keys.first : 0
  end

  def set_count_customers_for_customer_success 
    customer_for_cs = {}

    @customers.each do |customer|
      customer_success_id = return_customer_success_of_balance(customer[:score])
      (customer_for_cs.empty? || !customer_for_cs.key?(customer_success_id)) ? customer_for_cs[customer_success_id] = 1 : customer_for_cs[customer_success_id] += 1        
    end

    customer_for_cs
  end

  def customer_sucess_without_away_customer_success
    (@customer_success.reject { |cs| cs.key?(:id) && @away_customer_success.include?(cs[:id]) })
  end

  def return_customer_success_of_balance(score)
     find_customer_success = customer_sucess_without_away_customer_success.select{ |cs_work_today| cs_work_today[:score] >= score }.sort_by { |cs_work| cs_work[:score] }.first 

    (find_customer_success.is_a?(Hash) && find_customer_success.key?(:id)) ? find_customer_success[:id] : nil
  end

  def customer_success_length_is_valid?
    @customer_success.length > 0 && @customer_success.length < 1000
  end
 
  def customer_success_ids_is_valid?
    @customer_success.all? { |cs| cs.key?(:id) && cs[:id] > 0 && cs[:id] < 1000 }
  end

  def customer_success_score_is_valid?
    @customer_success.all? { |cs| cs.key?(:score) && cs[:score] > 0 && cs[:score] < 10000 }
  end

  def customer_success_score_duplicated?
    customer_success_score_duplicated = @customer_success.map { |cs| cs[:score] }

    customer_success_score_duplicated.uniq.length != customer_success_score_duplicated.length 
  end

  def away_customer_success_maximum
    (@customer_success.length / 2).truncate
  end

  def customers_length_is_valid?
    @customers.length > 0 && @customers.length < 1000000
  end

  def customers_ids_is_valid?
    @customers.all? { |customer| customer[:id] > 0 && customer[:id] < 1000000  }
  end

  def customer_score_is_valid?
    @customers.all? { |customer| customer[:score] > 0 && customer[:score] < 100000  }
  end

  def add_errors(type_error , message)
    case type_error
    when 'away_customer_success'
      @errors_away_customer_success.push(message.to_s)
    when 'customer'
      @errors_customer.push(message.to_s)
    else
      @errors_customer_success.push(message.to_s)
    end

    false
  end
end

class CustomerSuccessBalancingTests < Minitest::Test
  def test_scenario_one
    balancer = CustomerSuccessBalancing.new(
      build_scores([60, 20, 95, 75]),
      build_scores([90, 20, 70, 40, 60, 10]),
      [2, 4]
    )
    assert_equal 1, balancer.execute
  end

  def test_scenario_two
    balancer = CustomerSuccessBalancing.new(
      build_scores([11, 21, 31, 3, 4, 5]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      []
    )
    assert_equal 0, balancer.execute
  end

  def test_scenario_three
    balancer = CustomerSuccessBalancing.new(
      build_scores(Array(1..999)),
      build_scores(Array.new(10000, 998)),
      [999]
    )

    result = Timeout.timeout(1.0) { balancer.execute }
    assert_equal 998, result
  end

  def test_scenario_four
    balancer = CustomerSuccessBalancing.new(
      build_scores([1, 2, 3, 4, 5, 6]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      []
    )
    assert_equal 0, balancer.execute
  end

  def test_scenario_five
    balancer = CustomerSuccessBalancing.new(
      build_scores([100, 2, 3, 6, 4, 5]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      []
    )
    assert_equal 1, balancer.execute
  end

  def test_scenario_six
    balancer = CustomerSuccessBalancing.new(
      build_scores([100, 99, 88, 3, 4, 5]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      [1, 3, 2]
    )
    assert_equal 0, balancer.execute
  end

  def test_scenario_seven
    balancer = CustomerSuccessBalancing.new(
      build_scores([100, 99, 88, 3, 4, 5]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      [4, 5, 6]
    )
    assert_equal 3, balancer.execute
  end

  def test_scenario_eight
    balancer = CustomerSuccessBalancing.new(
      build_scores([60, 40, 95, 75]),
      build_scores([90, 70, 20, 40, 60, 10]),
      [2, 4]
    )
    assert_equal 1, balancer.execute
  end

  def test_customers_empty
    balancer = CustomerSuccessBalancing.new(
      build_scores([60, 40, 95, 75]),
      build_scores([]),
      [2, 4]
    )
    assert_equal -1, balancer.execute
    assert_equal 'Deve existir ao menos 1 cliente informado', balancer.return_errors
  end

  def test_customer_success_empty
    balancer = CustomerSuccessBalancing.new(
      build_scores([]),
      build_scores([60, 40, 95, 75]),
      [2, 4]
    )
    assert_equal -1, balancer.execute
    assert_equal 'Deve existir ao menos 1 CS informado', balancer.return_errors
  end

  def test_customer_success_length_invalid
    balancer = CustomerSuccessBalancing.new(
      build_scores(Array(1..1500)),
      build_scores([60, 40, 95, 75]),
      [2, 4]
    )
    assert_equal -1, balancer.execute
    assert_equal 'Quantidade de CSs informada é inválida', balancer.return_errors
  end

  def test_customer_length_invalid
    balancer = CustomerSuccessBalancing.new(
      build_scores([60, 40, 95, 75]),
      build_scores(Array(1..1000000)),
      [2, 4]
    )
    assert_equal -1, balancer.execute
    assert_equal 'Quantidade de clientes informada é inválida', balancer.return_errors
  end

  def test_customer_success_ids_invalid_when_id_eql_zero
    balancer = CustomerSuccessBalancing.new(
      build_scores_ids_with_zero_invalid([11]),
      build_scores([60, 40, 95, 75]),
      []
    )

    assert_equal -1, balancer.execute
    assert_equal 'IDs dos CSs são inválidos', balancer.return_errors
  end


  def test_customer_ids_invalid_when_id_most_limit
    balancer =  CustomerSuccessBalancing.new(
      build_scores_ids_invalid(Array(1..999)),
      build_scores([60, 40, 95, 75]),
      []
    )

    assert_equal -1, balancer.execute
    assert_equal 'IDs dos CSs são inválidos', balancer.return_errors
  end

  def test_customer_ids_invalid_when_id_eql_zero
    balancer = CustomerSuccessBalancing.new(
      build_scores([60, 40, 95, 75]),
      build_scores_ids_with_zero_invalid([11]),
      []
    )

    assert_equal -1, balancer.execute
    assert_equal 'IDs dos clientes são inválidos', balancer.return_errors
  end


  def test_customer_success_ids_invalid_when_id_most_limit
    balancer =  CustomerSuccessBalancing.new(
      build_scores([60, 40, 95, 75]),
      build_scores_ids_invalid(Array(1..999999)),
      []
    )

    assert_equal -1, balancer.execute
    assert_equal 'IDs dos clientes são inválidos', balancer.return_errors
  end

  def test_customer_score_invalid_when_id_eql_zero
    balancer = CustomerSuccessBalancing.new(
      build_scores([75]),
      build_scores([0]),
      []
    )

    assert_equal -1, balancer.execute
    assert_equal 'O Tamanho dos clientes é inválido', balancer.return_errors
  end


  def test_customer_score_invalid_when_id_most_limit
    balancer =  CustomerSuccessBalancing.new(
      build_scores([60]),
      build_scores([100000]),
      []
    )

    assert_equal -1, balancer.execute
    assert_equal 'O Tamanho dos clientes é inválido', balancer.return_errors
  end

  def test_customer_success_score_invalid_when_id_eql_zero
    balancer = CustomerSuccessBalancing.new(
      build_scores([0]),
      build_scores([75]),
      []
    )

    assert_equal -1, balancer.execute
    assert_equal 'Nível dos CSs são inválidos', balancer.return_errors
  end


  def test_customer_success_score_invalid_when_id_most_limit
    balancer =  CustomerSuccessBalancing.new(
      build_scores([10000]),
      build_scores([60]),
      []
    )

    assert_equal -1, balancer.execute
    assert_equal 'Nível dos CSs são inválidos', balancer.return_errors
  end

  def test_customer_success_invalid_for_score_duplicated
    balancer =  CustomerSuccessBalancing.new(
      build_scores([800,800]),
      build_scores([60]),
      []
    )

    assert_equal -1, balancer.execute
    assert_equal 'Não é permitido ter CSs com níveis idênticos.', balancer.return_errors
  end

  def test_away_customer_success_invalid
    balancer =  CustomerSuccessBalancing.new(
      build_scores([9999,500,200]),
      build_scores([60]),
      [1,2]
    )

    assert_equal -1, balancer.execute
    assert_equal 'Quantidade de CSs ausentes ultrapassou a quantidade máxima permitida', balancer.return_errors
  end



  private

  def build_scores(scores)
    scores.map.with_index do |score, index|
      { id: index + 1, score: score }
    end
  end

  def build_scores_ids_invalid(scores)
    scores.map.with_index do |score, index|
      { id: (index+1) * 2, score: score }
    end
  end

  def build_scores_ids_with_zero_invalid(scores)
    scores.map.with_index do |score, index|
      { id: (index) * 2, score: score }
    end
  end
end
