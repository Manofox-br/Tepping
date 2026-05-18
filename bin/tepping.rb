#!/usr/bin/env ruby

# Importa os arquivos do núcleo da linguagem
require_relative '../src/lexer'
require_relative '../src/parser'
require_relative '../src/interpreter'

# Verifica se o usuário passou um arquivo para rodar
if ARGV.empty?
  puts "Uso: tepping <caminho/do/arquivo.tp>"
  exit(1)
end

file_path = ARGV[0]

# Verifica se o arquivo existe
unless File.exist?(file_path)
  puts "Erro: Arquivo '#{file_path}' não encontrado."
  exit(1)
end

# Lê o código fonte do arquivo .tp
code = File.read(file_path)

# Inicia o processo de interpretação da Tepping
begin
  # 1. Lexer transforma texto em tokens e guarda as linhas originais
  lexer = Lexer.new(code)
  tokens = lexer.tokenize

  # 2. Parser transforma tokens na Árvore de Sintaxe (AST)
  parser = Parser.new(tokens)
  ast = parser.parse

  # 3. Interpreter roda a Árvore de Sintaxe usando as linhas para o sistema de erros
  interpreter = Interpreter.new(ast, lexer.lines)
  interpreter.run

rescue => e
  # Captura qualquer erro de sintaxe genérico ou léxico e exibe formatado
  puts e.message
end
