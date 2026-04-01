# 🍔 Cardápio Digital Multi-Tenant

![Status](https://img.shields.io/badge/Status-Concluído-success)
![Licença](https://img.shields.io/badge/Licen%C3%A7a-MIT-blue)
![Tecnologias](https://img.shields.io/badge/Tecnologias-HTML%20%7C%20CSS%20%7C%20JS%20%7C%20Firebase-orange)

Uma plataforma web completa, responsiva e dinâmica para gerenciamento de cardápios online. Permite o cadastro de múltiplas lojas (multi-tenant), carrinho de compras com envio direto para o WhatsApp e um painel de administração totalmente integrado com o Firebase (Autenticação e Banco de Dados em Tempo Real).

---

## ✨ Funcionalidades

### 🛒 Para o Cliente (Cardápio Online)
- **Design Premium:** Interface moderna com efeito *Glassmorphism*, modo escuro amigável e animações suaves (incluindo *crossfade* no cabeçalho).
- **Carrinho de Compras Inteligente:** Adição de produtos, seleção de quantidade e exclusão de itens.
- **Adicionais e Extras:** Suporte a opções extras para produtos (ex: "Borda recheada", "Bacon extra"), somando automaticamente ao valor do item.
- **Formas de Pagamento e Observações:** Campos dedicados no checkout para agilizar o atendimento.
- **Checkout via WhatsApp:** O pedido é formatado em texto organizado e enviado diretamente para o WhatsApp do estabelecimento.
- **Busca e Filtro em Tempo Real:** Pesquisa de produtos por nome e filtro dinâmico por categorias.

### ⚙️ Para o Lojista (Painel Administrativo / Hub)
- **Autenticação Segura:** Login protegido através do Firebase Authentication.
- **Gestão Multi-Lojas:** Crie, edite e exclua diferentes estabelecimentos no mesmo sistema. Cada loja possui sua própria URL (`index.html?s=id-da-loja`).
- **Personalização Total:** Altere cores do tema, imagens de capa, logotipo, textos de cabeçalho e WhatsApp diretamente pelo painel.
- **Gestão de Produtos:** Adicione, edite preços, descrições, imagens e marque itens como "Esgotados" em tempo real.
- **Ocultação de Categorias:** Esconda categorias inteiras dependendo do horário ou disponibilidade.
- **Backup de Dados:** Exporte e restaure todo o banco de dados em formato JSON.

---

## 📸 Capturas de Tela

> **Dica:** Adicione as imagens do seu projeto na pasta raiz e substitua os links abaixo!

<div align="center">
  <img src="https://via.placeholder.com/400x300.png?text=Tela+do+Cardapio" alt="Tela Inicial do Cardápio" width="45%">
  <img src="https://via.placeholder.com/400x300.png?text=Carrinho+de+Compras" alt="Carrinho de Compras" width="45%">
  <br>
  <img src="https://via.placeholder.com/400x300.png?text=Painel+Administrativo" alt="Painel Administrativo Hub" width="45%">
  <img src="https://via.placeholder.com/400x300.png?text=Edicao+de+Produto" alt="Edição de Produtos" width="45%">
</div>

---

## 🛠️ Tecnologias Utilizadas

- **Frontend:** HTML5, CSS3 (Variáveis, Flexbox, Grid), JavaScript (Vanilla/ES6+).
- **Backend (BaaS):** Firebase (Firestore Database).
- **Autenticação:** Firebase Authentication (E-mail e Senha).
- **Hospedagem Recomendada:** GitHub Pages ou Firebase Hosting.

---

## 🚀 Como Executar o Projeto Localmente

1. **Clone o repositório:**
   ```bash
   git clone https://github.com/SEU_USUARIO/SEU_REPOSITORIO.git
   ```
2. **Acesse a pasta do projeto:**
   ```bash
   cd SEU_REPOSITORIO
   ```
3. **Configure o Firebase:**
   - Crie um projeto no Firebase Console.
   - Ative o **Firestore Database** e o **Authentication** (E-mail/Senha).
   - Cadastre um usuário (Administrador) na aba Authentication.
   - Substitua a variável `firebaseConfig` nos arquivos `index.html` e `hub.html` pelas suas credenciais.
   - Configure as Regras de Segurança do Firestore para permitir escrita apenas para usuários logados.

4. **Abra o projeto:**
   - Como o projeto usa JS puro, você pode simplesmente abrir o arquivo `index.html` no seu navegador usando a extensão *Live Server* do VS Code ou abrir diretamente o arquivo.
   - Acesse o painel pelo arquivo `hub.html`. No primeiro login, os dados de exemplo do `data.js` serão enviados automaticamente para o seu banco de dados na nuvem!

---

## 🔗 Como Acessar as Lojas

O sistema identifica qual loja carregar através de parâmetros na URL. 
Exemplo: se você criou uma loja com o ID `minha-loja` no painel, o link do cardápio será:

```text
https://seusite.com/index.html?s=minha-loja
```
*(Se nenhum parâmetro for passado, a loja cadastrada como `default` será carregada).*

---

## 🤝 Contribuição

Contribuições são sempre bem-vindas! Se você tem alguma ideia para melhorar o projeto, sinta-se à vontade para criar um *Pull Request* ou abrir uma *Issue*.

1. Faça o *Fork* do projeto
2. Crie sua *Branch* para a nova *Feature* (`git checkout -b feature/MinhaNovaFeature`)
3. Faça o *Commit* das suas alterações (`git commit -m 'Add: Minha nova feature'`)
4. Faça o *Push* para a *Branch* (`git push origin feature/MinhaNovaFeature`)
5. Abra um *Pull Request*

---

## 📝 Licença

Este projeto está sob a licença MIT. Consulte o arquivo LICENSE para obter mais detalhes.

---

Desenvolvido com 💚 e muita dedicação.