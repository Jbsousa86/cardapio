class StoreTenantApp {
    constructor(storeKey) {
        this.storeKey = storeKey;
        // Busca os dados da loja correspondente ou faz fallback para default
        const storeData = STORES_DATA[this.storeKey] || STORES_DATA['default'];
        this.config = storeData.CONFIG;
        this.hiddenCategories = this.config.hiddenCategories || [];
        
        // Carrega os produtos para o cardápio (exceto os que pertencem a categorias ocultas)
        this.products = storeData.PRODUCTS.filter(p => !this.hiddenCategories.includes(p.category));

        // Gerenciamento de Estado
        this.categories = ['Todos', ...new Set(this.products.map(p => p.category))];
        this.currentCategory = 'Todos';
        this.searchQuery = '';
        this.isLightTheme = this.config.themeMode === 'light';

        try {
            const savedTheme = localStorage.getItem(`cardapio-theme-${this.storeKey}`);
            if (savedTheme === 'light' || savedTheme === 'dark') {
                this.isLightTheme = savedTheme === 'light';
            }
        } catch (error) {
            this.isLightTheme = this.config.themeMode === 'light';
        }
        
        this.cart = []; // Nosso estado do carrinho
        this.currentProductForExtras = null; // Guarda o produto alvo
    }

    init() {
        this.applyTheme();
        this.setupThemeToggle();
        this.setupHeader();
        this.setupCart();
        this.setupSearch();
        this.renderBrandInfo();
        this.renderPromo();
        this.setupShareButton();
        this.setupBackToTop();
        
        // Renderizações iniciais
        this.renderCategories();
        this.renderProducts();
    }

    applyTheme() {
        const root = document.documentElement;
        root.setAttribute('data-theme', this.isLightTheme ? 'light' : 'dark');

        if (this.config.theme) {
            if (!this.isLightTheme) {
                root.style.setProperty('--primary-bg', this.config.theme.primaryBg);
            }
            root.style.setProperty('--accent', this.config.theme.accent);
            root.style.setProperty('--accent-hover', this.config.theme.accentHover);
        }

        const toggle = document.getElementById('theme-toggle');
        if (toggle) {
            toggle.setAttribute('aria-pressed', this.isLightTheme ? 'true' : 'false');
            toggle.title = this.isLightTheme ? 'Ativar tema escuro' : 'Ativar tema claro';
            toggle.innerHTML = this.isLightTheme ? '🌙' : '☀️';
        }
    }

    showToast(message) {
        let toast = document.getElementById('toast-msg');
        if (!toast) {
            toast = document.createElement('div');
            toast.id = 'toast-msg';
            toast.className = 'toast';
            document.body.appendChild(toast);
        }
        toast.innerHTML = message;
        toast.classList.add('show');
        
        if (this.toastTimeout) clearTimeout(this.toastTimeout);
        this.toastTimeout = setTimeout(() => {
            toast.classList.remove('show');
        }, 3000);
    }

    async persistThemeToFirestore() {
        if (typeof db === 'undefined' || !this.storeKey) return;

        this.config.themeMode = this.isLightTheme ? 'light' : 'dark';

        try {
            await db.collection('stores').doc(this.storeKey).set({
                CONFIG: {
                    themeMode: this.config.themeMode
                }
            }, { merge: true });
        } catch (error) {
            console.error('Erro ao salvar tema no Firestore:', error);
        }
    }

    setupThemeToggle() {
        const toggle = document.getElementById('theme-toggle');
        if (!toggle) return;

        toggle.addEventListener('click', async () => {
            this.isLightTheme = !this.isLightTheme;
            try {
                localStorage.setItem(`cardapio-theme-${this.storeKey}`, this.isLightTheme ? 'light' : 'dark');
            } catch (error) {
                // Ignora falhas de armazenamento local
            }
            this.applyTheme();
            await this.persistThemeToFirestore();
        });
    }

    setupHeader() {
        const header = document.querySelector('.header');
        if (this.config.headerImageUrls && this.config.headerImageUrls.length >= 2) {
            const root = document.documentElement;
            root.style.setProperty('--header-bg-image-1', `url('${this.config.headerImageUrls[0]}')`);
            root.style.setProperty('--header-bg-image-2', `url('${this.config.headerImageUrls[1]}')`);
            
            setInterval(() => {
                header.classList.toggle('show-second-bg');
            }, 4000);
        } else if (this.config.headerImageUrls && this.config.headerImageUrls.length === 1) {
            document.documentElement.style.setProperty('--header-bg-image-1', `url('${this.config.headerImageUrls[0]}')`);
        }
    }

    renderBrandInfo() {
        document.getElementById('page-title').textContent = `Cardápio | ${this.config.name} ${this.config.nameHighlight}`;
        
        const logoImg = document.getElementById('brand-logo');
        if (this.config.logoUrl) {
            logoImg.src = this.config.logoUrl;
            logoImg.style.display = 'block';
        }
        
        document.getElementById('brand-name').innerHTML = `${this.config.name} <span>${this.config.nameHighlight}</span>`;
        document.getElementById('brand-subtitle').textContent = this.config.subtitle;
        document.getElementById('brand-slogan').textContent = this.config.slogan;
        
        const yearElem = document.getElementById('year');
        if (yearElem) yearElem.textContent = new Date().getFullYear();
    }

    formatCurrency(value) {
        return value.toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' });
    }

    renderPromo() {
        const promoSection = document.getElementById('promo-section');
        if (this.config.todayPromo) {
            const promo = this.config.todayPromo;
            document.getElementById('promo-image').src = promo.image;
            document.getElementById('promo-image').style.display = 'block';
            document.getElementById('promo-title').textContent = promo.title;
            document.getElementById('promo-desc').textContent = promo.description;
            document.getElementById('promo-price').textContent = this.formatCurrency(promo.price);
            
            const orderBtn = document.getElementById('promo-order');
            // Garante que não duplique listeners se for chamado de novo
            orderBtn.replaceWith(orderBtn.cloneNode(true));
            document.getElementById('promo-order').addEventListener('click', () => {
                this.addToCart({ name: promo.title, price: promo.price });
            });
            
            promoSection.style.display = 'block';
        } else {
            promoSection.style.display = 'none';
        }
    }

    setupSearch() {
        const searchInput = document.getElementById('search-input');
        searchInput.addEventListener('input', (e) => {
            this.searchQuery = e.target.value;
            this.renderProducts();
        });
    }

    renderCategories() {
        const categoryMenu = document.getElementById('category-menu');
        categoryMenu.innerHTML = '';
        
        this.categories.forEach(cat => {
            const btn = document.createElement('button');
            btn.className = `btn-category ${cat === this.currentCategory ? 'active' : ''}`;
            btn.textContent = cat;
            btn.addEventListener('click', () => {
                this.currentCategory = cat;
                this.renderCategories();
                this.renderProducts();
            });
            categoryMenu.appendChild(btn);
        });
    }

    renderProducts() {
        const productList = document.getElementById('product-list');
        productList.innerHTML = '';
        
        const filteredProducts = this.products.filter(p => {
            const matchesCategory = this.currentCategory === 'Todos' || p.category === this.currentCategory;
            const matchesSearch = p.name.toLowerCase().includes(this.searchQuery.toLowerCase()) || 
                                  p.description.toLowerCase().includes(this.searchQuery.toLowerCase());
            
            return matchesCategory && matchesSearch;
        });

        if (filteredProducts.length === 0) {
            productList.innerHTML = `
                <div class="empty-state">
                    <p>😕 Nenhum produto encontrado.</p>
                    <small>Tente alterar sua busca ou categoria.</small>
                </div>
            `;
            return;
        }

        filteredProducts.forEach(product => {
            const card = document.createElement('div');
            // Adiciona a classe 'sold-out' se o produto estiver esgotado
            card.className = `card ${product.soldOut ? 'sold-out' : ''}`;
            
            let displayPrice = this.formatCurrency(product.price);
            if (product.byWeight) {
                displayPrice = `${this.formatCurrency(product.price)} <span style="font-size:0.7rem; color:var(--text-muted); font-weight:normal;">/ kg</span>`;
            } else if (product.variants && product.variants.length > 0) {
                const minPrice = Math.min(...product.variants.map(v => v.price));
                displayPrice = `<span style="font-size:0.7rem; color:var(--text-muted); font-weight:normal;">A partir de</span><br>${this.formatCurrency(minPrice)}`;
            }

            card.innerHTML = `
                <div class="card-image-wrapper">
                    <img src="${product.image}" alt="${product.name}" class="card-image">
                </div>
                <div class="card-content">
                    <h3 class="card-title">${product.name}</h3>
                    <p class="card-description">${product.description}</p>
                    <div class="card-footer">
                        <span class="price" style="line-height: 1.2;">${displayPrice}</span>
                        <button class="btn-order" ${product.soldOut ? 'disabled' : ''}>
                            ${product.soldOut ? 'Indisponível' : 'Adicionar 🛒'}
                        </button>
                    </div>
                </div>
            `;

            // Adiciona o evento de clique apenas se o produto NÃO estiver esgotado
            if (!product.soldOut) {
                const btnOrder = card.querySelector('.btn-order');
                btnOrder.addEventListener('click', () => this.addToCart(product));
            }
            
            productList.appendChild(card);
        });
    }

    // ==========================================
    // LÓGICA DO CARRINHO
    // ==========================================
    setupCart() {
        this.cartFab = document.getElementById('cart-fab');
        this.cartModal = document.getElementById('cart-modal');
        this.cartOverlay = document.getElementById('cart-overlay');
        this.cartBadge = document.getElementById('cart-badge');
        this.cartItemsContainer = document.getElementById('cart-items');
        this.cartTotalPrice = document.getElementById('cart-total-price');

        this.cartFab.addEventListener('click', () => this.toggleCart(true));
        document.getElementById('close-cart').addEventListener('click', () => this.toggleCart(false));
        this.cartOverlay.addEventListener('click', () => this.toggleCart(false));
        document.getElementById('btn-checkout').addEventListener('click', () => this.checkout());

        // Eventos do Modal de Extras
        document.getElementById('close-extras').addEventListener('click', () => this.toggleExtrasModal(false));
        document.getElementById('extras-overlay').addEventListener('click', () => this.toggleExtrasModal(false));
        document.getElementById('btn-confirm-extras').addEventListener('click', () => this.confirmExtrasAndAdd());
    }

    toggleCart(show) {
        if (show) {
            this.cartOverlay.classList.add('active');
            this.cartModal.classList.add('active');
        } else {
            this.cartOverlay.classList.remove('active');
            this.cartModal.classList.remove('active');
        }
    }

    toggleExtrasModal(show) {
        const overlay = document.getElementById('extras-overlay');
        const modal = document.getElementById('extras-modal');
        if (show) {
            overlay.classList.add('active');
            modal.classList.add('active');
        } else {
            overlay.classList.remove('active');
            modal.classList.remove('active');
        }
    }

    addToCart(product) {
        // Prevenção extra para não adicionar item esgotado
        if (product.soldOut) return;

        const hasVariants = product.variants && product.variants.length > 0;
        const hasExtras = product.extras && product.extras.length > 0;

        if (hasVariants || hasExtras) {
            this.currentProductForExtras = product;
            document.getElementById('extras-title').textContent = product.name;
            
            const list = document.getElementById('extras-list');
            list.innerHTML = '';
            
            if (hasVariants) {
                const variantHeader = document.createElement('strong');
                variantHeader.style.display = 'block';
                variantHeader.style.marginBottom = '10px';
                variantHeader.textContent = 'Escolha o Tamanho/Peso (Obrigatório):';
                list.appendChild(variantHeader);

                product.variants.forEach((variant, index) => {
                    const div = document.createElement('label');
                    div.className = 'extra-option';
                    div.innerHTML = `
                        <span style="display:flex; align-items:center; gap:10px;"><input type="radio" name="variant-radio" class="variant-radio" data-index="${index}" style="width:18px; height:18px; accent-color:var(--accent);"> ${variant.name}</span>
                        <span class="price">${this.formatCurrency(variant.price)}</span>
                    `;
                    list.appendChild(div);
                });
            }

            if (hasExtras) {
                const extraHeader = document.createElement('strong');
                extraHeader.style.display = 'block';
                extraHeader.style.marginTop = hasVariants ? '15px' : '0';
                extraHeader.style.marginBottom = '10px';
                extraHeader.textContent = 'Adicionais (Opcional):';
                list.appendChild(extraHeader);

                product.extras.forEach((extra, index) => {
                    const div = document.createElement('label');
                    div.className = 'extra-option';
                    div.innerHTML = `
                        <span style="display:flex; align-items:center; gap:10px;"><input type="checkbox" class="extra-checkbox" data-index="${index}" style="width:18px; height:18px; accent-color:var(--accent);"> ${extra.name}</span>
                        <span class="price">+ ${this.formatCurrency(extra.price)}</span>
                    `;
                    list.appendChild(div);
                });
            }

            this.toggleExtrasModal(true);
        } else {
            this.finalizeAddToCart(product, null, []);
        }
    }

    confirmExtrasAndAdd() {
        let selectedVariant = null;
        if (this.currentProductForExtras.variants && this.currentProductForExtras.variants.length > 0) {
            const checkedVariant = document.querySelector('.variant-radio:checked');
            if (!checkedVariant) {
                alert('Por favor, escolha uma das opções obrigatórias de tamanho/peso.');
                return;
            }
            selectedVariant = this.currentProductForExtras.variants[checkedVariant.getAttribute('data-index')];
        }

        const selectedExtras = [];
        const checkboxes = document.querySelectorAll('.extra-checkbox:checked');
        checkboxes.forEach(cb => {
            const index = cb.getAttribute('data-index');
            selectedExtras.push(this.currentProductForExtras.extras[index]);
        });
        this.finalizeAddToCart(this.currentProductForExtras, selectedVariant, selectedExtras);
        this.toggleExtrasModal(false);
    }

    finalizeAddToCart(product, selectedVariant, selectedExtras) {
        // Gera um ID único baseado no nome e nos extras escolhidos para não misturar pedidos diferentes do mesmo item
        const cartItemId = product.name + (selectedVariant ? selectedVariant.name : '') + JSON.stringify(selectedExtras);
        
        const cartItem = {
            ...product,
            selectedVariant: selectedVariant,
            selectedExtras: selectedExtras,
            cartItemId: cartItemId
        };

        const existingItem = this.cart.find(item => item.cartItemId === cartItem.cartItemId);
        if (existingItem) {
            existingItem.quantity += 1;
        } else {
            this.cart.push({ ...cartItem, quantity: 1 });
        }
        this.updateCartUI();
        
        // Efeito de pulso para indicar que adicionou
        this.cartFab.style.transform = 'scale(1.2)';
        setTimeout(() => this.cartFab.style.transform = 'scale(1)', 200);

        this.showToast('✅ Produto adicionado ao carrinho!');
    }

    changeQuantity(cartItemId, delta) {
        const itemIndex = this.cart.findIndex(item => item.cartItemId === cartItemId);
        if (itemIndex > -1) {
            this.cart[itemIndex].quantity += delta;
            if (this.cart[itemIndex].quantity <= 0) {
                this.cart.splice(itemIndex, 1); // Remove do carrinho se zerar
            }
        }
        this.updateCartUI();
    }

    removeItem(cartItemId) {
        this.cart = this.cart.filter(item => item.cartItemId !== cartItemId);
        this.updateCartUI();
    }

    updateCartUI() {
        const totalItems = this.cart.reduce((sum, item) => sum + item.quantity, 0);
        this.cartBadge.textContent = totalItems;
        this.cartFab.style.display = totalItems > 0 ? 'flex' : 'none';

        if (totalItems === 0) this.toggleCart(false); // Fecha o modal se esvaziar

        this.cartItemsContainer.innerHTML = '';
        let totalPrice = 0;

        this.cart.forEach(item => {
            // Soma o valor do item mais o valor de todos os extras selecionados
            const basePrice = item.selectedVariant ? item.selectedVariant.price : item.price;
            const extrasTotal = item.selectedExtras ? item.selectedExtras.reduce((s, e) => s + e.price, 0) : 0;
            const itemTotal = (basePrice + extrasTotal) * item.quantity;
            totalPrice += itemTotal;

            // Exibe de forma sutil os adicionais escolhidos abaixo do nome no carrinho
            const variantText = item.selectedVariant ? ` <span style="color:var(--accent); font-size:0.8rem;">(${item.selectedVariant.name})</span>` : '';
            const extrasText = item.selectedExtras && item.selectedExtras.length > 0 
                ? `<small style="color:var(--text-muted); display:block; margin-top:3px;">+ ${item.selectedExtras.map(e => e.name).join(', ')}</small>` 
                : '';

            const itemEl = document.createElement('div');
            itemEl.className = 'cart-item';
            itemEl.innerHTML = `
                <div class="cart-item-info"><h4>${item.name}${variantText}</h4>${extrasText}<p style="margin-top:0.2rem;">${this.formatCurrency(itemTotal)}</p></div>
                <div class="cart-controls">
                    <button class="btn-minus">-</button> <span>${item.quantity}</span> <button class="btn-plus">+</button>
                    <button class="btn-remove" title="Remover item">🗑️</button>
                </div>
            `;
            itemEl.querySelector('.btn-minus').addEventListener('click', () => this.changeQuantity(item.cartItemId, -1));
            itemEl.querySelector('.btn-plus').addEventListener('click', () => this.changeQuantity(item.cartItemId, 1));
            itemEl.querySelector('.btn-remove').addEventListener('click', () => this.removeItem(item.cartItemId));
            this.cartItemsContainer.appendChild(itemEl);
        });
        this.cartTotalPrice.textContent = this.formatCurrency(totalPrice);
    }

    checkout() {
        if (this.cart.length === 0) return;
        let message = `Olá, vim pelo cardápio online! Gostaria de pedir:\n\n`;
        let total = 0;
        
        this.cart.forEach(item => {
            const basePrice = item.selectedVariant ? item.selectedVariant.price : item.price;
            const extrasTotal = item.selectedExtras ? item.selectedExtras.reduce((s, e) => s + e.price, 0) : 0;
            const itemTotal = (basePrice + extrasTotal) * item.quantity;
            total += itemTotal;
            const variantText = item.selectedVariant ? ` (${item.selectedVariant.name})` : '';
            message += `*${item.quantity}x* ${item.name}${variantText} - ${this.formatCurrency(itemTotal)}\n`;
            if (item.selectedExtras && item.selectedExtras.length > 0) {
                message += `  ↳ *Adicionais:* ${item.selectedExtras.map(e => e.name).join(', ')}\n`;
            }
        });

        const paymentMethod = document.getElementById('cart-payment-method').value;
        if (!paymentMethod) {
            alert('Por favor, selecione uma forma de pagamento antes de finalizar o pedido.');
            return;
        }

        const notes = document.getElementById('cart-notes').value.trim();
        if (notes) {
            message += `\n*Observações/Endereço:*\n${notes}\n`;
        }

        message += `\n*Forma de Pagamento:* ${paymentMethod}\n`;
        message += `\n*Total:* ${this.formatCurrency(total)}\n\nComo funciona para entrega?`;
        const encodedMessage = encodeURIComponent(message);
        
        const btnCheckout = document.getElementById('btn-checkout');
        const originalText = btnCheckout.innerHTML;
        btnCheckout.innerHTML = '<span class="spinner"></span> Gerando pedido...';
        btnCheckout.disabled = true;

        setTimeout(() => {
            window.open(`https://wa.me/${this.config.whatsappNumber}?text=${encodedMessage}`, '_blank');
            
            // Limpa o carrinho e atualiza a interface após o redirecionamento
            this.cart = [];
            const notesInput = document.getElementById('cart-notes');
            if (notesInput) notesInput.value = '';
            const paymentInput = document.getElementById('cart-payment-method');
            if (paymentInput) paymentInput.value = '';
            this.updateCartUI();
            
            btnCheckout.innerHTML = originalText;
            btnCheckout.disabled = false;
        }, 1200);
    }

    setupShareButton() {
        const btnShare = document.getElementById('btn-share');
        if (btnShare) {
            btnShare.addEventListener('click', async () => {
                try {
                    await navigator.clipboard.writeText(window.location.href);
                    alert('Link do cardápio copiado para a área de transferência! Envie para seus amigos.');
                } catch (err) {
                    console.error('Erro ao copiar o link', err);
                }
            });
        }
    }

    setupBackToTop() {
        const backToTopBtn = document.getElementById('back-to-top');
        if (!backToTopBtn) return;

        window.addEventListener('scroll', () => {
            if (window.scrollY > 300) {
                backToTopBtn.classList.add('visible');
            } else {
                backToTopBtn.classList.remove('visible');
            }
        });

        backToTopBtn.addEventListener('click', () => {
            window.scrollTo({ top: 0, behavior: 'smooth' });
        });
    }
}

document.addEventListener('DOMContentLoaded', async () => {
    // Pega a loja pela URL (Ex: index.html?s=pizzaria)
    const urlParams = new URLSearchParams(window.location.search);
    const storeKey = urlParams.get('s') || 'default';
    
    try {
        // Busca os dados desta loja específica diretamente da nuvem
        const docRef = await db.collection('stores').doc(storeKey).get();
        if (docRef.exists) {
            STORES_DATA[storeKey] = docRef.data();
        }
    } catch (error) {
        console.error("Erro ao carregar do banco de dados na nuvem. Usando fallback local: ", error);
    }

    // Instancia a loja e inicializa o aplicativo garantindo um escopo fechado (isolado)
    const app = new StoreTenantApp(storeKey);
    app.init();
});