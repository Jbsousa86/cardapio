// ==========================================
// BANCO DE DADOS DOS ESTABELECIMENTOS
// ==========================================
// Adicione novas lojas aqui e elas aparecerão no Hub automaticamente!

const STORES_DATA = {
    "default": {
        CONFIG: {
            whatsappNumber: "5563999756166",
            name: "SeuNegócio",
            nameHighlight: "Aqui",
            subtitle: "A melhor experiência em delivery da cidade!",
            slogan: "Aberto de Terça a Domingo das 18h às 23h",
            logoUrl: "https://tse4.mm.bing.net/th/id/OIP.Rf3lxtuuTH8MOQJowy4ubQHaHa?pid=Api&P=0&h=180",
            headerImageUrls: [
                "https://images.unsplash.com/photo-1550547660-d9450f859349?ixlib=rb-4.0.3&auto=format&fit=crop&w=1920&q=80",
                "https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?ixlib=rb-4.0.3&auto=format&fit=crop&w=1920&q=80"
            ],
            theme: {
                primaryBg: "#100732",
                accent: "#17e01bff",
                accentHover: "#122790ff"
            }
        },
        PRODUCTS: [
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
        ]
    },
    "pizzaria": {
        CONFIG: {
            whatsappNumber: "5511999999999",
            name: "Pizzaria",
            nameHighlight: "Premium",
            subtitle: "Massa fininha e ingredientes selecionados.",
            slogan: "Entregas em até 40 minutos!",
            logoUrl: "https://tse2.mm.bing.net/th/id/OIP.byDKeBf0tYMxd3xPb2OrQQHaHa?pid=Api&P=0&h=180",
            headerImageUrls: [
                "https://images.unsplash.com/photo-1513104890138-7c749659a591?ixlib=rb-4.0.3&auto=format&fit=crop&w=1920&q=80",
                "https://images.unsplash.com/photo-1574126154517-d1e0d89ef734?ixlib=rb-4.0.3&auto=format&fit=crop&w=1920&q=80"
            ],
            theme: {
                primaryBg: "#122721ff",
                accent: "#17e408ff",
                accentHover: "#085809ff"
            }
        },
        PRODUCTS: [
            {
                name: "Margherita Especial",
                description: "Muçarela de búfala e manjericão.",
                price: 45.00,
                image: "https://tse1.mm.bing.net/th/id/OIP.-Jd7y8p_VUg3OFzjWkVLzwHaEK?pid=Api&P=0&h=180",
                category: "Pizzas"
            }
        ]
    },
    "acai": {
        CONFIG: {
            whatsappNumber: "5511888888888",
            name: "Rei do",
            nameHighlight: "Açaí",
            subtitle: "Refresque o seu dia com o melhor açaí!",
            slogan: "Monte do seu jeito!",
            logoUrl: "https://tse3.mm.bing.net/th/id/OIP.hcZm1Ia-BjWejDvNTzOItgHaEw?pid=Api&P=0&h=180",
            headerImageUrls: [
                "https://images.unsplash.com/photo-1590301157890-4810ed352733?ixlib=rb-4.0.3&auto=format&fit=crop&w=1920&q=80"
            ],
            theme: {
                primaryBg: "#1e0b2e",
                accent: "#8e44ad",
                accentHover: "#732d91"
            }
        },
        PRODUCTS: [
            { name: "Copo 500ml", description: "Açaí batido na hora.", price: 18.00, image: "https://images.unsplash.com/photo-1590301157890-4810ed352733?ixlib=rb-4.0.3&auto=format&fit=crop&w=400&q=80", category: "Copos" }
        ]
    }
};
