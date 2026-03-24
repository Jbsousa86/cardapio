// ==========================================
// CONFIGURAÇÕES DOS ESTABELECIMENTOS
// ==========================================

// ==========================================
// SELEÇÃO AUTOMÁTICA DA LOJA
// ==========================================

const urlParams = new URLSearchParams(window.location.search);
const storeId = urlParams.get('s') || 'default';
console.log("Loja detectada:", storeId);
const currentStore = STORES_DATA[storeId] || STORES_DATA['default'];

const CONFIG = currentStore.CONFIG;
const PRODUCTS = currentStore.PRODUCTS;

// ==========================================
// LÓGICA DO SITE (NÃO PRECISA MEXER AQUI)
// ==========================================

function formatPrice(priceNumber) {
    return `R$ ${priceNumber.toFixed(2).replace('.', ',')}`;
}

if ('scrollRestoration' in history) {
    history.scrollRestoration = 'manual';
}

// Função para aplicar o tema visual
function applyTheme(theme) {
    if (!theme) return;
    const root = document.documentElement;
    if (theme.primaryBg) root.style.setProperty('--primary-bg', theme.primaryBg);
    if (theme.accent) root.style.setProperty('--accent', theme.accent);
    if (theme.accentHover) root.style.setProperty('--accent-hover', theme.accentHover);
}

document.addEventListener("DOMContentLoaded", () => {
    window.scrollTo(0, 0);

    // Aplica as cores da marca
    applyTheme(CONFIG.theme);

    document.title = `Menu | ${CONFIG.name}${CONFIG.nameHighlight}`;
    document.getElementById("brand-name").innerHTML = `${CONFIG.name}<span>${CONFIG.nameHighlight}</span>`;
    document.getElementById("brand-subtitle").textContent = CONFIG.subtitle;
    document.getElementById("brand-slogan").textContent = CONFIG.slogan;
    document.getElementById("year").textContent = new Date().getFullYear();

    const logoImg = document.getElementById("brand-logo");
    if (CONFIG.logoUrl && CONFIG.logoUrl !== "") {
        logoImg.src = CONFIG.logoUrl;
        logoImg.style.display = "block";
    } else {
        logoImg.style.display = "none";
    }

    const headerElement = document.querySelector(".header");
    if (CONFIG.headerImageUrls && CONFIG.headerImageUrls.length > 0) {
        headerElement.style.setProperty("--header-bg-image-1", `url('${CONFIG.headerImageUrls[0]}')`);
        
        if (CONFIG.headerImageUrls.length > 1) {
            headerElement.style.setProperty("--header-bg-image-2", `url('${CONFIG.headerImageUrls[1]}')`);
            setInterval(() => {
                headerElement.classList.toggle("show-second-bg");
            }, 5000);
        } else {
            headerElement.classList.remove("show-second-bg");
            headerElement.style.setProperty("--header-bg-image-2", "none");
        }
    }

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

    // Lógica do Botão de Compartilhar
    const btnShare = document.getElementById("btn-share");
    if (btnShare) {
        btnShare.addEventListener("click", async () => {
            const shareData = {
                title: `Cardápio | ${CONFIG.name}${CONFIG.nameHighlight}`,
                text: `Dê uma olhada no cardápio de ${CONFIG.name}!`,
                url: window.location.href
            };

            try {
                if (navigator.share) {
                    await navigator.share(shareData);
                } else {
                    await navigator.clipboard.writeText(window.location.href);
                    
                    // Feedback visual no ícone
                    const originalColor = btnShare.style.color;
                    btnShare.style.color = 'var(--accent)';
                    btnShare.style.borderColor = 'var(--accent)';
                    
                    setTimeout(() => {
                        btnShare.style.color = originalColor;
                        btnShare.style.borderColor = 'rgba(255, 255, 255, 0.1)';
                    }, 2000);
                }
            } catch (err) {
                console.log("Erro ao compartilhar:", err);
            }
        });
    }

    renderCategories();
    renderProducts();
});

