#!/bin/bash

# 1. Descobre a pasta atual de onde o usuário está rodando o instalador
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 2. Define uma pasta OCULTA no sistema do usuário para guardar a linguagem
# No Linux/Android, qualquer pasta que começa com um ponto (.) fica invisível
INSTALL_DIR="$HOME/.tepping_lang"

echo "📦 Instalando a Tepping no sistema..."

# 3. Cria a pasta oculta e copia apenas o código-fonte e o binário para lá
mkdir -p "$INSTALL_DIR"
cp -r "$DIR/bin" "$DIR/src" "$INSTALL_DIR/"

# Dá permissão para o Ruby rodar o arquivo lá dentro da pasta oculta
chmod +x "$INSTALL_DIR/bin/tepping.rb"

# 4. Descobre se é Android (Termux) ou Linux Normal
if [ -d "/data/data/com.termux/files/usr/bin" ]; then
    TARGET="/data/data/com.termux/files/usr/bin/tepping"
else
    TARGET="/usr/local/bin/tepping"
fi

# 5. Cria o atalho no sistema, mas agora apontando para a pasta OCULTA
echo '#!/bin/bash' > "$TARGET"
echo "ruby \"$INSTALL_DIR/bin/tepping.rb\" \"\$@\"" >> "$TARGET"
chmod +x "$TARGET"

echo "✅ Tepping instalada com sucesso!"
echo "A linguagem agora faz parte do seu sistema."
echo "Se quiser, você já pode apagar a pasta que baixou."
