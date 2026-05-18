class Parser
  def initialize(tokens)
    @tokens = tokens
    @current = 0
  end

  def parse
    statements = []
    while !at_end?
      statements << parse_statement
    end
    { type: :program, body: statements }
  end

  private

  def peek
    @tokens[@current]
  end

  def previous
    @tokens[@current - 1]
  end

  def advance
    @current += 1 unless at_end?
    previous
  end

  def at_end?
    @current >= @tokens.length
  end

  def check(type)
    return false if at_end?
    peek[:type] == type
  end

  def match(*types)
    types.each do |type|
      if check(type)
        advance
        return true
      end
    end
    false
  end

  def consume(type, message)
    return advance if check(type)
    tok = peek || previous
    raise "erro (Erro de Sintaxe) em #{tok[:line]}:#{tok[:col]}.\n#{message}"
  end

  def parse_statement
    if match(:VAR)
      parse_var_statement
    elsif match(:DEF)
      parse_def_statement
    elsif match(:RETURN)
      parse_return_statement
    elsif match(:WHILE)
      parse_while_statement
    elsif match(:FOR)
      parse_for_statement
    elsif match(:CONSOLE_PRINT)
      parse_print_statement
    else
      parse_expression_statement
    end
  end

  def parse_var_statement
    name_token = consume(:STRING, "Esperado o nome da variável entre aspas")
    name = name_token[:value]

    if match(:ASSIGN)
      expr = parse_expression
      { type: :var_decl, name: name, value: expr, line: name_token[:line], col: name_token[:col] }
    elsif match(:ASSIGN_ADD)
      expr = parse_expression
      { type: :var_add, name: name, value: expr, line: name_token[:line], col: name_token[:col] }
    elsif match(:ASSIGN_SUB)
      expr = parse_expression
      { type: :var_sub, name: name, value: expr, line: name_token[:line], col: name_token[:col] }
    else
      consume(:ASSIGN, "Esperado '=', '+=' ou '-=' após o nome da variável")
    end
  end

  def parse_def_statement
    name_token = consume(:STRING, "Esperado o nome da função entre aspas")
    name = name_token[:value]

    consume(:LPAREN, "Esperado '(' após o nome da função")
    params = []
    unless check(:RPAREN)
      begin
        params << consume(:IDENTIFIER, "Esperado nome do parâmetro")[:value]
      end while match(:COMMA)
    end
    consume(:RPAREN, "Esperado ')' após os parâmetros")
    consume(:COLON, "Esperado ':' antes do escopo")
    consume(:LBRACE, "Esperado '{' para iniciar o bloco da função")

    body = []
    while !check(:RBRACE) && !at_end?
      body << parse_statement
    end
    consume(:RBRACE, "Esperado '}' para fechar o bloco da função")

    { type: :def_decl, name: name, params: params, body: body, line: name_token[:line], col: name_token[:col] }
  end

  def parse_return_statement
    tok = previous
    expr = check(:RBRACE) ? nil : parse_expression
    { type: :return_stmt, value: expr, line: tok[:line], col: tok[:col] }
  end

  def parse_while_statement
    tok = previous
    condition = parse_expression
    consume(:COLON, "Esperado ':' após a condição do while")
    consume(:LBRACE, "Esperado '{' para iniciar o bloco do while")
    body = []
    while !check(:RBRACE) && !at_end?
      body << parse_statement
    end
    consume(:RBRACE, "Esperado '}' para fechar o bloco do while")
    { type: :while_stmt, condition: condition, body: body, line: tok[:line], col: tok[:col] }
  end

  def parse_for_statement
    tok = previous
    var_token = consume(:STRING, "Esperado nome da variável do loop entre aspas")
    var_name = var_token[:value]

    match(:IN)
    consume(:RANGE, "Esperado comando 'range' no loop for")
    consume(:LPAREN, "Esperado '('")
    range_expr = parse_expression
    consume(:RPAREN, "Esperado ')'")
    consume(:COLON, "Esperado ':'")
    consume(:LBRACE, "Esperado '{'")

    body = []
    while !check(:RBRACE) && !at_end?
      body << parse_statement
    end
    consume(:RBRACE, "Esperado '}'")

    { type: :for_stmt, var_name: var_name, range_expr: range_expr, body: body, line: tok[:line], col: tok[:col] }
  end

  def parse_print_statement
    tok = previous
    consume(:LPAREN, "Esperado '(' após console.print")
    expr = parse_expression
    consume(:RPAREN, "Esperado ')'")
    { type: :print_stmt, argument: expr, line: tok[:line], col: tok[:col] }
  end

  def parse_expression_statement
    expr = parse_expression
    { type: :expr_stmt, expression: expr, line: expr[:line], col: expr[:col] }
  end

  def parse_expression
    parse_comparison
  end

  def parse_comparison
    expr = parse_addition
    if match(:LESS)
      right = parse_addition
      expr = { type: :binary_op, op: :<, left: expr, right: right, line: expr[:line], col: expr[:col] }
    end
    expr
  end

  def parse_addition
    expr = parse_primary
    while match(:PLUS, :MINUS)
      op = previous[:type] == :PLUS ? :+ : :-
      right = parse_primary
      expr = { type: :binary_op, op: op, left: expr, right: right, line: expr[:line], col: expr[:col] }
    end
    expr
  end

  def parse_primary
    if match(:NUMBER)
      { type: :literal, value: previous[:value], line: previous[:line], col: previous[:col] }
    elsif match(:STRING)
      { type: :literal, value: previous[:value], line: previous[:line], col: previous[:col] }
    elsif match(:VAR_REF)
      { type: :var_ref, name: previous[:value], line: previous[:line], col: previous[:col] }
    elsif match(:IDENTIFIER)
      { type: :var_ref, name: previous[:value], line: previous[:line], col: previous[:col] }
    elsif match(:FUNC)
      parse_func_call
    elsif match(:CALC)
      parse_calc_expression
    else
      tok = peek || previous
      raise "erro (Erro de Sintaxe) em #{tok[:line]}:#{tok[:col]}.\nExpressão inválida"
    end
  end

  def parse_func_call
    tok = previous
    name_token = consume(:STRING, "Esperado nome da função entre aspas após 'func'")
    name = name_token[:value]
    consume(:LPAREN, "Esperado '('")
    args = []
    unless check(:RPAREN)
      begin
        args << parse_expression
      end while match(:COMMA)
    end
    consume(:RPAREN, "Esperado ')'")
    { type: :func_call, name: name, arguments: args, line: tok[:line], col: tok[:col] }
  end

  def parse_calc_expression
    tok = previous
    consume(:LPAREN, "Esperado '(' após 'calc'")
    expr = parse_expression
    consume(:RPAREN, "Esperado ')' após a expressão de cálculo")
    { type: :calc_expr, expression: expr, line: tok[:line], col: tok[:col] }
  end
end
