# Notação de Erros

---

## Variáveis não definidas
- **Posível erro**: tentar obter uma variável sem definilas antes podem ocasionar esse erro.
   ```tepping
   console.print("$var(exemplo)")
   ```
- **console**: resultado vai ser:
   ```console
   erro (Variáveis não defnidas) em linha:coluna.
   "console.print("=>$var(exemplo)<=")"
   $var(exemplo) não foi defnida
  ```

## Loops de funções
- **Posível erro**: repetir chamadas de funções nelas mesmas.
   ```tepping
   def "exemplo"(): {
     func "exemplo"()
   }
   ```
- **console**: resultado vai ser:
   ```console
   erro em linha:coluna.
   "def "exemplo"(): {
     =>func "exemplo"()<=
   }"
   você não pode iniciar uma função dentro de uma função
   ```
- **Outro posível erro**: se baseia nesse mesmo erro, mas se adiciona mais funções.
   ```tepping
   def "exemploA"(): {
     func "exemploB"()
   }
   def "exemploB"(): {
    func "exemploA"()
   }
   ```
- **console**: resultado vai ser:
   ```console
   erro (Loops de funções) em linha:coluna.
   "def "exemploA"(): {
     func "exemploB"()
   }
   def "exemploB"(): {
    =>func "exemploA"()<=
   }"
   você não pode iniciar uma funções dentro de uma funções
   ```

## Outros erros (erros de sintaxe)
- **Posível erro**: aqui nao tem erro específico, pode ser algo escrito errado, coisas for ados lugar, tome cuidado.

---

### Última edição: 27/05/26
