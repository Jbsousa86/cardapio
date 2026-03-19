// ==========================================
// CONFIGURAÇÕES GERAIS DO ESTABELECIMENTO
// ==========================================
// Altere os valores abaixo de acordo com o seu negócio. O site vai se atualizar sozinho!

const CONFIG = {
    // 1. Seu número de WhatsApp (Apenas números, inclua DDD. Ex: 5511999999999)
    whatsappNumber: "5563999756166",
    
    // 2. O nome do seu estabelecimento
    name: "SeuNegócio",
    
    // 3. A segunda parte do nome (Fica verde/em destaque)
    nameHighlight: "Aqui",
    
    // 4. Frase de subtítulo (Abaixo do nome)
    subtitle: "A melhor experiência em delivery da cidade!",
    
    // 5. Frase extra ou slogan (Se quiser apagar, deixe vazio "")
    slogan: "Aberto de Terça a Domingo das 18h às 23h",
    
    // 6. Imagem da sua Logo (Se não tiver, deixe vazio "")
    logoUrl: "./images/image.png",
    
    // 7. Imagens de fundo do Cabeçalho (Crossfade)
    // Deixei duas imagens diferentes para que fiquem trocando sozinhas!
    headerImageUrls: [
        "https://images.unsplash.com/photo-1550547660-d9450f859349?ixlib=rb-4.0.3&auto=format&fit=crop&w=1920&q=80",
        "https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?ixlib=rb-4.0.3&auto=format&fit=crop&w=1920&q=80"
    ],
};


// ==========================================
// LISTA DE PRODUTOS
// ==========================================
// Edite, copie e cole blocos entre chaves {} para adicionar mais itens.

const PRODUCTS = [
    {
        name: "Hambúrguer Clássico",
        description: "Pão, carne artesanal de 160g, queijo, alface e tomate.",
        price: 25.90,
        image: "./images/burger.png",
        category: "Lanches"
    },
    {
        name: "Pizza de Calabresa",
        description: "Massa fina, molho de tomate, calabresa fatiada, cebola e orégano.",
        price: 45.00,
        image: "./images/pizza.png",
        category: "Pizzas"
    },
    {
        name: "Bolo de Chocolate",
        description: "Fatia deliciosa de bolo de chocolate com cobertura cremosa.",
        price: 15.50,
        image: "./images/dessert.png",
        category: "Sobremesas"
    },
    {
        name: "Refrigerante 350ml",
        description: "Lata gelada (Guaraná, Coca-cola, Sprite).",
        price: 6.00,
        image: "https://images.unsplash.com/photo-1622483767028-3f66f32aef97?ixlib=rb-4.0.3&auto=format&fit=crop&w=400&q=80",
        category: "Bebidas"
    }
];

// ==========================================
// LÓGICA DO SITE (NÃO PRECISA MEXER AQUI)
// ==========================================

function formatPrice(priceNumber) {
    return `R$ ${priceNumber.toFixed(2).replace('.', ',')}`;
}

// Força a página a carregar sempre no topo absoluto, ignorando o cache de rolagem do navegador
if ('scrollRestoration' in history) {
    history.scrollRestoration = 'manual';
}

document.addEventListener("DOMContentLoaded", () => {
    // Joga a tela de volta pro topo imediatamente após o carregamento
    window.scrollTo(0, 0);

    // 1. Aplicar Configurações Visuais Automatically
    document.title = `Menu | ${CONFIG.name}${CONFIG.nameHighlight}`;
    document.getElementById("brand-name").innerHTML = `${CONFIG.name}<span>${CONFIG.nameHighlight}</span>`;
    document.getElementById("brand-subtitle").textContent = CONFIG.subtitle;
    document.getElementById("brand-slogan").textContent = CONFIG.slogan;
    document.getElementById("year").textContent = new Date().getFullYear();

    // Mostrar ou esconder logo baseada na configuração
    const logoImg = document.getElementById("brand-logo");
    if (CONFIG.logoUrl && CONFIG.logoUrl !== "") {
        logoImg.src = CONFIG.logoUrl;
        logoImg.style.display = "block"; // Revela a logo se existir
    }

    // Configurar as imagens de fundo em slide
    const headerElement = document.querySelector(".header");
    if (CONFIG.headerImageUrls && CONFIG.headerImageUrls.length > 0) {
        // Define a primeira imagem
        headerElement.style.setProperty("--header-bg-image-1", `url('${CONFIG.headerImageUrls[0]}')`);
        
        // Se houver uma segunda imagem, define ela e inicia o temporizador "pisca-pisca" suave
        if (CONFIG.headerImageUrls.length > 1) {
            headerElement.style.setProperty("--header-bg-image-2", `url('${CONFIG.headerImageUrls[1]}')`);
            
            // Troca o fundo a cada 5 segundos
            setInterval(() => {
                headerElement.classList.toggle("show-second-bg");
            }, 5000);
        }
    }

    // 2. Renderizar Categorias e Produtos
    const productListContainer = document.getElementById("product-list");
    const categoryMenuContainer = document.getElementById("category-menu");

    const categories = ["Todos", ...new Set(PRODUCTS.map(p => p.category))];
    let currentCategory = "Todos";

    function renderCategories() {
        categoryMenuContainer.innerHTML = categories.map(cat => `
            <button class="btn-category ${cat === currentCategory ? 'active' : ''}" data-category="${cat}">
                ${cat}
            </button>
        `).join('');

        const categoryButtons = document.querySelectorAll(".btn-category");
        categoryButtons.forEach(btn => {
            btn.addEventListener("click", (e) => {
                currentCategory = btn.getAttribute("data-category");
                renderCategories();
                renderProducts();
            });
        });
    }

    function renderProducts() {
        const filteredProducts = currentCategory === "Todos" 
            ? PRODUCTS 
            : PRODUCTS.filter(p => p.category === currentCategory);

        productListContainer.innerHTML = filteredProducts.map(product => `
            <article class="card">
                <div class="card-image-wrapper">
                    <img src="${product.image}" alt="${product.name}" class="card-image">
                </div>
                <div class="card-content">
                    <h3 class="card-title">${product.name}</h3>
                    <p class="card-description">${product.description}</p>
                    <div class="card-footer">
                        <span class="price">${formatPrice(product.price)}</span>
                        <button class="btn-order" data-name="${product.name}" data-price="${product.price.toFixed(2)}">
                            <span>Pedir Agora</span>
                            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7A2 2 0 0 1 22 16.92z"></path></svg>
                        </button>
                    </div>
                </div>
            </article>
        `).join('');

        // Recapturar eventos dos botões recém renderizados
        const orderButtons = document.querySelectorAll(".btn-order");
        orderButtons.forEach(button => {
            button.addEventListener("click", (e) => {
                const productName = button.getAttribute("data-name");
                const productPrice = button.getAttribute("data-price");
                
                const message = `Olá, vim do cardápio online do *${CONFIG.name}${CONFIG.nameHighlight}*!\n\nGostaria de pedir:\n1x *${productName}*\nValor unitário: R$ ${productPrice.replace('.', ',')}\n\nPoderia me informar as opções de pagamento e o tempo de entrega?`;
                
                const encodedMessage = encodeURIComponent(message);
                const whatsappURL = `https://wa.me/${CONFIG.whatsappNumber}?text=${encodedMessage}`;
                
                window.open(whatsappURL, '_blank');
            });
        });
    }

    renderCategories();
    renderProducts();
});
